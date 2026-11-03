import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/dropdown_defaults.dart';
import '../../../../core/services/firestore_service.dart';
import '../domain/dropdown_item.dart';

/// Repository for managing dropdown items in Firestore
class DropdownsRepository {
  final FirebaseFirestore _firestore;

  DropdownsRepository(this._firestore);

  /// Get the collection reference for a dropdown group
  CollectionReference<Map<String, dynamic>> _getCollection(DropdownGroup group) {
    return _firestore.collection('dropdowns').doc(group.collectionPath).collection('items');
  }

  /// Watch dropdown items for a specific group
  Stream<List<DropdownItem>> watchGroup(DropdownGroup group) {
    // Sorted here, not with orderBy('order'): Firestore's orderBy silently drops
    // items that have no `order` field.
    return _getCollection(group).snapshots().map((snapshot) {
      final items = snapshot.docs.map(DropdownItem.fromFirestore).toList()
        ..sort((a, b) {
          final byOrder = a.order.compareTo(b.order);
          return byOrder != 0 ? byOrder : a.label.toLowerCase().compareTo(b.label.toLowerCase());
        });
      return items;
    });
  }

  /// Repairs a group so the manager and the forms agree. Admin only; safe to repeat.
  ///
  /// 1. Items saved by the old form quick-add (random document id, no `updatedAt`)
  ///    are moved to `items/{value}` with the missing fields filled in.
  /// 2. The first time, the built-in options (Wedding, Birthday, …) are saved too.
  ///    The forms only fall back to the built-ins while a group is empty, so a
  ///    single added item used to hide all of them. Marked by `defaultsSeeded` on
  ///    `dropdowns/{group}`, so built-ins an admin later deletes don't come back.
  Future<void> repairGroup(DropdownGroup group) async {
    final collection = _getCollection(group);
    final snapshot = await collection.get();
    final batch = _firestore.batch();
    var writes = 0;
    final docIds = snapshot.docs.map((d) => d.id).toSet();
    final values = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final value = (data['value'] as String?)?.trim();
      final fill = <String, dynamic>{
        ...DropdownRepair.missingFields(data, doc.id),
        if (data['createdAt'] is! Timestamp) 'createdAt': FieldValue.serverTimestamp(),
        if (data['updatedAt'] is! Timestamp) 'updatedAt': FieldValue.serverTimestamp(),
      };
      if (DropdownRepair.needsRelocate(doc.id, value)) {
        if (!docIds.contains(value)) {
          batch.set(collection.doc(value!), {...data, ...fill, 'value': value});
          writes++;
        }
        batch.delete(doc.reference);
        writes++;
        values.add(value!);
      } else {
        values.add(doc.id);
        if (fill.isNotEmpty || value == null) {
          batch.set(doc.reference, {...fill, 'value': doc.id}, SetOptions(merge: true));
          writes++;
        }
      }
    }

    if (group != DropdownGroup.statuses) {
      final parent = _firestore.collection('dropdowns').doc(group.collectionPath);
      final parentSnap = await parent.get();
      if (parentSnap.data()?['defaultsSeeded'] != true) {
        final defaults = DropdownDefaults.forCollection(group.collectionPath);
        for (var i = 0; i < defaults.length; i++) {
          final value = defaults[i]['value']!;
          if (values.contains(value)) continue;
          batch.set(collection.doc(value), {
            'value': value,
            'label': defaults[i]['label'],
            'active': true,
            'order': i + 1,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          writes++;
        }
        batch.set(parent, {
          'defaultsSeeded': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        writes++;
      }
    }

    if (writes > 0) await batch.commit();
  }

  /// Quick-add from a form field: repairs the group first (so the built-ins stay),
  /// then saves like the manager does. Returns the stored value.
  Future<String> quickAdd(DropdownGroup group, String label) async {
    await repairGroup(group);
    final trimmed = label.trim();
    final value = DropdownItem.valueFromLabel(trimmed);
    if (value.isEmpty) {
      throw ArgumentError('Label must contain at least one letter or digit');
    }
    final collection = _getCollection(group);
    final existing = await collection.doc(value).get();
    if (existing.exists) {
      // Re-adding a deactivated type turns it back on instead of failing.
      if (existing.data()?['active'] != true) await update(group, value, {'active': true});
      return value;
    }
    await collection.doc(value).set({
      'value': value,
      'label': trimmed,
      'active': true,
      'order': await _getNextOrder(group),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return value;
  }

  /// Resolve `items/{value}` or a stray quick-add doc whose `value` field matches.
  Future<DocumentReference<Map<String, dynamic>>?> _docForValue(
    DropdownGroup group,
    String value,
  ) async {
    final collection = _getCollection(group);
    final byId = await collection.doc(value).get();
    if (byId.exists) return byId.reference;
    final byField = await collection.where('value', isEqualTo: value).limit(1).get();
    if (byField.docs.isEmpty) return null;
    return byField.docs.first.reference;
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
  Future<void> update(DropdownGroup group, String value, Map<String, dynamic> patch) async {
    final docRef = await _docForValue(group, value);
    if (docRef == null) {
      throw Exception('Dropdown item "$value" not found');
    }
    await docRef.update({...patch, 'updatedAt': FieldValue.serverTimestamp()});
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

    final docRef = await _docForValue(group, value);
    if (docRef == null) {
      throw Exception('Dropdown item "$value" not found');
    }
    await docRef.delete();
  }

  /// Reorder dropdown items
  Future<void> reorder(DropdownGroup group, List<String> orderedValues) async {
    final batch = _firestore.batch();

    for (int i = 0; i < orderedValues.length; i++) {
      final docRef = await _docForValue(group, orderedValues[i]);
      if (docRef == null) continue;
      batch.update(docRef, {'order': i + 1, 'updatedAt': FieldValue.serverTimestamp()});
    }

    await batch.commit();
  }

  /// Replace a dropdown value in all enquiries
  Future<void> replaceInEnquiries(DropdownGroup group, String oldValue, String newValue) async {
    final enquiriesRef = _firestore.collection('enquiries');
    final newItemDoc = await _getCollection(group).doc(newValue).get();
    final newLabel = newItemDoc.exists ? (newItemDoc.data()?['label'] as String?) : null;
    final labelField = group.enquiryLabelFieldName;

    for (final enquiryField in group.enquiryFieldNames) {
      const batchSize = 400;
      QueryDocumentSnapshot? lastDoc;

      while (true) {
        Query query = enquiriesRef.where(enquiryField, isEqualTo: oldValue).limit(batchSize);

        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }

        final snapshot = await query.get();

        if (snapshot.docs.isEmpty) break;

        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          final updates = <String, dynamic>{
            enquiryField: newValue,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          // Keep sibling type fields in sync when replacing event types.
          if (group == DropdownGroup.eventTypes) {
            updates['eventType'] = newValue;
            updates['eventTypeValue'] = newValue;
          }
          if (newLabel != null && labelField != null) {
            updates[labelField] = newLabel;
          }
          batch.update(doc.reference, updates);
        }

        await batch.commit();

        if (snapshot.docs.length < batchSize) break;
        lastDoc = snapshot.docs.last;
      }
    }

    if (group == DropdownGroup.eventTypes) {
      await _replaceInFunctionArrays(oldValue, newValue, newLabel);
    }
  }

  /// Multi-function bookings store secondary types only on `functions[]`.
  Future<void> _replaceInFunctionArrays(String oldValue, String newValue, String? newLabel) async {
    const batchSize = 100;
    QueryDocumentSnapshot? lastDoc;
    while (true) {
      Query query = _firestore
          .collection('enquiries')
          .where('functionCount', isGreaterThanOrEqualTo: 2)
          .limit(batchSize);
      if (lastDoc != null) query = query.startAfterDocument(lastDoc);
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      var writes = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? const {};
        final functions = data['functions'];
        if (functions is! List) continue;
        var changed = false;
        final next = <Map<String, dynamic>>[];
        for (final raw in functions) {
          if (raw is! Map) continue;
          final fn = Map<String, dynamic>.from(raw);
          if (fn['eventType'] == oldValue || fn['eventTypeValue'] == oldValue) {
            fn['eventType'] = newValue;
            fn['eventTypeValue'] = newValue;
            if (newLabel != null) fn['eventTypeLabel'] = newLabel;
            changed = true;
          }
          next.add(fn);
        }
        if (!changed) continue;
        batch.update(doc.reference, {'functions': next, 'updatedAt': FieldValue.serverTimestamp()});
        writes++;
      }
      if (writes > 0) await batch.commit();
      if (snapshot.docs.length < batchSize) break;
      lastDoc = snapshot.docs.last;
    }
  }

  /// Get the next order value for a group
  Future<int> _getNextOrder(DropdownGroup group) async {
    final snapshot = await _getCollection(group).get();
    var maxOrder = 0;
    for (final doc in snapshot.docs) {
      final order = (doc.data()['order'] as num?)?.toInt() ?? 0;
      if (order > maxOrder) maxOrder = order;
    }
    return maxOrder + 1;
  }

  /// Check if a dropdown value has references in enquiries
  Future<bool> _hasReferencesInEnquiries(DropdownGroup group, String value) async {
    for (final enquiryField in group.enquiryFieldNames) {
      final snapshot = await _firestore
          .collection('enquiries')
          .where(enquiryField, isEqualTo: value)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) return true;
    }

    // Secondary function types live only on `functions[]` (top-level stays the main).
    if (group == DropdownGroup.eventTypes && await _hasFunctionEventTypeReference(value)) {
      return true;
    }

    return false;
  }

  Future<bool> _hasFunctionEventTypeReference(String value) async {
    const batchSize = 100;
    QueryDocumentSnapshot? lastDoc;
    while (true) {
      Query query = _firestore
          .collection('enquiries')
          .where('functionCount', isGreaterThanOrEqualTo: 2)
          .limit(batchSize);
      if (lastDoc != null) query = query.startAfterDocument(lastDoc);
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) return false;
      for (final doc in snapshot.docs) {
        final functions = (doc.data() as Map<String, dynamic>?)?['functions'];
        if (functions is! List) continue;
        for (final raw in functions) {
          if (raw is! Map) continue;
          if (raw['eventType'] == value || raw['eventTypeValue'] == value) return true;
        }
      }
      if (snapshot.docs.length < batchSize) return false;
      lastDoc = snapshot.docs.last;
    }
  }

  /// Get dropdown items for a specific group (non-stream)
  Future<List<DropdownItem>> getGroup(DropdownGroup group) async {
    // Same client-side sort as [watchGroup] — no orderBy, so docs without
    // `order` are not silently dropped.
    final snapshot = await _getCollection(group).get();
    final items = snapshot.docs.map(DropdownItem.fromFirestore).toList()
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        return byOrder != 0 ? byOrder : a.label.toLowerCase().compareTo(b.label.toLowerCase());
      });
    return items;
  }

  /// Search dropdown items within a group
  Future<List<DropdownItem>> searchGroup(DropdownGroup group, String searchQuery) async {
    final items = await getGroup(group);
    final query = searchQuery.toLowerCase();

    return items.where((item) {
      return item.value.toLowerCase().contains(query) || item.label.toLowerCase().contains(query);
    }).toList();
  }
}

/// Provider for the dropdowns repository
final dropdownsRepositoryProvider = Provider<DropdownsRepository>((ref) {
  return DropdownsRepository(ref.watch(firestoreServiceProvider).firestore);
});

/// Provider for dropdown items stream
final dropdownsStreamProvider = StreamProvider.family<List<DropdownItem>, DropdownGroup>((
  ref,
  group,
) {
  final repository = ref.watch(dropdownsRepositoryProvider);
  return repository.watchGroup(group);
});

/// Provider for dropdown items (non-stream)
final dropdownsProvider = FutureProvider.family<List<DropdownItem>, DropdownGroup>((ref, group) {
  final repository = ref.watch(dropdownsRepositoryProvider);
  return repository.getGroup(group);
});

/// Provider for checking if a dropdown value has references
final dropdownHasReferencesProvider = FutureProvider.family<bool, (DropdownGroup, String)>((
  ref,
  params,
) async {
  final (group, value) = params;
  final firestore = ref.watch(firestoreServiceProvider).firestore;

  for (final enquiryField in group.enquiryFieldNames) {
    final snapshot = await firestore
        .collection('enquiries')
        .where(enquiryField, isEqualTo: value)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) return true;
  }

  return false;
});
