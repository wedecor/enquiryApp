// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pagination_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PaginationState {
  /// Current page of documents
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get documents =>
      throw _privateConstructorUsedError;

  /// Last document snapshot for pagination cursor
  QueryDocumentSnapshot<Map<String, dynamic>>? get lastDocument =>
      throw _privateConstructorUsedError;

  /// Whether more pages are available
  bool get hasMore => throw _privateConstructorUsedError;

  /// Whether currently loading
  bool get isLoading => throw _privateConstructorUsedError;

  /// Whether currently loading more (next page)
  bool get isLoadingMore => throw _privateConstructorUsedError;

  /// Error message if any
  String? get error => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PaginationStateCopyWith<PaginationState> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaginationStateCopyWith<$Res> {
  factory $PaginationStateCopyWith(PaginationState value, $Res Function(PaginationState) then) =
      _$PaginationStateCopyWithImpl<$Res, PaginationState>;
  @useResult
  $Res call({
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument,
    bool hasMore,
    bool isLoading,
    bool isLoadingMore,
    String? error,
  });
}

/// @nodoc
class _$PaginationStateCopyWithImpl<$Res, $Val extends PaginationState>
    implements $PaginationStateCopyWith<$Res> {
  _$PaginationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? documents = null,
    Object? lastDocument = freezed,
    Object? hasMore = null,
    Object? isLoading = null,
    Object? isLoadingMore = null,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            documents: null == documents
                ? _value.documents
                : documents // ignore: cast_nullable_to_non_nullable
                      as List<QueryDocumentSnapshot<Map<String, dynamic>>>,
            lastDocument: freezed == lastDocument
                ? _value.lastDocument
                : lastDocument // ignore: cast_nullable_to_non_nullable
                      as QueryDocumentSnapshot<Map<String, dynamic>>?,
            hasMore: null == hasMore
                ? _value.hasMore
                : hasMore // ignore: cast_nullable_to_non_nullable
                      as bool,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            isLoadingMore: null == isLoadingMore
                ? _value.isLoadingMore
                : isLoadingMore // ignore: cast_nullable_to_non_nullable
                      as bool,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PaginationStateImplCopyWith<$Res> implements $PaginationStateCopyWith<$Res> {
  factory _$$PaginationStateImplCopyWith(
    _$PaginationStateImpl value,
    $Res Function(_$PaginationStateImpl) then,
  ) = __$$PaginationStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument,
    bool hasMore,
    bool isLoading,
    bool isLoadingMore,
    String? error,
  });
}

/// @nodoc
class __$$PaginationStateImplCopyWithImpl<$Res>
    extends _$PaginationStateCopyWithImpl<$Res, _$PaginationStateImpl>
    implements _$$PaginationStateImplCopyWith<$Res> {
  __$$PaginationStateImplCopyWithImpl(
    _$PaginationStateImpl _value,
    $Res Function(_$PaginationStateImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? documents = null,
    Object? lastDocument = freezed,
    Object? hasMore = null,
    Object? isLoading = null,
    Object? isLoadingMore = null,
    Object? error = freezed,
  }) {
    return _then(
      _$PaginationStateImpl(
        documents: null == documents
            ? _value._documents
            : documents // ignore: cast_nullable_to_non_nullable
                  as List<QueryDocumentSnapshot<Map<String, dynamic>>>,
        lastDocument: freezed == lastDocument
            ? _value.lastDocument
            : lastDocument // ignore: cast_nullable_to_non_nullable
                  as QueryDocumentSnapshot<Map<String, dynamic>>?,
        hasMore: null == hasMore
            ? _value.hasMore
            : hasMore // ignore: cast_nullable_to_non_nullable
                  as bool,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        isLoadingMore: null == isLoadingMore
            ? _value.isLoadingMore
            : isLoadingMore // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$PaginationStateImpl implements _PaginationState {
  const _$PaginationStateImpl({
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents = const [],
    this.lastDocument,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  }) : _documents = documents;

  /// Current page of documents
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _documents;

  /// Current page of documents
  @override
  @JsonKey()
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get documents {
    if (_documents is EqualUnmodifiableListView) return _documents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_documents);
  }

  /// Last document snapshot for pagination cursor
  @override
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;

  /// Whether more pages are available
  @override
  @JsonKey()
  final bool hasMore;

  /// Whether currently loading
  @override
  @JsonKey()
  final bool isLoading;

  /// Whether currently loading more (next page)
  @override
  @JsonKey()
  final bool isLoadingMore;

  /// Error message if any
  @override
  final String? error;

  @override
  String toString() {
    return 'PaginationState(documents: $documents, lastDocument: $lastDocument, hasMore: $hasMore, isLoading: $isLoading, isLoadingMore: $isLoadingMore, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaginationStateImpl &&
            const DeepCollectionEquality().equals(other._documents, _documents) &&
            (identical(other.lastDocument, lastDocument) || other.lastDocument == lastDocument) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.isLoading, isLoading) || other.isLoading == isLoading) &&
            (identical(other.isLoadingMore, isLoadingMore) ||
                other.isLoadingMore == isLoadingMore) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_documents),
    lastDocument,
    hasMore,
    isLoading,
    isLoadingMore,
    error,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PaginationStateImplCopyWith<_$PaginationStateImpl> get copyWith =>
      __$$PaginationStateImplCopyWithImpl<_$PaginationStateImpl>(this, _$identity);
}

abstract class _PaginationState implements PaginationState {
  const factory _PaginationState({
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    final QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument,
    final bool hasMore,
    final bool isLoading,
    final bool isLoadingMore,
    final String? error,
  }) = _$PaginationStateImpl;

  @override
  /// Current page of documents
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get documents;
  @override
  /// Last document snapshot for pagination cursor
  QueryDocumentSnapshot<Map<String, dynamic>>? get lastDocument;
  @override
  /// Whether more pages are available
  bool get hasMore;
  @override
  /// Whether currently loading
  bool get isLoading;
  @override
  /// Whether currently loading more (next page)
  bool get isLoadingMore;
  @override
  /// Error message if any
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$PaginationStateImplCopyWith<_$PaginationStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
