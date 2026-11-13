import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  ReminderSource,
  isActiveOpenEnquiry,
  isWishEligible,
  selectReminders,
} from "../src/reengagementLogic";

/** Fixed "now": 2026-11-14 12:00 UTC ≈ afternoon IST. */
const NOW = new Date("2026-11-14T12:00:00.000Z");
/** Occasion / event date before today IST. */
const PAST = new Date("2026-06-01T18:30:00.000Z"); // 2026-06-02 00:00 IST
/** Event date today or later IST. */
const FUTURE = new Date("2026-12-01T18:30:00.000Z");

function baseEligible(over: Partial<Parameters<typeof isWishEligible>[0]> = {}) {
  return isWishEligible({
    eventDate: PAST,
    now: NOW,
    merged: false,
    lostReason: null,
    eventTypeValue: "wedding",
    eventTypeLabel: "Wedding",
    remindersOn: true,
    phoneNormalized: "9876543210",
    ...over,
  });
}

function source(over: Partial<ReminderSource> = {}): ReminderSource {
  return {
    id: over.id ?? "e1",
    phoneNormalized: over.phoneNormalized ?? "9876543210",
    customerName: "Test",
    customerPhone: "+919876543210",
    status: over.status ?? "not_interested",
    merged: over.merged ?? false,
    remindersOn: over.remindersOn ?? true,
    occasionKind: over.occasionKind ?? "wedding_anniversary",
    occasionMonthDay: over.occasionMonthDay ?? "06-02",
    occasionDate: over.occasionDate ?? PAST,
    person: over.person ?? null,
    eventTypeValue: over.eventTypeValue ?? "wedding",
    eventTypeLabel: over.eventTypeLabel ?? "Wedding",
    eventDate: over.eventDate ?? PAST,
    assignedTo: over.assignedTo ?? null,
    wishEligible: over.wishEligible ?? true,
  };
}

describe("isWishEligible", () => {
  it("lost from New (no In Talks) with past date → eligible", () => {
    assert.equal(
      baseEligible({ lostReason: "price", eventTypeValue: "birthday" }),
      true
    );
  });

  it("open with past date → eligible", () => {
    assert.equal(baseEligible({ eventTypeValue: "haldi" }), true);
  });

  it("open with future date → not eligible", () => {
    assert.equal(baseEligible({ eventDate: FUTURE }), false);
  });

  it("duplicate / out_of_scope / event_cancelled → not eligible", () => {
    assert.equal(baseEligible({ lostReason: "duplicate" }), false);
    assert.equal(baseEligible({ lostReason: "out_of_scope" }), false);
    assert.equal(baseEligible({ lostReason: "event_cancelled" }), false);
  });

  it("corporate → not eligible", () => {
    assert.equal(
      baseEligible({ eventTypeValue: "corporate", eventTypeLabel: "Corporate event" }),
      false
    );
  });

  it("opted-out → not eligible", () => {
    assert.equal(baseEligible({ optedOut: true }), false);
  });

  it("no usable phone → not eligible", () => {
    assert.equal(baseEligible({ phoneNormalized: "123" }), false);
  });

  it("reminders off → not eligible", () => {
    assert.equal(baseEligible({ remindersOn: false }), false);
  });

  it("merged → not eligible", () => {
    assert.equal(baseEligible({ merged: true }), false);
  });

  it("missing event date → not eligible", () => {
    assert.equal(baseEligible({ eventDate: null }), false);
  });
});

describe("isActiveOpenEnquiry", () => {
  it("open + future date blocks (still talking)", () => {
    assert.equal(isActiveOpenEnquiry("in_talks", FUTURE, NOW), true);
    assert.equal(isActiveOpenEnquiry("new", FUTURE, NOW), true);
    assert.equal(isActiveOpenEnquiry("approved", FUTURE, NOW), true);
  });

  it("open + past date does not block", () => {
    assert.equal(isActiveOpenEnquiry("in_talks", PAST, NOW), false);
    assert.equal(isActiveOpenEnquiry("new", PAST, NOW), false);
  });

  it("completed / lost never active", () => {
    assert.equal(isActiveOpenEnquiry("completed", FUTURE, NOW), false);
    assert.equal(isActiveOpenEnquiry("not_interested", FUTURE, NOW), false);
  });
});

describe("selectReminders", () => {
  it("includes open-past when wishEligible; skips when not", () => {
    const openPast = source({ id: "open", status: "in_talks", wishEligible: true });
    const blocked = source({ id: "future", status: "in_talks", wishEligible: false });
    const { plans, skipped } = selectReminders([openPast, blocked], 2027, new Set());
    assert.equal(plans.length, 1);
    assert.equal(plans[0].source.id, "open");
    assert.equal(skipped.notEligible, 1);
  });

  it("activePhones still skips wish-eligible sources on that phone", () => {
    const s = source({ wishEligible: true, status: "not_interested" });
    const { plans, skipped } = selectReminders([s], 2027, new Set(), new Set(["9876543210"]));
    assert.equal(plans.length, 0);
    assert.equal(skipped.activeEnquiry, 1);
  });

  it("priority: completed beats enquired in the same (phone, kind) group", () => {
    const lost = source({ id: "lost", status: "not_interested", wishEligible: true, person: "A" });
    const done = source({
      id: "done",
      status: "completed",
      wishEligible: true,
      person: null,
      eventDate: new Date(PAST.getTime() - 86400000),
    });
    const { plans } = selectReminders([lost, done], 2027, new Set());
    assert.equal(plans.length, 1);
    assert.equal(plans[0].source.id, "done");
  });
});
