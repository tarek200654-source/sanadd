import '../../domain/models/app_user.dart';
import '../../domain/models/auth_json.dart';
import '../../domain/models/user_role.dart';

abstract final class LaravelUserMapper {
  static AppUser fromJson(Map<String, dynamic> json) {
    final role = switch (json['role']) {
      'patient' => UserRole.patient,
      'caregiver' => UserRole.caregiver,
      _ => throw const FormatException('Invalid user role.'),
    };
    return AppUser(
      uid: authString(json['id']),
      name: authString(json['name']),
      email: authString(json['email']),
      role: role,
      username: _optional(json['username']),
      firstName: _optional(json['first_name']),
      lastName: _optional(json['last_name']),
      phoneNumber: _optional(json['phone_number']),
      country: _optional(json['country']),
      region: _optional(json['region']),
      address: _optional(json['address']),
      createdAt: json['created_at'] == null
          ? null
          : authTimestamp(json['created_at']),
    );
  }

  static Map<String, dynamic> toJson(AppUser user) => {
    'id': user.uid,
    'name': user.name,
    'email': user.email,
    'role': user.role.value,
    'username': user.username,
    'first_name': user.firstName,
    'last_name': user.lastName,
    'phone_number': user.phoneNumber,
    'country': user.country,
    'region': user.region,
    'address': user.address,
    'created_at': user.createdAt?.toUtc().toIso8601String(),
  };

  static String? _optional(Object? value) {
    if (value == null || value is String) return value as String?;
    throw const FormatException('Invalid user profile field.');
  }
}
