import "dotenv/config";
import fs from "node:fs";
import path from "node:path";
import admin from "firebase-admin";

function panic(msg: string, code = 1): never {
  console.error("❌", msg);
  process.exit(code);
}

function initAdmin() {
  try {
    if (admin.apps.length === 0) {
      admin.initializeApp({ credential: admin.credential.applicationDefault() });
    }
  } catch {
    panic(
      "Firebase Admin init failed. Set GOOGLE_APPLICATION_CREDENTIALS to your serviceAccountKey.json\n" +
      "Example:\n  export GOOGLE_APPLICATION_CREDENTIALS=\"$PWD/serviceAccountKey.json\""
    );
  }
}

function upsertEnv(envPath: string, key: string, val: string) {
  const row = `${key}=${val}`;
  let contents = fs.existsSync(envPath) ? fs.readFileSync(envPath, "utf8") : "";
  const re = new RegExp(`^${key}=.*$`, "m");
  if (re.test(contents)) contents = contents.replace(re, row);
  else contents += (contents && !contents.endsWith("\n") ? "\n" : "") + row + "\n";
  fs.writeFileSync(envPath, contents, "utf8");
}

async function main() {
  const ADMIN_EMAIL = process.env.ADMIN_EMAIL?.trim() || "admin@wedecorevents.com";
  const TEMP_PASSWORD = process.env.ADMIN_TEMP_PASSWORD?.trim() || "admin12"; // change later in Console

  const envPath = path.resolve(".env");
  console.log("🔐 Admin email:", ADMIN_EMAIL);
  initAdmin();

  let user: admin.auth.UserRecord;
  try {
    user = await admin.auth().getUserByEmail(ADMIN_EMAIL);
    console.log("✅ Found existing user:", user.uid);
  } catch (e: any) {
    if (e?.code === "auth/user-not-found") {
      console.log("ℹ️  User not found. Creating…");
      user = await admin.auth().createUser({
        email: ADMIN_EMAIL,
        password: TEMP_PASSWORD,
        emailVerified: true,
      });
      console.log("✅ Created user:", user.uid);
    } else {
      panic(`Failed to get/create user for ${ADMIN_EMAIL}: ${e?.message || e}`);
    }
  }

  upsertEnv(envPath, "ADMIN_UID", user.uid);
  upsertEnv(envPath, "ADMIN_EMAIL", ADMIN_EMAIL);
  console.log("📝 Wrote to .env → ADMIN_UID, ADMIN_EMAIL");

  console.log("\n=== Summary ===");
  console.log("UID:", user.uid);
  console.log("Email:", ADMIN_EMAIL);
  console.log("env:", envPath);
  console.log("\nNext:");
  console.log("  1) export GOOGLE_APPLICATION_CREDENTIALS=\"$PWD/serviceAccountKey.json\"");
  console.log("  2) npm run seed");
  console.log("  3) npm run verify-seed");
}

main().catch((e) => panic(String(e)));