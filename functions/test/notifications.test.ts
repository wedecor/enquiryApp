import { describe, it, before, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { Timestamp } from "firebase-admin/firestore";
import {
  ActiveUser,
  canAnnounce,
  handleNotifyEnquiryEvent,
  isRecentEvent,
  planEnquiryNotifications,
} from "../src/notifications";
import { clearEmulator, hasEmulator, inbox, seedUsers, testDb } from "./helpers";

const NOW = new Date("2026-11-04T06:00:00Z");
const admins: ActiveUser[] = [
  { uid: "admin1", name: "Admin One", role: "admin" },
  { uid: "admin2", name: "Admin Two", role: "admin" },
];
const staff1: ActiveUser = { uid: "staff1", name: "Staff One", role: "staff" };
const enquiry = {
  customerName: "Priya Sharma",
  eventTypeLabel: "Birthday",
  statusValue: "in_talks",
  assignedTo: "staff1",
};

describe("planEnquiryNotifications (pure)", () => {
  it("created: every admin except the creator, fixed server wording", () => {
    const out = planEnquiryNotifications({
      event: "created", actorUid: "admin1", enquiryId: "e1", enquiry, admins, assignee: staff1,
      oldStatus: null, notifyAdmins: true, notifyAssignee: true,
    });
    assert.deepEqual(out.map((n) => n.uid), ["admin2"]);
    assert.equal(out[0].title, "New Enquiry Created");
    assert.equal(out[0].body, "New enquiry from Priya Sharma for Birthday");
  });

  it("status_changed by staff: admins + no self push; text built from stored status", () => {
    const out = planEnquiryNotifications({
      event: "status_changed", actorUid: "staff1", enquiryId: "e1", enquiry, admins, assignee: staff1,
      oldStatus: "new", notifyAdmins: true, notifyAssignee: true,
    });
    assert.deepEqual(out.map((n) => n.uid).sort(), ["admin1", "admin2"]);
    assert.equal(out[0].body, "Status changed from New to In Talks for Priya Sharma");
  });

  it("status_changed ignores an unknown old status instead of echoing client text", () => {
    const out = planEnquiryNotifications({
      event: "status_changed", actorUid: "admin1", enquiryId: "e1", enquiry, admins, assignee: staff1,
      oldStatus: "<b>pay me</b>", notifyAdmins: true, notifyAssignee: true,
    });
    assert.ok(out.every((n) => !n.body.includes("pay me")));
    assert.ok(out.some((n) => n.uid === "staff1"));
  });

  it("assigned with notifyAdmins false: only the assignee", () => {
    const out = planEnquiryNotifications({
      event: "assigned", actorUid: "admin1", enquiryId: "e1", enquiry, admins, assignee: staff1,
      oldStatus: null, notifyAdmins: false, notifyAssignee: true,
    });
    assert.deepEqual(out.map((n) => n.uid), ["staff1"]);
    assert.equal(out[0].title, "Enquiry Assigned to You");
  });

  it("an admin assignee gets one push, not two", () => {
    const out = planEnquiryNotifications({
      event: "updated", actorUid: "staff1", enquiryId: "e1", enquiry: { ...enquiry, assignedTo: "admin2" },
      admins, assignee: admins[1], oldStatus: null, notifyAdmins: true, notifyAssignee: true,
    });
    assert.deepEqual(out.map((n) => n.uid).sort(), ["admin1", "admin2"]);
  });
});

describe("canAnnounce / isRecentEvent (pure)", () => {
  it("staff may only announce status/edit on their own enquiry", () => {
    assert.equal(canAnnounce("updated", staff1, enquiry), true);
    assert.equal(canAnnounce("updated", staff1, { ...enquiry, assignedTo: "staff2" }), false);
    assert.equal(canAnnounce("created", staff1, enquiry), false);
    assert.equal(canAnnounce("assigned", staff1, enquiry), false);
    assert.equal(canAnnounce("assigned", admins[0], enquiry), true);
  });

  it("requires a matching write within 15 minutes", () => {
    const fresh = Timestamp.fromDate(new Date(NOW.getTime() - 60_000));
    const old = Timestamp.fromDate(new Date(NOW.getTime() - 60 * 60_000));
    assert.equal(isRecentEvent("updated", { updatedAt: fresh }, NOW), true);
    assert.equal(isRecentEvent("updated", { updatedAt: old }, NOW), false);
    assert.equal(isRecentEvent("created", { createdAt: old, updatedAt: fresh }, NOW), false);
    assert.equal(isRecentEvent("status_changed", { statusUpdatedAt: fresh }, NOW), true);
  });
});

describe("notifyEnquiryEvent (emulator)", { skip: !hasEmulator }, () => {
  const db = hasEmulator ? testDb() : (null as unknown as FirebaseFirestore.Firestore);

  before(async () => {
    await clearEmulator();
  });

  beforeEach(async () => {
    await clearEmulator();
    await seedUsers(db);
    const now = Timestamp.now();
    await db.collection("enquiries").doc("mine").set({ ...enquiry, assignedTo: "staff1", updatedAt: now, statusUpdatedAt: now, createdAt: now });
    await db.collection("enquiries").doc("theirs").set({ ...enquiry, assignedTo: "staff2", updatedAt: now, createdAt: now });
  });

  it("staff cannot announce someone else's enquiry", async () => {
    await assert.rejects(
      handleNotifyEnquiryEvent(db, "staff1", { enquiryId: "theirs", event: "updated" }),
      /Not allowed/,
    );
    assert.equal((await inbox(db, "admin1")).length, 0);
  });

  it("staff cannot announce a new enquiry or an assignment", async () => {
    await assert.rejects(handleNotifyEnquiryEvent(db, "staff1", { enquiryId: "mine", event: "created" }), /Not allowed/);
    await assert.rejects(handleNotifyEnquiryEvent(db, "staff1", { enquiryId: "mine", event: "assigned" }), /Not allowed/);
  });

  it("inactive or unknown callers are rejected", async () => {
    await assert.rejects(handleNotifyEnquiryEvent(db, "staffOff", { enquiryId: "mine", event: "updated" }), /Active account/);
    await assert.rejects(handleNotifyEnquiryEvent(db, "nobody", { enquiryId: "mine", event: "updated" }), /Active account/);
    await assert.rejects(handleNotifyEnquiryEvent(db, undefined, { enquiryId: "mine", event: "updated" }), /signed in/);
  });

  it("extra client fields (title/body) are ignored; server text is used", async () => {
    const res = await handleNotifyEnquiryEvent(db, "staff1", {
      enquiryId: "mine", event: "updated", title: "Fake", body: "Fake body",
    } as any);
    assert.equal(res.queued, 2);
    const items = await inbox(db, "admin1");
    assert.equal(items.length, 1);
    assert.equal(items[0].title, "Enquiry Updated");
    assert.equal(items[0].createdBy, "staff1");
    assert.equal((await inbox(db, "adminOff")).length, 0, "inactive admins are skipped");
    assert.equal((await inbox(db, "staff1")).length, 0, "no push to the actor");
  });

  it("a retried call within the dedupe window does not duplicate", async () => {
    await handleNotifyEnquiryEvent(db, "admin1", { enquiryId: "mine", event: "status_changed", oldStatus: "new" });
    await handleNotifyEnquiryEvent(db, "admin1", { enquiryId: "mine", event: "status_changed", oldStatus: "new" });
    assert.equal((await inbox(db, "staff1")).length, 1);
    assert.equal((await inbox(db, "admin2")).length, 1);
  });

  it("a stale event (no recent write) queues nothing", async () => {
    const old = Timestamp.fromDate(new Date(Date.now() - 2 * 60 * 60 * 1000));
    await db.collection("enquiries").doc("mine").update({ updatedAt: old, statusUpdatedAt: old });
    const res = await handleNotifyEnquiryEvent(db, "staff1", { enquiryId: "mine", event: "updated" });
    assert.equal(res.queued, 0);
    assert.equal(res.skipped, "stale");
  });
});
