import '../../application/auth/auth_failure.dart';

/// Server messages are available for inspection but are not localization keys.
/// This exception never retains raw responses, requests or underlying errors.
final class ApiException implements Exception {
  ApiException({
    required this.code,
    this.statusCode,
    Map<String, List<String>> fieldCodes = const {},
    Map<String, List<String>> fieldErrors = const {},
  }) : fieldCodes = _freeze(fieldCodes),
       fieldErrors = _freeze(fieldErrors);

  final String code;
  final int? statusCode;
  final Map<String, List<String>> fieldCodes;
  final Map<String, List<String>> fieldErrors;

  factory ApiException.fromResponse(int status, Map<String, dynamic>? json) {
    final rawCode = json?['code'];
    final fallback = switch (status) {
      401 => 'unauthenticated',
      422 => 'validation-failed',
      429 => 'too-many-requests',
      _ => 'server-error',
    };
    return ApiException(
      code: _codes.contains(rawCode) ? rawCode as String : fallback,
      statusCode: status,
      fieldCodes: _fields(json?['error_codes']),
      fieldErrors: _fields(json?['errors']),
    );
  }

  /// Reuses existing auth failure categories without changing screen handling.
  AuthFailure toAuthFailure() => AuthFailure(switch (code) {
    'email-already-in-use' => AuthFailureType.emailAlreadyInUse,
    'invalid-email' => AuthFailureType.invalidEmail,
    'weak-password' => AuthFailureType.weakPassword,
    'invalid-credentials' => AuthFailureType.invalidCredentials,
    'network-request-failed' || 'request-timeout' => AuthFailureType.network,
    'too-many-requests' => AuthFailureType.tooManyRequests,
    _ => AuthFailureType.unknown,
  });

  static const _codes = {
    'caregiver-not-found',
    'relationship-not-found',
    'forbidden',
    'duplicate-live-relationship',
    'caregiver-slots-full',
    'invalid-relationship-state',
    'validation-failed',
    'invalid-credentials',
    'unauthenticated',
    'invalid-code',
    'invalid-challenge',
    'otp-expired',
    'too-many-requests',
    'challenge-used',
    'profile-incomplete',
    'account-changed',
    'weak-password',
    'email-already-in-use',
    'username-taken',
    'otp-service-unavailable',
  };

  static Map<String, List<String>> _fields(Object? value) {
    if (value is! Map<String, dynamic>) return {};
    return {
      for (final entry in value.entries)
        if (entry.value is List &&
            (entry.value as List).every((v) => v is String))
          entry.key: List<String>.from(entry.value as List),
    };
  }

  static Map<String, List<String>> _freeze(Map<String, List<String>> value) =>
      Map.unmodifiable({
        for (final entry in value.entries)
          entry.key: List<String>.unmodifiable(entry.value),
      });

  @override
  String toString() => 'ApiException(status: $statusCode)';
}
