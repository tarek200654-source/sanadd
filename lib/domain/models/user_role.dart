enum UserRole { patient, caregiver }

extension UserRoleX on UserRole {
  String get value => switch (this) {
    UserRole.patient => 'patient',
    UserRole.caregiver => 'caregiver',
  };
}

UserRole userRoleFromString(Object? value) {
  if (value is! String) {
    throw InvalidUserRoleException(value);
  }

  return switch (value) {
    'patient' => UserRole.patient,
    'caregiver' => UserRole.caregiver,
    _ => throw InvalidUserRoleException(value),
  };
}

class InvalidUserRoleException implements Exception {
  const InvalidUserRoleException(this.value);

  final Object? value;

  @override
  String toString() => 'InvalidUserRoleException: unsupported role value.';
}
