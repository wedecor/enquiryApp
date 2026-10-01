import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/role_provider.dart';
import '../../../shared/models/user_model.dart';
import 'enquiry_repository.dart';
import 'pagination_state.dart';

/// Provider for paginated enquiries state.
///
/// Stays in a loading state until the role (and, for staff, the uid) is known, so an admin
/// never runs an assigned-only query and staff never run an unscoped one.
final paginatedEnquiriesProvider =
    StateNotifierProvider.family<PaginatedEnquiriesNotifier, PaginationState, PaginationParams>((
      ref,
      params,
    ) {
      final repository = ref.watch(enquiryRepositoryProvider);
      final uid = ref.watch(currentUserWithFirestoreProvider.select((u) => u.valueOrNull?.uid));
      final role = ref.watch(roleProvider.select((r) => r.valueOrNull));
      final roleFailed = ref.watch(roleProvider.select((r) => r.hasError && !r.hasValue));
      final isAdmin = role == UserRole.admin;

      return PaginatedEnquiriesNotifier(
        repository: repository,
        isAdmin: isAdmin,
        assignedTo: uid,
        status: params.status,
        ready: role != null && (isAdmin || uid != null),
        initialError: roleFailed ? 'Could not load your access role' : null,
      );
    });

/// Parameters for paginated enquiries
class PaginationParams {
  final String? status;

  const PaginationParams({this.status});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginationParams && runtimeType == other.runtimeType && status == other.status;

  @override
  int get hashCode => status.hashCode;
}

/// State notifier for paginated enquiries
class PaginatedEnquiriesNotifier extends StateNotifier<PaginationState> {
  final EnquiryRepository repository;
  final bool isAdmin;
  final String? assignedTo;
  final String? status;

  /// False until the caller's access scope is known; loads are no-ops meanwhile.
  final bool ready;
  final int pageSize = 20;

  PaginatedEnquiriesNotifier({
    required this.repository,
    required this.isAdmin,
    this.assignedTo,
    this.status,
    this.ready = true,
    String? initialError,
  }) : super(
         initialError != null
             ? PaginationState(error: initialError)
             : const PaginationState(isLoading: true),
       ) {
    if (ready && initialError == null) loadFirstPage();
  }

  /// Load first page (reset pagination)
  Future<void> loadFirstPage() async {
    if (!ready) return;
    state = state.copyWith(isLoading: true, error: null, documents: [], lastDocument: null);

    final result = await repository.getPaginatedEnquiries(
      isAdmin: isAdmin,
      assignedTo: assignedTo,
      status: status,
      pageSize: pageSize,
    );

    if (!mounted) return;
    state = result.copyWith(isLoading: false);
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (!ready || !state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true, error: null);

    final result = await repository.getPaginatedEnquiries(
      isAdmin: isAdmin,
      assignedTo: assignedTo,
      status: status,
      lastDocument: state.lastDocument,
      pageSize: pageSize,
    );

    if (!mounted) return;
    if (result.error != null) {
      state = state.copyWith(isLoadingMore: false, error: result.error);
      return;
    }

    // Append new documents to existing ones
    state = state.copyWith(
      documents: [...state.documents, ...result.documents],
      lastDocument: result.lastDocument,
      hasMore: result.hasMore,
      isLoadingMore: false,
    );
  }

  /// Refresh (reload first page)
  Future<void> refresh() => loadFirstPage();

  /// Alias for [loadNextPage] used by scroll listeners.
  Future<void> loadMore() => loadNextPage();
}
