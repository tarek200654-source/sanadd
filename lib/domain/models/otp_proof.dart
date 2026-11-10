import 'auth_json.dart';
import 'otp_attempt.dart';

final class OtpProof {
  const OtpProof._({
    required this.value,
    required this.expiresAt,
    required this.purpose,
  });
  final String value;
  final DateTime expiresAt;
  final OtpPurpose purpose;

  factory OtpProof.fromJson(
    Map<String, dynamic> json, {
    required OtpPurpose purpose,
  }) {
    if (json['authenticated'] != false || purpose == OtpPurpose.login) {
      throw const FormatException('Invalid OTP proof response.');
    }
    return OtpProof._(
      value: authSecret(
        json[purpose == OtpPurpose.signup
            ? 'verification_proof'
            : 'reset_proof'],
      ),
      expiresAt: authTimestamp(json['expires_at']),
      purpose: purpose,
    );
  }

  @override
  String toString() => 'OtpProof(redacted)';
}
