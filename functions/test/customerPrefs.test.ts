import { describe, it, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { handleSetReengagementPref } from "../src/customerPrefs";
import { clearEmulator, hasEmulator, seedUsers, testDb } from "./helpers";

describe("setReengagementPref (emulator)", { skip: !hasEmulator }, () => {
  const db = hasEmulator ? testDb() : (null as unknown as FirebaseFirestore.Firestore);
  const pref = () => db.collection("customer_prefs").doc("9876543210").get();

  beforeEach(async () => {
    await clearEmulator();
    await seedUsers(db);
    await db.collection("enquiries").doc("e1").set({ phoneNormalized: "9876543210", assignedTo: "staff1" });
  });

  it("admin can set the preference for any customer; only the three fields are written", async () => {
    await handleSetReengagementPref(db, "admin1", { phone: "+91 98765 43210", noReminders: true });
    const snap = await pref();
    assert.equal(snap.get("noReminders"), true);
    assert.equal(snap.get("updatedBy"), "admin1");
    assert.deepEqual(Object.keys(snap.data()!).sort(), ["noReminders", "updatedAt", "updatedBy"]);
  });

  it("assigned staff can set it; unassigned staff cannot", async () => {
    await handleSetReengagementPref(db, "staff1", { phone: "9876543210", noReminders: true });
    assert.equal((await pref()).get("updatedBy"), "staff1");
    await assert.rejects(
      handleSetReengagementPref(db, "staff2", { phone: "9876543210", noReminders: false }),
      /Not assigned/,
    );
    assert.equal((await pref()).get("noReminders"), true);
  });

  it("inactive / unknown / signed-out callers and bad input are rejected", async () => {
    await assert.rejects(handleSetReengagementPref(db, "staffOff", { phone: "9876543210", noReminders: true }), /Active account/);
    await assert.rejects(handleSetReengagementPref(db, "nobody", { phone: "9876543210", noReminders: true }), /Active account/);
    await assert.rejects(handleSetReengagementPref(db, undefined, { phone: "9876543210", noReminders: true }), /signed in/);
    await assert.rejects(handleSetReengagementPref(db, "admin1", { phone: "123", noReminders: true }), /too short/);
    await assert.rejects(handleSetReengagementPref(db, "admin1", { phone: "9876543210", noReminders: "yes" }), /true or false/);
    assert.equal((await pref()).exists, false);
  });
});
