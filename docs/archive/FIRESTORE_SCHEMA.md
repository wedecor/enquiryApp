# Firestore Schema Documentation

This document describes the Firestore database schema for the We Decor Enquiries application.

## Collections Overview

The application uses the following Firestore collections:

1. **users/** - User management and authentication
2. **enquiries/** - Customer enquiries and event requests
3. **dropdowns/event_types/** - Event type options
4. **dropdowns/statuses/** - Enquiry status options
5. **dropdowns/payment_statuses/** - Payment status options

## Collection Details

### 1. users/ Collection

**Purpose**: Store user information and roles for authentication and authorization.

**Document ID**: Firebase Auth UID

**Document Structure**:
```json
{
  "name": "string",
  "email": "string",
  "phone": "string",
  "role": "string (admin|staff)",
  "fcmToken": "string (optional, for push notifications)",
  "lastTokenUpdate": "timestamp (optional)",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "isActive": "boolean",
  "profileImageUrl": "string (optional)",
  "metadata": "object (optional)"
}
```

**Fields**:
- `name`: User's full name
- `email`: User's email address
- `phone`: User's phone number
- `role`: User's role in the system (admin or staff)
- `fcmToken`: FCM token for push notifications (optional)
- `lastTokenUpdate`: When the FCM token was last updated (optional)
- `createdAt`: When the user was created
- `updatedAt`: When the user was last updated
- `isActive`: Whether the user account is active
- `profileImageUrl`: Optional profile image URL
- `metadata`: Additional user metadata

### 2. enquiries/ Collection

**Purpose**: Store customer enquiries and event requests.

**Document ID**: Auto-generated

**Document Structure**:
```json
{
  "id": "string",
  "customerName": "string",
  "customerEmail": "string",
  "customerPhone": "string",
  "eventType": "string (references event_types)",
  "eventDate": "timestamp",
  "eventLocation": "string",
  "guestCount": "number",
  "budgetRange": "string",
  "description": "string",
  "status": "string (references statuses)",
  "paymentStatus": "string (references payment_statuses)",
  "totalCost": "number (optional, admin only)",
  "advancePaid": "number (optional, admin only)",
  "assignedTo": "string (optional, references users, admin only)",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "createdBy": "string (references users)",
  "staffNotes": "string (optional)",
  "priority": "string (high|medium|low)",
  "source": "string"
}
```

**Fields**:
- `id`: Unique enquiry ID
- `customerName`: Customer's full name
- `customerEmail`: Customer's email address
- `customerPhone`: Customer's phone number
- `eventType`: Event type (references dropdowns/event_types)
- `eventDate`: Event date
- `eventLocation`: Event location
- `guestCount`: Number of guests
- `budgetRange`: Budget range
- `description`: Detailed description of requirements
- `status`: Current status (references dropdowns/statuses)
- `paymentStatus`: Payment status (references dropdowns/payment_statuses)
- `totalCost`: Total cost of the event (optional, admin only)
- `advancePaid`: Advance payment amount (optional, admin only)
- `assignedTo`: Assigned staff member ID (optional, admin only)
- `createdAt`: When the enquiry was created
- `updatedAt`: When the enquiry was last updated
- `createdBy`: Created by user ID
- `staffNotes`: Additional notes from staff (optional)
- `priority`: Priority level (high, medium, low)
- `source`: Source of enquiry (website, phone, referral, etc.)

### 3. enquiries/{enquiryId}/history/ Collection

**Purpose**: Store audit trail and change history for each enquiry.

**Document ID**: Auto-generated

**Document Structure**:
```json
{
  "id": "string",
  "field_changed": "string",
  "old_value": "any",
  "new_value": "any",
  "user_id": "string (references users)",
  "user_email": "string",
  "timestamp": "timestamp"
}
```

**Fields**:
- `id`: Unique history record identifier
- `field_changed`: Name of the field that was changed
- `old_value`: Previous value of the field
- `new_value`: New value of the field
- `user_id`: ID of the user who made the change
- `user_email`: Email of the user who made the change
- `timestamp`: When the change was made

### 4. dropdowns/event_types/ Collection

**Purpose**: Store event type options for dropdown menus.

**Document ID**: Auto-generated

**Document Structure**:
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "isActive": "boolean",
  "sortOrder": "number",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Default Values**:
- Wedding
- Birthday Party
- Corporate Event
- Anniversary
- Other

### 5. dropdowns/statuses/ Collection

**Purpose**: Store enquiry status options for dropdown menus.

**Document ID**: Auto-generated

**Document Structure**:
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "color": "string (hex color)",
  "isActive": "boolean",
  "sortOrder": "number",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Default Values**:
- New (Red)
- In Progress (Teal)
- Quote Sent (Blue)
- Confirmed (Green)
- Completed (Yellow)
- Cancelled (Purple)

### 6. dropdowns/payment_statuses/ Collection

**Purpose**: Store payment status options for dropdown menus.

**Document ID**: Auto-generated

**Document Structure**:
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "color": "string (hex color)",
  "isActive": "boolean",
  "sortOrder": "number",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Default Values**:
- Pending (Red)
- Partial (Orange)
- Paid (Green)
- Overdue (Red)

### 7. users/{userId}/notifications/ Collection

**Purpose**: Store user-specific notifications.

**Document ID**: Auto-generated

**Document Structure**:
```json
{
  "id": "string",
  "title": "string",
  "body": "string",
  "data": "object",
  "read": "boolean",
  "createdAt": "timestamp",
  "readAt": "timestamp (optional)"
}
```

**Fields**:
- `id`: Unique notification identifier
- `title`: Notification title
- `body`: Notification body text
- `data`: Additional notification data (enquiryId, type, etc.)
- `read`: Whether the notification has been read
- `createdAt`: When the notification was created
- `readAt`: When the notification was marked as read (optional)

### 7. notifications/{topic}/messages/ Collection

**Purpose**: Store topic-based notifications.

**Document ID**: Auto-generated

**Document Structure**:
```json
{
  "id": "string",
  "title": "string",
  "body": "string",
  "data": "object",
  "topic": "string",
  "createdAt": "timestamp"
}
```

**Fields**:
- `id`: Unique notification identifier
- `title`: Notification title
- `body`: Notification body text
- `data`: Additional notification data
- `topic`: Topic name (admin, staff, user_uid, etc.)
- `createdAt`: When the notification was created

## Security Rules

The following Firestore security rules should be implemented:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read their own document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Only authenticated users can access enquiries
    match /enquiries/{enquiryId} {
      allow read, write: if request.auth != null;
    }
    
    // Only admin users can modify dropdowns
    match /dropdowns/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## Usage Examples

### Creating a User
```dart
final firestoreService = ref.read(firestoreServiceProvider);
await firestoreService.createUser(
  uid: user.uid,
  name: 'John Doe',
  email: 'john@example.com',
  phone: '+1234567890',
  role: 'staff',
);
```

### Creating an Enquiry
```dart
final enquiryId = await firestoreService.createEnquiry(
  customerName: 'Jane Smith',
  customerEmail: 'jane@example.com',
  customerPhone: '+1234567890',
  eventType: 'Wedding',
  eventDate: DateTime.now().add(Duration(days: 30)),
  eventLocation: 'Grand Hotel',
  guestCount: 150,
  budgetRange: '5000-10000',
  description: 'Beautiful wedding decoration needed',
  createdBy: currentUser.uid,
  priority: 'high',
  source: 'website',
);
```

### Getting Enquiries
```dart
// Get all enquiries
final enquiries = ref.watch(enquiriesProvider);

// Get enquiries by status
final newEnquiries = ref.watch(enquiriesByStatusProvider('New'));
```

## Initialization

The dropdown collections are automatically initialized with default values when the app starts. You can check if they're initialized using:

```dart
final isInitialized = ref.watch(dropdownsInitializedProvider);
```

## Best Practices

1. **Always use the FirestoreService** for database operations instead of direct Firestore calls
2. **Use Riverpod providers** for reactive data streams
3. **Validate data** before writing to Firestore
4. **Handle errors gracefully** in the UI
5. **Use proper indexing** for queries with multiple where clauses
6. **Implement security rules** to protect sensitive data
7. **Use server timestamps** for created/updated fields
8. **Keep documents small** and denormalize when necessary for performance

## Indexes Required

The following composite indexes should be created in Firestore:

1. `enquiries` collection:
   - `status` (Ascending) + `createdAt` (Descending)
   - `customerName` (Ascending) + `createdAt` (Descending)

2. `dropdowns/event_types` collection:
   - `isActive` (Ascending) + `sortOrder` (Ascending)

3. `dropdowns/statuses` collection:
   - `isActive` (Ascending) + `sortOrder` (Ascending)

4. `dropdowns/payment_statuses` collection:
   - `isActive` (Ascending) + `sortOrder` (Ascending)

5. `users/{userId}/notifications` collection:
   - `read` (Ascending) + `createdAt` (Descending)

6. `notifications/{topic}/messages` collection:
   - `topic` (Ascending) + `createdAt` (Descending)

7. `enquiries/{enquiryId}/history` collection:
   - `timestamp` (Descending)
   - `field_changed` (Ascending) + `timestamp` (Descending)
   - `user_id` (Ascending) + `timestamp` (Descending)