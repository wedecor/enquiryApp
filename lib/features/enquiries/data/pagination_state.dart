import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination_state.freezed.dart';

/// Pagination state for cursor-based pagination
@freezed
class PaginationState with _$PaginationState {
  const factory PaginationState({
    /// Current page of documents
    @Default([]) List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,

    /// Last document snapshot for pagination cursor
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument,

    /// Whether more pages are available
    @Default(false) bool hasMore,

    /// Whether currently loading
    @Default(false) bool isLoading,

    /// Whether currently loading more (next page)
    @Default(false) bool isLoadingMore,

    /// Error message if any
    String? error,
  }) = _PaginationState;
}
