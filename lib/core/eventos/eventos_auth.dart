import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../logging/logger.dart';
import 'eventos_config.dart';

/// Connection state for the EventOS bridge (admin tile only).
enum EventosConnectionState {
  disabled,
  connected,
  notLinked,
  disconnected,
}

class EventosUser {
  const EventosUser({
    required this.id,
    required this.name,
    required this.role,
    required this.permissions,
  });

  final String id;
  final String name;
  final String role;
  final List<String> permissions;

  factory EventosUser.fromJson(Map<String, dynamic> json) {
    final permissions = json['permissions'];
    return EventosUser(
      id: (json['id'] ?? json['userId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      permissions: permissions is List
          ? permissions.map((e) => e.toString()).toList()
          : const [],
    );
  }
}

class EventosSession {
  const EventosSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final EventosUser? user;
}

/// Firebase → EventOS token exchange + refresh (lazy; no startup cost).
class EventosAuth {
  EventosAuth({
    FirebaseAuth? firebaseAuth,
    FlutterSecureStorage? secureStorage,
    http.Client? httpClient,
    Future<String?> Function()? idTokenProvider,
  }) : _auth = firebaseAuth ?? FirebaseAuth.instance,
       _storage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
           ),
       _http = httpClient ?? http.Client(),
       _idTokenProvider = idTokenProvider;

  static const _refreshKey = 'eventos_refresh_token';

  final FirebaseAuth _auth;
  final FlutterSecureStorage _storage;
  final http.Client _http;
  final Future<String?> Function()? _idTokenProvider;

  String? _accessToken;
  EventosUser? _user;
  EventosConnectionState _state = EventosConfig.isEnabled
      ? EventosConnectionState.disconnected
      : EventosConnectionState.disabled;

  EventosConnectionState get state => _state;
  EventosUser? get user => _user;
  String? get accessToken => _accessToken;

  /// Ensures a valid access token (exchange or refresh). Lazy — call on demand.
  Future<String?> ensureAccessToken({bool forceExchange = false}) async {
    if (!EventosConfig.isEnabled) {
      _state = EventosConnectionState.disabled;
      return null;
    }

    if (!forceExchange && _accessToken != null) return _accessToken;

    try {
      if (!forceExchange) {
        final stored = await _storage.read(key: _refreshKey);
        if (stored != null && stored.isNotEmpty) {
          final refreshed = await _refresh(stored);
          if (refreshed != null) return refreshed.accessToken;
        }
      }
      return (await _exchange())?.accessToken;
    } on EventosNotLinkedException {
      _state = EventosConnectionState.notLinked;
      _accessToken = null;
      _user = null;
      return null;
    } catch (e) {
      Log.w('eventos_auth_failed', data: {'error': e.toString()}, tag: 'eventos');
      _state = EventosConnectionState.disconnected;
      _accessToken = null;
      return null;
    }
  }

  Future<EventosSession?> testConnection() async {
    if (!EventosConfig.isEnabled) {
      _state = EventosConnectionState.disabled;
      return null;
    }
    try {
      final session = await _exchange();
      return session;
    } on EventosNotLinkedException {
      _state = EventosConnectionState.notLinked;
      return null;
    } catch (e) {
      Log.w('eventos_test_failed', data: {'error': e.toString()}, tag: 'eventos');
      _state = EventosConnectionState.disconnected;
      return null;
    }
  }

  /// On 401: refresh once, then Firebase re-exchange once. Returns new access token or null.
  Future<String?> recoverFromUnauthorized() async {
    _accessToken = null;
    final stored = await _storage.read(key: _refreshKey);
    if (stored != null && stored.isNotEmpty) {
      final refreshed = await _refresh(stored);
      if (refreshed != null) return refreshed.accessToken;
    }
    try {
      final exchanged = await _exchange();
      return exchanged?.accessToken;
    } on EventosNotLinkedException {
      _state = EventosConnectionState.notLinked;
      return null;
    } catch (e) {
      Log.w('eventos_recover_failed', data: {'error': e.toString()}, tag: 'eventos');
      _state = EventosConnectionState.disconnected;
      return null;
    }
  }

  /// Clears local tokens and best-effort EventOS logout.
  Future<void> clearOnSignOut() async {
    final refresh = await _storage.read(key: _refreshKey);
    _accessToken = null;
    _user = null;
    await _storage.delete(key: _refreshKey);
    if (!EventosConfig.isEnabled) {
      _state = EventosConnectionState.disabled;
      return;
    }
    _state = EventosConnectionState.disconnected;
    if (refresh == null || refresh.isEmpty) return;
    try {
      await _http.post(
        Uri.parse(EventosConfig.path('/api/v1/auth/logout')),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'refreshToken': refresh}),
      );
    } catch (_) {
      // Best effort.
    }
  }

  Future<EventosSession?> _exchange() async {
    final idToken = await _resolveIdToken();
    if (idToken == null || idToken.isEmpty) {
      _state = EventosConnectionState.disconnected;
      return null;
    }

    final res = await _http.post(
      Uri.parse(EventosConfig.path('/api/v1/auth/firebase/exchange')),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'idToken': idToken, 'client': 'mobile'}),
    );

    if (res.statusCode == 403 && _errorCode(res.body) == 'IDENTITY_NOT_LINKED') {
      throw EventosNotLinkedException();
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw EventosHttpException(res.statusCode, 'exchange failed');
    }

    final session = _parseSession(res.body);
    await _applySession(session);
    return session;
  }

  Future<EventosSession?> _refresh(String refreshToken) async {
    final res = await _http.post(
      Uri.parse(EventosConfig.path('/api/v1/auth/refresh')),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
    final session = _parseSession(res.body, fallbackRefresh: refreshToken);
    await _applySession(session);
    return session;
  }

  Future<void> _applySession(EventosSession session) async {
    _accessToken = session.accessToken;
    _user = session.user;
    _state = EventosConnectionState.connected;
    if (session.refreshToken.isNotEmpty) {
      await _storage.write(key: _refreshKey, value: session.refreshToken);
    }
  }

  EventosSession _parseSession(String body, {String? fallbackRefresh}) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final data = (decoded['data'] is Map<String, dynamic>)
        ? decoded['data'] as Map<String, dynamic>
        : decoded;
    final access = (data['accessToken'] ?? '').toString();
    final refresh = (data['refreshToken'] ?? fallbackRefresh ?? '').toString();
    final expiresIn = data['expiresIn'] is int
        ? data['expiresIn'] as int
        : int.tryParse('${data['expiresIn']}') ?? 900;
    EventosUser? user;
    if (data['user'] is Map<String, dynamic>) {
      user = EventosUser.fromJson(data['user'] as Map<String, dynamic>);
    }
    if (access.isEmpty) throw StateError('accessToken missing');
    return EventosSession(
      accessToken: access,
      refreshToken: refresh,
      expiresIn: expiresIn,
      user: user,
    );
  }

  String? _errorCode(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final err = decoded['error'];
      if (err is Map<String, dynamic>) return err['code']?.toString();
    } catch (_) {}
    return null;
  }

  Future<String?> _resolveIdToken() async {
    if (_idTokenProvider != null) return _idTokenProvider!();
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return firebaseUser.getIdToken(true);
  }

  /// Test helper: seed an in-memory access token without calling the network.
  void debugSetAccessToken(String? token) {
    _accessToken = token;
    if (token != null) _state = EventosConnectionState.connected;
  }
}

class EventosNotLinkedException implements Exception {}

class EventosHttpException implements Exception {
  EventosHttpException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'EventosHttpException($statusCode): $message';
}
