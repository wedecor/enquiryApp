#!/usr/bin/env node
/**
 * Migration Script: Standardize 'active' field to 'isActive' for user documents
 * 
 * This script migrates all user documents in Firestore from using 'active' field
 * to 'isActive' field for consistency.
 * 
 * Usage:
 *   npx ts-node scripts/migrate-active-to-isactive.ts [--dry-run] [--batch-size=500]
 * 
 * Safety Features:
 * - Dry-run mode to preview changes
 * - Batch processing to avoid timeouts
 * - Backward compatibility: reads both fields during migration
 * - Rollback script available
 */

import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as readline from "readline";

// Configuration
const BATCH_SIZE = parseInt(process.env.BATCH_SIZE || "500", 10);
const DRY_RUN = process.argv.includes("--dry-run");

// Initialize Firebase Admin
if (getApps().length === 0) {
  // Try to use service account from environment or default credentials
  const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  
  if (serviceAccountPath) {
    const serviceAccount = require(serviceAccountPath);
    initializeApp({
      credential: cert(serviceAccount),
    });
  } else {
    // Use default credentials (for Firebase Functions environment)
    initializeApp();
  }
}

const db = getFirestore();

interface MigrationStats {
  total: number;
  migrated: number;
  skipped: number;
  errors: number;
  alreadyMigrated: number;
}

async function migrateUsers(): Promise<MigrationStats> {
  const stats: MigrationStats = {
    total: 0,
    migrated: 0,
    skipped: 0,
    errors: 0,
    alreadyMigrated: 0,
  };

  console.log("🔍 Starting migration...");
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
        // Check if migration is needed
        const hasActive = "active" in data && data.active !== undefined;
        const hasIsActive = "isActive" in data && data.isActive !== undefined;

        if (!hasActive && hasIsActive) {
          // Already migrated
          stats.alreadyMigrated++;
          continue;
        }

        if (!hasActive && !hasIsActive) {
          // No active field at all - set default
          console.log(`   ⚠️  User ${docId} has no active/isActive field, setting default`);
          if (!DRY_RUN) {
            batch.update(doc.ref, {
              isActive: true,
              updatedAt: FieldValue.serverTimestamp(),
            });
            batchOperations++;
          }
          stats.migrated++;
          continue;
        }

        // Migration needed: copy 'active' to 'isActive'
        const activeValue = data.active as boolean;
        
        if (DRY_RUN) {
          console.log(`   📝 Would migrate: ${docId} (active: ${activeValue} → isActive: ${activeValue})`);
        } else {
          const updateData: Record<string, any> = {
            isActive: activeValue,
            updatedAt: FieldValue.serverTimestamp(),
          };

          // Only remove 'active' if 'isActive' doesn't exist or matches
          // Keep both during migration period for backward compatibility
          // We'll remove 'active' in a second migration phase after verification
          
          batch.update(doc.ref, updateData);
          batchOperations++;
        }

        stats.migrated++;
      } catch (error: any) {
        stats.errors++;
        console.error(`   ❌ Error migrating user ${docId}:`, error.message);
      }
    }

    if (!DRY_RUN && batchOperations > 0) {
      await batch.commit();
      console.log(`   ✅ Committed ${batchOperations} updates`);
    }

    lastDoc = snapshot.docs[snapshot.docs.length - 1];
  }

  return stats;
}

async function main() {
  console.log("=".repeat(60));
  console.log("Migration: active → isActive");
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
        "⚠️  This will modify Firestore documents. Continue? (yes/no): ",
        resolve
      );
    });

    rl.close();

    if (answer.toLowerCase() !== "yes") {
      console.log("Migration cancelled.");
      process.exit(0);
    }
  }

  try {
    const stats = await migrateUsers();

    console.log("\n" + "=".repeat(60));
    console.log("Migration Summary");
    console.log("=".repeat(60));
    console.log(`Total documents processed: ${stats.total}`);
    console.log(`✅ Migrated: ${stats.migrated}`);
    console.log(`⏭️  Already migrated: ${stats.alreadyMigrated}`);
    console.log(`⏭️  Skipped: ${stats.skipped}`);
    console.log(`❌ Errors: ${stats.errors}`);

    if (DRY_RUN) {
      console.log("\n💡 Run without --dry-run to apply changes");
    } else {
      console.log("\n✅ Migration completed!");
      console.log("\n📋 Next steps:");
      console.log("   1. Verify notifications still work");
      console.log("   2. Monitor for 24-48 hours");
      console.log("   3. Run cleanup script to remove 'active' field (optional)");
    }
  } catch (error: any) {
    console.error("\n❌ Migration failed:", error);
    process.exit(1);
  }
}

main();

