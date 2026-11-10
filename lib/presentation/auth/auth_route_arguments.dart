import '../../domain/models/user_role.dart';

/// Display-only routing state. Secrets live in the app-owned auth flow.
class AuthRouteArguments {
  const AuthRouteArguments({
    required this.role,
    this.email,
    this.phoneNumber,
    this.isLoginVerification = false,
    this.isPasswordRecovery = false,
  });
  final UserRole role;
  final String? email;
  final String? phoneNumber;
  final bool isLoginVerification;
  final bool isPasswordRecovery;
  AuthRouteArguments copyWith({
    UserRole? role,
    String? email,
    String? phoneNumber,
    bool? isLoginVerification,
    bool? isPasswordRecovery,
  }) => AuthRouteArguments(
    role: role ?? this.role,
    email: email ?? this.email,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    isLoginVerification: isLoginVerification ?? this.isLoginVerification,
    isPasswordRecovery: isPasswordRecovery ?? this.isPasswordRecovery,
  );
}
