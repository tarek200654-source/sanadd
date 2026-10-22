import 'user_role.dart';

/// Account fields collected by the existing multi-step registration flow.
/// Password remains in memory only until Firebase Authentication accepts it.
class RegistrationData {
  const RegistrationData({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.role,
    required this.country,
    required this.region,
    required this.address,
    required this.phoneNumber,
  });

  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final UserRole role;
  final String country;
  final String region;
  final String address;
  final String phoneNumber;

  String get fullName => '${firstName.trim()} ${lastName.trim()}'.trim();
}
