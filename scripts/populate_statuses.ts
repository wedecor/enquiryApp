#!/usr/bin/env tsx

import * as admin from 'firebase-admin';
import { promises as fs } from 'fs';
import * as path from 'path';

// Configuration
const PROJECT_ID = 'wedecorenquries';
const PATH = 'dropdowns/statuses/items';
const BACKUP_DIR = 'backups';

// Target statuses - exactly what should exist
const DESIRED_STATUSES = [
  { id: "new", label: "New" },
  { id: "in_talks", label: "In Talks" },
  { id: "confirmed", label: "Confirmed" },
  { id: "completed", label: "Completed" },
  { id: "cancelled", label: "Cancelled" },
  { id: "not_interested", label: "Not Interested" },
  { id: "quotation_sent", label: "Quotation Sent" },
] as const;

// Safety and environment checks
interface Environment {
  isDryRun: boolean;
  isProductionConfirmed: boolean;
  credentialsPath: string;
}

function checkEnvironment(): Environment {
  const isDryRun = process.env.DRY_RUN === '1';
  const isProductionConfirmed = process.env.CONFIRM_PROD === 'YES';
  const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || '';

  console.log('🔍 Environment Check:');
  console.log(`  DRY_RUN: ${isDryRun ? '✅ YES' : '❌ NO'}`);
  console.log(`  CONFIRM_PROD: ${isProductionConfirmed ? '✅ YES' : '❌ NO'}`);
  console.log(`  GOOGLE_APPLICATION_CREDENTIALS: ${credentialsPath ? '✅ Set' : '❌ Missing'}`);

  // Safety checks
  if (!credentialsPath) {
    console.error('❌ FATAL: GOOGLE_APPLICATION_CREDENTIALS environment variable is required');
    console.error('   Set it to the path of your service account JSON file');
    process.exit(1);
  }

  if (!isDryRun && !isProductionConfirmed) {
    console.error('❌ FATAL: Production run requires CONFIRM_PROD=YES');
    console.error('   This is a safety measure to prevent accidental production changes');
    console.error('   Run with: CONFIRM_PROD=YES npm run seed:statuses');
    process.exit(1);
  }

  // Verify credentials file exists
  try {
    fs.accessSync(credentialsPath);
  } catch (error) {
    console.error(`❌ FATAL: Credentials file not found: ${credentialsPath}`);
    process.exit(1);
  }

  return { isDryRun, isProductionConfirmed, credentialsPath };
}

// Initialize Firebase Admin
function initializeFirebase(): admin.firestore.Firestore {
  try {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: PROJECT_ID,
    });
    console.log(`✅ Firebase Admin initialized for project: ${PROJECT_ID}`);
    return admin.firestore();
  } catch (error) {
    console.error('❌ FATAL: Failed to initialize Firebase Admin:', error);
    process.exit(1);
  }
}

// Create backup directory and save existing data
async function createBackup(db: admin.firestore.Firestore): Promise<string> {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const backupFileName = `statuses-${timestamp}.json`;
  const backupPath = path.join(BACKUP_DIR, backupFileName);

  // Create backup directory if it doesn't exist
  await fs.mkdir(BACKUP_DIR, { recursive: true });

  console.log('📦 Creating backup of existing data...');
  
  try {
    const snapshot = await db.collection(PATH).get();
    const existingDocs: Record<string, any> = {};
    
    snapshot.forEach(doc => {
      existingDocs[doc.id] = doc.data();
    });

    await fs.writeFile(backupPath, JSON.stringify(existingDocs, null, 2));
    console.log(`✅ Backup created: ${backupPath}`);
    console.log(`   Documents backed up: ${Object.keys(existingDocs).length}`);
    
    return backupPath;
  } catch (error) {
    console.error('❌ Failed to create backup:', error);
    throw error;
  }
}

// Batch operations helper
async function executeBatch(
  db: admin.firestore.Firestore,
  operations: Array<{ type: 'upsert' | 'delete'; id: string; data?: any }>,
  isDryRun: boolean
): Promise<{ upserts: number; deletions: number; errors: number }> {
  if (isDryRun) {
    console.log('🔍 DRY RUN - Operations that would be executed:');
    operations.forEach(op => {
      if (op.type === 'upsert') {
        console.log(`  📝 UPSERT: ${op.id} -> ${JSON.stringify(op.data, null, 2)}`);
      } else {
        console.log(`  🗑️  DELETE: ${op.id}`);
      }
    });
    return { upserts: 0, deletions: 0, errors: 0 };
  }

  const batchSize = 400; // Conservative batch size
  let upserts = 0;
  let deletions = 0;
  let errors = 0;

  for (let i = 0; i < operations.length; i += batchSize) {
    const batch = db.batch();
    const batchOps = operations.slice(i, i + batchSize);
    
    console.log(`📦 Executing batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(operations.length / batchSize)} (${batchOps.length} operations)`);

    try {
      for (const op of batchOps) {
        const docRef = db.collection(PATH).doc(op.id);
        
        if (op.type === 'upsert') {
          batch.set(docRef, op.data!, { merge: true });
          upserts++;
        } else if (op.type === 'delete') {
          batch.delete(docRef);
          deletions++;
        }
      }

      await batch.commit();
      console.log(`✅ Batch committed successfully`);
    } catch (error) {
      console.error(`❌ Batch failed:`, error);
      errors += batchOps.length;
    }
  }

  return { upserts, deletions, errors };
}

// Main execution function
async function main() {
  console.log('🚀 WeDecor Enquiries - Status Population Script');
  console.log('=' .repeat(50));

  // Environment and safety checks
  const env = checkEnvironment();
  
  // Initialize Firebase
  const db = initializeFirebase();

  // Create backup
  const backupPath = await createBackup(db);

  // Read existing documents
  console.log('📖 Reading existing status documents...');
  const snapshot = await db.collection(PATH).get();
  const existingDocs = new Map<string, admin.firestore.DocumentData>();
  
  snapshot.forEach(doc => {
    existingDocs.set(doc.id, doc.data());
  });

  console.log(`📊 Found ${existingDocs.size} existing documents`);

  // Determine operations needed
  const desiredIds = new Set(DESIRED_STATUSES.map(s => s.id));
  const existingIds = new Set(existingDocs.keys());
  
  // Upsert operations (all desired statuses)
  const toUpsert = DESIRED_STATUSES.map((status, index) => ({
    type: 'upsert' as const,
    id: status.id,
    data: {
      id: status.id,
      label: status.label,
      order: index + 1,
      active: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: existingDocs.get(status.id)?.createdAt ?? admin.firestore.FieldValue.serverTimestamp(),
    }
  }));

  // Delete operations (existing docs not in desired set)
  const toDelete = Array.from(existingIds)
    .filter(id => !desiredIds.has(id))
    .map(id => ({
      type: 'delete' as const,
      id
    }));

  const operations = [...toUpsert, ...toDelete];

  console.log('\n📋 Operation Summary:');
  console.log(`  📝 Upserts: ${toUpsert.length}`);
  console.log(`  🗑️  Deletions: ${toDelete.length}`);
  console.log(`  📦 Total operations: ${operations.length}`);

  if (toDelete.length > 0) {
    console.log(`\n🗑️  Documents to be deleted:`);
    toDelete.forEach(op => console.log(`    - ${op.id}`));
  }

  // Execute operations
  const results = await executeBatch(db, operations, env.isDryRun);

  // Final summary
  console.log('\n' + '='.repeat(50));
  console.log('📊 FINAL SUMMARY:');
  console.log(`  📦 Backup file: ${backupPath}`);
  console.log(`  📝 Upserts: ${results.upserts}`);
  console.log(`  🗑️  Deletions: ${results.deletions}`);
  console.log(`  ❌ Errors: ${results.errors}`);
  console.log(`  🎯 Target documents: ${DESIRED_STATUSES.length}`);
  
  if (env.isDryRun) {
    console.log('\n🔍 This was a DRY RUN - no changes were made');
    console.log('   To apply changes, run: CONFIRM_PROD=YES npm run seed:statuses');
  } else {
    console.log('\n✅ Production changes completed successfully!');
  }

  // Verify final state
  if (!env.isDryRun) {
    console.log('\n🔍 Verifying final state...');
    const finalSnapshot = await db.collection(PATH).get();
    const finalIds = Array.from(finalSnapshot.docs.map(doc => doc.id)).sort();
    const expectedIds = Array.from(desiredIds).sort();
    
    if (JSON.stringify(finalIds) === JSON.stringify(expectedIds)) {
      console.log('✅ VERIFICATION PASSED: Database contains exactly the expected statuses');
      console.log(`   Statuses: ${finalIds.join(', ')}`);
    } else {
      console.log('❌ VERIFICATION FAILED: Database state does not match expectations');
      console.log(`   Expected: ${expectedIds.join(', ')}`);
      console.log(`   Actual: ${finalIds.join(', ')}`);
    }
  }

  console.log('\n🎉 Script completed successfully!');
  process.exit(0);
}

// Error handling
process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught Exception:', error);
  process.exit(1);
});

// Run the script
main().catch(error => {
  console.error('❌ Script failed:', error);
  process.exit(1);
});
