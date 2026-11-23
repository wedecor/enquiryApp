import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  buildEventOSPayload,
  formatEventOSPhone,
  hashEventOSPayload,
  resolveGuestCount,
  shouldSendToEventOS,
  stableStringify,
} from "../src/eventosPayload";
import { signEventOSFeedBody } from "../src/eventosSign";

describe("formatEventOSPhone", () => {
  it("formats a 10-digit Indian mobile as +91…", () => {
    assert.equal(formatEventOSPhone("+91 98765 43210"), "+919876543210");
    assert.equal(formatEventOSPhone("09876543210"), "+919876543210");
  });

  it("returns null for missing or short numbers", () => {
    assert.equal(formatEventOSPhone(null), null);
    assert.equal(formatEventOSPhone("12345"), null);
    assert.equal(formatEventOSPhone(""), null);
  });
});

describe("buildEventOSPayload", () => {
  it("builds a single-function legacy enquiry with IST dates and money", () => {
    // 2026-12-11 18:30 UTC = 2026-12-12 00:00 IST
    const eventDate = new Date(Date.UTC(2026, 11, 11, 18, 30));
    const payload = buildEventOSPayload(
      "enq-1",
      {
        customerName: "Asha Rao",
        customerPhone: "9876543210",
        customerEmail: "asha@example.com",
        statusValue: "approved",
        eventTypeValue: "wedding",
        eventTypeLabel: "Wedding",
        eventDate,
        eventLocation: "Lotus Gardens",
        locationArea: "Banjara Hills",
        locationAddress: "Road 12",
        locationPlaceId: "ChIJ123",
        locationLat: 17.41,
        locationLng: 78.44,
        guestCount: 350,
        notes: "Pastel palette",
        assignedToName: "Ravi",
        updatedAt: new Date("2026-11-23T04:45:30.000Z"),
      },
      { totalCost: 450000, advancePaid: 150000 },
    );

    assert.equal(payload.schemaVersion, 1);
    assert.equal(payload.source, "wedecor-enquiries");
    assert.equal(payload.status, "approved");
    assert.equal(payload.customer.phone, "+919876543210");
    assert.equal(payload.event.startDate, "2026-12-12");
    assert.equal(payload.event.endDate, "2026-12-12");
    assert.equal(payload.functions.length, 1);
    assert.equal(payload.functions[0].functionId, "main");
    assert.equal(payload.functions[0].date, "2026-12-12");
    assert.equal(payload.functions[0].lat, 17.41);
    assert.equal(payload.functions[0].lng, 78.44);
    assert.deepEqual(payload.money, {
      totalCost: 450000,
      advancePaid: 150000,
      currency: "INR",
    });
  });

  it("builds multi-function payloads with min/max dates and null coords when absent", () => {
    const payload = buildEventOSPayload("enq-2", {
      customerName: "Priya",
      statusValue: "approved",
      functions: [
        {
          id: "fn_haldi",
          eventType: "haldi",
          eventTypeLabel: "Haldi",
          date: new Date(Date.UTC(2026, 11, 11, 18, 30)),
          time: "10:30",
          location: "Home",
        },
        {
          id: "fn_wedding",
          eventType: "wedding",
          eventTypeLabel: "Wedding",
          date: new Date(Date.UTC(2026, 11, 13, 18, 30)),
          time: "18:00",
          location: "Venue",
        },
      ],
      updatedAt: new Date("2026-11-23T10:00:00.000Z"),
    });

    assert.equal(payload.event.startDate, "2026-12-12");
    assert.equal(payload.event.endDate, "2026-12-14");
    assert.equal(payload.functions.length, 2);
    assert.equal(payload.functions[0].lat, null);
    assert.equal(payload.functions[0].lng, null);
    assert.equal(payload.money, undefined);
  });

  it("maps legacy status aliases via statusVocabulary", () => {
    const payload = buildEventOSPayload("enq-3", {
      customerName: "X",
      statusValue: "confirmed",
      eventDate: new Date(Date.UTC(2026, 5, 1, 18, 30)),
      eventType: "birthday",
    });
    assert.equal(payload.status, "approved");
  });

  it("normalises function times to HH:mm and logs unparsed via callback", () => {
    const unparsed: string[] = [];
    const payload = buildEventOSPayload(
      "enq-time",
      {
        customerName: "A",
        statusValue: "approved",
        functions: [
          {
            id: "a",
            eventType: "haldi",
            date: new Date(Date.UTC(2026, 11, 11, 18, 30)),
            time: "6:30 PM",
          },
          {
            id: "b",
            eventType: "wedding",
            date: new Date(Date.UTC(2026, 11, 12, 18, 30)),
            time: "18:30:00",
          },
          {
            id: "c",
            eventType: "reception",
            date: new Date(Date.UTC(2026, 11, 13, 18, 30)),
            time: "not-a-time",
          },
        ],
      },
      null,
      { onTimeUnparsed: (id) => unparsed.push(id) },
    );
    assert.equal(payload.functions[0].time, "18:30");
    assert.equal(payload.functions[1].time, "18:30");
    assert.equal(payload.functions[2].time, null);
    assert.deepEqual(unparsed, ["enq-time"]);
  });

  it("falls back eventType to others and customer name to Unknown", () => {
    const payload = buildEventOSPayload("enq-fb", {
      customerName: "   ",
      statusValue: "approved",
      eventDate: new Date(Date.UTC(2026, 11, 11, 18, 30)),
      eventType: "",
    });
    assert.equal(payload.customer.name, "Unknown");
    assert.equal(payload.event.eventType, "others");
  });

  it("turns empty optional strings into null", () => {
    const payload = buildEventOSPayload("enq-empty", {
      customerName: "A",
      customerEmail: "  ",
      statusValue: "approved",
      eventDate: new Date(Date.UTC(2026, 11, 11, 18, 30)),
      eventTypeValue: "wedding",
      notes: "",
      assignedToName: "   ",
      eventLocation: "",
    });
    assert.equal(payload.customer.email, null);
    assert.equal(payload.event.notes, null);
    assert.equal(payload.event.assigneeName, null);
    assert.equal(payload.functions[0].location, null);
  });

  it("ensures endDate >= startDate and unique functionIds", () => {
    const payload = buildEventOSPayload("enq-ids", {
      customerName: "A",
      statusValue: "approved",
      functions: [
        {
          id: "same",
          eventType: "haldi",
          date: new Date(Date.UTC(2026, 11, 13, 18, 30)),
          time: "10:00",
        },
        {
          id: "same",
          eventType: "wedding",
          date: new Date(Date.UTC(2026, 11, 11, 18, 30)),
          time: "18:00",
        },
      ],
    });
    assert.ok(payload.event.endDate >= payload.event.startDate);
    const ids = payload.functions.map((f) => f.functionId);
    assert.equal(new Set(ids).size, ids.length);
  });

  it("keeps money non-negative", () => {
    const payload = buildEventOSPayload(
      "enq-money",
      {
        customerName: "A",
        statusValue: "approved",
        eventDate: new Date(Date.UTC(2026, 11, 11, 18, 30)),
        eventTypeValue: "wedding",
      },
      { totalCost: -10, advancePaid: -5, currency: "INR" },
    );
    assert.deepEqual(payload.money, {
      totalCost: 0,
      advancePaid: 0,
      currency: "INR",
    });
  });
});

describe("resolveGuestCount", () => {
  it("rounds finite non-negative counts and nulls invalid values", () => {
    assert.equal(resolveGuestCount({ guestCount: 10.4 }), 10);
    assert.equal(resolveGuestCount({ guestCount: 10.6 }), 11);
    assert.equal(resolveGuestCount({ guestCount: "42" }), 42);
    assert.equal(resolveGuestCount({ guestCount: -1 }), null);
    assert.equal(resolveGuestCount({ guestCount: "nope" }), null);
    assert.equal(resolveGuestCount({}), null);
  });
});

describe("hashEventOSPayload", () => {
  it("is stable across sourceUpdatedAt changes and key order", () => {
    const a = buildEventOSPayload("enq-h", {
      customerName: "A",
      statusValue: "approved",
      eventTypeValue: "wedding",
      eventDate: new Date(Date.UTC(2026, 11, 11, 18, 30)),
      updatedAt: new Date("2026-01-01T00:00:00.000Z"),
    });
    const b = { ...a, sourceUpdatedAt: "2099-01-01T00:00:00.000Z" };
    assert.equal(hashEventOSPayload(a), hashEventOSPayload(b));
    assert.equal(
      stableStringify({ b: 1, a: 2 }),
      stableStringify({ a: 2, b: 1 }),
    );
  });
});

describe("shouldSendToEventOS", () => {
  it("never sends never-approved first sightings", () => {
    assert.equal(
      shouldSendToEventOS({
        status: "new",
        previouslySynced: false,
        lastHash: null,
        nextHash: "abc",
      }),
      false,
    );
    assert.equal(
      shouldSendToEventOS({
        status: "quoted",
        previouslySynced: false,
        lastHash: null,
        nextHash: "abc",
      }),
      false,
    );
  });

  it("sends approved / completed", () => {
    assert.equal(
      shouldSendToEventOS({
        status: "approved",
        previouslySynced: false,
        lastHash: null,
        nextHash: "abc",
      }),
      true,
    );
    assert.equal(
      shouldSendToEventOS({
        status: "completed",
        previouslySynced: false,
        lastHash: null,
        nextHash: "abc",
      }),
      true,
    );
  });

  it("sends cancelled when previously synced", () => {
    assert.equal(
      shouldSendToEventOS({
        status: "cancelled",
        previouslySynced: true,
        lastHash: "old",
        nextHash: "new",
      }),
      true,
    );
  });

  it("skips when the hash is unchanged", () => {
    assert.equal(
      shouldSendToEventOS({
        status: "approved",
        previouslySynced: true,
        lastHash: "same",
        nextHash: "same",
      }),
      false,
    );
  });
});

describe("signEventOSFeedBody (shared test vector)", () => {
  it("matches EventOS: secret test_secret, ts 1700000000, body {\"a\":1}", () => {
    const sig = signEventOSFeedBody("test_secret", "1700000000", '{"a":1}');
    assert.equal(
      sig,
      "v1=f5a131af104d1c1624551668e089377efc5317cc715258c10d2c12d6cf67cb4e",
    );
  });
});
