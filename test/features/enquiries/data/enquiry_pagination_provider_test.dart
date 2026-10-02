// ignore_for_file: subtype_of_sealed_class
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/core/providers/role_provider.dart';
import 'package:we_decor_enquiries/features/enquiries/data/enquiry_pagination_provider.dart';
import 'package:we_decor_enquiries/features/enquiries/data/enquiry_repository.dart';
import 'package:we_decor_enquiries/shared/models/user_model.dart';

class MockEnquiryRepository extends Mock implements EnquiryRepository {}

class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}

class MockSnapshotMetadata extends Mock implements SnapshotMetadata {}

class MockDoc extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

MockQuerySnapshot _snapshot(int docCount, {bool fromCache = false}) {
  final metadata = MockSnapshotMetadata();
  when(() => metadata.isFromCache).thenReturn(fromCache);
  final snapshot = MockQuerySnapshot();
  when(() => snapshot.docs).thenReturn([for (var i = 0; i < docCount; i++) MockDoc()]);
  when(() => snapshot.metadata).thenReturn(metadata);
  return snapshot;
}

MockQuerySnapshot _emptySnapshot({bool fromCache = false}) => _snapshot(0, fromCache: fromCache);

/// Repository whose live page emits [controller] events, or one empty snapshot by default.
MockEnquiryRepository _repo({StreamController<QuerySnapshot<Map<String, dynamic>>>? controller}) {
  final repo = MockEnquiryRepository();
  when(
    () => repo.watchEnquiriesPage(
      isAdmin: any(named: 'isAdmin'),
      assignedTo: any(named: 'assignedTo'),
      status: any(named: 'status'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer((_) => controller?.stream ?? Stream.value(_emptySnapshot()));
  return repo;
}

/// Repository backed by a server holding [total] enquiries.
MockEnquiryRepository _repoWithTotal(int total) {
  final repo = MockEnquiryRepository();
  when(
    () => repo.watchEnquiriesPage(
      isAdmin: any(named: 'isAdmin'),
      assignedTo: any(named: 'assignedTo'),
      status: any(named: 'status'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer((inv) {
    final limit = inv.namedArguments[#limit] as int;
    return Stream.value(_snapshot(total < limit ? total : limit));
  });
  return repo;
}

void _verifyNeverWatched(MockEnquiryRepository repo) {
  verifyNever(
    () => repo.watchEnquiriesPage(
      isAdmin: any(named: 'isAdmin'),
      assignedTo: any(named: 'assignedTo'),
      status: any(named: 'status'),
      limit: any(named: 'limit'),
    ),
  );
}

void main() {
  group('PaginatedEnquiriesNotifier', () {
    test('pageSize is 20 so Firestore reads at most 21 docs per page', () {
      final notifier = PaginatedEnquiriesNotifier(
        repository: MockEnquiryRepository(),
        isAdmin: true,
        ready: false,
      );
      expect(notifier.pageSize, 20);
      expect(notifier.pageSize + 1, lessThanOrEqualTo(21));
    });

    test('PaginationParams equality is based on status filter', () {
      const all = PaginationParams();
      const contacted = PaginationParams(status: 'contacted');
      expect(all, isNot(equals(contacted)));
      expect(const PaginationParams(status: 'contacted'), equals(contacted));
    });

    test('subscribes to the first page on construction', () async {
      final repo = _repo();
      final notifier = PaginatedEnquiriesNotifier(repository: repo, isAdmin: true);
      addTearDown(notifier.dispose);
      expect(notifier.state.isLoading, isTrue);
      await pumpEventQueue();
      expect(notifier.state.isLoading, isFalse);
      verify(
        () => repo.watchEnquiriesPage(isAdmin: true, assignedTo: null, status: null, limit: 21),
      ).called(1);
    });

    test('does not subscribe until ready', () async {
      final repo = _repo();
      final notifier = PaginatedEnquiriesNotifier(repository: repo, isAdmin: false, ready: false);
      addTearDown(notifier.dispose);
      await notifier.loadFirstPage();
      expect(notifier.state.isLoading, isTrue);
      _verifyNeverWatched(repo);
    });

    test('later snapshots update the list without a manual refresh', () async {
      final controller = StreamController<QuerySnapshot<Map<String, dynamic>>>();
      addTearDown(controller.close);
      final notifier = PaginatedEnquiriesNotifier(
        repository: _repo(controller: controller),
        isAdmin: true,
      );
      addTearDown(notifier.dispose);

      controller.add(_snapshot(3));
      await pumpEventQueue();
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.documents, hasLength(3));

      controller.add(_snapshot(4));
      await pumpEventQueue();
      expect(notifier.state.documents, hasLength(4));
    });

    test('shows one page and flags more when the server has extra', () async {
      final notifier = PaginatedEnquiriesNotifier(repository: _repoWithTotal(50), isAdmin: true);
      addTearDown(notifier.dispose);
      await pumpEventQueue();
      expect(notifier.state.documents, hasLength(20));
      expect(notifier.state.hasMore, isTrue);
    });

    test('loadNextPage is a no-op when the server reports no more', () async {
      final repo = _repoWithTotal(5);
      final notifier = PaginatedEnquiriesNotifier(repository: repo, isAdmin: true);
      addTearDown(notifier.dispose);
      await pumpEventQueue();
      expect(notifier.state.hasMore, isFalse);

      await notifier.loadNextPage();
      verify(
        () => repo.watchEnquiriesPage(
          isAdmin: any(named: 'isAdmin'),
          assignedTo: any(named: 'assignedTo'),
          status: any(named: 'status'),
          limit: any(named: 'limit'),
        ),
      ).called(1);
    });

    test('loadNextPage grows the live window by one page', () async {
      final repo = _repoWithTotal(50);
      final notifier = PaginatedEnquiriesNotifier(repository: repo, isAdmin: true);
      addTearDown(notifier.dispose);
      await pumpEventQueue();

      await notifier.loadNextPage();
      verify(
        () => repo.watchEnquiriesPage(isAdmin: true, assignedTo: null, status: null, limit: 41),
      ).called(1);
      expect(notifier.state.documents, hasLength(40));
      expect(notifier.state.hasMore, isTrue);
      expect(notifier.state.isLoadingMore, isFalse);

      await notifier.loadNextPage();
      expect(notifier.state.documents, hasLength(50));
      expect(notifier.state.hasMore, isFalse);
    });

    test('a short cache-only snapshot keeps hasMore until the server answers', () async {
      final controller = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      addTearDown(controller.close);
      final notifier = PaginatedEnquiriesNotifier(
        repository: _repo(controller: controller),
        isAdmin: true,
      );
      addTearDown(notifier.dispose);
      await pumpEventQueue();
      controller.add(_snapshot(21));
      await pumpEventQueue();
      expect(notifier.state.hasMore, isTrue);

      unawaited(notifier.loadNextPage());
      await pumpEventQueue();
      controller.add(_snapshot(25, fromCache: true));
      await pumpEventQueue();
      expect(notifier.state.documents, hasLength(25));
      expect(notifier.state.hasMore, isTrue);
      expect(notifier.state.isLoadingMore, isTrue);

      controller.add(_snapshot(30));
      await pumpEventQueue();
      expect(notifier.state.hasMore, isFalse);
      expect(notifier.state.isLoadingMore, isFalse);
    });

    test('refresh keeps the loaded depth', () async {
      final repo = _repoWithTotal(50);
      final notifier = PaginatedEnquiriesNotifier(repository: repo, isAdmin: true);
      addTearDown(notifier.dispose);
      await pumpEventQueue();
      await notifier.loadNextPage();

      await notifier.refresh();
      verify(
        () => repo.watchEnquiriesPage(isAdmin: true, assignedTo: null, status: null, limit: 41),
      ).called(2);
      expect(notifier.state.documents, hasLength(40));
    });

    test('stream errors surface as state.error', () async {
      final controller = StreamController<QuerySnapshot<Map<String, dynamic>>>();
      addTearDown(controller.close);
      final notifier = PaginatedEnquiriesNotifier(
        repository: _repo(controller: controller),
        isAdmin: true,
      );
      addTearDown(notifier.dispose);

      controller.addError(Exception('permission-denied'));
      await pumpEventQueue();
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, contains('permission-denied'));
    });
  });

  group('paginatedEnquiriesProvider', () {
    ProviderContainer containerFor(
      MockEnquiryRepository repo, {
      required Stream<UserRole> role,
      required String uid,
    }) {
      return ProviderContainer(
        overrides: [
          enquiryRepositoryProvider.overrideWithValue(repo),
          roleProvider.overrideWith((ref) => role),
          currentUserWithFirestoreProvider.overrideWith(
            (ref) => Stream.value(
              UserModel(uid: uid, name: 'U', email: 'u@x.com', phone: '', role: UserRole.staff),
            ),
          ),
        ],
      );
    }

    test('stays loading without querying while the role is unresolved', () async {
      final repo = _repo();
      final container = containerFor(repo, role: const Stream.empty(), uid: 'staff1');
      addTearDown(container.dispose);

      final sub = container.listen(paginatedEnquiriesProvider(const PaginationParams()), (_, _) {});
      addTearDown(sub.close);
      await pumpEventQueue();

      expect(sub.read().isLoading, isTrue);
      _verifyNeverWatched(repo);
    });

    test('admin gets an unscoped query once the role resolves', () async {
      final repo = _repo();
      final container = containerFor(repo, role: Stream.value(UserRole.admin), uid: 'admin1');
      addTearDown(container.dispose);

      final sub = container.listen(paginatedEnquiriesProvider(const PaginationParams()), (_, _) {});
      addTearDown(sub.close);
      await pumpEventQueue();

      expect(sub.read().isLoading, isFalse);
      verifyNever(
        () => repo.watchEnquiriesPage(
          isAdmin: false,
          assignedTo: any(named: 'assignedTo'),
          status: any(named: 'status'),
          limit: any(named: 'limit'),
        ),
      );
      verify(
        () => repo.watchEnquiriesPage(
          isAdmin: true,
          assignedTo: any(named: 'assignedTo'),
          status: null,
          limit: 21,
        ),
      ).called(greaterThanOrEqualTo(1));
    });

    test('staff get a query scoped to their uid', () async {
      final repo = _repo();
      final container = containerFor(repo, role: Stream.value(UserRole.staff), uid: 'staff1');
      addTearDown(container.dispose);

      final sub = container.listen(paginatedEnquiriesProvider(const PaginationParams()), (_, _) {});
      addTearDown(sub.close);
      await pumpEventQueue();

      verify(
        () =>
            repo.watchEnquiriesPage(isAdmin: false, assignedTo: 'staff1', status: null, limit: 21),
      ).called(greaterThanOrEqualTo(1));
    });
  });
}
