import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { normalizeEventOSWallClockTime } from "../src/eventosTime";

describe("normalizeEventOSWallClockTime", () => {
  it("passes through 24h HH:mm", () => {
    assert.equal(normalizeEventOSWallClockTime("18:30"), "18:30");
    assert.equal(normalizeEventOSWallClockTime("00:00"), "00:00");
    assert.equal(normalizeEventOSWallClockTime("23:59"), "23:59");
  });

  it("strips seconds from 24h times", () => {
    assert.equal(normalizeEventOSWallClockTime("18:30:00"), "18:30");
    assert.equal(normalizeEventOSWallClockTime("09:05:59"), "09:05");
  });

  it("parses 12h formats with AM/PM", () => {
    assert.equal(normalizeEventOSWallClockTime("6:30 PM"), "18:30");
    assert.equal(normalizeEventOSWallClockTime("6:30pm"), "18:30");
    assert.equal(normalizeEventOSWallClockTime("06:30 PM"), "18:30");
    assert.equal(normalizeEventOSWallClockTime("6 PM"), "18:00");
    assert.equal(normalizeEventOSWallClockTime("6:05 am"), "06:05");
  });

  it("handles midnight and noon edges", () => {
    assert.equal(normalizeEventOSWallClockTime("12:00 AM"), "00:00");
    assert.equal(normalizeEventOSWallClockTime("12 AM"), "00:00");
    assert.equal(normalizeEventOSWallClockTime("12:30 PM"), "12:30");
    assert.equal(normalizeEventOSWallClockTime("12 PM"), "12:00");
    assert.equal(normalizeEventOSWallClockTime("12:00 PM"), "12:00");
  });

  it("returns null for empty or unparseable input", () => {
    assert.equal(normalizeEventOSWallClockTime(null), null);
    assert.equal(normalizeEventOSWallClockTime(undefined), null);
    assert.equal(normalizeEventOSWallClockTime(""), null);
    assert.equal(normalizeEventOSWallClockTime("   "), null);
    assert.equal(normalizeEventOSWallClockTime("evening"), null);
    assert.equal(normalizeEventOSWallClockTime("25:00"), null);
    assert.equal(normalizeEventOSWallClockTime("13:00 PM"), null);
    assert.equal(normalizeEventOSWallClockTime(1830), null);
  });
});
