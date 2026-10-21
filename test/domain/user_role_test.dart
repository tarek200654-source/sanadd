import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/domain/models/user_role.dart';

void main() {
  group('UserRole', () {
    test('serializes patient and caregiver values', () {
      expect(UserRole.patient.value, 'patient');
      expect(UserRole.caregiver.value, 'caregiver');
    });

    test('parses valid Firestore values', () {
      expect(userRoleFromString('patient'), UserRole.patient);
      expect(userRoleFromString('caregiver'), UserRole.caregiver);
    });

    test('rejects unknown or invalid values explicitly', () {
      expect(
        () => userRoleFromString('doctor'),
        throwsA(isA<InvalidUserRoleException>()),
      );
      expect(
        () => userRoleFromString(null),
        throwsA(isA<InvalidUserRoleException>()),
      );
    });
  });
}
