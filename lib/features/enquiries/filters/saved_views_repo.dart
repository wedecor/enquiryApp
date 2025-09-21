import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/logger.dart';
import 'filters_state.dart';

/// Provider for the saved views repository
final savedViewsRepositoryProvider = Provider<SavedViewsRepository>((ref) {
  return SavedViewsRepository();
});

/// Repository for managing saved enquiry filter views
class SavedViewsRepository {
  SavedViewsRepository();

  /// Get the current user's saved views
  Future<List<SavedView>> getSavedViews() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Logger.warning('No authenticated user for saved views', tag: 'SavedViews');
        return [];
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedViews')
          .orderBy('createdAt', descending: false)
          .get();

      return doc.docs.map((doc) => SavedView.fromJson(doc.data())).toList();
    } catch (e) {
      Logger.error('Failed to get saved views', error: e, tag: 'SavedViews');
      rethrow;
    }
  }

  /// Get a specific saved view by ID
  Future<SavedView?> getSavedView(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Logger.warning('No authenticated user for saved view', tag: 'SavedViews');
        return null;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedViews')
          .doc(id)
          .get();

      if (!doc.exists) {
        return null;
      }

      return SavedView.fromJson(doc.data()!);
    } catch (e) {
      Logger.error('Failed to get saved view: $id', error: e, tag: 'SavedViews');
      rethrow;
    }
  }

  /// Save a new view or update an existing one
  Future<SavedView> saveView(SavedView view) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      final now = DateTime.now();
      final viewToSave = view.copyWith(
        updatedAt: now,
        createdAt: view.createdAt == view.updatedAt ? now : view.createdAt,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedViews')
          .doc(view.id)
          .set(viewToSave.toJson());

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Check if name already exists
      final existingViews = await getSavedViews();
      if (existingViews.any((view) => view.name.toLowerCase() == name.toLowerCase())) {
        throw Exception('A view with this name already exists');
      }

      // If this is set as default, unset other defaults
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

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedViews')
          .doc(newView.id)
          .set(newView.toJson());

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Check if name already exists (excluding current view)
      final existingViews = await getSavedViews();
      if (existingViews.any(
        (v) => v.id != view.id && v.name.toLowerCase() == view.name.toLowerCase(),
      )) {
        throw Exception('A view with this name already exists');
      }

      // If this is set as default, unset other defaults
      if (view.isDefault) {
        await _unsetDefaultViews(excludeId: view.id);
      }

      final updatedView = view.touch();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedViews')
          .doc(view.id)
          .update(updatedView.toJson());

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedViews')
          .doc(id)
          .delete();

      Logger.info('Deleted view: $id', tag: 'SavedViews');
    } catch (e) {
      Logger.error('Failed to delete view: $id', error: e, tag: 'SavedViews');
      rethrow;
    }
  }

  /// Set a view as default (unsetting others)
  Future<void> setDefaultView(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Unset all defaults
      await _unsetDefaultViews();

      // Set this one as default
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedViews')
          .doc(id)
          .update({'isDefault': true, 'updatedAt': FieldValue.serverTimestamp()});

      Logger.info('Set default view: $id', tag: 'SavedViews');
    } catch (e) {
      Logger.error('Failed to set default view: $id', error: e, tag: 'SavedViews');
      rethrow;
    }
  }

  /// Unset all default views (optionally excluding one)
  Future<void> _unsetDefaultViews({String? excludeId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final defaultViews = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('savedViews')
        .where('isDefault', isEqualTo: true)
        .get();

    for (final doc in defaultViews.docs) {
      if (excludeId == null || doc.id != excludeId) {
        batch.update(doc.reference, {
          'isDefault': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  /// Generate a unique ID for a new view
  String _generateViewId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Stream of saved views for real-time updates
  Stream<List<SavedView>> watchSavedViews() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('savedViews')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => SavedView.fromJson(doc.data())).toList();
        });
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

  /// Load saved views
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

  /// Create a new saved view
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

  /// Update an existing saved view
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

  /// Delete a saved view
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

  /// Set a view as default
  Future<void> setDefaultView(String id) async {
    try {
      final repository = ref.read(savedViewsRepositoryProvider);
      await repository.setDefaultView(id);

      // Update local state
      final updatedViews = state.views.map((v) {
        return v.id == id ? v.copyWith(isDefault: true) : v.copyWith(isDefault: false);
      }).toList();
      state = state.copyWith(views: updatedViews);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Refresh saved views
  Future<void> refresh() async {
    await _loadSavedViews();
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}
