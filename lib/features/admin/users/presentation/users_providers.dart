import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/current_user_role_provider.dart' as auth_providers;
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../data/users_repository.dart';
import '../domain/user_model.dart';

// Repository provider
final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(ref.watch(firestoreServiceProvider).firestore);
});

/// Users list filter. All filtering is client-side over the full list.
typedef UsersFilterState = ({String search, String role, bool? isActive});

const UsersFilterState _defaultUsersFilter = (search: '', role: 'All', isActive: null);

// Filter state for users list
class UsersFilter extends StateNotifier<UsersFilterState> {
  UsersFilter() : super(_defaultUsersFilter);

  void updateSearch(String search) {
    state = (search: search, role: state.role, isActive: state.isActive);
  }

  void updateRole(String role) {
    state = (search: state.search, role: role, isActive: state.isActive);
  }

  /// `null` means "All".
  void updateActive(bool? isActive) {
    state = (search: state.search, role: state.role, isActive: isActive);
  }

  void reset() {
    state = _defaultUsersFilter;
  }
}

final usersFilterProvider = StateNotifierProvider<UsersFilter, UsersFilterState>((ref) {
  return UsersFilter();
});

/// Live stream of all users (small team: no paging, no server-side filters).
final usersStreamProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  return ref.watch(usersRepositoryProvider).watchUsers();
});

/// [usersStreamProvider] with the current [usersFilterProvider] applied.
final filteredUsersProvider = Provider.autoDispose<AsyncValue<List<UserModel>>>((ref) {
  final filter = ref.watch(usersFilterProvider);
  return ref.watch(usersStreamProvider).whenData((users) => applyUsersFilter(users, filter));
});

/// Applies search (name/email), role and active filters. Active state is
/// already `isActive ?? active` in [UserModel.fromFirestore], so legacy docs
/// filter correctly.
List<UserModel> applyUsersFilter(List<UserModel> users, UsersFilterState filter) {
  final search = filter.search.trim().toLowerCase();
  final role = filter.role;
  final isActive = filter.isActive;
  return users.where((user) {
    if (role.isNotEmpty && role != 'All' && user.role.toLowerCase() != role) {
      return false;
    }
    if (isActive != null && user.isActive != isActive) {
      return false;
    }
    if (search.isNotEmpty &&
        !user.name.toLowerCase().contains(search) &&
        !user.email.toLowerCase().contains(search)) {
      return false;
    }
    return true;
  }).toList();
}

/// User-facing message for a failed admin user update. Uses the callable's
/// human-readable message (e.g. "You can't change your own role").
String userAdminErrorMessage(Object error) {
  if (error is FirebaseFunctionsException) {
    final message = error.message;
    if (message != null && message.isNotEmpty) return message;
    return 'Request failed (${error.code})';
  }
  return error.toString();
}

// User form controller for edit / activate operations. Errors are stored in
// state AND rethrown so callers can show a failure message.
class UserFormController extends StateNotifier<AsyncValue<void>> {
  UserFormController(this._repository) : super(const AsyncValue.data(null));

  final UsersRepository _repository;

  /// Sends only the changed fields (`name`, `phone`, `role`, `isActive`) to
  /// the `adminUpdateUser` callable.
  Future<void> updateUser(String uid, Map<String, dynamic> changes) async {
    state = const AsyncValue.loading();
    try {
      await _repository.adminUpdateUser(uid, changes);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> toggleActive(String uid, bool active) async {
    state = const AsyncValue.loading();
    try {
      await _repository.toggleActive(uid, active);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final userFormControllerProvider = StateNotifierProvider<UserFormController, AsyncValue<void>>((
  ref,
) {
  final repository = ref.read(usersRepositoryProvider);
  return UserFormController(repository);
});

// Current user provider (for role checking) - now using the new auth system
final currentUserProvider = Provider<UserModel?>((ref) {
  final authUser = ref.watch(auth_providers.firebaseAuthUserProvider).value;
  final userData = ref.watch(auth_providers.currentUserDataProvider);

  if (authUser == null || userData == null) return null;

  return UserModel(
    uid: authUser.uid,
    name: userData['name'] as String? ?? '',
    email: userData['email'] as String? ?? '',
    phone: userData['phone'] as String?,
    role: userData['role'] as String? ?? 'staff',
    isActive: (userData['isActive'] ?? userData['active']) as bool? ?? true,
    // fcmToken removed for security - stored in private subcollection
    createdAt: DateTime.now(), // These will be properly set when loaded from Firestore
    updatedAt: DateTime.now(),
  );
});

final isCurrentUserAdminProvider = Provider<bool>((ref) {
  return ref.watch(isAdminProvider);
});

/// Display name lookup (name · phone with fallbacks)
final userDisplayNameProvider = FutureProvider.family<String, String>((ref, userId) async {
  final repository = ref.watch(usersRepositoryProvider);

  final user = await repository.getUserByUid(userId);
  if (user == null) {
    return 'Unknown';
  }

  final name = user.name.trim();
  final phone = user.phone?.trim() ?? '';
  final email = user.email.trim();

  final parts = <String>[];
  if (name.isNotEmpty) {
    parts.add(name);
  }

  if (phone.isNotEmpty) {
    parts.add(phone);
  } else if (name.isEmpty && email.isNotEmpty) {
    // Use email only when no other human-friendly info exists
    parts.add(email);
  }

  if (parts.isEmpty) {
    return email.isNotEmpty ? email : 'Unknown';
  }

  return parts.join(' · ');
});
