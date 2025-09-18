import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/dropdown_item.dart';

/// Repository for managing dropdown items in Firestore
class DropdownsRepository {
  final FirebaseFirestore _firestore;

  DropdownsRepository(this._firestore);

  /// Get the collection reference for a dropdown group
  CollectionReference<Map<String, dynamic>> _getCollection(DropdownGroup group) {
    return _firestore
        .collection('dropdowns')
        .doc(group.collectionPath)
        .collection('items');
  }

  /// Watch dropdown items for a specific group
  Stream<List<DropdownItem>> watchGroup(DropdownGroup group) {
    return _getCollection(group)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => DropdownItem.fromFirestore(doc)).toList();
    });
  }

  /// Create a new dropdown item
  Future<void> create(DropdownGroup group, DropdownItemInput input) async {
    final collection = _getCollection(group);
    
    // Check if value already exists
    final existingDoc = await collection.doc(input.value).get();
    if (existingDoc.exists) {
      throw Exception('Dropdown item with value "${input.value}" already exists');
    }

    // Get the next order value
    final nextOrder = await _getNextOrder(group);

    // Create the item
    final item = input.toDropdownItem(nextOrder);
    await collection.doc(input.value).set({
      ...item.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update an existing dropdown item
  Future<void> update(
    DropdownGroup group,
    String value,
    Map<String, dynamic> patch,
  ) async {
    final docRef = _getCollection(group).doc(value);
    
    await docRef.update({
      ...patch,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Toggle active status of a dropdown item
  Future<void> toggleActive(DropdownGroup group, String value, bool active) async {
    await update(group, value, {'active': active});
  }

  /// Delete a dropdown item (only if no references exist)
  Future<void> delete(DropdownGroup group, String value) async {
    // Check for references in enquiries
    final hasReferences = await _hasReferencesInEnquiries(group, value);
    if (hasReferences) {
      throw Exception(
        'Cannot delete dropdown item "$value" because it is referenced by existing enquiries. '
        'Please deactivate it instead or use the "Replace in enquiries" feature.',
      );
    }

    await _getCollection(group).doc(value).delete();
  }

  /// Reorder dropdown items
  Future<void> reorder(DropdownGroup group, List<String> orderedValues) async {
    final batch = _firestore.batch();
    final collection = _getCollection(group);

    for (int i = 0; i < orderedValues.length; i++) {
      final docRef = collection.doc(orderedValues[i]);
      batch.update(docRef, {
        'order': i + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Replace a dropdown value in all enquiries
  Future<void> replaceInEnquiries(
    DropdownGroup group,
    String oldValue,
    String newValue,
  ) async {
    final enquiryField = group.enquiryFieldName;
    final enquiriesRef = _firestore.collection('enquiries');
    
    // Process in batches of 400
    const batchSize = 400;
    QueryDocumentSnapshot? lastDoc;
    
    while (true) {
      Query query = enquiriesRef
          .where(enquiryField, isEqualTo: oldValue)
          .limit(batchSize);
      
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) break;
      
      // Batch update
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          enquiryField: newValue,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      
      if (snapshot.docs.length < batchSize) break;
      lastDoc = snapshot.docs.last;
    }
  }

  /// Get the next order value for a group
  Future<int> _getNextOrder(DropdownGroup group) async {
    final snapshot = await _getCollection(group)
        .orderBy('order', descending: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return 1;
    
    final lastItem = DropdownItem.fromFirestore(snapshot.docs.first);
    return lastItem.order + 1;
  }

  /// Check if a dropdown value has references in enquiries
  Future<bool> _hasReferencesInEnquiries(DropdownGroup group, String value) async {
    final enquiryField = group.enquiryFieldName;
    final snapshot = await _firestore
        .collection('enquiries')
        .where(enquiryField, isEqualTo: value)
        .limit(1)
        .get();
    
    return snapshot.docs.isNotEmpty;
  }

  /// Get dropdown items for a specific group (non-stream)
  Future<List<DropdownItem>> getGroup(DropdownGroup group) async {
    final snapshot = await _getCollection(group).orderBy('order').get();
    return snapshot.docs.map((doc) => DropdownItem.fromFirestore(doc)).toList();
  }

  /// Search dropdown items within a group
  Future<List<DropdownItem>> searchGroup(
    DropdownGroup group,
    String searchQuery,
  ) async {
    final items = await getGroup(group);
    final query = searchQuery.toLowerCase();
    
    return items.where((item) {
      return item.value.toLowerCase().contains(query) ||
             item.label.toLowerCase().contains(query);
    }).toList();
  }
}

/// Provider for the dropdowns repository
final dropdownsRepositoryProvider = Provider<DropdownsRepository>((ref) {
  return DropdownsRepository(FirebaseFirestore.instance);
});

/// Provider for dropdown items stream
final dropdownsStreamProvider = StreamProvider.family<List<DropdownItem>, DropdownGroup>((ref, group) {
  final repository = ref.watch(dropdownsRepositoryProvider);
  return repository.watchGroup(group);
});

/// Provider for dropdown items (non-stream)
final dropdownsProvider = FutureProvider.family<List<DropdownItem>, DropdownGroup>((ref, group) {
  final repository = ref.watch(dropdownsRepositoryProvider);
  return repository.getGroup(group);
});

/// Provider for checking if a dropdown value has references
final dropdownHasReferencesProvider = FutureProvider.family<bool, (DropdownGroup, String)>((ref, params) async {
  final repository = ref.watch(dropdownsRepositoryProvider);
  final (group, value) = params;
  
  final enquiryField = group.enquiryFieldName;
  final snapshot = await FirebaseFirestore.instance
      .collection('enquiries')
      .where(enquiryField, isEqualTo: value)
      .limit(1)
      .get();
  
  return snapshot.docs.isNotEmpty;
});

