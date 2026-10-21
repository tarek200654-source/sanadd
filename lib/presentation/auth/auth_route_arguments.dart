import '../../domain/models/user_role.dart';

/// Signup state carried between the form and the Wexora OTP screen.
/// Password is kept only in memory until OTP verification completes.
class AuthRouteArguments {
  const AuthRouteArguments({
    required this.role,
    this.email,
    this.phoneNumber,
    this.name,
    this.password,
  });

  final UserRole role;
  final String? email;
  final String? phoneNumber;
  final String? name;
  final String? password;

  AuthRouteArguments copyWith({
    UserRole? role,
    String? email,
    String? phoneNumber,
    String? name,
    String? password,
  }) {
    return AuthRouteArguments(
      role: role ?? this.role,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      password: password ?? this.password,
    );
  }
}
