import { describe, it, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { Timestamp } from "firebase-admin/firestore";
import {
  DEFAULT_FOLLOW_UP_CONFIG,
  FOLLOW_UP_LEAD_DAYS,
  FollowUpConfig,
  isTenDayFollowUpMatch,
  nextAutoDueAt,
  nextIstSlot,
  parseFollowUpConfig,
  planFollowUpOnWrite,
  reminderNotificationId,
  reminderRecipients,
  reminderStageDue,
  tenDayNotificationId,
} from "../src/followUpsLogic";
import { applyFollowUpOnWrite, runFollowUpReminders } from "../src/followUps";
import { clearEmulator, hasEmulator, inbox, seedUsers, testDb } from "./helpers";

/** Old schedule still works when explicitly enabled. */
const cfg: FollowUpConfig = { ...DEFAULT_FOLLOW_UP_CONFIG, enabled: true };
const H = 60 * 60 * 1000;
const ist = (s: string) => new Date(`${s}:00+05:30`);

function enquiry(over: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    customerName: "Priya Sharma",
    eventTypeLabel: "Birthday",
    statusValue: "new",
    assignedTo: "staff1",
    createdAt: ist("2026-11-04T08:00"),
    eventDate: ist("2026-12-20T00:00"),
    ...over,
  };
}

describe("follow-up config (pure)", () => {
  it("defaults: scheduled pipeline OFF; FOLLOW_UP_LEAD_DAYS is 10 (matches Dart kFollowUpLeadDays)", () => {
    assert.equal(FOLLOW_UP_LEAD_DAYS, 10);
    assert.deepEqual(parseFollowUpConfig(undefined), DEFAULT_FOLLOW_UP_CONFIG);
    assert.equal(DEFAULT_FOLLOW_UP_CONFIG.enabled, false);
  });
  it("enabled only when followUpsEnabled === true", () => {
    assert.equal(parseFollowUpConfig({}).enabled, false);
    assert.equal(parseFollowUpConfig({ followUpsEnabled: false }).enabled, false);
    assert.equal(parseFollowUpConfig({ followUpsEnabled: true }).enabled, true);
  });
  it("reads admin overrides and ignores out-of-range or terminal values", () => {
    const c = parseFollowUpConfig({
      reminderDaysDefault: 5,
      followUpsEnabled: true,
      followUpDueHourIst: 99,
      followUpEligibleStatuses: ["in_talks", "completed", "not_interested"],
    });
    assert.equal(c.cadenceDays, 5);
    assert.equal(c.enabled, true);
    assert.equal(c.dueHourIst, 10);
    assert.deepEqual(c.eligibleStatuses, ["in_talks"]);
  });
});

describe("isTenDayFollowUpMatch (pure)", () => {
  const now = ist("2026-11-07T12:00");

  it("In Talks at exactly +10 → true; +9 / +11 / past → false", () => {
    assert.equal(isTenDayFollowUpMatch(enquiry({ statusValue: "in_talks", eventDate: ist("2026-11-17T00:00") }), now), true);
    assert.equal(isTenDayFollowUpMatch(enquiry({ statusValue: "in_talks", eventDate: ist("2026-11-16T00:00") }), now), false);
    assert.equal(isTenDayFollowUpMatch(enquiry({ statusValue: "in_talks", eventDate: ist("2026-11-18T00:00") }), now), false);
    assert.equal(isTenDayFollowUpMatch(enquiry({ statusValue: "in_talks", eventDate: ist("2026-11-01T00:00") }), now), false);
  });

  it("New / Approved / lost → false even at +10", () => {
    const day = ist("2026-11-17T00:00");
    for (const status of ["new", "approved", "completed", "not_interested", "closed_lost", "cancelled"]) {
      assert.equal(isTenDayFollowUpMatch(enquiry({ statusValue: status, eventDate: day }), now), false, status);
    }
  });

  it("legacy In Talks aliases count; merged skipped", () => {
    const day = ist("2026-11-17T00:00");
    assert.equal(isTenDayFollowUpMatch(enquiry({ statusValue: "quote_sent", eventDate: day }), now), true);
    assert.equal(isTenDayFollowUpMatch(enquiry({ statusValue: "contacted", eventDate: day }), now), true);
    assert.equal(
      isTenDayFollowUpMatch(enquiry({ statusValue: "in_talks", eventDate: day, mergedInto: "x" }), now),
      false,
    );
  });

  it("multi-function uses the first upcoming function", () => {
    const data = enquiry({
      statusValue: "in_talks",
      eventDate: ist("2026-11-30T00:00"),
      functions: [
        { id: "a", eventType: "haldi", date: ist("2026-11-17T00:00") },
        { id: "b", eventType: "wedding", date: ist("2026-11-30T00:00") },
      ],
    });
    assert.equal(isTenDayFollowUpMatch(data, now), true);
  });

  it("deterministic id is fu10_{id}_{yyyy-mm-dd IST}", () => {
    assert.equal(tenDayNotificationId("e1", now), "fu10_e1_2026-11-07");
  });
});

describe("due-time calculation when enabled (pure)", () => {
  const now = ist("2026-11-04T08:05");

  it("first follow-up: 10:00 IST next IST day", () => {
    const r = nextAutoDueAt(enquiry(), cfg, now);
    assert.equal(r.dueAt.toISOString(), ist("2026-11-05T10:00").toISOString());
  });

  it("backfill floor: next 10:00 IST slot", () => {
    const afternoon = ist("2026-11-04T12:00");
    const r = nextAutoDueAt(enquiry({ createdAt: ist("2026-09-01T10:00") }), cfg, afternoon, nextIstSlot(afternoon, cfg.dueHourIst));
    assert.equal(r.dueAt.toISOString(), ist("2026-11-05T10:00").toISOString());
  });
});

describe("planFollowUpOnWrite (pure)", () => {
  const now = ist("2026-11-04T08:05");

  it("follow-ups disabled → trigger plans nothing", () => {
    assert.equal(planFollowUpOnWrite(null, enquiry(), { ...cfg, enabled: false }, now), null);
    assert.equal(planFollowUpOnWrite(null, enquiry(), DEFAULT_FOLLOW_UP_CONFIG, now), null);
  });

  it("when enabled, schedules a new open enquiry", () => {
    const update = planFollowUpOnWrite(null, enquiry(), cfg, now);
    assert.ok(update);
    assert.equal(update.fields.followUpSeq, 1);
  });

  it("terminal statuses cancel the open follow-up", () => {
    const open = { ...enquiry(), followUpDueAt: ist("2026-11-07T10:00"), followUpSeq: 1, followUpReason: "auto" };
    const update = planFollowUpOnWrite(open, { ...open, statusValue: "not_interested" }, cfg, now);
    assert.equal(update?.fields.followUpDueAt, null);
  });
});

describe("reminder stages when enabled (pure)", () => {
  const due = ist("2026-11-07T10:00");
  const base = { ...enquiry(), followUpDueAt: due, followUpSeq: 3, followUpNotifiedStage: null };

  it("due / overdue stages", () => {
    assert.equal(reminderStageDue(base, cfg, due), "due");
    assert.equal(reminderStageDue({ ...base, followUpNotifiedStage: "due" }, cfg, new Date(due.getTime() + 24 * H)), "overdue");
  });
  it("ids carry the sequence", () => {
    assert.notEqual(reminderNotificationId("e", base, "due"), reminderNotificationId("e", { ...base, followUpSeq: 4 }, "due"));
  });
  it("recipients: active assignee, else all active admins", () => {
    assert.deepEqual(reminderRecipients(base, new Set(["staff1"]), ["admin1"]), ["staff1"]);
    assert.deepEqual(reminderRecipients({ ...base, assignedTo: null }, new Set(), ["admin1", "admin2"]), ["admin1", "admin2"]);
  });
});

describe("ten-day follow-up reminders (emulator)", { skip: !hasEmulator }, () => {
  const db = hasEmulator ? testDb() : (null as unknown as FirebaseFirestore.Firestore);
  const now = ist("2026-11-07T10:00");
  const eventAt10 = ist("2026-11-17T00:00");
  const ref = (id: string) => db.collection("enquiries").doc(id);
  const followUpInbox = async (uid: string) =>
    (await inbox(db, uid)).filter((n) => String(n.type).startsWith("follow_up"));

  beforeEach(async () => {
    await clearEmulator();
    await seedUsers(db);
  });

  it("creates one fu10_* notification for In Talks at +10; idempotent on retry", async () => {
    await ref("e1").set(
      enquiry({ statusValue: "in_talks", eventDate: eventAt10, customerName: "Asha" }),
      { merge: false },
    );
    const first = await runFollowUpReminders(db, now);
    const second = await runFollowUpReminders(db, now);
    assert.equal(first.matched, 1);
    assert.equal(first.sent, 1);
    assert.ok(second.skipped >= 1 || second.sent === 0);
    const items = await followUpInbox("staff1");
    assert.equal(items.length, 1);
    assert.equal(items[0].id, "fu10_e1_2026-11-07");
    assert.equal(items[0].title, "Event in 10 days");
    assert.match(String(items[0].body), /Asha/);
    assert.equal(items[0].data?.enquiryId, "e1");
    assert.equal((await followUpInbox("admin1")).length, 0, "assignee only");
  });

  it("unassigned → every active admin", async () => {
    await ref("e1").set(
      enquiry({ statusValue: "in_talks", eventDate: eventAt10, assignedTo: null }),
      { merge: false },
    );
    await runFollowUpReminders(db, now);
    assert.equal((await followUpInbox("admin1")).length, 1);
    assert.equal((await followUpInbox("admin2")).length, 1);
    assert.equal((await followUpInbox("adminOff")).length, 0);
  });

  it("over 5 matches → 5 individual + 1 summary", async () => {
    for (let i = 0; i < 7; i++) {
      await ref(`e${i}`).set(
        enquiry({ statusValue: "in_talks", eventDate: eventAt10, customerName: `C${i}` }),
        { merge: false },
      );
    }
    const stats = await runFollowUpReminders(db, now);
    assert.equal(stats.matched, 7);
    assert.equal(stats.sent, 5);
    assert.equal(stats.summarised, 1);
    const items = await inbox(db, "staff1");
    assert.equal(items.filter((n) => String(n.id).startsWith("fu10_e")).length, 5);
    const summary = items.find((n) => String(n.title).includes("more events in 10 days"));
    assert.ok(summary);
  });

  it("follow-ups disabled config does not schedule on write", async () => {
    const before = null;
    await ref("e1").set(enquiry(), { merge: false });
    const update = await applyFollowUpOnWrite(db, "e1", before, DEFAULT_FOLLOW_UP_CONFIG, now);
    assert.equal(update, null);
    const doc = (await ref("e1").get()).data()!;
    assert.equal(doc.followUpDueAt, undefined);
  });

  it("+9 day events are not matched", async () => {
    await ref("e1").set(
      enquiry({ statusValue: "in_talks", eventDate: ist("2026-11-16T00:00") }),
      { merge: false },
    );
    const stats = await runFollowUpReminders(db, now);
    assert.equal(stats.matched, 0);
    assert.equal(stats.sent, 0);
  });
});

// Keep a light smoke of cadence math (enabled path) so nextAutoDueAt stays covered.
describe("cadence smoke (pure)", () => {
  it("marked done: next follow-up 3 days later at 10:00 IST", () => {
    const r = nextAutoDueAt(
      enquiry({ followUpLastCompletedAt: ist("2026-11-08T17:00") }),
      cfg,
      ist("2026-11-08T17:01"),
    );
    assert.equal(r.dueAt.toISOString(), ist("2026-11-11T10:00").toISOString());
  });
});
