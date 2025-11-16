import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/role_provider.dart';
import '../../../../core/auth/current_user_role_provider.dart' as auth_providers;
import '../data/users_repository.dart';
import '../domain/user_model.dart';

// Repository provider
final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository();
});

// Filter state for users list
class UsersFilter extends StateNotifier<Map<String, dynamic>> {
  UsersFilter()
    : super({
        'search': '',
        'role': 'All',
        'active': null, // null means "All"
        'limit': 20,
        'startAfterEmail': null,
      });

  void updateSearch(String search) {
    state = {...state, 'search': search, 'startAfterEmail': null};
  }

  void updateRole(String role) {
    state = {...state, 'role': role, 'startAfterEmail': null};
  }

  void updateActive(bool? active) {
    state = {...state, 'active': active, 'startAfterEmail': null};
  }

  void loadMore(String lastEmail) {
    state = {...state, 'startAfterEmail': lastEmail};
  }

  void reset() {
    state = {'search': '', 'role': 'All', 'active': null, 'limit': 20, 'startAfterEmail': null};
  }
}

final usersFilterProvider = StateNotifierProvider<UsersFilter, Map<String, dynamic>>((ref) {
  return UsersFilter();
});

// Users stream provider
final usersStreamProvider = StreamProvider.family<List<UserModel>, Map<String, dynamic>>((
  ref,
  filter,
) {
  final repository = ref.read(usersRepositoryProvider);

  return repository.watchUsers(
    search: filter['search'] as String?,
    role: filter['role'] as String?,
    active: filter['active'] as bool?,
    limit: filter['limit'] as int,
    startAfterEmail: filter['startAfterEmail'] as String?,
  );
});

// User form controller for create/edit operations
class UserFormController extends StateNotifier<AsyncValue<void>> {
  UserFormController(this._repository) : super(const AsyncValue.data(null));

  final UsersRepository _repository;

  Future<void> createUser(UserModel user) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createUserDoc(user);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateUserDoc(uid, updates);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleActive(String uid, bool active) async {
    state = const AsyncValue.loading();
    try {
      await _repository.toggleActive(uid, active);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
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
    active: userData['active'] as bool? ?? true,
    // fcmToken removed for security - stored in private subcollection
    createdAt: DateTime.now(), // These will be properly set when loaded from Firestore
    updatedAt: DateTime.now(),
  );
});

final isCurrentUserAdminProvider = Provider<bool>((ref) {
  return ref.watch(isAdminProvider);
});

// Pagination state
class PaginationState {
  final bool hasMore;
  final bool isLoading;
  final String? lastEmail;

  const PaginationState({this.hasMore = false, this.isLoading = false, this.lastEmail});

  PaginationState copyWith({bool? hasMore, bool? isLoading, String? lastEmail}) {
    return PaginationState(
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      lastEmail: lastEmail ?? this.lastEmail,
    );
  }
}

final paginationStateProvider = StateNotifierProvider<PaginationStateNotifier, PaginationState>((
  ref,
) {
  return PaginationStateNotifier();
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

class PaginationStateNotifier extends StateNotifier<PaginationState> {
  PaginationStateNotifier() : super(const PaginationState());

  void setHasMore(bool hasMore) {
    state = state.copyWith(hasMore: hasMore);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setLastEmail(String email) {
    state = state.copyWith(lastEmail: email);
  }

  void reset() {
    state = const PaginationState();
  }
}
