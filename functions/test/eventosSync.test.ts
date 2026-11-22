import { describe, it, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { syncEnquiryToEventOS } from "../src/eventosSync";
import { clearEmulator, hasEmulator, testDb } from "./helpers";

describe("syncEnquiryToEventOS (emulator)", { skip: !hasEmulator }, () => {
  const db = hasEmulator ? testDb() : (null as unknown as FirebaseFirestore.Firestore);

  beforeEach(async () => {
    await clearEmulator();
  });

  async function seedApproved(id: string) {
    await db
      .collection("enquiries")
      .doc(id)
      .set({
        customerName: "Test Customer",
        customerPhone: "9876543210",
        statusValue: "approved",
        eventTypeValue: "wedding",
        eventTypeLabel: "Wedding",
        eventDate: new Date(Date.UTC(2026, 11, 11, 18, 30)),
        updatedAt: new Date("2026-11-23T10:00:00.000Z"),
      });
  }

  it("writes bookkeeping on 2xx", async () => {
    await seedApproved("enq-ok");
    const calls: Array<{ url: string; init: RequestInit }> = [];
    const result = await syncEnquiryToEventOS("enq-ok", {
      db,
      feedUrl: "https://example.test/sync",
      secret: "s".repeat(40),
      deliveryId: "delivery-1",
      eventTimeMs: Date.now(),
      fetchImpl: async (url, init) => {
        calls.push({ url: String(url), init: init ?? {} });
        return new Response(JSON.stringify({ ok: true, eventId: "evt-1" }), { status: 200 });
      },
    });

    assert.equal(result.action, "sent");
    assert.equal(calls.length, 1);
    const headers = calls[0].init.headers as Record<string, string>;
    assert.ok(headers["X-EventOS-Signature"]?.startsWith("v1="));
    assert.equal(headers["X-EventOS-Delivery-Id"], "delivery-1");

    const syncDoc = await db
      .collection("enquiries")
      .doc("enq-ok")
      .collection("private")
      .doc("eventosSync")
      .get();
    assert.equal(syncDoc.exists, true);
    assert.equal(syncDoc.data()?.eventosEventId, "evt-1");
    assert.equal(syncDoc.data()?.lastHttpStatus, 200);
  });

  it("throws on 500 so Cloud Functions can retry", async () => {
    await seedApproved("enq-500");
    await assert.rejects(
      () =>
        syncEnquiryToEventOS("enq-500", {
          db,
          feedUrl: "https://example.test/sync",
          secret: "s".repeat(40),
          deliveryId: "delivery-2",
          eventTimeMs: Date.now(),
          fetchImpl: async () => new Response("boom", { status: 500 }),
        }),
      /500/,
    );
  });

  it("does not throw on 400; records rejection", async () => {
    await seedApproved("enq-400");
    const result = await syncEnquiryToEventOS("enq-400", {
      db,
      feedUrl: "https://example.test/sync",
      secret: "s".repeat(40),
      deliveryId: "delivery-3",
      eventTimeMs: Date.now(),
      fetchImpl: async () => new Response("bad", { status: 400 }),
    });
    assert.equal(result.action, "rejected");
    assert.equal(result.action === "rejected" && result.httpStatus, 400);

    const syncDoc = await db
      .collection("enquiries")
      .doc("enq-400")
      .collection("private")
      .doc("eventosSync")
      .get();
    assert.equal(syncDoc.data()?.lastHttpStatus, 400);
    assert.equal(syncDoc.data()?.lastError, "http_400");
  });

  it("skips never-approved enquiries", async () => {
    await db.collection("enquiries").doc("enq-new").set({
      customerName: "New",
      statusValue: "new",
      eventDate: new Date(Date.UTC(2026, 11, 11, 18, 30)),
      eventTypeValue: "wedding",
      updatedAt: new Date(),
    });
    const result = await syncEnquiryToEventOS("enq-new", {
      db,
      feedUrl: "https://example.test/sync",
      secret: "s".repeat(40),
      deliveryId: "delivery-4",
      eventTimeMs: Date.now(),
      fetchImpl: async () => {
        throw new Error("should not be called");
      },
    });
    assert.equal(result.action, "skipped");
  });
});
