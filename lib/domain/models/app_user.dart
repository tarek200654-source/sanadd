import 'user_role.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? phoneNumber;
  final DateTime? createdAt;

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

    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      data['phoneNumber'] = phoneNumber;
    }

    if (createdAt != null) {
      data['createdAt'] = createdAt;
    }

    return data;
  }

  static String _requiredString(Object? value, String fieldName) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    throw FormatException('Invalid $fieldName value for AppUser.');
  }
}
