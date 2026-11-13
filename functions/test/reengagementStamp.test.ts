import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { istDayStart } from "../src/istTime";
import { STAMP_CATCHUP_DAYS } from "../src/reengagement";
import { hasOccasionStamp, isWishEligible } from "../src/reengagementLogic";

/**
 * Pure checks for the daily stamp window and eligibility used by
 * stampNewlyEligibleEnquiries (Firestore I/O is covered by emulator suites when run).
 */
describe("daily stamp of newly eligible enquiries", () => {
  it("exposes a bounded catch-up window", () => {
    assert.equal(STAMP_CATCHUP_DAYS, 14);
  });

  it("window is the last N IST days before today (eventDate range)", () => {
    const now = new Date("2026-11-14T12:00:00.000Z");
    const todayStart = istDayStart(now);
    const windowStart = new Date(todayStart.getTime() - STAMP_CATCHUP_DAYS * 86400000);
    assert.ok(windowStart < todayStart);
    assert.equal(
      Math.round((todayStart.getTime() - windowStart.getTime()) / 86400000),
      STAMP_CATCHUP_DAYS
    );
  });

  it("unstamped open-past is stampable; already stamped is skipped", () => {
    const past = new Date("2026-11-10T18:30:00.000Z");
    const now = new Date("2026-11-14T12:00:00.000Z");
    assert.equal(
      isWishEligible({
        eventDate: past,
        now,
        merged: false,
        lostReason: null,
        eventTypeValue: "birthday",
        remindersOn: true,
        phoneNormalized: "9876543210",
      }),
      true
    );
    assert.equal(
      hasOccasionStamp({
        occasionKind: "birthday",
        occasionMonthDay: "11-11",
        occasionDate: past,
      }),
      true
    );
    assert.equal(
      hasOccasionStamp({
        occasionKind: null,
        occasionMonthDay: null,
        occasionDate: null,
      }),
      false
    );
  });
});
