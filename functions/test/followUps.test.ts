import { describe, it, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { Timestamp } from "firebase-admin/firestore";
import {
  DEFAULT_FOLLOW_UP_CONFIG,
  FollowUpConfig,
  nextAutoDueAt,
  nextIstSlot,
  parseFollowUpConfig,
  planFollowUpOnWrite,
  reminderNotificationId,
  reminderRecipients,
  reminderStageDue,
} from "../src/followUpsLogic";
import { applyFollowUpOnWrite, runFollowUpReminders } from "../src/followUps";
import { clearEmulator, hasEmulator, inbox, seedUsers, testDb } from "./helpers";

const cfg: FollowUpConfig = DEFAULT_FOLLOW_UP_CONFIG;
const H = 60 * 60 * 1000;
const D = 24 * H;
/** "2026-11-04T08:00" IST → Date. */
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
  it("defaults: next morning first, then 3 days after each completion, 10:00 IST, overdue after 24 h, New + In Talks", () => {
    assert.deepEqual(parseFollowUpConfig(undefined), DEFAULT_FOLLOW_UP_CONFIG);
  });
  it("reads admin overrides and ignores out-of-range or terminal values", () => {
    const c = parseFollowUpConfig({
      reminderDaysDefault: 5,
      followUpsEnabled: false,
      followUpDueHourIst: 99,
      followUpEligibleStatuses: ["in_talks", "completed", "not_interested"],
    });
    assert.equal(c.cadenceDays, 5);
    assert.equal(c.enabled, false);
    assert.equal(c.dueHourIst, 10);
    assert.deepEqual(c.eligibleStatuses, ["in_talks"]);
  });
});

describe("due-time calculation (pure)", () => {
  const now = ist("2026-11-04T08:05");

  it("(1) first follow-up: 10:00 IST on the next IST day after creation, whatever the time", () => {
    for (const created of ["2026-11-04T00:05", "2026-11-04T08:00", "2026-11-04T15:00", "2026-11-04T23:55"]) {
      const at = ist(created);
      const r = nextAutoDueAt(enquiry({ createdAt: at }), cfg, new Date(at.getTime() + 60_000));
      assert.equal(r.dueAt.toISOString(), ist("2026-11-05T10:00").toISOString(), created);
      assert.equal(r.reason, "auto");
    }
  });

  it("the first chase ignores reminderDaysDefault (it only spaces later follow-ups)", () => {
    const fiveDays = { ...cfg, cadenceDays: 5 };
    assert.equal(nextAutoDueAt(enquiry(), fiveDays, now).dueAt.toISOString(), ist("2026-11-05T10:00").toISOString());
    const done = enquiry({ followUpLastCompletedAt: ist("2026-11-05T11:00") });
    assert.equal(
      nextAutoDueAt(done, fiveDays, ist("2026-11-05T11:01")).dueAt.toISOString(),
      ist("2026-11-10T10:00").toISOString(),
    );
  });

  it("(3) event sooner than the first morning: capped at 10:00 IST the day before the EARLIEST upcoming function", () => {
    const data = enquiry({
      eventDate: ist("2026-11-10T00:00"), // top-level = last function
      functions: [
        { id: "a", eventType: "haldi", date: ist("2026-11-05T00:00") },
        { id: "b", eventType: "wedding", date: ist("2026-11-10T00:00") },
      ],
    });
    // Created 11-04 08:00: next morning would be 11-05 10:00, but the Haldi is on 11-05.
    assert.equal(nextAutoDueAt(data, cfg, now).dueAt.toISOString(), ist("2026-11-04T10:00").toISOString());
    // Single-event enquiry with the event tomorrow: same cap.
    const single = enquiry({ eventDate: ist("2026-11-05T00:00") });
    assert.equal(nextAutoDueAt(single, cfg, now).dueAt.toISOString(), ist("2026-11-04T10:00").toISOString());
  });

  it("a later earliest function does not cap the next-morning chase", () => {
    const data = enquiry({
      functions: [
        { id: "a", eventType: "haldi", date: ist("2026-11-06T00:00") },
        { id: "b", eventType: "wedding", date: ist("2026-11-10T00:00") },
      ],
    });
    assert.equal(nextAutoDueAt(data, cfg, now).dueAt.toISOString(), ist("2026-11-05T10:00").toISOString());
  });

  it("a past function is ignored; the next upcoming one caps the date", () => {
    const data = enquiry({
      functions: [
        { id: "a", eventType: "engagement", date: ist("2026-11-01T00:00") },
        { id: "b", eventType: "wedding", date: ist("2026-11-05T00:00") },
      ],
    });
    assert.equal(nextAutoDueAt(data, cfg, now).dueAt.toISOString(), ist("2026-11-04T10:00").toISOString());
  });

  it("event today → due now", () => {
    const r = nextAutoDueAt(enquiry({ eventDate: ist("2026-11-04T00:00") }), cfg, now);
    assert.equal(r.dueAt.getTime(), now.getTime());
  });

  it("every event day passed → past_event review now; after a completion, normal cadence", () => {
    const past = enquiry({ eventDate: ist("2026-11-01T00:00") });
    assert.deepEqual(nextAutoDueAt(past, cfg, now), { dueAt: now, reason: "past_event" });
    const followedUp = { ...past, followUpLastCompletedAt: ist("2026-11-03T12:00") };
    assert.equal(nextAutoDueAt(followedUp, cfg, now).dueAt.toISOString(), ist("2026-11-06T10:00").toISOString());
  });

  it("(2) marked done: the next follow-up is 3 days after completion at 10:00 IST", () => {
    const r = nextAutoDueAt(enquiry({ followUpLastCompletedAt: ist("2026-11-08T17:00") }), cfg, ist("2026-11-08T17:01"));
    assert.equal(r.dueAt.toISOString(), ist("2026-11-11T10:00").toISOString());
    assert.equal(r.reason, "auto");
  });

  it("(4) backfill of an old open enquiry: next 10:00 IST slot, never immediate or in the past", () => {
    const old = enquiry({ createdAt: ist("2026-09-01T10:00") });
    const afternoon = ist("2026-11-04T12:00");
    const r1 = nextAutoDueAt(old, cfg, afternoon, nextIstSlot(afternoon, cfg.dueHourIst));
    assert.equal(r1.dueAt.toISOString(), ist("2026-11-05T10:00").toISOString());
    const morning = ist("2026-11-04T08:00");
    const r2 = nextAutoDueAt(old, cfg, morning, nextIstSlot(morning, cfg.dueHourIst));
    assert.equal(r2.dueAt.toISOString(), ist("2026-11-04T10:00").toISOString());
    for (const r of [r1, r2]) assert.equal(r.reason, "auto");
    assert.ok(r1.dueAt.getTime() > afternoon.getTime() && r2.dueAt.getTime() > morning.getTime());
  });
});

describe("planFollowUpOnWrite (pure)", () => {
  const now = ist("2026-11-04T08:05");

  it("schedules a new open enquiry and is a no-op on its own write", () => {
    const update = planFollowUpOnWrite(null, enquiry(), cfg, now);
    assert.ok(update);
    assert.equal(update.fields.followUpSeq, 1);
    assert.equal(update.fields.followUpNotifiedStage, null);
    assert.match(update.history!.newValue, /^scheduled: due 2026-11-05 10:00 IST \(auto\)/);
    const written = { ...enquiry(), ...update.fields };
    assert.equal(planFollowUpOnWrite(enquiry(), written, cfg, now), null);
  });

  it("(12) terminal and booked statuses cancel the open follow-up and never schedule one", () => {
    const open = { ...enquiry(), followUpDueAt: ist("2026-11-07T10:00"), followUpSeq: 1, followUpReason: "auto" };
    for (const status of ["not_interested", "closed_lost", "cancelled", "completed", "approved"]) {
      const update = planFollowUpOnWrite(open, { ...open, statusValue: status }, cfg, now);
      assert.equal(update?.fields.followUpDueAt, null, status);
      assert.equal(update?.fields.followUpSeq, 2);
      assert.match(update!.history!.newValue, /cancelled/);
      assert.equal(planFollowUpOnWrite(null, enquiry({ statusValue: status }), cfg, now), null, status);
    }
  });

  it("merged duplicates are not followed up", () => {
    const open = { ...enquiry(), followUpDueAt: ist("2026-11-07T10:00"), followUpSeq: 1 };
    const update = planFollowUpOnWrite(open, { ...open, statusValue: "closed_lost", mergedInto: "x" }, cfg, now);
    assert.match(update!.history!.newValue, /merged/);
  });

  it("(11) reassignment after the reminder resets the sent stage for the new assignee", () => {
    const sent = { ...enquiry(), followUpDueAt: ist("2026-11-04T08:00"), followUpSeq: 1, followUpNotifiedStage: "due" };
    const update = planFollowUpOnWrite(sent, { ...sent, assignedTo: "staff2" }, cfg, now);
    assert.deepEqual(update?.fields, { followUpNotifiedStage: null });
  });

  it("an automatic follow-up moves earlier when the event moves earlier; a callback does not", () => {
    const due = { ...enquiry(), followUpDueAt: ist("2026-11-07T10:00"), followUpSeq: 1, followUpReason: "auto", followUpNotifiedStage: null };
    const moved = { ...due, eventDate: ist("2026-11-05T00:00") };
    assert.equal(planFollowUpOnWrite(due, moved, cfg, now)?.fields.followUpDueAt instanceof Date, true);
    assert.equal(planFollowUpOnWrite(due, { ...moved, followUpReason: "callback" }, cfg, now), null);
  });

  it("an automatic follow-up becomes a past-event review once every event day has passed", () => {
    const later = ist("2026-11-10T12:00");
    const sent = {
      ...enquiry({ eventDate: ist("2026-11-08T00:00") }),
      followUpDueAt: ist("2026-11-07T10:00"), followUpSeq: 2, followUpReason: "auto", followUpNotifiedStage: "overdue",
    };
    const update = planFollowUpOnWrite(sent, sent, cfg, later);
    assert.equal(update?.fields.followUpReason, "past_event");
    assert.equal(update?.fields.followUpNotifiedStage, null);
    assert.equal((update?.fields.followUpDueAt as Date).getTime(), later.getTime());
    const written = { ...sent, ...update!.fields };
    assert.equal(planFollowUpOnWrite(sent, written, cfg, later), null, "switches only once");
    // A customer callback is respected.
    assert.equal(planFollowUpOnWrite(sent, { ...sent, followUpReason: "callback", followUpDueAt: ist("2026-11-12T18:00") }, cfg, later), null);
  });

  it("disabled config schedules nothing", () => {
    assert.equal(planFollowUpOnWrite(null, enquiry(), { ...cfg, enabled: false }, now), null);
  });
});

describe("reminder stages (pure)", () => {
  const due = ist("2026-11-07T10:00");
  const base = { ...enquiry(), followUpDueAt: due, followUpSeq: 3, followUpNotifiedStage: null };

  it("nothing before the due time; 'due' once it is reached", () => {
    assert.equal(reminderStageDue(base, cfg, new Date(due.getTime() - 1)), null);
    assert.equal(reminderStageDue(base, cfg, due), "due");
  });
  it("(8) one overdue reminder 24 h later, then nothing", () => {
    const sent = { ...base, followUpNotifiedStage: "due" };
    assert.equal(reminderStageDue(sent, cfg, new Date(due.getTime() + 23 * H)), null);
    assert.equal(reminderStageDue(sent, cfg, new Date(due.getTime() + 24 * H)), "overdue");
    assert.equal(reminderStageDue({ ...base, followUpNotifiedStage: "overdue" }, cfg, new Date(due.getTime() + 30 * D)), null);
  });
  it("a long-missed follow-up gets one overdue reminder, not due + overdue", () => {
    assert.equal(reminderStageDue(base, cfg, new Date(due.getTime() + 3 * D)), "overdue");
  });
  it("terminal enquiries are never reminded", () => {
    assert.equal(reminderStageDue({ ...base, statusValue: "completed" }, cfg, due), null);
  });
  it("ids carry the sequence, so a reschedule can never re-use the old reminder", () => {
    assert.notEqual(reminderNotificationId("e", base, "due"), reminderNotificationId("e", { ...base, followUpSeq: 4 }, "due"));
  });
  it("recipients: active assignee, else all active admins", () => {
    assert.deepEqual(reminderRecipients(base, new Set(["staff1"]), ["admin1"]), ["staff1"]);
    assert.deepEqual(reminderRecipients({ ...base, assignedTo: null }, new Set(), ["admin1", "admin2"]), ["admin1", "admin2"]);
    assert.deepEqual(reminderRecipients(base, new Set(), ["admin1"]), ["admin1"]);
  });
});

describe("follow-up workflow (emulator)", { skip: !hasEmulator }, () => {
  const db = hasEmulator ? testDb() : (null as unknown as FirebaseFirestore.Firestore);
  const T0 = ist("2026-11-04T08:00");
  const ref = (id: string) => db.collection("enquiries").doc(id);

  /** Writes [data] then runs the trigger core the way onEnquiryWrittenFollowUp would. */
  async function write(id: string, data: Record<string, unknown>, now: Date, merge = true) {
    const before = (await ref(id).get()).data() ?? null;
    await ref(id).set(data, { merge });
    await applyFollowUpOnWrite(db, id, before, cfg, now);
    return (await ref(id).get()).data()!;
  }
  const history = async (id: string) =>
    (await ref(id).collection("history").get()).docs.map((d) => d.data()).filter((h) => h.field_changed === "followUp");
  const followUpInbox = async (uid: string) => (await inbox(db, uid)).filter((n) => String(n.type).startsWith("follow_up"));

  beforeEach(async () => {
    await clearEmulator();
    await seedUsers(db);
    // Skip the one-time backfill unless a test wants it.
    await db.collection("app_config").doc("followups_state").set({ backfilledAt: Timestamp.now() });
  });

  it("(6) a new open enquiry is scheduled automatically with history", async () => {
    const doc = await write("e1", enquiry(), T0, false);
    assert.equal(doc.followUpDueAt.toDate().toISOString(), ist("2026-11-05T10:00").toISOString());
    assert.equal(doc.followUpSeq, 1);
    assert.equal(doc.followUpReason, "auto");
    assert.equal((await history("e1")).length, 1);
  });

  it("(7) the due reminder is delivered once, even if the job runs again or is retried", async () => {
    await write("e1", enquiry(), T0, false);
    const at = ist("2026-11-05T10:05");
    const first = await runFollowUpReminders(db, at, cfg);
    await runFollowUpReminders(db, at, cfg);
    await runFollowUpReminders(db, new Date(at.getTime() + 15 * 60 * 1000), cfg);
    assert.equal(first.sent, 1);
    const items = await followUpInbox("staff1");
    assert.equal(items.length, 1);
    assert.equal(items[0].id, "fu_e1_1_due");
    assert.equal(items[0].title, "Follow-up due");
    assert.equal((await followUpInbox("admin1")).length, 0, "assignee only");
  });

  it("(8) one overdue reminder after 24 h, none after that", async () => {
    await write("e1", enquiry(), T0, false);
    await runFollowUpReminders(db, ist("2026-11-05T10:05"), cfg);
    await runFollowUpReminders(db, ist("2026-11-05T22:00"), cfg);
    await runFollowUpReminders(db, ist("2026-11-06T10:15"), cfg);
    await runFollowUpReminders(db, ist("2026-11-10T10:15"), cfg);
    const ids = (await followUpInbox("staff1")).map((n) => n.id).sort();
    assert.deepEqual(ids, ["fu_e1_1_due", "fu_e1_1_overdue"]);
  });

  it("(9) rescheduling (customer callback) stops the old reminder; the new time fires once", async () => {
    await write("e1", enquiry(), T0, false);
    // Client reschedule (FollowUpService.reschedule): new time, seq+1, stage reset.
    await write("e1", {
      followUpDueAt: ist("2026-11-09T18:30"),
      followUpSeq: 2,
      followUpReason: "callback",
      followUpNotifiedStage: null,
      followUpScheduledBy: "staff1",
      followUpNote: "Call after 6 pm",
    }, ist("2026-11-04T18:00"));
    await runFollowUpReminders(db, ist("2026-11-05T10:05"), cfg); // old due time
    assert.equal((await followUpInbox("staff1")).length, 0);
    await runFollowUpReminders(db, ist("2026-11-09T18:45"), cfg);
    const items = await followUpInbox("staff1");
    assert.deepEqual(items.map((n) => n.id), ["fu_e1_2_due"]);
    assert.equal(items[0].title, "Callback due");
    assert.match(items[0].body, /Call after 6 pm/);
  });

  it("(10) a completed follow-up is not notified again; the next one is scheduled from completion", async () => {
    await write("e1", enquiry(), T0, false);
    await runFollowUpReminders(db, ist("2026-11-05T10:05"), cfg);
    const doneAt = ist("2026-11-05T11:00");
    const doc = await write("e1", {
      followUpDueAt: null,
      followUpSeq: 2,
      followUpNotifiedStage: null,
      followUpLastCompletedAt: doneAt,
      followUpLastCompletedBy: "staff1",
    }, doneAt);
    assert.equal(doc.followUpSeq, 3);
    assert.equal(doc.followUpDueAt.toDate().toISOString(), ist("2026-11-08T10:00").toISOString());
    await runFollowUpReminders(db, ist("2026-11-06T12:00"), cfg); // would be overdue for the old one
    assert.deepEqual((await followUpInbox("staff1")).map((n) => n.id), ["fu_e1_1_due"]);
    const actions = (await history("e1")).map((h) => h.new_value);
    assert.equal(actions.filter((v: string) => v.startsWith("scheduled")).length, 2);
  });

  it("(11) reassignment: the new assignee gets the reminder, the old one is not re-notified", async () => {
    await write("e1", enquiry(), T0, false);
    await runFollowUpReminders(db, ist("2026-11-05T10:05"), cfg);
    await write("e1", { assignedTo: "staff2" }, ist("2026-11-05T12:00"));
    await runFollowUpReminders(db, ist("2026-11-05T12:15"), cfg);
    assert.equal((await followUpInbox("staff1")).length, 1);
    assert.deepEqual((await followUpInbox("staff2")).map((n) => n.id), ["fu_e1_1_due"]);
  });

  it("(12) terminal / booked enquiries get no reminders", async () => {
    await write("lost", enquiry(), T0, false);
    await write("booked", enquiry(), T0, false);
    await write("lost", { statusValue: "not_interested" }, ist("2026-11-04T09:00"));
    await write("booked", { statusValue: "approved" }, ist("2026-11-04T09:00"));
    await write("closed", enquiry({ statusValue: "completed" }), T0, false);
    await runFollowUpReminders(db, ist("2026-11-08T12:00"), cfg);
    assert.equal((await followUpInbox("staff1")).length, 0);
    assert.equal((await ref("lost").get()).get("followUpDueAt"), null);
    assert.equal((await ref("closed").get()).get("followUpSeq"), undefined);
    const lostHistory = (await history("lost")).map((h) => h.new_value as string);
    assert.ok(lostHistory.some((v) => v === "cancelled: status not_interested"), lostHistory.join(" | "));
  });

  it("unassigned enquiries remind every active admin", async () => {
    await write("e1", enquiry({ assignedTo: null }), T0, false);
    await runFollowUpReminders(db, ist("2026-11-05T10:05"), cfg);
    assert.equal((await followUpInbox("admin1")).length, 1);
    assert.equal((await followUpInbox("admin2")).length, 1);
    assert.equal((await followUpInbox("adminOff")).length, 0);
  });

  it("backfill: legacy open enquiries are scheduled once, at the next slot, without a burst", async () => {
    await db.collection("app_config").doc("followups_state").delete();
    await ref("legacy-open").set(enquiry({ createdAt: ist("2026-09-01T10:00") }));
    await ref("legacy-lost").set(enquiry({ statusValue: "closed_lost" }));
    const now = ist("2026-11-04T12:00");
    const stats = await runFollowUpReminders(db, now, cfg);
    assert.equal(stats.backfilled, 1);
    assert.equal(stats.sent, 0, "nothing is due the moment it is backfilled");
    assert.equal((await ref("legacy-open").get()).get("followUpDueAt").toDate().toISOString(), ist("2026-11-05T10:00").toISOString());
    assert.equal((await ref("legacy-lost").get()).get("followUpSeq"), undefined);
    const again = await runFollowUpReminders(db, now, cfg);
    assert.equal(again.backfilled, 0);
  });

  it("flood guard: over 5 due for one person → 5 pushes + 1 summary", async () => {
    for (let i = 0; i < 7; i++) await write(`e${i}`, enquiry({ customerName: `C${i}` }), T0, false);
    const stats = await runFollowUpReminders(db, ist("2026-11-05T10:05"), cfg);
    assert.equal(stats.sent, 5);
    assert.equal(stats.summarised, 2);
    const items = await inbox(db, "staff1");
    assert.equal(items.filter((n) => n.type === "follow_up_due").length, 5);
    const summary = items.find((n) => n.type === "follow_up_summary");
    assert.equal(summary?.title, "2 more follow-ups due");
    // Summarised follow-ups are marked, so they don't come back next run.
    assert.equal((await runFollowUpReminders(db, ist("2026-11-05T10:20"), cfg)).sent, 0);
  });
});
