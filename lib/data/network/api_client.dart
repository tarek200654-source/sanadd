import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/sanctum_token.dart';
import '../../domain/repositories/token_store.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// Transport only. Never saves tokens, retries OTP operations or navigates UI.
final class ApiClient {
  ApiClient({
    required this.config,
    required TokenStore tokenStore,
    http.Client? httpClient,
    DateTime Function()? now,
  }) : _tokens = tokenStore,
       _http = httpClient ?? http.Client(),
       _now = now ?? DateTime.now;

  final ApiConfig config;
  final TokenStore _tokens;
  final http.Client _http;
  final DateTime Function() _now;

  Future<Map<String, dynamic>?> get(
    String path, {
    bool authenticated = false,
    Map<String, String>? query,
    String? expectedToken,
  }) => _request(
    'GET',
    path,
    authenticated: authenticated,
    query: query,
    expectedToken: expectedToken,
  );
  Future<Map<String, dynamic>?> post(
    String path, {
    required Map<String, dynamic> body,
    bool authenticated = false,
    String? expectedToken,
  }) => _request(
    'POST',
    path,
    body: body,
    authenticated: authenticated,
    expectedToken: expectedToken,
  );

  Future<Map<String, dynamic>?> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    String? expectedToken,
    required bool authenticated,
  }) async {
    final endpoint = config.endpoint(path);
    final request = http.Request(
      method,
      query == null ? endpoint : endpoint.replace(queryParameters: query),
    )..followRedirects = false;
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    SanctumToken? attached;
    if (authenticated) {
      attached = await _tokens.read();
      if (attached == null) throw ApiException(code: 'unauthenticated');
      if (expectedToken != null && attached.value != expectedToken) {
        throw ApiException(code: 'session-changed');
      }
      if (attached.isExpired(_now())) {
        await _tokens.clearIfMatches(attached);
        throw ApiException(code: 'token-expired');
      }
      request.headers['Authorization'] = 'Bearer ${attached.value}';
    }
    try {
      final response = await (() async {
        final streamed = await _http.send(request);
        return http.Response.fromStream(streamed);
      })().timeout(config.timeout);
      // Invalidate even if a proxy returns a non-JSON 401 body.
      if (response.statusCode == 401 && attached != null) {
        await _tokens.clearIfMatches(attached);
      }
      Map<String, dynamic>? json;
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) json = decoded;
      } on FormatException {
        /* Never expose a response body or decoder error. */
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException.fromResponse(response.statusCode, json);
      }
      if (response.statusCode == 204) return null;
      if (json == null) {
        throw ApiException(
          code: 'invalid-response',
          statusCode: response.statusCode,
        );
      }
      return json;
    } on TimeoutException {
      throw ApiException(code: 'request-timeout');
    } on http.ClientException {
      throw ApiException(code: 'network-request-failed');
    }
  }

  /// Owns the injected client as well; call once when the app container closes.
  void close() => _http.close();
}
