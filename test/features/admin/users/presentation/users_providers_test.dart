import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/admin/users/presentation/users_providers.dart';

void main() {
  group('UsersFilter', () {
    late UsersFilter filter;

    setUp(() {
      filter = UsersFilter();
    });

    test('should initialize with default values', () {
      final state = filter.state;
      
      expect(state['search'], '');
      expect(state['role'], 'All');
      expect(state['active'], null);
      expect(state['limit'], 20);
      expect(state['startAfterEmail'], null);
    });

    test('should update search correctly', () {
      filter.updateSearch('john');
      
      final state = filter.state;
      expect(state['search'], 'john');
      expect(state['startAfterEmail'], null); // should reset pagination
    });

    test('should update role correctly', () {
      filter.updateRole('admin');
      
      final state = filter.state;
      expect(state['role'], 'admin');
      expect(state['startAfterEmail'], null); // should reset pagination
    });

    test('should update active status correctly', () {
      filter.updateActive(true);
      
      final state = filter.state;
      expect(state['active'], true);
      expect(state['startAfterEmail'], null); // should reset pagination
      
      filter.updateActive(null);
      
      final newState = filter.state;
      expect(newState['active'], null);
    });

    test('should load more correctly', () {
      filter.loadMore('last@example.com');
      
      final state = filter.state;
      expect(state['startAfterEmail'], 'last@example.com');
      expect(state['search'], ''); // other filters should remain unchanged
      expect(state['role'], 'All');
      expect(state['active'], null);
    });

    test('should reset to default values', () {
      // First modify some values
      filter.updateSearch('test');
      filter.updateRole('staff');
      filter.updateActive(true);
      filter.loadMore('test@example.com');
      
      // Then reset
      filter.reset();
      
      final state = filter.state;
      expect(state['search'], '');
      expect(state['role'], 'All');
      expect(state['active'], null);
      expect(state['limit'], 20);
      expect(state['startAfterEmail'], null);
    });

    test('should handle role filter combinations', () {
      // Test all role combinations
      const roles = ['All', 'admin', 'staff'];
      
      for (final role in roles) {
        filter.updateRole(role);
        expect(filter.state['role'], role);
      }
    });

    test('should handle active filter combinations', () {
      // Test all active combinations
      const activeValues = [null, true, false];
      
      for (final active in activeValues) {
        filter.updateActive(active);
        expect(filter.state['active'], active);
      }
    });
  });

  group('PaginationState', () {
    test('should initialize with default values', () {
      const state = PaginationState();
      
      expect(state.hasMore, false);
      expect(state.isLoading, false);
      expect(state.lastEmail, null);
    });

    test('should copyWith correctly', () {
      const original = PaginationState();
      
      final updated = original.copyWith(
        hasMore: true,
        isLoading: true,
        lastEmail: 'test@example.com',
      );
      
      expect(updated.hasMore, true);
      expect(updated.isLoading, true);
      expect(updated.lastEmail, 'test@example.com');
    });

    test('should copyWith with partial updates', () {
      const original = PaginationState(
        hasMore: true,
        isLoading: false,
        lastEmail: 'original@example.com',
      );
      
      final updated = original.copyWith(
        isLoading: true,
      );
      
      expect(updated.hasMore, true); // unchanged
      expect(updated.isLoading, true); // changed
      expect(updated.lastEmail, 'original@example.com'); // unchanged
    });
  });

  group('PaginationStateNotifier', () {
    late PaginationStateNotifier notifier;

    setUp(() {
      notifier = PaginationStateNotifier();
    });

    test('should set hasMore correctly', () {
      notifier.setHasMore(true);
      expect(notifier.state.hasMore, true);
      
      notifier.setHasMore(false);
      expect(notifier.state.hasMore, false);
    });

    test('should set loading state correctly', () {
      notifier.setLoading(true);
      expect(notifier.state.isLoading, true);
      
      notifier.setLoading(false);
      expect(notifier.state.isLoading, false);
    });

    test('should set last email correctly', () {
      notifier.setLastEmail('test@example.com');
      expect(notifier.state.lastEmail, 'test@example.com');
      
      notifier.setLastEmail('another@example.com');
      expect(notifier.state.lastEmail, 'another@example.com');
    });

    test('should reset to default state', () {
      // First set some values
      notifier.setHasMore(true);
      notifier.setLoading(true);
      notifier.setLastEmail('test@example.com');
      
      // Then reset
      notifier.reset();
      
      final state = notifier.state;
      expect(state.hasMore, false);
      expect(state.isLoading, false);
      expect(state.lastEmail, null);
    });
  });
}

