import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/current_user_role_provider.dart';
import '../data/dropdowns_repository.dart';
import '../domain/dropdown_item.dart';

/// State for dropdown group selection
class DropdownGroupState extends StateNotifier<DropdownGroup> {
  DropdownGroupState() : super(DropdownGroup.statuses);

  void setGroup(DropdownGroup group) {
    state = group;
  }
}

final dropdownGroupProvider =
    StateNotifierProvider<DropdownGroupState, DropdownGroup>((ref) {
      return DropdownGroupState();
    });

/// State for dropdown search query
class DropdownQueryState extends StateNotifier<String> {
  Timer? _debounceTimer;

  DropdownQueryState() : super('');

  void setQuery(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      state = query;
    });
  }

  void clearQuery() {
    _debounceTimer?.cancel();
    state = '';
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final dropdownQueryProvider = StateNotifierProvider<DropdownQueryState, String>(
  (ref) {
    return DropdownQueryState();
  },
);

/// Provider for filtered dropdown items
final filteredDropdownsProvider =
    StreamProvider.family<List<DropdownItem>, DropdownGroup>((ref, group) {
      final dropdownsAsync = ref.watch(dropdownsStreamProvider(group));
      final query = ref.watch(dropdownQueryProvider);

      return dropdownsAsync.when(
        data: (items) {
          final searchQuery = query.toLowerCase().trim();
          if (searchQuery.isEmpty) {
            return Stream.value(items);
          }

          final filtered = items.where((item) {
            return item.value.toLowerCase().contains(searchQuery) ||
                item.label.toLowerCase().contains(searchQuery);
          }).toList();

          return Stream.value(filtered);
        },
        loading: () => Stream.value(<DropdownItem>[]),
        error: (_, __) => Stream.value(<DropdownItem>[]),
      );
    });

/// Controller for dropdown form operations
class DropdownFormController extends StateNotifier<AsyncValue<void>> {
  DropdownFormController(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  /// Create a new dropdown item
  Future<void> createItem(DropdownGroup group, DropdownItemInput input) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(dropdownsRepositoryProvider);
      await repository.create(group, input);
    });
  }

  /// Update an existing dropdown item
  Future<void> updateItem(
    DropdownGroup group,
    String value,
    Map<String, dynamic> patch,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(dropdownsRepositoryProvider);
      await repository.update(group, value, patch);
    });
  }

  /// Toggle active status of a dropdown item
  Future<void> toggleActive(
    DropdownGroup group,
    String value,
    bool active,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(dropdownsRepositoryProvider);
      await repository.toggleActive(group, value, active);
    });
  }

  /// Delete a dropdown item
  Future<void> deleteItem(DropdownGroup group, String value) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(dropdownsRepositoryProvider);
      await repository.delete(group, value);
    });
  }

  /// Reorder dropdown items
  Future<void> reorderItems(
    DropdownGroup group,
    List<String> orderedValues,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(dropdownsRepositoryProvider);
      await repository.reorder(group, orderedValues);
    });
  }

  /// Replace a dropdown value in all enquiries
  Future<void> replaceInEnquiries(
    DropdownGroup group,
    String oldValue,
    String newValue,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(dropdownsRepositoryProvider);
      await repository.replaceInEnquiries(group, oldValue, newValue);
    });
  }
}

final dropdownFormControllerProvider =
    StateNotifierProvider<DropdownFormController, AsyncValue<void>>((ref) {
      return DropdownFormController(ref);
    });

/// Provider for checking if current user is admin
final isDropdownAdminProvider = Provider<bool>((ref) {
  return ref.watch(isAdminProvider);
});

/// Provider for dropdown group statistics
final dropdownGroupStatsProvider =
    FutureProvider.family<Map<String, int>, DropdownGroup>((ref, group) async {
      final items = await ref.watch(dropdownsProvider(group).future);

      return {
        'total': items.length,
        'active': items.where((item) => item.active).length,
        'inactive': items.where((item) => !item.active).length,
      };
    });

/// Provider for checking if a dropdown value is referenced in enquiries
final isDropdownReferencedProvider =
    FutureProvider.family<bool, (DropdownGroup, String)>((ref, params) async {
      return ref.watch(dropdownHasReferencesProvider(params).future);
    });

/// Provider for getting available replacement values for a dropdown group
final availableReplacementsProvider =
    FutureProvider.family<List<DropdownItem>, (DropdownGroup, String)>((
      ref,
      params,
    ) async {
      final (group, excludeValue) = params;
      final items = await ref.watch(dropdownsProvider(group).future);

      return items
          .where((item) => item.value != excludeValue && item.active)
          .toList();
    });

/// State for dropdown reordering
class DropdownReorderState extends StateNotifier<Map<String, dynamic>> {
  DropdownReorderState()
    : super({'isReordering': false, 'reorderedValues': <String>[]});

  void startReordering(List<String> initialValues) {
    state = {'isReordering': true, 'reorderedValues': List.from(initialValues)};
  }

  void updateReorderedValues(List<String> newOrder) {
    state = {...state, 'reorderedValues': List.from(newOrder)};
  }

  void cancelReordering() {
    state = {'isReordering': false, 'reorderedValues': <String>[]};
  }

  void confirmReordering() {
    state = {...state, 'isReordering': false};
  }
}

final dropdownReorderProvider =
    StateNotifierProvider<DropdownReorderState, Map<String, dynamic>>((ref) {
      return DropdownReorderState();
    });

/// Provider for dropdown item validation
final validateDropdownItemProvider =
    Provider.family<DropdownItemValidation, DropdownItemInput>((ref, input) {
      return DropdownItemValidation.validate(input);
    });

/// Provider for checking if a dropdown value is unique within a group
final isDropdownValueUniqueProvider =
    FutureProvider.family<bool, (DropdownGroup, String)>((ref, params) async {
      final (group, value) = params;
      final items = await ref.watch(dropdownsProvider(group).future);

      return !items.any((item) => item.value == value);
    });
