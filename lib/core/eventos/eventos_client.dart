import 'dart:convert';

import 'package:http/http.dart' as http;

import '../logging/logger.dart';
import 'eventos_auth.dart';
import 'eventos_config.dart';

/// Authenticated HTTP client for EventOS. Retries once after refresh / re-exchange on 401.
class EventosClient {
  EventosClient({required EventosAuth auth, http.Client? httpClient})
    : _auth = auth,
      _http = httpClient ?? http.Client();

  final EventosAuth _auth;
  final http.Client _http;

  EventosAuth get auth => _auth;

  Future<http.Response> get(String relativePath) => _send('GET', relativePath);

  Future<http.Response> post(String relativePath, {Object? body}) =>
      _send('POST', relativePath, body: body);

  Future<http.Response> _send(
    String method,
    String relativePath, {
    Object? body,
    bool isRetry = false,
  }) async {
    if (!EventosConfig.isEnabled) {
      throw StateError('EventOS is disabled');
    }

    final token = await _auth.ensureAccessToken();
    if (token == null) {
      throw StateError('EventOS session unavailable');
    }

    final res = await _raw(method, relativePath, token: token, body: body);
    if (res.statusCode != 401 || isRetry) return res;

    Log.i('eventos_http_401_recover');
    final recovered = await _auth.recoverFromUnauthorized();
    if (recovered == null) return res;
    return _send(method, relativePath, body: body, isRetry: true);
  }

  Future<http.Response> _raw(
    String method,
    String relativePath, {
    required String token,
    Object? body,
  }) {
    final uri = Uri.parse(EventosConfig.path(relativePath));
    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };
    if (method == 'GET') return _http.get(uri, headers: headers);
    if (method == 'POST') {
      return _http.post(
        uri,
        headers: headers,
        body: body == null
            ? null
            : body is String
            ? body
            : jsonEncode(body),
      );
    }
    throw UnsupportedError('HTTP $method');
  }
}
