import { describe, it, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { Timestamp } from "firebase-admin/firestore";
import { runAutoExpire } from "../src/autoExpireEnquiries";
import { applyFollowUpOnWrite, runFollowUpReminders } from "../src/followUps";
import { DEFAULT_FOLLOW_UP_CONFIG } from "../src/followUpsLogic";
import { clearEmulator, hasEmulator, inbox, seedUsers, testDb } from "./helpers";

const ist = (s: string) => new Date(`${s}:00+05:30`);

describe("autoExpireEnquiries (emulator)", { skip: !hasEmulator }, () => {
  const db = hasEmulator ? testDb() : (null as unknown as FirebaseFirestore.Firestore);
  const ref = (id: string) => db.collection("enquiries").doc(id);
  const NOW = ist("2026-11-10T12:00");

  const base = (over: Record<string, unknown>) => ({
    customerName: "Priya Sharma",
    eventTypeLabel: "Birthday",
    assignedTo: "staff1",
    createdAt: Timestamp.fromDate(ist("2026-10-20T10:00")),
    eventDate: Timestamp.fromDate(ist("2026-11-08T00:00")),
    ...over,
  });

  beforeEach(async () => {
    await clearEmulator();
    await seedUsers(db);
    await db.collection("app_config").doc("followups_state").set({ backfilledAt: Timestamp.now() });
  });

  it("(13) past-event New / In Talks enquiries are NOT marked Not Interested; they are flagged once", async () => {
    await ref("new1").set(base({ statusValue: "new" }));
    await ref("talk1").set(base({ statusValue: "quote_sent" })); // legacy alias of In Talks
    const first = await runAutoExpire(db, NOW);
    const second = await runAutoExpire(db, new Date(NOW.getTime() + 4 * 60 * 60 * 1000));

    assert.equal(first.flagged, 2);
    assert.equal(second.flagged, 0, "idempotent");
    for (const id of ["new1", "talk1"]) {
      const doc = await ref(id).get();
      assert.notEqual(doc.get("statusValue"), "not_interested");
      assert.equal(doc.get("lostReason"), undefined);
      assert.equal(doc.get("lostAt"), undefined);
      assert.ok(doc.get("pastEventReviewAt"), "flagged for review");
      const history = (await ref(id).collection("history").get()).docs.map((d) => d.data());
      assert.equal(history.length, 1);
      assert.equal(history[0].field_changed, "pastEventReview");
    }
    assert.equal((await ref("new1").get()).get("statusValue"), "new");
    // One notice per admin per enquiry, none to the assignee (follow-up reminder covers them).
    const adminItems = (await inbox(db, "admin1")).filter((n) => n.type === "past_event_review");
    assert.deepEqual(adminItems.map((n) => n.id).sort(), ["pastevent_new1", "pastevent_talk1"]);
    assert.equal((await inbox(db, "staff1")).length, 0);
    assert.equal((await inbox(db, "adminOff")).length, 0);
  });

  it("(14) approved past-event enquiries still auto-complete with history and notifications", async () => {
    await ref("booked").set(base({ statusValue: "approved" }));
    const res = await runAutoExpire(db, NOW);
    assert.equal(res.changed, 1);
    const doc = await ref("booked").get();
    assert.equal(doc.get("statusValue"), "completed");
    assert.equal(doc.get("statusUpdatedBy"), "system:auto-complete");
    assert.ok(doc.get("completedAt"));
    const history = (await ref("booked").collection("history").get()).docs.map((d) => d.data());
    assert.ok(history.some((h) => h.field_changed === "statusValue" && h.new_value === "completed"));
    assert.equal((await inbox(db, "staff1")).filter((n) => n.title === "Enquiry Auto-Completed").length, 1);
    assert.equal((await runAutoExpire(db, NOW)).changed, 0, "idempotent");
  });

  it("multi-function bookings are flagged only after the LAST function day", async () => {
    await ref("multi").set(base({
      statusValue: "in_talks",
      eventDate: Timestamp.fromDate(ist("2026-11-09T00:00")),
      functions: [
        { id: "a", eventType: "haldi", date: Timestamp.fromDate(ist("2026-11-07T00:00")) },
        { id: "b", eventType: "wedding", date: Timestamp.fromDate(ist("2026-11-12T00:00")) },
      ],
    }));
    // Top-level eventDate is stale here (11-09) but a function is still upcoming (11-12).
    const res = await runAutoExpire(db, NOW);
    assert.equal(res.flagged, 0);
    assert.equal((await ref("multi").get()).get("pastEventReviewAt"), undefined);
  });

  it("terminal, future and merged enquiries are left alone", async () => {
    await ref("lost").set(base({ statusValue: "closed_lost" }));
    await ref("future").set(base({ statusValue: "new", eventDate: Timestamp.fromDate(ist("2026-12-01T00:00")) }));
    await ref("merged").set(base({ statusValue: "new", mergedInto: "x" }));
    const res = await runAutoExpire(db, NOW);
    assert.equal(res.flagged, 0);
    assert.equal(res.changed, 0);
  });

  it("a flagged enquiry becomes due for the assignee through the follow-up workflow", async () => {
    await ref("e1").set(base({ statusValue: "in_talks", createdAt: Timestamp.fromDate(ist("2026-11-05T09:00")) }));
    // The regular automatic follow-up, scheduled when the enquiry came in (due 11-07 10:00).
    await applyFollowUpOnWrite(db, "e1", null, DEFAULT_FOLLOW_UP_CONFIG, ist("2026-11-05T09:00"));
    assert.equal((await ref("e1").get()).get("followUpReason"), "auto");
    const before = (await ref("e1").get()).data()!;
    await runAutoExpire(db, NOW);
    await applyFollowUpOnWrite(db, "e1", before, DEFAULT_FOLLOW_UP_CONFIG, NOW);
    const doc = (await ref("e1").get()).data()!;
    assert.equal(doc.followUpReason, "past_event");
    assert.ok(doc.followUpDueAt.toDate().getTime() <= NOW.getTime() + 1000);
    await runFollowUpReminders(db, new Date(NOW.getTime() + 60_000), DEFAULT_FOLLOW_UP_CONFIG);
    const items = (await inbox(db, "staff1")).filter((n) => n.type === "follow_up_due");
    assert.equal(items.length, 1);
    assert.equal(items[0].title, "Event date passed — needs review");
  });
});
