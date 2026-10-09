import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/logger.dart';
import '../../../core/services/firestore_service.dart';
import 'date_range_presets.dart';
import 'filters_state.dart';

/// Provider for the saved views repository
final savedViewsRepositoryProvider = Provider<SavedViewsRepository>((ref) {
  return SavedViewsRepository(ref.watch(firestoreServiceProvider));
});

/// Repository for managing saved enquiry filter views
class SavedViewsRepository {
  SavedViewsRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  /// JSON for Firestore. A "Today"/"This Week" range also stores its preset key so the
  /// view keeps meaning "today" instead of the day it was saved.
  static Map<String, dynamic> _toFirestore(SavedView view) {
    final json = view.toJson();
    // toJson keeps nested freezed objects as instances; Firestore needs plain maps.
    json['filters'] = view.filters.toJson();
    final range = view.filters.dateRange;
    if (range != null) {
      (json['filters'] as Map<String, dynamic>)['dateRange'] = range.toJson();
    }
    json[DateRangePreset.savedViewField] = DateRangePreset.keyFor(range);
    return json;
  }

  /// Parses a stored view, re-resolving a relative date preset to the current range.
  static SavedView _fromFirestore(Map<String, dynamic> data) {
    final view = SavedView.fromJson(data);
    final preset = DateRangePreset.resolve(data[DateRangePreset.savedViewField] as String?);
    if (preset == null) return view;
    return view.copyWith(filters: view.filters.copyWith(dateRange: preset));
  }

  CollectionReference<Map<String, dynamic>>? _collectionForCurrentUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return _firestoreService.savedViewsCollection(uid);
  }

  /// Get the current user's saved views
  Future<List<SavedView>> getSavedViews() async {
    try {
      final collection = _collectionForCurrentUser();
      if (collection == null) {
        Logger.error('No authenticated user for saved views', tag: 'SavedViews');
        return [];
      }

      final doc = await collection.orderBy('createdAt', descending: false).get();
      return doc.docs.map((doc) => _fromFirestore(doc.data())).toList();
    } catch (e) {
      Logger.error('Failed to get saved views', error: e, tag: 'SavedViews');
      rethrow;
    }
  }

  /// Get a specific saved view by ID
  Future<SavedView?> getSavedView(String id) async {
    try {
      final collection = _collectionForCurrentUser();
      if (collection == null) {
        Logger.error('No authenticated user for saved view', tag: 'SavedViews');
        return null;
      }

      final doc = await collection.doc(id).get();
      if (!doc.exists) {
        return null;
      }

      return _fromFirestore(doc.data()!);
    } catch (e) {
      Logger.error('Failed to get saved view: $id', error: e, tag: 'SavedViews');
      rethrow;
    }
  }

  /// Save a new view or update an existing one
  Future<SavedView> saveView(SavedView view) async {
    try {
      final collection = _collectionForCurrentUser();
      if (collection == null) {
        throw Exception('No authenticated user');
      }

      final now = DateTime.now();
      final viewToSave = view.copyWith(
        updatedAt: now,
        createdAt: view.createdAt == view.updatedAt ? now : view.createdAt,
      );

      await collection.doc(view.id).set(_toFirestore(viewToSave));

      Logger.info('Saved view: ${view.name}', tag: 'SavedViews');
      return viewToSave;
    } catch (e) {
      Logger.error('Failed to save view: ${view.name}', error: e, tag: 'SavedViews');
      rethrow;
    }
  }

  /// Create a new saved view
  Future<SavedView> createView({
    required String name,
    required EnquiryFilters filters,
    bool isDefault = false,
  }) async {
    try {
      final collection = _collectionForCurrentUser();
      if (collection == null) {
        throw Exception('No authenticated user');
      }

      final existingViews = await getSavedViews();
      if (existingViews.any((view) => view.name.toLowerCase() == name.toLowerCase())) {
        throw Exception('A view with this name already exists');
      }

      if (isDefault) {
        await _unsetDefaultViews();
      }

      final now = DateTime.now();
      final newView = SavedView(
        id: _generateViewId(),
        name: name,
        filters: filters,
        isDefault: isDefault,
        createdAt: now,
        updatedAt: now,
      );

      await collection.doc(newView.id).set(_toFirestore(newView));

      Logger.info('Created view: ${newView.name}', tag: 'SavedViews');
      return newView;
    } catch (e) {
      Logger.error('Failed to create view: $name', error: e, tag: 'SavedViews');
      rethrow;
    }
  }

  /// Update an existing saved view
  Future<SavedView> updateView(SavedView view) async {
    try {
      final collection = _collectionForCurrentUser();
      if (collection == null) {
        throw Exception('No authenticated user');
      }

      final existingViews = await getSavedViews();
      if (existingViews.any(
        (v) => v.id != view.id && v.name.toLowerCase() == view.name.toLowerCase(),
      )) {
        throw Exception('A view with this name already exists');
      }

      if (view.isDefault) {
        await _unsetDefaultViews(excludeId: view.id);
      }

      final updatedView = view.touch();
      await collection.doc(view.id).update(_toFirestore(updatedView));

      Logger.info('Updated view: ${view.name}', tag: 'SavedViews');
      return updatedView;
    } catch (e) {
      Logger.error('Failed to update view: ${view.name}', error: e, tag: 'SavedViews');
      rethrow;
    }
  }

  /// Delete a saved view
  Future<void> deleteView(String id) async {
    try {
      final collection = _collectionForCurrentUser();
      if (collection == null) {
        throw Exception('No authenticated user');
      }

      await collection.doc(id).delete();

      Logger.info('Deleted view: $id', tag: 'SavedViews');
    } catch (e) {
      Logger.error('Failed to delete view: $id', error: e, tag: 'SavedViews');
      rethrow;
    }
  }

  /// Set a view as default (unsetting others)
  Future<void> setDefaultView(String id) async {
    try {
      final collection = _collectionForCurrentUser();
      if (collection == null) {
        throw Exception('No authenticated user');
      }

      await _unsetDefaultViews();
      await collection.doc(id).update({
        'isDefault': true,
        'updatedAt': DateTime.now().toIso8601String(), // SavedView.fromJson parses a string
      });

      Logger.info('Set default view: $id', tag: 'SavedViews');
    } catch (e) {
      Logger.error('Failed to set default view: $id', error: e, tag: 'SavedViews');
      rethrow;
    }
  }

  Future<void> _unsetDefaultViews({String? excludeId}) async {
    final collection = _collectionForCurrentUser();
    if (collection == null) return;

    final batch = _firestoreService.startBatch();
    final defaultViews = await collection.where('isDefault', isEqualTo: true).get();

    for (final doc in defaultViews.docs) {
      if (excludeId == null || doc.id != excludeId) {
        batch.update(doc.reference, {
          'isDefault': false,
          'updatedAt': DateTime.now().toIso8601String(), // SavedView.fromJson parses a string
        });
      }
    }

    await batch.commit();
  }

  String _generateViewId() => DateTime.now().millisecondsSinceEpoch.toString();

  /// Stream of saved views for real-time updates
  Stream<List<SavedView>> watchSavedViews() {
    final collection = _collectionForCurrentUser();
    if (collection == null) {
      return Stream.value([]);
    }

    return collection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _fromFirestore(doc.data())).toList());
  }
}

/// Provider for saved views state
final savedViewsProvider = StreamProvider<List<SavedView>>((ref) {
  final repository = ref.watch(savedViewsRepositoryProvider);
  return repository.watchSavedViews();
});

/// Provider for saved views state management
final savedViewsStateProvider = StateNotifierProvider<SavedViewsStateController, SavedViewsState>((
  ref,
) {
  return SavedViewsStateController(ref);
});

/// Controller for managing saved views state
class SavedViewsStateController extends StateNotifier<SavedViewsState> {
  SavedViewsStateController(this.ref) : super(const SavedViewsState()) {
    _loadSavedViews();
  }

  final Ref ref;

  Future<void> _loadSavedViews() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final repository = ref.read(savedViewsRepositoryProvider);
      final views = await repository.getSavedViews();

      state = state.copyWith(views: views, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createView({
    required String name,
    required EnquiryFilters filters,
    bool isDefault = false,
  }) async {
    try {
      final repository = ref.read(savedViewsRepositoryProvider);
      final newView = await repository.createView(
        name: name,
        filters: filters,
        isDefault: isDefault,
      );

      final updatedViews = List<SavedView>.from(state.views)..add(newView);
      state = state.copyWith(views: updatedViews);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateView(SavedView view) async {
    try {
      final repository = ref.read(savedViewsRepositoryProvider);
      final updatedView = await repository.updateView(view);

      final updatedViews = state.views.map((v) => v.id == view.id ? updatedView : v).toList();
      state = state.copyWith(views: updatedViews);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteView(String id) async {
    try {
      final repository = ref.read(savedViewsRepositoryProvider);
      await repository.deleteView(id);

      final updatedViews = state.views.where((v) => v.id != id).toList();
      state = state.copyWith(views: updatedViews);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> setDefaultView(String id) async {
    try {
      final repository = ref.read(savedViewsRepositoryProvider);
      await repository.setDefaultView(id);

      final updatedViews = state.views.map((v) {
        return v.id == id ? v.copyWith(isDefault: true) : v.copyWith(isDefault: false);
      }).toList();
      state = state.copyWith(views: updatedViews);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadSavedViews();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
