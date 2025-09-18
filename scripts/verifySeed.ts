import "dotenv/config";
import { db } from "../src/lib/firebaseAdmin.js";

const firestore = db();

interface VerificationResult {
  Check: string;
  Result: 'PASS' | 'FAIL';
  Details?: string;
}

async function main() {
  console.log("🔍 WeDecor Firestore Verification");
  console.log("==================================");
  console.log("");

  const ADMIN_UID = process.env.ADMIN_UID?.trim();
  if (!ADMIN_UID) {
    console.error("❌ ADMIN_UID not set in environment");
    process.exit(1);
  }

  console.log(`Admin UID: ${ADMIN_UID}`);
  console.log(`Project: wedecorenquries`);
  console.log("");

  const results: VerificationResult[] = [];
  let allPassed = true;

  // Check 1: Statuses Dropdown
  try {
    const statusDoc = await firestore.doc('dropdowns/statuses/items/new').get();
    if (statusDoc.exists) {
      results.push({ Check: 'Statuses Dropdown', Result: 'PASS' });
    } else {
      results.push({ Check: 'Statuses Dropdown', Result: 'FAIL', Details: 'dropdowns/statuses/items/new missing' });
      allPassed = false;
    }
  } catch (error) {
    results.push({ Check: 'Statuses Dropdown', Result: 'FAIL', Details: `Error: ${error}` });
    allPassed = false;
  }

  // Check 2: Event Types Dropdown
  try {
    const eventTypeDoc = await firestore.doc('dropdowns/event_types/items/wedding').get();
    if (eventTypeDoc.exists) {
      results.push({ Check: 'Event Types Dropdown', Result: 'PASS' });
    } else {
      results.push({ Check: 'Event Types Dropdown', Result: 'FAIL', Details: 'dropdowns/event_types/items/wedding missing' });
      allPassed = false;
    }
  } catch (error) {
    results.push({ Check: 'Event Types Dropdown', Result: 'FAIL', Details: `Error: ${error}` });
    allPassed = false;
  }

  // Check 3: Priorities Dropdown
  try {
    const priorityDoc = await firestore.doc('dropdowns/priorities/items/medium').get();
    if (priorityDoc.exists) {
      results.push({ Check: 'Priorities Dropdown', Result: 'PASS' });
    } else {
      results.push({ Check: 'Priorities Dropdown', Result: 'FAIL', Details: 'dropdowns/priorities/items/medium missing' });
      allPassed = false;
    }
  } catch (error) {
    results.push({ Check: 'Priorities Dropdown', Result: 'FAIL', Details: `Error: ${error}` });
    allPassed = false;
  }

  // Check 4: Payment Statuses Dropdown
  try {
    const paymentDoc = await firestore.doc('dropdowns/payment_statuses/items/pending').get();
    if (paymentDoc.exists) {
      results.push({ Check: 'Payment Statuses Dropdown', Result: 'PASS' });
    } else {
      results.push({ Check: 'Payment Statuses Dropdown', Result: 'FAIL', Details: 'dropdowns/payment_statuses/items/pending missing' });
      allPassed = false;
    }
  } catch (error) {
    results.push({ Check: 'Payment Statuses Dropdown', Result: 'FAIL', Details: `Error: ${error}` });
    allPassed = false;
  }

  // Check 5: Admin User
  try {
    const userDoc = await firestore.doc(`users/${ADMIN_UID}`).get();
    if (userDoc.exists) {
      const userData = userDoc.data();
      if (userData?.role === 'admin') {
        results.push({ Check: 'Admin User', Result: 'PASS' });
      } else {
        results.push({ Check: 'Admin User', Result: 'FAIL', Details: `users/${ADMIN_UID} exists but role is not admin` });
        allPassed = false;
      }
    } else {
      results.push({ Check: 'Admin User', Result: 'FAIL', Details: `users/${ADMIN_UID} missing` });
      allPassed = false;
    }
  } catch (error) {
    results.push({ Check: 'Admin User', Result: 'FAIL', Details: `Error: ${error}` });
    allPassed = false;
  }

  // Check 6: Enquiries Collection
  try {
    const enquiriesSnapshot = await firestore.collection('enquiries').limit(1).get();
    if (!enquiriesSnapshot.empty) {
      results.push({ Check: 'Enquiries Collection', Result: 'PASS' });
    } else {
      results.push({ Check: 'Enquiries Collection', Result: 'FAIL', Details: 'No enquiries found' });
      allPassed = false;
    }
  } catch (error) {
    results.push({ Check: 'Enquiries Collection', Result: 'FAIL', Details: `Error: ${error}` });
    allPassed = false;
  }

  // Check 7: Dropdown Count (22 expected)
  try {
    const statusesSnapshot = await firestore.collection('dropdowns/statuses/items').get();
    const eventTypesSnapshot = await firestore.collection('dropdowns/event_types/items').get();
    const prioritiesSnapshot = await firestore.collection('dropdowns/priorities/items').get();
    const paymentStatusesSnapshot = await firestore.collection('dropdowns/payment_statuses/items').get();
    
    const totalDropdowns = statusesSnapshot.size + eventTypesSnapshot.size + prioritiesSnapshot.size + paymentStatusesSnapshot.size;
    const expectedTotal = 22; // 8 statuses + 6 event_types + 4 priorities + 4 payment_statuses
    
    if (totalDropdowns >= expectedTotal) {
      results.push({ Check: 'Dropdown Count (22 expected)', Result: 'PASS' });
    } else {
      results.push({ Check: 'Dropdown Count (22 expected)', Result: 'FAIL', Details: `Only ${totalDropdowns}/${expectedTotal} dropdown items found` });
      allPassed = false;
    }
  } catch (error) {
    results.push({ Check: 'Dropdown Count (22 expected)', Result: 'FAIL', Details: `Error: ${error}` });
    allPassed = false;
  }

  // Print results table in exact format requested
  console.log("📋 Verification Results:");
  console.log("");
  
  // Create table data for console.table
  const tableData: Record<string, { Check: string; Result: string }> = {};
  results.forEach((result, index) => {
    tableData[index] = {
      Check: result.Check,
      Result: result.Result
    };
  });
  
  console.table(tableData);
  
  // Print details for failed checks
  const failedChecks = results.filter(r => r.Result === 'FAIL');
  if (failedChecks.length > 0) {
    console.log("");
    console.log("❌ Failed Checks Details:");
    failedChecks.forEach(check => {
      console.log(`   • ${check.Check}: ${check.Details}`);
    });
  }

  // Summary
  const passCount = results.filter(r => r.Result === 'PASS').length;
  const totalCount = results.length;
  
  console.log("");
  console.log(`📊 Summary: ${passCount}/${totalCount} checks passed`);
  
  if (allPassed) {
    console.log("✅ All verification checks passed!");
    console.log("");
    console.log("🎯 Your Flutter app should now:");
    console.log("   • Load without any loading symbols");
    console.log("   • Have working dropdowns with all options");
    console.log("   • Show clean console output (no permission errors)");
    console.log("   • Display professional UX experience");
    console.log("");
    console.log("🚀 WeDecor app is fully functional!");
    process.exit(0);
  } else {
    console.log("❌ Some verification checks failed!");
    console.log("");
    console.log("🔧 Troubleshooting:");
    console.log("   • Check Firebase Console for missing collections");
    console.log("   • Re-run the seeder: npm run seed");
    console.log("   • Verify ADMIN_UID is correct Firebase Auth UID");
    console.log("   • Check service account permissions");
    process.exit(1);
  }
}

main().catch((error) => {
  console.error("❌ Verification script failed:", error);
  process.exit(1);
});
