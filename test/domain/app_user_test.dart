import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/domain/models/app_user.dart';
import 'package:sanad/domain/models/user_role.dart';

void main() {
  group('AppUser', () {
    test('serializes to a Firestore-compatible map', () {
      final createdAt = DateTime.utc(2026, 10, 17, 12, 30);
      const user = AppUser(
        uid: 'abc123',
        name: 'Amina Hassan',
        email: 'amina@example.com',
        role: UserRole.patient,
        createdAt: null,
      );
      final withTimestamp = AppUser(
        uid: user.uid,
        name: user.name,
        email: user.email,
        role: user.role,
        phoneNumber: '+201012345678',
        createdAt: createdAt,
      );

      expect(withTimestamp.toFirestore(), {
        'name': 'Amina Hassan',
        'email': 'amina@example.com',
        'role': 'patient',
        'phoneNumber': '+201012345678',
        'createdAt': createdAt,
      });
      expect(user.toFirestore(), {
        'name': 'Amina Hassan',
        'email': 'amina@example.com',
        'role': 'patient',
      });
    });

    test('deserializes user data and converts the role', () {
      final createdAt = DateTime.utc(2026, 10, 17, 12, 30);
      final user = AppUser.fromFirestore(
        uid: 'abc123',
        data: {
          'name': 'Omar Ali',
          'email': 'omar@example.com',
          'role': 'caregiver',
          'createdAt': createdAt,
        },
      );

      expect(user.uid, 'abc123');
      expect(user.name, 'Omar Ali');
      expect(user.email, 'omar@example.com');
      expect(user.role, UserRole.caregiver);
      expect(user.createdAt, createdAt);
    });

    test('rejects invalid role data', () {
      expect(
        () => AppUser.fromFirestore(
          uid: 'abc123',
          data: {
            'name': 'Omar Ali',
            'email': 'omar@example.com',
            'role': 'unknown',
          },
        ),
        throwsA(isA<InvalidUserRoleException>()),
      );
    });
  });
}
