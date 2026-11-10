import 'auth_json.dart';

/// Opaque Sanctum personal access token, not a JWT or proof of a live session.
final class SanctumToken {
  SanctumToken({required String value, required DateTime expiresAt})
    : value = _value(value),
      expiresAt = expiresAt.toUtc();

  final String value;
  final DateTime expiresAt;

  factory SanctumToken.fromJson(Map<String, dynamic> json) {
    if (json['token_type'] != 'Bearer') {
      throw const FormatException('Invalid authentication token type.');
    }
    return SanctumToken(
      value: authString(json['token']),
      expiresAt: authTimestamp(json['expires_at']),
    );
  }

  bool isExpired(DateTime now) => !expiresAt.isAfter(now.toUtc());

  Map<String, dynamic> toJson() => {
    'token': value,
    'token_type': 'Bearer',
    'expires_at': expiresAt.toIso8601String(),
  };

  static String _value(String value) {
    if (value.isEmpty || RegExp(r'[\s\x00-\x1f\x7f]').hasMatch(value)) {
      throw const FormatException('Invalid authentication token.');
    }
    return value;
  }

  @override
  String toString() => 'SanctumToken(redacted)';
}
