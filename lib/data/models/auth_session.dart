import '../../domain/models/app_user.dart';
import '../../domain/models/sanctum_token.dart';
import '../mappers/laravel_user_mapper.dart';

/// Parse the data object of registered/authenticated responses, never OTP steps.
final class AuthSession {
  const AuthSession({required this.user, required this.token});
  final AppUser user;
  final SanctumToken token;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    if (json['authenticated'] != true ||
        json['user'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid authenticated session response.');
    }
    return AuthSession(
      user: LaravelUserMapper.fromJson(json['user'] as Map<String, dynamic>),
      token: SanctumToken.fromJson(json),
    );
  }

  @override
  String toString() => 'AuthSession(redacted)';
}
