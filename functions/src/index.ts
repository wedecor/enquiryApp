import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { setGlobalOptions } from "firebase-functions/v2/options";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

// Set global options for all functions
setGlobalOptions({
  region: 'asia-south1',
  timeoutSeconds: 30,
  memory: '128MiB'
});

// Initialize Firebase Admin
initializeApp();
const firestore = getFirestore();
const messaging = getMessaging();

/**
 * Sends FCM notification when enquiry is created, assigned, or status/payment changes
 */
export const notifyOnEnquiryChange = onDocumentWritten(
  'enquiries/{id}',
  async (event) => {
    const enquiryId = event.params.id;
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    // If document was deleted, skip
    if (!after) {
      return;
    }

    // For new documents (create), treat as meaningful change
    const isCreate = !before;
    
    // Check for meaningful changes
    const changes: string[] = [];
    
    if (isCreate) {
      changes.push('Created');
    } else {
      if (before.assignedTo !== after.assignedTo) {
        changes.push('Assigned');
      }
      if (before.eventStatus !== after.eventStatus) {
        changes.push(`Status: ${after.eventStatus || 'Unknown'}`);
      }
      if (before.paymentStatus !== after.paymentStatus) {
        changes.push(`Payment: ${after.paymentStatus || 'Unknown'}`);
      }
    }

    // If no meaningful changes, skip notification
    if (changes.length === 0) {
      return;
    }

    // Must have an assigned user to notify
    if (!after.assignedTo) {
      console.log(`Enquiry ${enquiryId}: No assigned user, skipping notification`);
      return;
    }

    try {
      // Load user document to get FCM tokens
      const userDoc = await firestore.collection('users').doc(after.assignedTo).get();
      
      if (!userDoc.exists) {
        console.log(`User ${after.assignedTo} not found, skipping notification`);
        return;
      }

      const userData = userDoc.data()!;
      const tokens: string[] = [];

      // Collect FCM tokens (dedupe)
      if (userData.fcmToken && typeof userData.fcmToken === 'string') {
        tokens.push(userData.fcmToken);
      }
      
      if (userData.webTokens && Array.isArray(userData.webTokens)) {
        userData.webTokens.forEach((token: any) => {
          if (typeof token === 'string' && token && !tokens.includes(token)) {
            tokens.push(token);
          }
        });
      }

      if (tokens.length === 0) {
        console.log(`User ${after.assignedTo}: No FCM tokens, skipping notification`);
        return;
      }

      // Build notification content
      const title = changes.join(' • ');
      const body = `Customer: ${after.customerName || 'Open the app for details'}`;
      
      const notificationData = {
        type: 'enquiry_update',
        enquiryId: enquiryId,
        eventStatus: after.eventStatus || '',
        paymentStatus: after.paymentStatus || ''
      };

      // Send FCM notification
      const response = await messaging.sendEachForMulticast({
        tokens: tokens,
        notification: {
          title: title,
          body: body
        },
        data: notificationData,
        webpush: {
          notification: {
            icon: '/icons/Icon-192.png',
            badge: '/icons/Icon-192.png',
            tag: enquiryId,
            requireInteraction: false
          }
        }
      });

      // Optional: Write notification document
      const notificationDoc = {
        type: 'enquiry_update',
        enquiryId: enquiryId,
        title: title,
        body: body,
        createdAt: Timestamp.now(),
        read: false,
        archived: false
      };

      await firestore
        .collection('notifications')
        .doc(after.assignedTo)
        .collection('items')
        .add(notificationDoc);

      // Log summary
      console.log(`Enquiry ${enquiryId}: Sent ${response.successCount}/${tokens.length} notifications to user ${after.assignedTo}. Changes: ${changes.join(', ')}`);

      // Log any failures
      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.error(`Token ${idx} failed:`, resp.error);
          }
        });
      }

    } catch (error) {
      console.error(`Failed to send notification for enquiry ${enquiryId}:`, error);
    }
  }
);