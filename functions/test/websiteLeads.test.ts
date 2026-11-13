import { describe, it, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { handleLookupCustomer } from "../src/customers";
import { handleWebsiteLead, parseWebsiteLead, secretMatches, WebsiteLeadPayload } from "../src/websiteLeads";
import { clearEmulator, hasEmulator, inbox, seedUsers, testDb } from "./helpers";

const NOW = new Date("2026-11-04T06:00:00Z");

function payload(overrides: Partial<{ externalId: string; phone: string; type: string; date: string }> = {}): WebsiteLeadPayload {
  return {
    externalId: overrides.externalId ?? "lead-0001-abcd",
    contact: { name: "priya sharma", phone: overrides.phone ?? "+91 98765 43210", email: "priya@example.com" },
    event: {
      type: overrides.type ?? "Birthday",
      date: overrides.date ?? "2026-12-12",
      budget: "50k-1L",
      notes: "Balloon decor",
      location: "Indiranagar",
    },
    metadata: { pageUrl: "https://www.wedecorevents.com/contact" },
  };
}

describe("website lead parsing (pure)", () => {
  it("accepts the website payload and normalises the phone", () => {
    const parsed = parseWebsiteLead(payload(), NOW);
    assert.notEqual(typeof parsed, "string");
    if (typeof parsed === "string") return;
    assert.equal(parsed.phoneNormalized, "9876543210");
    assert.equal(parsed.name, "Priya Sharma");
  });

  it("rejects past dates, missing location and bad ids", () => {
    assert.equal(parseWebsiteLead(payload({ date: "2026-11-01" }), NOW), "event date is in the past");
    assert.equal(parseWebsiteLead({ ...payload(), event: { type: "Birthday", date: "2026-12-12" } }, NOW), "location required");
    assert.equal(parseWebsiteLead(payload({ externalId: "x" }), NOW), "externalId missing or invalid");
  });

  it("secret comparison is exact", () => {
    assert.equal(secretMatches("s3cret", "s3cret"), true);
    assert.equal(secretMatches("s3cre", "s3cret"), false);
    assert.equal(secretMatches(undefined, "s3cret"), false);
    assert.equal(secretMatches("", ""), false);
  });
});

describe("websiteLead + lookupCustomer (emulator)", { skip: !hasEmulator }, () => {
  const db = hasEmulator ? testDb() : (null as unknown as FirebaseFirestore.Firestore);

  beforeEach(async () => {
    await clearEmulator();
    await seedUsers(db);
    // Website assignee comes from Settings (app_config/notifications.websiteAssigneeUid).
    await db.collection("app_config").doc("notifications").set({ websiteAssigneeUid: "staff1" });
  });

  it("(1) the same external id submitted twice creates one enquiry and one set of notifications", async () => {
    const first = await handleWebsiteLead(db, payload(), NOW);
    const second = await handleWebsiteLead(db, payload(), NOW);
    assert.equal(first.status, 201);
    assert.equal(second.status, 200);
    assert.equal(second.json.duplicate, true);
    assert.equal(second.json.enquiryId, first.json.enquiryId);
    const all = await db.collection("enquiries").get();
    assert.equal(all.size, 1);
    assert.equal(all.docs[0].id, "web_lead-0001-abcd");
    assert.equal((await inbox(db, "admin1")).length, 1);
  });

  it("(2) same phone, different external id → a separate enquiry, not marked duplicate", async () => {
    await handleWebsiteLead(db, payload({ externalId: "lead-birthday-01", type: "Birthday" }), NOW);
    const res = await handleWebsiteLead(db, payload({ externalId: "lead-wedding-02", type: "Wedding", date: "2027-02-10" }), NOW);
    assert.equal(res.status, 201);
    const docs = (await db.collection("enquiries").where("phoneNormalized", "==", "9876543210").get()).docs;
    assert.equal(docs.length, 2);
    for (const d of docs) {
      assert.equal(d.get("statusValue"), "new");
      assert.equal(d.get("mergedInto"), undefined);
      assert.notEqual(d.get("lostReason"), "duplicate");
    }
    assert.deepEqual(docs.map((d) => d.get("eventTypeValue")).sort(), ["birthday", "wedding"]);
    const titles = (await inbox(db, "admin1")).map((n) => n.title).sort();
    assert.deepEqual(titles, ["New website enquiry", "New website enquiry · repeat customer"]);
  });

  it("a retried first delivery is not labelled a repeat customer", async () => {
    await handleWebsiteLead(db, payload(), NOW);
    await handleWebsiteLead(db, payload(), NOW);
    const titles = (await inbox(db, "admin1")).map((n) => n.title);
    assert.deepEqual(titles, ["New website enquiry"]);
  });

  it("(3) enquiries sharing a phone stay independently editable", async () => {
    await handleWebsiteLead(db, payload({ externalId: "lead-birthday-01" }), NOW);
    await handleWebsiteLead(db, payload({ externalId: "lead-wedding-02", type: "Wedding" }), NOW);
    await db.collection("enquiries").doc("web_lead-birthday-01").update({ statusValue: "in_talks", notes: "Call back Friday" });
    const other = await db.collection("enquiries").doc("web_lead-wedding-02").get();
    assert.equal(other.get("statusValue"), "new");
    assert.equal(other.get("notes"), "Balloon decor");
  });

  it("(4) lookupCustomer lists related enquiries without merging them", async () => {
    await handleWebsiteLead(db, payload({ externalId: "lead-birthday-01" }), NOW);
    await handleWebsiteLead(db, payload({ externalId: "lead-wedding-02", type: "Wedding" }), NOW);
    const before = (await db.collection("enquiries").get()).docs.map((d) => d.data());

    const result = await handleLookupCustomer(db, "staff1", { phone: "98765 43210", excludeEnquiryId: "web_lead-wedding-02" });
    assert.equal(result.totalEvents, 1);
    assert.equal(result.events[0].id, "web_lead-birthday-01");
    assert.equal(result.events[0].isOpen, true);
    assert.equal(result.customer?.name, "Priya Sharma");
    assert.equal(result.customer?.phone, "+919876543210");
    assert.equal(result.customer?.email, "priya@example.com");

    const unassigned = await handleLookupCustomer(db, "staff2", { phone: "98765 43210" });
    assert.equal(unassigned.customer?.name, "Priya Sharma");
    assert.equal(unassigned.customer?.email, null);
    assert.equal(unassigned.customer?.whatsappNumber, null);
    assert.equal(unassigned.customer?.phone, null);

    const after = (await db.collection("enquiries").get()).docs.map((d) => d.data());
    assert.deepEqual(after, before, "lookup is read-only");
  });

  it("lookupCustomer skips enquiries already merged away and rejects inactive callers", async () => {
    await handleWebsiteLead(db, payload({ externalId: "lead-birthday-01" }), NOW);
    await handleWebsiteLead(db, payload({ externalId: "lead-wedding-02" }), NOW);
    await db.collection("enquiries").doc("web_lead-birthday-01").update({ mergedInto: "web_lead-wedding-02" });
    const result = await handleLookupCustomer(db, "admin1", { phone: "9876543210" });
    assert.deepEqual(result.events.map((e) => e.id), ["web_lead-wedding-02"]);
    await assert.rejects(handleLookupCustomer(db, "staffOff", { phone: "9876543210" }), /Active account/);
  });

  it("(5) no configured / missing / inactive website assignee → unassigned, admins still notified", async () => {
    for (const [i, config] of [{}, { websiteAssigneeUid: "ghost" }, { websiteAssigneeUid: "staffOff" }].entries()) {
      await db.collection("app_config").doc("notifications").set(config);
      const res = await handleWebsiteLead(db, payload({ externalId: `lead-noassign-${i}` }), NOW);
      assert.equal(res.status, 201);
      const doc = await db.collection("enquiries").doc(`web_lead-noassign-${i}`).get();
      assert.equal(doc.get("assignedTo"), null, JSON.stringify(config));
    }
    assert.equal((await inbox(db, "admin1")).length, 3);
    assert.equal((await inbox(db, "staffOff")).length, 0);
  });

  it("(15) website integration: attribution, assignee, admin + assignee notifications, validation", async () => {
    const bad = await handleWebsiteLead(db, payload({ date: "2026-10-01" }), NOW);
    assert.equal(bad.status, 400);

    const res = await handleWebsiteLead(db, payload({ type: "Kitty Party" }), NOW);
    assert.equal(res.status, 201);
    const doc = await db.collection("enquiries").doc("web_lead-0001-abcd").get();
    assert.equal(doc.get("sourceValue"), "google_website");
    assert.equal(doc.get("createdBy"), "system:website");
    assert.equal(doc.get("websiteLeadId"), "lead-0001-abcd");
    assert.equal(doc.get("assignedTo"), "staff1");
    // No money on the enquiry: it lives in the admin-only financial summary.
    for (const field of ["totalCost", "advancePaid", "paymentStatus", "paymentStatusValue"]) {
      assert.equal(doc.get(field), undefined, field);
    }
    const summary = await doc.ref.collection("financial").doc("summary").get();
    assert.equal(summary.get("paymentStatusValue"), "pending");
    assert.equal(doc.get("eventTypeValue"), "others", "unknown website types fall back to Others");
    assert.match(String(doc.get("notes")), /Event type on website: Kitty Party/);
    assert.equal((await inbox(db, "admin1")).length, 1);
    assert.equal((await inbox(db, "admin2")).length, 1);
    assert.equal((await inbox(db, "staff1")).length, 1);
    assert.equal((await inbox(db, "adminOff")).length, 0);
  });
});
