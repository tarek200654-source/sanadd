import 'package:sanad/application/auth/auth_service.dart';
import 'package:sanad/domain/models/app_user.dart';
import 'package:sanad/domain/models/user_role.dart';
import 'package:sanad/domain/repositories/auth_repository.dart';
import 'package:sanad/domain/repositories/user_repository.dart';

// Test-only account: no Firebase requests or credentials are used in UI checks.
class DashboardTestAuth extends AuthService {
  DashboardTestAuth()
    : super(authRepository: _Auth(), userRepository: _Users());
  bool signedOut = false;
  @override
  Future<AppUser?> getCurrentUserProfile() async => const AppUser(
    uid: 'test',
    name: 'SANAD User',
    firstName: 'SANAD',
    lastName: 'User',
    email: 'test@example.com',
    role: UserRole.patient,
    username: 'test',
    country: 'Egypt',
    region: 'Cairo',
    address: 'Test address',
    phoneNumber: '+201000000000',
  );
  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

class _Auth implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Users implements UserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
