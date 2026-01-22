#!/usr/bin/env node
/**
 * Rollback Script: Revert 'isActive' field back to 'active' for user documents
 * 
 * This script rolls back the migration by copying 'isActive' back to 'active'
 * and removing 'isActive' field. Use this if migration causes issues.
 * 
 * Usage:
 *   npx ts-node scripts/rollback-isactive-to-active.ts [--dry-run] [--batch-size=500]
 * 
 * WARNING: This will revert all migrated documents. Use with caution.
 */

import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as readline from "readline";

// Configuration
const BATCH_SIZE = parseInt(process.env.BATCH_SIZE || "500", 10);
const DRY_RUN = process.argv.includes("--dry-run");

// Initialize Firebase Admin
if (getApps().length === 0) {
  const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  
  if (serviceAccountPath) {
    const serviceAccount = require(serviceAccountPath);
    initializeApp({
      credential: cert(serviceAccount),
    });
  } else {
    initializeApp();
  }
}

const db = getFirestore();

interface RollbackStats {
  total: number;
  rolledBack: number;
  skipped: number;
  errors: number;
}

async function rollbackUsers(): Promise<RollbackStats> {
  const stats: RollbackStats = {
    total: 0,
    rolledBack: 0,
    skipped: 0,
    errors: 0,
  };

  console.log("🔍 Starting rollback...");
  console.log(`   Mode: ${DRY_RUN ? "DRY RUN" : "LIVE"}`);
  console.log(`   Batch size: ${BATCH_SIZE}`);

  let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  let batchCount = 0;

  while (true) {
    let query = db.collection("users").limit(BATCH_SIZE);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.get();

    if (snapshot.empty) {
      break;
    }

    batchCount++;
    console.log(`\n📦 Processing batch ${batchCount} (${snapshot.docs.length} documents)...`);

    const batch = db.batch();
    let batchOperations = 0;

    for (const doc of snapshot.docs) {
      stats.total++;
      const data = doc.data();
      const docId = doc.id;

      try {
        const hasIsActive = "isActive" in data && data.isActive !== undefined;

        if (!hasIsActive) {
          // No isActive field - skip
          stats.skipped++;
          continue;
        }

        const isActiveValue = data.isActive as boolean;

        if (DRY_RUN) {
          console.log(`   📝 Would rollback: ${docId} (isActive: ${isActiveValue} → active: ${isActiveValue})`);
        } else {
          // Copy isActive to active and remove isActive
          batch.update(doc.ref, {
            active: isActiveValue,
            isActive: FieldValue.delete(),
            updatedAt: FieldValue.serverTimestamp(),
          });
          batchOperations++;
        }

        stats.rolledBack++;
      } catch (error: any) {
        stats.errors++;
        console.error(`   ❌ Error rolling back user ${docId}:`, error.message);
      }
    }

    if (!DRY_RUN && batchOperations > 0) {
      await batch.commit();
      console.log(`   ✅ Committed ${batchOperations} rollbacks`);
    }

    lastDoc = snapshot.docs[snapshot.docs.length - 1];
  }

  return stats;
}

async function main() {
  console.log("=".repeat(60));
  console.log("ROLLBACK: isActive → active");
  console.log("=".repeat(60));

  if (DRY_RUN) {
    console.log("\n⚠️  DRY RUN MODE - No changes will be made\n");
  } else {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });

    const answer = await new Promise<string>((resolve) => {
      rl.question(
        "⚠️  WARNING: This will revert the migration. Continue? (yes/no): ",
        resolve
      );
    });

    rl.close();

    if (answer.toLowerCase() !== "yes") {
      console.log("Rollback cancelled.");
      process.exit(0);
    }
  }

  try {
    const stats = await rollbackUsers();

    console.log("\n" + "=".repeat(60));
    console.log("Rollback Summary");
    console.log("=".repeat(60));
    console.log(`Total documents processed: ${stats.total}`);
    console.log(`✅ Rolled back: ${stats.rolledBack}`);
    console.log(`⏭️  Skipped: ${stats.skipped}`);
    console.log(`❌ Errors: ${stats.errors}`);

    if (DRY_RUN) {
      console.log("\n💡 Run without --dry-run to apply changes");
    } else {
      console.log("\n✅ Rollback completed!");
      console.log("\n📋 Next steps:");
      console.log("   1. Revert code changes (use git)");
      console.log("   2. Redeploy Cloud Functions");
      console.log("   3. Verify notifications work");
    }
  } catch (error: any) {
    console.error("\n❌ Rollback failed:", error);
    process.exit(1);
  }
}

main();

