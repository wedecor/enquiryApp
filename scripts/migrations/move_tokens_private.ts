#!/usr/bin/env tsx
/**
 * One-time migration: Move FCM tokens from users/{uid} to private subcollection
 * 
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
 *   npm run migrate:tokens
 */

import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('❌ Set GOOGLE_APPLICATION_CREDENTIALS to your serviceAccountKey.json');
  process.exit(1);
}

initializeApp({ credential: applicationDefault() });
const db = getFirestore();

interface MigrationStats {
  usersSeen: number;
  tokensMoved: number;
  usersCleaned: number;
  errors: number;
}

async function migrateTokensToPrivate(): Promise<MigrationStats> {
  console.log('🔄 Starting FCM [REDACTED] migration to [REDACTED] subcollection...\n');

  const stats: MigrationStats = {
    usersSeen: 0,
    tokensMoved: 0,
    usersCleaned: 0,
    errors: 0,
  };

  try {
    // Get all users
    const usersSnapshot = await db.collection("users").get();
    console.log(`📁 Found ${usersSnapshot.docs.length} user documents\n`);

    for (const userDoc of usersSnapshot.docs) {
      stats.usersSeen++;
      
      try {
        const userData = userDoc.data() || {};
        const legacyTokens = new Set<string>();

        // Collect legacy fcmToken
        if (typeof userData.fcmToken === "string" && userData.fcmToken.trim()) {
          legacyTokens.add(userData.fcmToken.trim());
        }

        // Collect legacy webTokens array
        if (Array.isArray(userData.webTokens)) {
          for (const token of userData.webTokens) {
            if (typeof token === "string" && token.trim()) {
              legacyTokens.add(token.trim());
            }
          }
        }

        // Skip if no legacy tokens found
        if (legacyTokens.size === 0) {
          continue;
        }

        console.log(`👤 User ${userDoc.id}: Found [LEGACYTOKENS_REDACTED].size} legacy tokens`);

        // Move tokens to private subcollection
        const tokensCollection = userDoc.ref
          .collection("private")
          .doc("notifications")
          .collection("tokens");

        for (const token of legacyTokens) {
          await tokensCollection.doc(token).set({
            token: token,
            migratedAt: FieldValue.serverTimestamp(),
            source: 'migration_from_users_doc',
          }, { merge: true });
          
          stats.tokensMoved++;
        }

        // Remove legacy fields from users document
        await userDoc.ref.set({
          fcmToken: FieldValue.delete(),
          webTokens: FieldValue.delete(),
          // Keep all other fields intact
        }, { merge: true });

        stats.usersCleaned++;
        console.log(`✅ User ${userDoc.id}: Migrated [LEGACYTOKENS_REDACTED].size} tokens to [REDACTED] collection`);

      } catch (error) {
        stats.errors++;
        console.error(`❌ Error migrating user ${userDoc.id}:`, error);
      }
    }

  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  }

  return stats;
}

async function verifyMigration(): Promise<void> {
  console.log('\n🔍 Verifying migration...');

  // Check if any users still have legacy token fields
  const usersWithTokens = await db.collection("users")
    .where("fcmToken", "!=", null)
    .limit(1)
    .get();

  const usersWithWebTokens = await db.collection("users")
    .where("webTokens", "!=", null)
    .limit(1)
    .get();

  if (usersWithTokens.size > 0 || usersWithWebTokens.size > 0) {
    console.warn('⚠️  Some users still have legacy [REDACTED] fields');
  } else {
    console.log('✅ No legacy [REDACTED] fields found in users collection');
  }

  // Sample check of private tokens
  const sampleUser = await db.collection("users").limit(1).get();
  if (!sampleUser.empty) {
    const sampleUid = sampleUser.docs[0].id;
    const privateTokens = await db.collection("users").doc(sampleUid)
      .collection("private").doc("notifications")
      .collection("tokens").limit(1).get();
    
    if (privateTokens.size > 0) {
      console.log('✅ [REDACTED] [REDACTED] collection structure verified');
    }
  }
}

async function main() {
  try {
    console.log('🛡️  FCM [REDACTED] SECURITY MIGRATION');
    console.log('═'.repeat(40));
    console.log(`🕐 Started: ${new Date().toLocaleString()}\n`);

    const stats = await migrateTokensToPrivate();
    
    await verifyMigration();

    console.log('\n📊 MIGRATION SUMMARY');
    console.log('═'.repeat(30));
    console.log(`👥 Users scanned: ${stats.usersSeen}`);
    console.log(`🔑 Tokens moved: ${stats.tokensMoved}`);
    console.log(`🧹 Users cleaned: ${stats.usersCleaned}`);
    console.log(`❌ Errors: ${stats.errors}`);

    if (stats.errors > 0) {
      console.log('\n⚠️  Some errors occurred during migration');
      console.log('Review the logs above and consider re-running');
      process.exit(1);
    }

    console.log('\n✅ MIGRATION SUCCESSFUL!');
    console.log('🔒 FCM tokens are now stored securely in [REDACTED] subcollections');
    console.log('🚀 Deploy updated Cloud Functions to use the new [REDACTED] location');
    
    console.log(`\n🕐 Completed: ${new Date().toLocaleString()}`);

  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

// Run if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
