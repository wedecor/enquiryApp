# 📊 Complete Data Model Structure for Firebase Console

## 🗂️ Collection Structure Overview

```
📁 wedecorenquries (Firestore Database)
├── 👥 users/
│   └── {userId} (Document)
├── 📋 enquiries/
│   ├── {enquiryId} (Document)
│   └── {enquiryId}/history/ (Subcollection)
└── 📝 dropdowns/
    ├── statuses/items/ (Subcollection)
    ├── event_types/items/ (Subcollection)
    ├── priorities/items/ (Subcollection)
    └── payment_statuses/items/ (Subcollection)
```

---

## 🔥 **CRITICAL: Create These Collections First (Fixes Loading Symbols)**

### 1. `dropdowns/statuses/items/` Collection

**Collection Path**: `dropdowns` → `statuses` → `items`

**Documents to Create:**

**Document ID: `new`**
```json
{
  "value": "new",
  "label": "New",
  "order": 1,
  "active": true,
  "color": "#FF9800"
}
```

**Document ID: `in_progress`**
```json
{
  "value": "in_progress",
  "label": "In Progress", 
  "order": 2,
  "active": true,
  "color": "#2196F3"
}
```

**Document ID: `quote_sent`**
```json
{
  "value": "quote_sent",
  "label": "Quote Sent",
  "order": 3,
  "active": true,
  "color": "#009688"
}
```

**Document ID: `approved`**
```json
{
  "value": "approved",
  "label": "Approved",
  "order": 4,
  "active": true,
  "color": "#3F51B5"
}
```

**Document ID: `scheduled`**
```json
{
  "value": "scheduled",
  "label": "Scheduled",
  "order": 5,
  "active": true,
  "color": "#9C27B0"
}
```

**Document ID: `completed`**
```json
{
  "value": "completed",
  "label": "Completed",
  "order": 6,
  "active": true,
  "color": "#4CAF50"
}
```

**Document ID: `cancelled`**
```json
{
  "value": "cancelled",
  "label": "Cancelled",
  "order": 7,
  "active": true,
  "color": "#F44336"
}
```

**Document ID: `closed_lost`**
```json
{
  "value": "closed_lost",
  "label": "Closed Lost",
  "order": 8,
  "active": true,
  "color": "#607D8B"
}
```

### 2. `dropdowns/event_types/items/` Collection

**Collection Path**: `dropdowns` → `event_types` → `items`

**Document ID: `wedding`**
```json
{
  "value": "wedding",
  "label": "Wedding",
  "order": 1,
  "active": true,
  "category": "celebration"
}
```

**Document ID: `birthday`**
```json
{
  "value": "birthday",
  "label": "Birthday Party",
  "order": 2,
  "active": true,
  "category": "celebration"
}
```

**Document ID: `corporate_event`**
```json
{
  "value": "corporate_event",
  "label": "Corporate Event",
  "order": 3,
  "active": true,
  "category": "business"
}
```

**Document ID: `anniversary`**
```json
{
  "value": "anniversary",
  "label": "Anniversary",
  "order": 4,
  "active": true,
  "category": "celebration"
}
```

**Document ID: `other`**
```json
{
  "value": "other",
  "label": "Other",
  "order": 99,
  "active": true,
  "category": "general"
}
```

### 3. `dropdowns/priorities/items/` Collection

**Collection Path**: `dropdowns` → `priorities` → `items`

**Document ID: `low`**
```json
{
  "value": "low",
  "label": "Low",
  "order": 1,
  "active": true,
  "color": "#4CAF50"
}
```

**Document ID: `medium`**
```json
{
  "value": "medium",
  "label": "Medium",
  "order": 2,
  "active": true,
  "color": "#FF9800"
}
```

**Document ID: `high`**
```json
{
  "value": "high",
  "label": "High",
  "order": 3,
  "active": true,
  "color": "#F44336"
}
```

**Document ID: `urgent`**
```json
{
  "value": "urgent",
  "label": "Urgent",
  "order": 4,
  "active": true,
  "color": "#9C27B0"
}
```

### 4. `dropdowns/payment_statuses/items/` Collection

**Collection Path**: `dropdowns` → `payment_statuses` → `items`

**Document ID: `pending`**
```json
{
  "value": "pending",
  "label": "Pending",
  "order": 1,
  "active": true,
  "color": "#FF9800"
}
```

**Document ID: `partial`**
```json
{
  "value": "partial",
  "label": "Partial Payment",
  "order": 2,
  "active": true,
  "color": "#2196F3"
}
```

**Document ID: `paid`**
```json
{
  "value": "paid",
  "label": "Fully Paid",
  "order": 3,
  "active": true,
  "color": "#4CAF50"
}
```

**Document ID: `overdue`**
```json
{
  "value": "overdue",
  "label": "Overdue",
  "order": 4,
  "active": true,
  "color": "#F44336"
}
```

---

## 📋 **OPTIONAL: Sample Data for Testing**

### `users/` Collection

**Document ID: `[your-auth-uid]`**
```json
{
  "uid": "[your-firebase-auth-uid]",
  "name": "Admin User",
  "email": "admin@wedecor.com",
  "phone": "+1234567890",
  "role": "admin",
  "fcmToken": null,
  "createdAt": "[current-timestamp]",
  "updatedAt": "[current-timestamp]"
}
```

### `enquiries/` Collection

**Document ID: `sample_enquiry_1`**
```json
{
  "customerName": "John Doe",
  "customerPhone": "8880888832",
  "customerEmail": "john@example.com",
  "eventType": "wedding",
  "eventDate": "[future-timestamp]",
  "eventLocation": "Grand Hotel",
  "guestCount": 150,
  "budgetRange": "50000-100000",
  "description": "Beautiful wedding decoration needed",
  "eventStatus": "new",
  "paymentStatus": "pending",
  "priority": "medium",
  "source": "app",
  "assignedTo": null,
  "createdBy": "[admin-user-id]",
  "createdAt": "[current-timestamp]",
  "updatedAt": "[current-timestamp]",
  "totalCost": null,
  "advancePaid": null
}
```

---

## 🎯 **Quick Setup Steps:**

### Step 1: Open Firebase Console
Go to: https://console.firebase.google.com/project/wedecorenquries/firestore

### Step 2: Create Collections (in this order)
1. **dropdowns** → **statuses** → **items** (8 documents)
2. **dropdowns** → **event_types** → **items** (5+ documents)  
3. **dropdowns** → **priorities** → **items** (4 documents)
4. **dropdowns** → **payment_statuses** → **items** (4 documents)

### Step 3: Test
- Refresh your Flutter app
- Loading symbols should disappear
- Dropdowns should work perfectly

---

## ⚡ **Expected Results After Creation:**

✅ **No more loading symbols** - Dropdowns load instantly
✅ **Clean console output** - No more Firestore query errors  
✅ **Functional dropdowns** - All status/event type options available
✅ **Professional UX** - Smooth, responsive interface

**Priority: Create the `dropdowns` collections first - this will immediately eliminate all loading symbols!**

