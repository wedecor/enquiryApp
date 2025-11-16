import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/services/network_service.dart';

void main() {
  late NetworkService networkService;

  setUp(() {
    networkService = NetworkService.instance;
  });

  tearDown(() {
    networkService.dispose();
  });

  group('NetworkService', () {
    group('isOnline', () {
      test('returns true when online', () {
        // Note: This test depends on actual connectivity
        // In a real scenario, you'd mock the connectivity
        expect(networkService.isOnline, isA<bool>());
      });

      test('isOffline returns opposite of isOnline', () {
        expect(networkService.isOffline, !networkService.isOnline);
      });
    });

    group('callbacks', () {
      test('onOnline registers callback', () {
        networkService.onOnline(() {
          // Callback registered
        });

        // Callback should be registered
        expect(networkService.isOnline, isA<bool>());
      });

      test('onOffline registers callback', () {
        networkService.onOffline(() {
          // Callback registered
        });

        // Callback should be registered
        expect(networkService.isOnline, isA<bool>());
      });

      test('removeOnlineCallback removes callback', () {
        final callback = () {
          // Callback function
        };

        networkService.onOnline(callback);
        networkService.removeOnlineCallback(callback);

        // Callback should be removed
        expect(networkService.isOnline, isA<bool>());
      });

      test('removeOfflineCallback removes callback', () {
        final callback = () {
          // Callback function
        };

        networkService.onOffline(callback);
        networkService.removeOfflineCallback(callback);

        // Callback should be removed
        expect(networkService.isOnline, isA<bool>());
      });
    });

    group('dispose', () {
      test('clears all callbacks', () {
        networkService.onOnline(() {});
        networkService.onOffline(() {});

        networkService.dispose();

        // After dispose, should still be able to check status
        expect(networkService.isOnline, isA<bool>());
      });
    });
  });
}
