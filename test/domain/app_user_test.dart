import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/domain/models/app_user.dart';
import 'package:sanad/domain/models/user_role.dart';

void main() {
  test('serializes the complete profile without credentials', () {
    const user = AppUser(
      uid: 'uid-1',
      name: 'أحمد O’Neill',
      email: 'first.last+tag@example.com',
      role: UserRole.caregiver,
      username: 'Ahmad_1',
      firstName: 'أحمد',
      lastName: 'O’Neill',
      country: 'مصر',
      region: 'القاهرة',
      address: 'شارع التحرير، 12',
      phoneNumber: '+201012345678',
    );

    final data = user.toFirestore();

    expect(data['username'], 'Ahmad_1');
    expect(data['firstName'], 'أحمد');
    expect(data['lastName'], 'O’Neill');
    expect(data['country'], 'مصر');
    expect(data['region'], 'القاهرة');
    expect(data['address'], 'شارع التحرير، 12');
    expect(data['phoneNumber'], '+201012345678');
    expect(data.containsKey('password'), isFalse);
    expect(data.containsKey('passwordHash'), isFalse);

    final restored = AppUser.fromMap('uid-1', data);
    expect(restored.username, 'Ahmad_1');
    expect(restored.address, 'شارع التحرير، 12');
  });
}
