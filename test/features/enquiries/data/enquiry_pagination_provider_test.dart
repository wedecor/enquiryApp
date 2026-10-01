import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/core/providers/role_provider.dart';
import 'package:we_decor_enquiries/features/enquiries/data/enquiry_pagination_provider.dart';
import 'package:we_decor_enquiries/features/enquiries/data/enquiry_repository.dart';
import 'package:we_decor_enquiries/features/enquiries/data/pagination_state.dart';
import 'package:we_decor_enquiries/shared/models/user_model.dart';

class MockEnquiryRepository extends Mock implements EnquiryRepository {}

MockEnquiryRepository _repoReturningEmptyPage() {
  final repo = MockEnquiryRepository();
  when(
    () => repo.getPaginatedEnquiries(
      isAdmin: any(named: 'isAdmin'),
      assignedTo: any(named: 'assignedTo'),
      status: any(named: 'status'),
      lastDocument: any(named: 'lastDocument'),
      pageSize: any(named: 'pageSize'),
    ),
  ).thenAnswer((_) async => const PaginationState());
  return repo;
}

void main() {
  group('PaginatedEnquiriesNotifier', () {
    test('pageSize is 20 so Firestore reads at most 21 docs per request', () {
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

    test('loads the first page on construction', () async {
      final repo = _repoReturningEmptyPage();
      final notifier = PaginatedEnquiriesNotifier(repository: repo, isAdmin: true);
      expect(notifier.state.isLoading, isTrue);
      await pumpEventQueue();
      expect(notifier.state.isLoading, isFalse);
      verify(
        () =>
            repo.getPaginatedEnquiries(isAdmin: true, assignedTo: null, status: null, pageSize: 20),
      ).called(1);
    });

    test('does not query until ready', () async {
      final repo = _repoReturningEmptyPage();
      final notifier = PaginatedEnquiriesNotifier(repository: repo, isAdmin: false, ready: false);
      await notifier.loadFirstPage();
      expect(notifier.state.isLoading, isTrue);
      verifyNever(
        () => repo.getPaginatedEnquiries(
          isAdmin: any(named: 'isAdmin'),
          assignedTo: any(named: 'assignedTo'),
          status: any(named: 'status'),
          lastDocument: any(named: 'lastDocument'),
          pageSize: any(named: 'pageSize'),
        ),
      );
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
      final repo = _repoReturningEmptyPage();
      final container = containerFor(repo, role: const Stream.empty(), uid: 'staff1');
      addTearDown(container.dispose);

      final sub = container.listen(paginatedEnquiriesProvider(const PaginationParams()), (_, _) {});
      addTearDown(sub.close);
      await pumpEventQueue();

      expect(sub.read().isLoading, isTrue);
      verifyNever(
        () => repo.getPaginatedEnquiries(
          isAdmin: any(named: 'isAdmin'),
          assignedTo: any(named: 'assignedTo'),
          status: any(named: 'status'),
          lastDocument: any(named: 'lastDocument'),
          pageSize: any(named: 'pageSize'),
        ),
      );
    });

    test('admin gets an unscoped query once the role resolves', () async {
      final repo = _repoReturningEmptyPage();
      final container = containerFor(repo, role: Stream.value(UserRole.admin), uid: 'admin1');
      addTearDown(container.dispose);

      final sub = container.listen(paginatedEnquiriesProvider(const PaginationParams()), (_, _) {});
      addTearDown(sub.close);
      await pumpEventQueue();

      expect(sub.read().isLoading, isFalse);
      verifyNever(
        () => repo.getPaginatedEnquiries(
          isAdmin: false,
          assignedTo: any(named: 'assignedTo'),
          status: any(named: 'status'),
          lastDocument: any(named: 'lastDocument'),
          pageSize: any(named: 'pageSize'),
        ),
      );
      verify(
        () => repo.getPaginatedEnquiries(
          isAdmin: true,
          assignedTo: any(named: 'assignedTo'),
          status: null,
          pageSize: 20,
        ),
      ).called(greaterThanOrEqualTo(1));
    });
  });
}
