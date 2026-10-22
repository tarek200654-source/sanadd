import 'user_role.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.username,
    this.firstName,
    this.lastName,
    this.country,
    this.region,
    this.address,
    this.phoneNumber,
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? country;
  final String? region;
  final String? address;
  final String? phoneNumber;
  final DateTime? createdAt;

  bool get hasCompleteRegistrationProfile =>
      _hasValue(username) &&
      _hasValue(firstName) &&
      _hasValue(lastName) &&
      _hasValue(country) &&
      _hasValue(region) &&
      _hasValue(address) &&
      _hasValue(phoneNumber);

  factory AppUser.fromFirestore({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    return AppUser.fromMap(uid, data);
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    final normalizedUid = _requiredString(uid, 'uid');
    final name = _requiredString(data['name'], 'name');
    final email = _requiredString(data['email'], 'email');
    final createdAtValue = data['createdAt'];

    DateTime? createdAt;
    if (createdAtValue == null) {
      createdAt = null;
    } else if (createdAtValue is DateTime) {
      createdAt = createdAtValue;
    } else {
      throw FormatException('Invalid createdAt value for user $normalizedUid.');
    }

    return AppUser(
      uid: normalizedUid,
      name: name,
      email: email,
      role: userRoleFromString(data['role']),
      username: data['username'] as String?,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      country: data['country'] as String?,
      region: data['region'] as String?,
      address: data['address'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'name': name,
      'email': email,
      'role': role.value,
    };

    _addIfPresent(data, 'username', username);
    _addIfPresent(data, 'firstName', firstName);
    _addIfPresent(data, 'lastName', lastName);
    _addIfPresent(data, 'country', country);
    _addIfPresent(data, 'region', region);
    _addIfPresent(data, 'address', address);

    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      data['phoneNumber'] = phoneNumber;
    }

    if (createdAt != null) {
      data['createdAt'] = createdAt;
    }

    return data;
  }

  static void _addIfPresent(
    Map<String, dynamic> data,
    String key,
    String? value,
  ) {
    if (value != null && value.isNotEmpty) data[key] = value;
  }

  static String _requiredString(Object? value, String fieldName) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    throw FormatException('Invalid $fieldName value for AppUser.');
  }

  static bool _hasValue(String? value) =>
      value != null && value.trim().isNotEmpty;
}
