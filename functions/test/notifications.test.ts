import { describe, it, before, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { Timestamp } from "firebase-admin/firestore";
import {
  ActiveUser,
  canAnnounce,
  deriveEnquiryNotificationEvents,
  handleEnquiryWrittenNotify,
  handleNotifyEnquiryEvent,
  isRecentEvent,
  planEnquiryNotifications,
} from "../src/notifications";
import { WEBSITE_LEAD_CREATED_BY } from "../src/websiteLeads";
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

describe("deriveEnquiryNotificationEvents (pure)", () => {
  it("no before → created (and assigned if assignedTo set)", () => {
    assert.deepEqual(
      deriveEnquiryNotificationEvents(undefined, { customerName: "A", createdBy: "admin1" }),
      [{ event: "created", actorUid: "admin1", notifyAdmins: true, notifyAssignee: false }],
    );
    assert.deepEqual(
      deriveEnquiryNotificationEvents(undefined, { customerName: "A", createdBy: "admin1", assignedTo: "staff1" }),
      [
        { event: "created", actorUid: "admin1", notifyAdmins: true, notifyAssignee: false },
        { event: "assigned", actorUid: "admin1", notifyAdmins: false, notifyAssignee: true },
      ],
    );
  });

  it("website lead create → nothing", () => {
    assert.deepEqual(
      deriveEnquiryNotificationEvents(undefined, {
        customerName: "A",
        createdBy: WEBSITE_LEAD_CREATED_BY,
        assignedTo: "staff1",
      }),
      [],
    );
  });

  it("assignedTo changed → assigned", () => {
    assert.deepEqual(
      deriveEnquiryNotificationEvents(
        { customerName: "A", assignedTo: "staff1", statusValue: "new" },
        { customerName: "A", assignedTo: "staff2", statusValue: "new", updatedBy: "admin1" },
      ),
      [{ event: "assigned", actorUid: "admin1", notifyAdmins: true, notifyAssignee: true }],
    );
  });

  it("canonical status changed → status_changed with oldStatus and statusUpdatedBy actor", () => {
    assert.deepEqual(
      deriveEnquiryNotificationEvents(
        { customerName: "A", statusValue: "new", assignedTo: "staff1" },
        { customerName: "A", statusValue: "in_talks", assignedTo: "staff1", statusUpdatedBy: "staff1", updatedBy: "admin1" },
      ),
      [
        {
          event: "status_changed",
          actorUid: "staff1",
          oldStatus: "new",
          notifyAdmins: true,
          notifyAssignee: true,
        },
      ],
    );
  });

  it("user-facing field changed → updated", () => {
    assert.deepEqual(
      deriveEnquiryNotificationEvents(
        { customerName: "A", statusValue: "new", notes: "old" },
        { customerName: "A", statusValue: "new", notes: "new", updatedBy: "staff1" },
      ),
      [{ event: "updated", actorUid: "staff1", notifyAdmins: true, notifyAssignee: true }],
    );
  });

  it("server-only change → nothing", () => {
    assert.deepEqual(
      deriveEnquiryNotificationEvents(
        { customerName: "A", statusValue: "new", followUpSeq: 1, textIndex: "a" },
        {
          customerName: "A",
          statusValue: "new",
          followUpSeq: 2,
          followUpDueAt: Timestamp.fromDate(NOW),
          pastEventReviewAt: Timestamp.fromDate(NOW),
          occasionStamps: { birthday: true },
          textIndex: "a b",
          updatedAt: Timestamp.fromDate(NOW),
          updatedBy: "system",
        },
      ),
      [],
    );
  });

  it("assignedTo + status_changed emits assigned to new assignee and status_changed to others", () => {
    assert.deepEqual(
      deriveEnquiryNotificationEvents(
        { customerName: "A", statusValue: "new", assignedTo: "staff1" },
        { customerName: "A", statusValue: "in_talks", assignedTo: "staff2", statusUpdatedBy: "admin1", updatedBy: "admin1" },
      ),
      [
        { event: "assigned", actorUid: "admin1", notifyAdmins: false, notifyAssignee: true },
        { event: "status_changed", actorUid: "admin1", oldStatus: "new", notifyAdmins: true, notifyAssignee: false },
      ],
    );
  });

  it("missing or system actor produces empty actorUid so nobody is excluded", () => {
    assert.deepEqual(
      deriveEnquiryNotificationEvents(
        { customerName: "A", statusValue: "approved" },
        { customerName: "A", statusValue: "completed", statusUpdatedBy: "system" },
      ),
      [
        {
          event: "status_changed",
          actorUid: "",
          oldStatus: "approved",
          notifyAdmins: true,
          notifyAssignee: true,
        },
      ],
    );
  });
});

describe("onEnquiryWrittenNotify & notifyEnquiryEvent (emulator)", { skip: !hasEmulator }, () => {
  const db = hasEmulator ? testDb() : (null as unknown as FirebaseFirestore.Firestore);

  before(async () => {
    await clearEmulator();
  });

  beforeEach(async () => {
    await clearEmulator();
    await seedUsers(db);
  });

  it("notifyEnquiryEvent callable is a no-op returning skipped: server", async () => {
    const res = await handleNotifyEnquiryEvent(db, "staff1", { enquiryId: "mine", event: "updated" });
    assert.deepEqual(res, { queued: 0, skipped: "server" });
    assert.equal((await inbox(db, "admin1")).length, 0);
  });

  it("creates notifications with expireAt and dedupes retried trigger events by eventId", async () => {
    const beforeDoc = { ...enquiry, statusValue: "new" };
    const afterDoc = { ...enquiry, statusValue: "in_talks", statusUpdatedBy: "admin1" };

    const first = await handleEnquiryWrittenNotify(db, "e1", "evt-123", beforeDoc, afterDoc, NOW);
    const second = await handleEnquiryWrittenNotify(db, "e1", "evt-123", beforeDoc, afterDoc, NOW);

    assert.equal(first, 2);
    assert.equal(second, 0);
    const staffItems = await inbox(db, "staff1");
    const admin2Items = await inbox(db, "admin2");
    assert.equal(staffItems.length, 1);
    assert.equal(admin2Items.length, 1);
    assert.equal(staffItems[0].id, "ev_e1_status_changed_evt-123");
    assert.ok(staffItems[0].expireAt, "expireAt should be set");
    assert.equal((await inbox(db, "admin1")).length, 0, "actor excluded");
    assert.equal((await inbox(db, "adminOff")).length, 0, "inactive admin excluded");
  });

  it("assignedTo + status_changed to an admin sends at most one push per uid", async () => {
    const beforeDoc = { ...enquiry, statusValue: "new", assignedTo: "staff1" };
    const afterDoc = { ...enquiry, statusValue: "in_talks", assignedTo: "admin2", statusUpdatedBy: "admin1", updatedBy: "admin1" };

    const queued = await handleEnquiryWrittenNotify(db, "e2", "evt-456", beforeDoc, afterDoc, NOW);
    assert.equal(queued, 1);
    const admin2Items = await inbox(db, "admin2");
    assert.equal(admin2Items.length, 1);
    assert.equal(admin2Items[0].type, "enquiry_assigned");
  });

  it("system actor sends to all recipients without excluding anyone", async () => {
    const beforeDoc = { ...enquiry, statusValue: "approved", assignedTo: "staff1" };
    const afterDoc = { ...enquiry, statusValue: "completed", statusUpdatedBy: "system" };

    const queued = await handleEnquiryWrittenNotify(db, "e3", "evt-789", beforeDoc, afterDoc, NOW);
    assert.equal(queued, 3);
    assert.equal((await inbox(db, "admin1")).length, 1);
    assert.equal((await inbox(db, "admin2")).length, 1);
    assert.equal((await inbox(db, "staff1")).length, 1);
  });

  it("server-only write queues nothing", async () => {
    const beforeDoc = { ...enquiry, followUpSeq: 1 };
    const afterDoc = { ...enquiry, followUpSeq: 2, updatedAt: Timestamp.fromDate(NOW) };

    const queued = await handleEnquiryWrittenNotify(db, "e4", "evt-000", beforeDoc, afterDoc, NOW);
    assert.equal(queued, 0);
  });
});
