# How to Debug Notifications

## Step 1: Check if Admin has FCM Token in Chrome

1. Open Chrome DevTools (F12)
2. Go to Console tab
3. Make sure you're logged in as admin
4. Run this command:

```javascript
// Check if Firebase Messaging is available
if (typeof firebase !== 'undefined' && firebase.messaging) {
    firebase.messaging().getToken().then(token => {
        console.log('✅:', token);
        if (token) {
            console.log('✅ Admin HAS FCM token');
        } else {
            console.error('❌ Admin has NO FCM token');
        }
    }).catch(err => {
        console.error('Error getting token:', err);
    });
} else {
    console.error('Firebase Messaging not available');
}
```

## Step 2: Check Firestore Collections

### A. Check if notifications are being created:
1. Go to: https://console.firebase.google.com/project/wedecorenquries/firestore
2. Navigate to: `users/{YOUR_ADMIN_USER_ID}/notifications`
3. Look for recent notification documents
4. If you see notifications → They're being created ✅
5. If empty → Notifications aren't being stored ❌

### B. Check if admin has FCM tokens:
1. Go to: https://console.firebase.google.com/project/wedecorenquries/firestore
2. Navigate to: `users/{YOUR_ADMIN_USER_ID}/private/notifications/tokens`
3. Look for token documents
4. If you see tokens → Admin has tokens ✅
5. If empty → Admin needs to grant notification permission ❌

## Step 3: Check Cloud Function Logs

1. Go to: https://console.cloud.google.com/functions/list?project=wedecorenquries
2. Click on `sendNotificationToUser` function
3. Go to "Logs" tab
4. Look for recent executions when staff changes status
5. Check for errors or "No FCM tokens found" messages

## Step 4: Test Notification Flow

1. Have staff member change an enquiry status on mobile
2. Immediately check Firestore `users/{adminId}/notifications` - should see new notification
3. Check Cloud Function logs - should see execution
4. Check if notification appears in Chrome

## Most Likely Issues:

1. **Admin doesn't have FCM token** → Need to grant notification permission in Chrome
2. **Notifications not being created** → Check mobile app logs or Firestore rules
3. **Cloud Function not triggering** → Check function deployment
4. **Cloud Function failing** → Check function logs for errors
