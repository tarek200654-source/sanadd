import 'dart:async';
import 'dart:convert';
import 'dart:io';

abstract interface class OtpVerificationRepository {
  Future<OtpChallenge> sendCode({
    required String phoneNumber,
    required String language,
  });

  Future<bool> verifyCode({required String challengeId, required String code});
}

class WexoraOtpException implements Exception {
  const WexoraOtpException(this.code);

  final String code;
}

class WexoraOtpRepository implements OtpVerificationRepository {
  WexoraOtpRepository({HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient();

  static const _apiBaseUrl = 'https://wexora.pro/api/v1';
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
    return OtpChallenge(id: challengeId, expiresAt: expiresAt);
  }

  @override
  Future<bool> verifyCode({
    required String challengeId,
    required String code,
  }) async {
    final data = await _post('/otp/$challengeId/verify', {
      'code': code,
    });
    return data['verified'] == true;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, String> body,
  ) async {
    if (_apiKey.isEmpty || _sessionId.isEmpty) {
      throw const WexoraOtpException('credentials-not-configured');
    }

    try {
      return await _sendAndRead(Uri.parse('$_apiBaseUrl$path'), body).timeout(
        const Duration(seconds: 20),
      );
    } on WexoraOtpException {
      rethrow;
    } on TimeoutException {
      throw const WexoraOtpException('timeout');
    } on SocketException {
      throw const WexoraOtpException('unavailable');
    } on HttpException {
      throw const WexoraOtpException('unavailable');
    } on FormatException {
      throw const WexoraOtpException('invalid-response');
    }
  }

  DateTime? _parseWexoraDate(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value) ?? DateTime.tryParse('${value.replaceFirst(' ', 'T')}Z');
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
      throw const WexoraOtpException('invalid-response');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WexoraOtpException(decoded['code'] as String? ?? 'unavailable');
    }
    return decoded;
  }
}

class OtpChallenge {
  const OtpChallenge({required this.id, required this.expiresAt});

  final String id;
  final DateTime expiresAt;
}
