import 'auth_json.dart';

enum OtpPurpose {
  signup('signup'),
  login('login'),
  passwordReset('password_reset');

  const OtpPurpose(this.value);
  final String value;
}

/// Sensitive challenge credentials remain in memory; never store as a session.
final class OtpAttempt {
  const OtpAttempt._({
    required this.id,
    required this.token,
    required this.purpose,
    required this.expiresAt,
    this.maskedPhoneNumber,
  });
  final String id;
  final String token;
  final OtpPurpose purpose;
  final DateTime expiresAt;
  final String? maskedPhoneNumber;

  factory OtpAttempt.fromJson(Map<String, dynamic> json) {
    final id = authString(json['attempt_id']);
    if (json['authenticated'] != false ||
        !RegExp(
          r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$',
        ).hasMatch(id)) {
      throw const FormatException('Invalid OTP attempt.');
    }
    final purpose = switch (json['purpose']) {
      'signup' => OtpPurpose.signup,
      'login' => OtpPurpose.login,
      'password_reset' => OtpPurpose.passwordReset,
      _ => throw const FormatException('Invalid OTP purpose.'),
    };
    return OtpAttempt._(
      id: id,
      token: authSecret(json['attempt_token']),
      purpose: purpose,
      expiresAt: authTimestamp(json['expires_at']),
      maskedPhoneNumber: json['masked_phone_number'] is String
          ? json['masked_phone_number'] as String
          : null,
    );
  }

  Map<String, dynamic> toRequest() => {
    'attempt_id': id,
    'attempt_token': token,
  };
  @override
  String toString() => 'OtpAttempt(redacted)';
}
