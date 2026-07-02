#!/usr/bin/env tsx
/**
 * Post-migration verification for audit migrations.
 */

import "dotenv/config";
import { db } from "../../src/lib/firebaseAdmin.js";

const firestore = db();

const LEGACY_STATUSES = new Set([
  "in_progress",
  "confirmed",
  "quoted",
  "enquired",
  "assigned",
]);

const VALID_PAYMENTS = new Set(["pending", "partial", "paid", "overdue"]);

async function main() {
  const enquiries = await firestore.collection("enquiries").get();
  let legacyStatusCount = 0;
  let invalidPaymentCount = 0;

  for (const doc of enquiries.docs) {
    const data = doc.data();
    const status = (data.statusValue as string | undefined)?.toLowerCase();
    if (status && LEGACY_STATUSES.has(status)) legacyStatusCount++;

    const payment = (data.paymentStatusValue as string | undefined)?.toLowerCase();
    if (payment && !VALID_PAYMENTS.has(payment)) invalidPaymentCount++;
  }

  const users = await firestore.collection("users").get();
  let missingIsActive = 0;
  for (const doc of users.docs) {
    const data = doc.data();
    if (!Object.prototype.hasOwnProperty.call(data, "isActive")) missingIsActive++;
  }

  console.log("Post-migration verification:");
  console.log(`  legacy statusValue count: ${legacyStatusCount}`);
  console.log(`  invalid paymentStatusValue count: ${invalidPaymentCount}`);
  console.log(`  users missing isActive: ${missingIsActive}`);

  if (legacyStatusCount + invalidPaymentCount + missingIsActive > 0) {
    process.exit(1);
  }
}

main().catch((error) => {
  console.error("Verification failed:", error);
  process.exit(1);
});
