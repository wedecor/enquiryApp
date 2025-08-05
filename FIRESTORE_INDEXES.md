# 🔥 Firestore Indexes Guide

This guide explains the Firestore indexes required for the We Decor Enquiries application and how to manage them.

## 📋 Required Indexes

### Composite Indexes for Enquiries Collection

| Index | Fields | Purpose | Query Example |
|-------|--------|---------|---------------|
| 1 | `eventStatus` + `assignedTo` | Filter by status and assigned user | `where('eventStatus', isEqualTo: 'Enquired').where('assignedTo', isEqualTo: 'user123')` |
| 2 | `eventType` + `createdAt` | Filter by event type and order by date | `where('eventType', isEqualTo: 'Wedding').orderBy('createdAt', descending: true)` |
| 3 | `assignedTo` + `createdAt` | Filter by assigned user and order by date | `where('assignedTo', isEqualTo: 'user123').orderBy('createdAt', descending: true)` |
| 4 | `eventStatus` + `createdAt` | Filter by status and order by date | `where('eventStatus', isEqualTo: 'In Progress').orderBy('createdAt', descending: true)` |
| 5 | `createdBy` + `createdAt` | Filter by creator and order by date | `where('createdBy', isEqualTo: 'user123').orderBy('createdAt', descending: true)` |
| 6 | `assignedTo` + `eventStatus` + `createdAt` | Complex filtering and ordering | `where('assignedTo', isEqualTo: 'user123').where('eventStatus', isEqualTo: 'Enquired').orderBy('createdAt', descending: true)` |

## 🚀 Setup Instructions

### Option 1: Firebase Console (Manual)

1. **Go to Firebase Console**:
   - Navigate to [Firebase Console](https://console.firebase.google.com)
   - Select your project: `wedecorenquiries`

2. **Access Firestore Indexes**:
   - Go to **Firestore Database**
   - Click on **Indexes** tab

3. **Create Composite Indexes**:
   - Click **Create Index**
   - Select **Collection ID**: `enquiries`
   - Add the required fields for each index

#### Index 1: eventStatus + assignedTo
```
Collection ID: enquiries
Fields:
  - eventStatus (Ascending)
  - assignedTo (Ascending)
```

#### Index 2: eventType + createdAt
```
Collection ID: enquiries
Fields:
  - eventType (Ascending)
  - createdAt (Descending)
```

#### Index 3: assignedTo + createdAt
```
Collection ID: enquiries
Fields:
  - assignedTo (Ascending)
  - createdAt (Descending)
```

#### Index 4: eventStatus + createdAt
```
Collection ID: enquiries
Fields:
  - eventStatus (Ascending)
  - createdAt (Descending)
```

#### Index 5: createdBy + createdAt
```
Collection ID: enquiries
Fields:
  - createdBy (Ascending)
  - createdAt (Descending)
```

#### Index 6: assignedTo + eventStatus + createdAt
```
Collection ID: enquiries
Fields:
  - assignedTo (Ascending)
  - eventStatus (Ascending)
  - createdAt (Descending)
```

### Option 2: Firebase CLI (Automated)

1. **Deploy Indexes**:
   ```bash
   firebase deploy --only firestore:indexes
   ```

2. **Verify Deployment**:
   ```bash
   dart run scripts/manage_indexes.dart verify
   ```

3. **Test Queries**:
   ```bash
   dart run scripts/manage_indexes.dart test-queries
   ```

## 🔍 Monitoring Index Status

### Check Index Status

1. **Firebase Console**:
   - Go to Firestore → Indexes
   - Look for status indicators:
     - ✅ **Enabled**: Index is ready
     - 🔄 **Building**: Index is being created
     - ❌ **Error**: Index creation failed

2. **Using Scripts**:
   ```bash
   # Verify index status
   dart run scripts/manage_indexes.dart verify
   
   # Test queries that require indexes
   dart run scripts/manage_indexes.dart test-queries
   ```

### Index Building Time

- **Small datasets** (< 1M documents): 1-5 minutes
- **Medium datasets** (1M-10M documents): 5-15 minutes
- **Large datasets** (> 10M documents): 15-60 minutes

## 🧪 Testing Indexes

### Test Queries

Run the test script to verify all indexes are working:

```bash
dart run scripts/manage_indexes.dart test-queries
```

This will test:
1. Filtering by `eventStatus` + `assignedTo`
2. Ordering by `createdAt` + filtering by `eventType`
3. Filtering by `assignedTo` + ordering by `createdAt`
4. Filtering by `eventStatus` + ordering by `createdAt`
5. Filtering by `createdBy` + ordering by `createdAt`

### Expected Results

If indexes are properly configured, all queries should return:
```
✅ Query X successful: Y results
```

If indexes are missing or building, you'll see:
```
❌ Query X failed: The query requires an index to support this combination of filters and orderBy clauses
```

## 🛠️ Troubleshooting

### Common Issues

1. **Index Building Failed**:
   - Check Firebase Console for error messages
   - Verify field names match exactly
   - Ensure collection exists

2. **Query Still Failing After Index Creation**:
   - Wait for index to finish building
   - Check index status in Firebase Console
   - Verify query syntax matches index fields

3. **Performance Issues**:
   - Ensure queries use indexed fields
   - Limit result sets with `.limit()`
   - Use pagination for large datasets

### Error Messages

| Error | Solution |
|-------|----------|
| `The query requires an index` | Create the missing composite index |
| `Index is building` | Wait for index to finish building |
| `Invalid field path` | Check field names in your query |
| `Too many indexes` | Remove unused indexes (Firestore limit: 200) |

## 📊 Index Performance

### Best Practices

1. **Create indexes only when needed**:
   - Firestore automatically suggests missing indexes
   - Don't create indexes for queries you don't use

2. **Optimize field order**:
   - Put equality filters first
   - Put range filters last
   - Put ordering fields last

3. **Monitor usage**:
   - Check Firebase Console for index usage statistics
   - Remove unused indexes to save costs

### Cost Considerations

- **Index storage**: ~1KB per 1000 documents
- **Index maintenance**: Included in Firestore pricing
- **Query performance**: Faster queries reduce read costs

## 🔗 Related Files

- `firestore.indexes.json` - Index configuration file
- `scripts/manage_indexes.dart` - Index management script
- `lib/core/services/firestore_service.dart` - Firestore service with queries
- `DATABASE_SETUP.md` - Database setup guide

## 📝 Notes

- Indexes are created automatically when you run queries that need them
- Index building time depends on collection size
- You can monitor index status in Firebase Console
- Remove unused indexes to optimize performance and costs
- Test queries in development before deploying to production 