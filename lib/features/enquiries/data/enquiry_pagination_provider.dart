import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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

/// State notifier for paginated enquiries.
///
/// Listens live to the newest [pageSize] × pages enquiries, so edits, status changes,
/// new enquiries and deletions from anywhere show up without a manual refresh.
class PaginatedEnquiriesNotifier extends StateNotifier<PaginationState> {
  final EnquiryRepository repository;
  final bool isAdmin;
  final String? assignedTo;
  final String? status;

  /// False until the caller's access scope is known; loads are no-ops meanwhile.
  final bool ready;
  final int pageSize = 20;

  late int _limit = pageSize;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

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
  Future<void> loadFirstPage() {
    if (!ready) return Future.value();
    _limit = pageSize;
    state = state.copyWith(isLoading: true, error: null, documents: [], lastDocument: null);
    return _listen();
  }

  /// Load next page
  Future<void> loadNextPage() {
    if (!ready || !state.hasMore || state.isLoadingMore) return Future.value();
    _limit += pageSize;
    state = state.copyWith(isLoadingMore: true, error: null);
    return _listen();
  }

  /// Re-subscribes at the current depth without clearing what is on screen.
  Future<void> refresh() {
    if (!ready) return Future.value();
    if (_subscription == null) return loadFirstPage();
    return _listen();
  }

  /// Alias for [loadNextPage] used by scroll listeners.
  Future<void> loadMore() => loadNextPage();

  /// Completes on the first snapshot (or error) of the new subscription.
  Future<void> _listen() {
    final firstEvent = Completer<void>();
    void done() {
      if (!firstEvent.isCompleted) firstEvent.complete();
    }

    final limit = _limit;
    unawaited(_subscription?.cancel());
    _subscription = repository
        .watchEnquiriesPage(
          isAdmin: isAdmin,
          assignedTo: assignedTo,
          status: status,
          limit: limit + 1,
        )
        .listen(
          (snapshot) {
            if (!mounted) return;
            final docs = snapshot.docs;
            final hasMore = docs.length > limit;
            final documents = hasMore ? docs.sublist(0, limit) : docs;
            // A cache-only result can be shorter than what the server holds.
            final pending = snapshot.metadata.isFromCache && !hasMore;
            state = state.copyWith(
              documents: documents,
              lastDocument: documents.isNotEmpty ? documents.last : null,
              hasMore: pending ? state.hasMore : hasMore,
              isLoading: false,
              isLoadingMore: pending && state.isLoadingMore,
              error: null,
            );
            done();
          },
          onError: (Object e) {
            if (mounted) {
              state = state.copyWith(isLoading: false, isLoadingMore: false, error: e.toString());
            }
            done();
          },
        );
    return firstEvent.future;
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
