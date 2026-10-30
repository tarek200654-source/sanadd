import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

abstract interface class OtpVerificationRepository {
  Future<OtpChallenge> sendCode({
    required String phoneNumber,
    required String language,
  });

  Future<bool> verifyCode({required String challengeId, required String code});

  Future<OtpDeliveryStatus> getDeliveryStatus(String challengeId) async =>
      OtpDeliveryStatus.unknown;
}

class WexoraOtpException implements Exception {
  const WexoraOtpException(this.code, {this.message, this.requestId});

  final String code;
  final String? message;
  final String? requestId;
}

class WexoraOtpRepository implements OtpVerificationRepository {
  WexoraOtpRepository({HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient();

  static const _apiBaseUrl = 'https://wexora.pro/api/v1';
  // Temporary local-development setup. These values are included in the app
  // build; never use this approach for a distributed release.
  static const _apiKey = String.fromEnvironment('WEXORA_API_KEY');
  static const _sessionId = String.fromEnvironment('WEXORA_SESSION_ID');

  final HttpClient _httpClient;

  @override
  Future<OtpChallenge> sendCode({
    required String phoneNumber,
    required String language,
  }) async {
    final data = await _post('/otp', {
      'session_id': _sessionId,
      'to': phoneNumber,
      'purpose': 'sanad_signup',
      'reference': 'sanad-signup-${DateTime.now().microsecondsSinceEpoch}',
      'language': language,
    });
    final expiresAt = _parseWexoraDate(data['expires_at'] as String?);
    final challengeId = data['id'];
    if (challengeId is! String || expiresAt == null) {
      throw const WexoraOtpException('invalid-response');
    }
    return OtpChallenge(
      id: challengeId,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<bool> verifyCode({
    required String challengeId,
    required String code,
  }) async {
    final data = await _post('/otp/$challengeId/verify', {'code': code});
    return data['verified'] == true;
  }

  @override
  Future<OtpDeliveryStatus> getDeliveryStatus(String challengeId) async {
    final data = await _get('/otp/$challengeId');
    return OtpDeliveryStatus.fromWexora(data['delivery_status']);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, String> body,
  ) async {
    if (_apiKey.isEmpty || _sessionId.isEmpty) {
      throw const WexoraOtpException('credentials-not-configured');
    }

    try {
      return await _sendAndRead(
        Uri.parse('$_apiBaseUrl$path'),
        body,
      ).timeout(const Duration(seconds: 20));
    } on WexoraOtpException {
      rethrow;
    } on TimeoutException {
      throw const WexoraOtpException('timeout');
    } on SocketException {
      throw const WexoraOtpException('unavailable');
    } on HttpException {
      throw const WexoraOtpException('unavailable');
    } on TlsException {
      throw const WexoraOtpException('unavailable');
    } on FormatException {
      throw const WexoraOtpException('invalid-response');
    }
  }

  Future<Map<String, dynamic>> _get(String path) async {
    if (_apiKey.isEmpty || _sessionId.isEmpty) {
      throw const WexoraOtpException('credentials-not-configured');
    }
    try {
      final request = await _httpClient.getUrl(Uri.parse('$_apiBaseUrl$path'));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey');
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        _logResponse('GET', path, response.statusCode, {'body': 'non-json'});
        throw const WexoraOtpException('invalid-response');
      }
      _logResponse('GET', path, response.statusCode, decoded);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded['error'] ?? decoded['message'];
        final code = decoded['code'];
        final requestId = decoded['request_id'] ?? decoded['requestId'];
        throw WexoraOtpException(
          code is String
              ? code
              : _errorCodeForStatus(response.statusCode, path),
          message: message is String ? message : null,
          requestId: requestId is String ? requestId : null,
        );
      }
      return decoded;
    } on WexoraOtpException {
      rethrow;
    } on TimeoutException {
      throw const WexoraOtpException('timeout');
    } on SocketException {
      throw const WexoraOtpException('unavailable');
    } on HttpException {
      throw const WexoraOtpException('unavailable');
    } on TlsException {
      throw const WexoraOtpException('unavailable');
    } on FormatException {
      throw const WexoraOtpException('invalid-response');
    }
  }

  DateTime? _parseWexoraDate(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value) ??
        DateTime.tryParse('${value.replaceFirst(' ', 'T')}Z');
  }

  Future<Map<String, dynamic>> _sendAndRead(
    Uri uri,
    Map<String, String> body,
  ) async {
    final request = await _httpClient.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey');
    if (uri.path.endsWith('/otp')) {
      request.headers.set(
        'Idempotency-Key',
        'sanad-${DateTime.now().microsecondsSinceEpoch}-${body['reference'] ?? 'verify'}',
      );
    }
    request.write(jsonEncode(body));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      _logResponse('POST', uri.path, response.statusCode, {'body': 'non-json'});
      throw const WexoraOtpException('invalid-response');
    }
    _logResponse('POST', uri.path, response.statusCode, decoded);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final serverMessage = decoded['error'] ?? decoded['message'];
      final serverCode = decoded['code'];
      final requestId = decoded['request_id'] ?? decoded['requestId'];
      throw WexoraOtpException(
        serverCode is String
            ? serverCode
            : _errorCodeForStatus(response.statusCode, uri.path),
        message: serverMessage is String ? serverMessage : null,
        requestId: requestId is String ? requestId : null,
      );
    }
    // Wexora accepts OTP creation requests with HTTP 202.
    if (uri.path.endsWith('/otp') && response.statusCode != 202) {
      throw WexoraOtpException(
        'unexpected-success-status',
        message: decoded['error'] is String ? decoded['error'] as String : null,
        requestId: (decoded['request_id'] ?? decoded['requestId']) is String
            ? (decoded['request_id'] ?? decoded['requestId']) as String
            : null,
      );
    }
    return decoded;
  }

  void _logResponse(
    String method,
    String path,
    int httpStatus,
    Map<String, dynamic> response,
  ) {
    // Log only response diagnostics. Never print credentials, phone numbers,
    // request bodies, or the one-time code.
    final details = <String, Object?>{
      'http': httpStatus,
      if (response['code'] is String) 'code': response['code'],
      if (response['error'] is String) 'error': response['error'],
      if (response['message'] is String) 'message': response['message'],
      if (response['request_id'] is String)
        'request_id': response['request_id'],
      if (response['requestId'] is String) 'requestId': response['requestId'],
      if (response['status'] is String) 'status': response['status'],
      if (response['delivery_status'] is String)
        'delivery_status': response['delivery_status'],
      if (response['verified'] is bool) 'verified': response['verified'],
      if (response['expires_at'] is String)
        'expires_at': response['expires_at'],
    };
    developer.log(
      'Wexora OTP $method $path response: $details',
      name: 'sanad.wexora.otp',
      level: httpStatus >= 400 ? 1000 : 800,
    );
  }

  String _errorCodeForStatus(int statusCode, String path) =>
      switch (statusCode) {
        401 => 'invalid-api-key',
        402 => 'billing-required',
        403 => 'missing-otp-permission',
        404 => path.endsWith('/verify') ? 'not-found' : 'session-not-found',
        409 => 'wexora-conflict',
        410 => 'not-found',
        422 => path.endsWith('/verify') ? 'invalid-code' : 'invalid-argument',
        429 => 'rate-limited',
        >= 500 => 'wexora-unavailable',
        _ => 'unavailable',
      };
}

class OtpChallenge {
  const OtpChallenge({
    required this.id,
    required this.expiresAt,
    this.deliveryStatus = OtpDeliveryStatus.unknown,
  });

  final String id;
  final DateTime expiresAt;
  final OtpDeliveryStatus deliveryStatus;
}

enum OtpDeliveryStatus {
  queued,
  sending,
  sent,
  delivered,
  failed,
  unknown;

  static OtpDeliveryStatus fromWexora(Object? value) => switch (value) {
    'queued' => queued,
    'sending' => sending,
    'sent' => sent,
    'delivered' => delivered,
    'failed' => failed,
    _ => unknown,
  };
}
