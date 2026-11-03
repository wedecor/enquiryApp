import { describe, it, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { clearEmulator, hasEmulator, seedUsers, testDb } from "./helpers";

// index.ts calls initializeApp() on load; load it before the helpers create an app.
// eslint-disable-next-line @typescript-eslint/no-var-requires
const index = hasEmulator ? require("../src/index") : null;

describe("adminUpdateUser contact details (emulator)", { skip: !hasEmulator }, () => {
  const db = hasEmulator ? testDb() : (null as unknown as FirebaseFirestore.Firestore);
  const fn = () => index.adminUpdateUser as { run: (req: unknown) => Promise<unknown> };
  const call = (callerUid: string, data: Record<string, unknown>) =>
    fn().run({ data, auth: { uid: callerUid, token: { email: "admin@example.com" } }, rawRequest: {} });

  beforeEach(async () => {
    await clearEmulator();
    await seedUsers(db);
    // Legacy public contact details.
    await db.collection("users").doc("staff1").update({ email: "staff1@example.com", phone: "9111111111" });
  });

  it("writes the phone to users/{uid}/private/profile and removes contact details from the public doc", async () => {
    await call("admin1", { uid: "staff1", phone: "9222222222" });
    const pub = await db.collection("users").doc("staff1").get();
    assert.equal(pub.get("phone"), undefined);
    assert.equal(pub.get("email"), undefined);
    assert.equal(pub.get("name"), "Staff One");
    const profile = await db.collection("users").doc("staff1").collection("private").doc("profile").get();
    assert.equal(profile.get("phone"), "9222222222");
    assert.equal(profile.get("email"), "staff1@example.com", "legacy email moved, not lost");
  });

  it("a name-only edit also moves legacy contact details", async () => {
    await call("admin1", { uid: "staff1", name: "Staff Uno" });
    const pub = await db.collection("users").doc("staff1").get();
    assert.equal(pub.get("name"), "Staff Uno");
    assert.equal(pub.get("phone"), undefined);
    const profile = await db.collection("users").doc("staff1").collection("private").doc("profile").get();
    assert.equal(profile.get("phone"), "9111111111");
  });

  it("non-admins cannot update users", async () => {
    await assert.rejects(call("staff2", { uid: "staff1", phone: "1" }), /Admin privileges/);
  });
});
