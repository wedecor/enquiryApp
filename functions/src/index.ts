import {onDocumentCreated, onDocumentUpdated, onDocumentDeleted} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onRequest} from "firebase-functions/v2/https";
import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";

// Initialize Firebase Admin
initializeApp();
const auth = getAuth();
const firestore = getFirestore();

/**
 * Auth Sync Cloud Functions for WeDecor Enquiries App
 * 
 * These functions automatically sync Firestore user documents with Firebase Auth:
 * - Create Auth user when Firestore user doc is created
 * - Update Auth user custom claims when role changes
 * - Disable/enable Auth user when active status changes
 * - Delete Auth user when Firestore user doc is deleted
 */

interface UserDocument {
  uid: string;
  name: string;
  email: string;
  phone?: string;
  role: 'admin' | 'staff';
  active: boolean;
  fcmToken?: string;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}

/**
 * Triggered when a new user document is created in Firestore
 * Creates a corresponding Firebase Auth user with temporary password
 */
export const onUserCreated = onDocumentCreated(
  {
    document: "users/{uid}",
    region: "us-central1",
  },
  async (event) => {
    const userData = event.data?.data() as UserDocument;
    const uid = event.params.uid;

    if (!userData) {
      console.error("No user data found in document");
      return;
    }

    try {
      console.log(`Creating Auth user for: ${userData.email}`);

      // Generate a random temporary password
      const tempPassword = generateTempPassword();

      // Create Auth user
      await auth.createUser({
        uid: uid,
        email: userData.email,
        password: tempPassword,
        displayName: userData.name,
        emailVerified: true, // Mark as verified since admin created it
        disabled: !userData.active,
      });

      // Set custom claims for role-based access
      await auth.setCustomUserClaims(uid, {
        role: userData.role,
        admin: userData.role === 'admin',
      });

      console.log(`Successfully created Auth user for: ${userData.email}`);
      console.log(`Temporary password: ${tempPassword} (user should change this on first login)`);

    } catch (error) {
      console.error(`Failed to create Auth user for ${userData.email}:`, error);
      throw error;
    }
  }
);

/**
 * Triggered when a user document is updated in Firestore
 * Updates Firebase Auth user accordingly (role, active status, etc.)
 */
export const onUserUpdated = onDocumentUpdated(
  {
    document: "users/{uid}",
    region: "us-central1",
  },
  async (event) => {
    const beforeData = event.data?.before.data() as UserDocument;
    const afterData = event.data?.after.data() as UserDocument;
    const uid = event.params.uid;

    if (!beforeData || !afterData) {
      console.error("Missing user data in update event");
      return;
    }

    try {
      console.log(`Updating Auth user for: ${afterData.email}`);

      const updates: any = {};

      // Check if role changed
      if (beforeData.role !== afterData.role) {
        console.log(`Role changed from ${beforeData.role} to ${afterData.role}`);
        
        // Update custom claims
        await auth.setCustomUserClaims(uid, {
          role: afterData.role,
          admin: afterData.role === 'admin',
        });
      }

      // Check if active status changed
      if (beforeData.active !== afterData.active) {
        console.log(`Active status changed from ${beforeData.active} to ${afterData.active}`);
        
        // Enable/disable Auth user
        await auth.updateUser(uid, {
          disabled: !afterData.active,
        });
      }

      // Check if name changed
      if (beforeData.name !== afterData.name) {
        console.log(`Name changed from ${beforeData.name} to ${afterData.name}`);
        updates.displayName = afterData.name;
      }

      // Check if email changed (should be rare/not allowed in UI)
      if (beforeData.email !== afterData.email) {
        console.log(`Email changed from ${beforeData.email} to ${afterData.email}`);
        updates.email = afterData.email;
      }

      // Apply any Auth updates
      if (Object.keys(updates).length > 0) {
        await auth.updateUser(uid, updates);
      }

      console.log(`Successfully updated Auth user for: ${afterData.email}`);

    } catch (error) {
      console.error(`Failed to update Auth user for ${afterData.email}:`, error);
      throw error;
    }
  }
);

/**
 * Triggered when a user document is deleted from Firestore
 * Deletes the corresponding Firebase Auth user
 */
export const onUserDeleted = onDocumentDeleted(
  {
    document: "users/{uid}",
    region: "us-central1",
  },
  async (event) => {
    const userData = event.data?.data() as UserDocument;
    const uid = event.params.uid;

    if (!userData) {
      console.error("No user data found in deleted document");
      return;
    }

    try {
      console.log(`Deleting Auth user for: ${userData.email}`);

      // Delete Auth user
      await auth.deleteUser(uid);

      console.log(`Successfully deleted Auth user for: ${userData.email}`);

    } catch (error) {
      console.error(`Failed to delete Auth user for ${userData.email}:`, error);
      throw error;
    }
  }
);

/**
 * Helper function to generate a secure temporary password
 */
function generateTempPassword(): string {
  const chars = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
  let password = '';
  
  // Ensure at least one of each required type
  password += 'ABCDEFGHJKMNPQRSTUVWXYZ'[Math.floor(Math.random() * 23)]; // uppercase
  password += 'abcdefghijkmnpqrstuvwxyz'[Math.floor(Math.random() * 23)]; // lowercase  
  password += '23456789'[Math.floor(Math.random() * 8)]; // number
  
  // Fill the rest randomly
  for (let i = 3; i < 12; i++) {
    password += chars[Math.floor(Math.random() * chars.length)];
  }
  
  // Shuffle the password
  return password.split('').sort(() => Math.random() - 0.5).join('');
}

// ============================================================================
// ANALYTICS AGGREGATION FUNCTIONS (Optional - for better performance)
// ============================================================================

interface EnquiryDocument {
  id: string;
  customerName: string;
  eventType: string;
  eventStatus: string;
  priority: string;
  source: string;
  totalCost?: number;
  createdAt: FirebaseFirestore.Timestamp;
  [key: string]: any;
}

interface DailyAnalytics {
  date: string; // YYYY-MM-DD format
  totalEnquiries: number;
  statusBreakdown: Record<string, number>;
  eventTypeBreakdown: Record<string, number>;
  sourceBreakdown: Record<string, number>;
  priorityBreakdown: Record<string, number>;
  totalRevenue: number;
  createdAt: FirebaseFirestore.Timestamp;
}

interface RollupAnalytics {
  range: string; // e.g., "7d", "30d", "90d"
  startDate: string;
  endDate: string;
  totalEnquiries: number;
  statusBreakdown: Record<string, number>;
  eventTypeBreakdown: Record<string, number>;
  sourceBreakdown: Record<string, number>;
  priorityBreakdown: Record<string, number>;
  totalRevenue: number;
  createdAt: FirebaseFirestore.Timestamp;
}

/**
 * Scheduled function that runs every hour to compute analytics aggregations
 * This improves client-side performance by pre-computing common queries
 */
export const computeAnalyticsAggregations = onSchedule(
  {
    schedule: "0 * * * *", // Every hour at minute 0
    timeZone: "UTC",
    region: "us-central1",
  },
  async (event) => {
    console.log("Starting analytics aggregation computation...");
    
    try {
      const now = new Date();
      const last90Days = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
      
      // Compute daily analytics for the last 90 days
      await computeDailyAnalytics(last90Days, now);
      
      // Compute rollup analytics for common ranges
      await computeRollupAnalytics(now);
      
      console.log("Analytics aggregation computation completed successfully");
    } catch (error) {
      console.error("Failed to compute analytics aggregations:", error);
      throw error;
    }
  }
);

/**
 * HTTPS function for manual backfill of analytics data
 * Usage: POST to function URL with { "startDate": "YYYY-MM-DD", "endDate": "YYYY-MM-DD" }
 */
export const backfillAnalytics = onRequest(
  {
    region: "us-central1",
  },
  async (req, res) => {
    // Only allow POST requests
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const { startDate, endDate } = req.body;
      
      if (!startDate || !endDate) {
        res.status(400).json({ error: 'startDate and endDate are required' });
        return;
      }
      
      const start = new Date(startDate);
      const end = new Date(endDate);
      
      if (isNaN(start.getTime()) || isNaN(end.getTime())) {
        res.status(400).json({ error: 'Invalid date format. Use YYYY-MM-DD' });
        return;
      }
      
      console.log(`Starting manual backfill from ${startDate} to ${endDate}`);
      
      // Compute daily analytics for the specified range
      await computeDailyAnalytics(start, end);
      
      // Compute rollup analytics
      await computeRollupAnalytics(end);
      
      res.json({ 
        success: true, 
        message: `Analytics backfilled from ${startDate} to ${endDate}` 
      });
      
    } catch (error) {
      console.error("Analytics backfill failed:", error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
);

/**
 * Compute daily analytics for a date range
 */
async function computeDailyAnalytics(startDate: Date, endDate: Date) {
  console.log(`Computing daily analytics from ${startDate.toISOString()} to ${endDate.toISOString()}`);
  
  // Get all enquiries in the date range
  const enquiriesSnapshot = await firestore
    .collection('enquiries')
    .where('createdAt', '>=', FirebaseFirestore.Timestamp.fromDate(startDate))
    .where('createdAt', '<=', FirebaseFirestore.Timestamp.fromDate(endDate))
    .get();
  
  // Group enquiries by date
  const enquiriesByDate: Record<string, EnquiryDocument[]> = {};
  
  enquiriesSnapshot.docs.forEach(doc => {
    const data = doc.data() as EnquiryDocument;
    const date = data.createdAt.toDate();
    const dateKey = formatDateKey(date);
    
    if (!enquiriesByDate[dateKey]) {
      enquiriesByDate[dateKey] = [];
    }
    
    enquiriesByDate[dateKey].push({ ...data, id: doc.id });
  });
  
  // Compute analytics for each date
  const batch = firestore.batch();
  let operationCount = 0;
  
  for (const [dateKey, enquiries] of Object.entries(enquiriesByDate)) {
    const analytics = computeAnalyticsForEnquiries(enquiries);
    const dailyAnalytics: DailyAnalytics = {
      date: dateKey,
      ...analytics,
      createdAt: FirebaseFirestore.Timestamp.now(),
    };
    
    const docRef = firestore.collection('analytics').doc('daily').collection('data').doc(dateKey);
    batch.set(docRef, dailyAnalytics, { merge: true });
    operationCount++;
    
    // Firestore batch has a limit of 500 operations
    if (operationCount >= 400) {
      await batch.commit();
      operationCount = 0;
    }
  }
  
  if (operationCount > 0) {
    await batch.commit();
  }
  
  console.log(`Computed daily analytics for ${Object.keys(enquiriesByDate).length} days`);
}

/**
 * Compute rollup analytics for common date ranges
 */
async function computeRollupAnalytics(endDate: Date) {
  console.log("Computing rollup analytics...");
  
  const ranges = [
    { key: '7d', days: 7 },
    { key: '30d', days: 30 },
    { key: '90d', days: 90 },
  ];
  
  for (const range of ranges) {
    const startDate = new Date(endDate.getTime() - range.days * 24 * 60 * 60 * 1000);
    
    console.log(`Computing ${range.key} rollup from ${startDate.toISOString()} to ${endDate.toISOString()}`);
    
    // Get all enquiries in the range
    const enquiriesSnapshot = await firestore
      .collection('enquiries')
      .where('createdAt', '>=', FirebaseFirestore.Timestamp.fromDate(startDate))
      .where('createdAt', '<=', FirebaseFirestore.Timestamp.fromDate(endDate))
      .get();
    
    const enquiries: EnquiryDocument[] = enquiriesSnapshot.docs.map(doc => ({
      ...doc.data() as EnquiryDocument,
      id: doc.id,
    }));
    
    const analytics = computeAnalyticsForEnquiries(enquiries);
    const rollupAnalytics: RollupAnalytics = {
      range: range.key,
      startDate: formatDateKey(startDate),
      endDate: formatDateKey(endDate),
      ...analytics,
      createdAt: FirebaseFirestore.Timestamp.now(),
    };
    
    await firestore
      .collection('analytics')
      .doc('rollups')
      .collection('data')
      .doc(range.key)
      .set(rollupAnalytics, { merge: true });
  }
  
  console.log(`Computed rollup analytics for ${ranges.length} ranges`);
}

/**
 * Compute analytics metrics for a set of enquiries
 */
function computeAnalyticsForEnquiries(enquiries: EnquiryDocument[]) {
  const statusBreakdown: Record<string, number> = {};
  const eventTypeBreakdown: Record<string, number> = {};
  const sourceBreakdown: Record<string, number> = {};
  const priorityBreakdown: Record<string, number> = {};
  let totalRevenue = 0;
  
  enquiries.forEach(enquiry => {
    // Status breakdown
    const status = enquiry.eventStatus || 'unknown';
    statusBreakdown[status] = (statusBreakdown[status] || 0) + 1;
    
    // Event type breakdown
    const eventType = enquiry.eventType || 'unknown';
    eventTypeBreakdown[eventType] = (eventTypeBreakdown[eventType] || 0) + 1;
    
    // Source breakdown
    const source = enquiry.source || 'unknown';
    sourceBreakdown[source] = (sourceBreakdown[source] || 0) + 1;
    
    // Priority breakdown
    const priority = enquiry.priority || 'medium';
    priorityBreakdown[priority] = (priorityBreakdown[priority] || 0) + 1;
    
    // Revenue
    if (enquiry.totalCost && typeof enquiry.totalCost === 'number') {
      totalRevenue += enquiry.totalCost;
    }
  });
  
  return {
    totalEnquiries: enquiries.length,
    statusBreakdown,
    eventTypeBreakdown,
    sourceBreakdown,
    priorityBreakdown,
    totalRevenue,
  };
}

/**
 * Format date as YYYY-MM-DD
 */
function formatDateKey(date: Date): string {
  return date.toISOString().split('T')[0];
}

