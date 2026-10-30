import '../../domain/models/user_role.dart';
import '../../domain/models/registration_data.dart';

/// Auth state carried between an auth form and the Wexora OTP screen.
/// Password is kept in memory only while the OTP flow is active.
class AuthRouteArguments {
  const AuthRouteArguments({
    required this.role,
    this.email,
    this.phoneNumber,
    this.name,
    this.password,
    this.registrationData,
    this.isLoginVerification = false,
  });

  final UserRole role;
  final String? email;
  final String? phoneNumber;
  final String? name;
  final String? password;
  final RegistrationData? registrationData;
  final bool isLoginVerification;

  AuthRouteArguments copyWith({
    UserRole? role,
    String? email,
    String? phoneNumber,
    String? name,
    String? password,
    RegistrationData? registrationData,
    bool? isLoginVerification,
  }) {
    return AuthRouteArguments(
      role: role ?? this.role,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      password: password ?? this.password,
      registrationData: registrationData ?? this.registrationData,
      isLoginVerification: isLoginVerification ?? this.isLoginVerification,
    );
  }
}
