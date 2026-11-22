import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:we_decor_enquiries/core/eventos/eventos_auth.dart';
import 'package:we_decor_enquiries/core/eventos/eventos_client.dart';
import 'package:we_decor_enquiries/core/eventos/eventos_config.dart';
import 'package:we_decor_enquiries/core/logging/logger.dart';
import 'package:we_decor_enquiries/core/logging/safe_log.dart';

class _MemoryStorage implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _data[key];

  @override
  Future<void> delete({
    required String key,
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('$invocation');
}

Map<String, dynamic> _sessionBody({required String access, required String refresh, String? code}) {
  if (code != null) {
    return {
      'error': {'code': code, 'message': 'denied'},
    };
  }
  return {
    'data': {
      'accessToken': access,
      'refreshToken': refresh,
      'expiresIn': 900,
      'user': {
        'id': 'u1',
        'name': 'Ilyas',
        'role': 'owner',
        'permissions': ['bookings:read'],
      },
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    EventosConfig.debugApiBaseUrlOverride = 'https://eventos-api-staging.test';
  });
  tearDown(() {
    EventosConfig.debugApiBaseUrlOverride = null;
  });

  group('token redaction', () {
    test('accessToken / refreshToken / authorization never appear in logs', () {
      final map = createSafeLogMap({
        'accessToken': 'super-secret-access-token-value',
        'refreshToken': 'super-secret-refresh-token-value',
        'authorization': 'Bearer abc.def.ghi',
      });
      expect(map['accessToken'], isNot(contains('super-secret')));
      expect(map['refreshToken'], isNot(contains('super-secret')));
      expect(map['authorization'], isNot(contains('Bearer abc')));

      final free = formatLogData({'note': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.aaa.bbb'});
      expect(free, isNot(contains('eyJhbGciOi')));
    });
  });

  group('EventosAuth', () {
    test('exchange success stores refresh token and sets connected', () async {
      final storage = _MemoryStorage();
      final mock = MockClient((request) async {
        expect(request.url.path, contains('/auth/firebase/exchange'));
        return http.Response(
          jsonEncode(_sessionBody(access: 'access-1', refresh: 'refresh-1')),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final auth = EventosAuth(
        secureStorage: storage,
        httpClient: mock,
        idTokenProvider: () async => 'firebase-id-token',
      );

      final session = await auth.testConnection();
      expect(session?.accessToken, 'access-1');
      expect(await storage.read(key: 'eventos_refresh_token'), 'refresh-1');
      expect(auth.state, EventosConnectionState.connected);
      expect(auth.user?.role, 'owner');
    });

    test('403 IDENTITY_NOT_LINKED → notLinked', () async {
      final storage = _MemoryStorage();
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode(_sessionBody(access: '', refresh: '', code: 'IDENTITY_NOT_LINKED')),
          403,
          headers: {'content-type': 'application/json'},
        );
      });
      final auth = EventosAuth(
        secureStorage: storage,
        httpClient: mock,
        idTokenProvider: () async => 'firebase-id-token',
      );
      final session = await auth.testConnection();
      expect(session, isNull);
      expect(auth.state, EventosConnectionState.notLinked);
    });

    test('clearOnSignOut deletes refresh token', () async {
      final storage = _MemoryStorage();
      await storage.write(key: 'eventos_refresh_token', value: 'refresh-keep');
      final mock = MockClient((_) async => http.Response('{}', 200));
      final auth = EventosAuth(
        secureStorage: storage,
        httpClient: mock,
        idTokenProvider: () async => 'x',
      );
      auth.debugSetAccessToken('access');
      await auth.clearOnSignOut();
      expect(await storage.read(key: 'eventos_refresh_token'), isNull);
      expect(auth.accessToken, isNull);
    });
  });

  group('EventosClient', () {
    test('401 → refresh → retry', () async {
      var healthCalls = 0;
      final storage = _MemoryStorage();
      await storage.write(key: 'eventos_refresh_token', value: 'refresh-1');

      final mock = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          return http.Response(
            jsonEncode(_sessionBody(access: 'access-2', refresh: 'refresh-2')),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/health')) {
          healthCalls += 1;
          final authHeader = request.headers['Authorization'] ?? '';
          if (authHeader.contains('access-stale')) {
            return http.Response('unauthorized', 401);
          }
          expect(authHeader, contains('access-2'));
          return http.Response('{"ok":true}', 200);
        }
        return http.Response('nope', 404);
      });

      final auth = EventosAuth(
        secureStorage: storage,
        httpClient: mock,
        idTokenProvider: () async => 'firebase-id-token',
      );
      auth.debugSetAccessToken('access-stale');
      final client = EventosClient(auth: auth, httpClient: mock);
      final res = await client.get('/api/v1/health');
      expect(res.statusCode, 200);
      expect(healthCalls, 2);
    });

    test('refresh fail → re-exchange', () async {
      final storage = _MemoryStorage();
      await storage.write(key: 'eventos_refresh_token', value: 'bad-refresh');
      var exchanged = false;

      final mock = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          return http.Response('nope', 401);
        }
        if (request.url.path.endsWith('/auth/firebase/exchange')) {
          exchanged = true;
          return http.Response(
            jsonEncode(_sessionBody(access: 'access-new', refresh: 'refresh-new')),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/health')) {
          final authHeader = request.headers['Authorization'] ?? '';
          if (authHeader.contains('access-stale')) {
            return http.Response('unauthorized', 401);
          }
          return http.Response('{"ok":true}', 200);
        }
        return http.Response('nope', 404);
      });

      final auth = EventosAuth(
        secureStorage: storage,
        httpClient: mock,
        idTokenProvider: () async => 'firebase-id-token',
      );
      auth.debugSetAccessToken('access-stale');
      final client = EventosClient(auth: auth, httpClient: mock);
      final res = await client.get('/api/v1/health');
      expect(res.statusCode, 200);
      expect(exchanged, isTrue);
    });
  });
}
