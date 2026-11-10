import 'auth_json.dart';

/// Laravel accepted a real login/signup OTP send, not a delivery confirmation.
final class OtpDispatch {
  const OtpDispatch._({
    required this.attemptId,
    required this.expiresAt,
    required this.resendAt,
  });

  final String attemptId;
  final DateTime expiresAt;
  final DateTime resendAt;

  factory OtpDispatch.fromJson(Map<String, dynamic> json) {
    if (json['authenticated'] != false || json['otp_started'] != true) {
      throw const FormatException('Invalid OTP send response.');
    }
    return OtpDispatch._(
      attemptId: authString(json['attempt_id']),
      expiresAt: authTimestamp(json['expires_at']),
      resendAt: authTimestamp(json['resend_at']),
    );
  }

  @override
  String toString() => 'OtpDispatch';
}
