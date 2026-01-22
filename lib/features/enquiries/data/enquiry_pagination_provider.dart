import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/role_provider.dart';
import '../../../shared/models/user_model.dart';
import 'enquiry_repository.dart';
import 'pagination_state.dart';

/// Provider for paginated enquiries state
final paginatedEnquiriesProvider =
    StateNotifierProvider.family<PaginatedEnquiriesNotifier, PaginationState, PaginationParams>((
      ref,
      params,
    ) {
      final repository = ref.watch(enquiryRepositoryProvider);
      final currentUser = ref.watch(currentUserWithFirestoreProvider);
      final roleAsync = ref.watch(roleProvider);

      return PaginatedEnquiriesNotifier(
        repository: repository,
        isAdmin: roleAsync.valueOrNull == UserRole.admin,
        assignedTo: currentUser.value?.uid,
        status: params.status,
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
  final int pageSize = 20;

  PaginatedEnquiriesNotifier({
    required this.repository,
    required this.isAdmin,
    this.assignedTo,
    this.status,
  }) : super(const PaginationState());

  /// Load first page (reset pagination)
  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null, documents: [], lastDocument: null);

    final result = await repository.getPaginatedEnquiries(
      isAdmin: isAdmin,
      assignedTo: assignedTo,
      status: status,
      pageSize: pageSize,
    );

    state = result.copyWith(isLoading: false);
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true, error: null);

    final result = await repository.getPaginatedEnquiries(
      isAdmin: isAdmin,
      assignedTo: assignedTo,
      status: status,
      lastDocument: state.lastDocument,
      pageSize: pageSize,
    );

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
}
