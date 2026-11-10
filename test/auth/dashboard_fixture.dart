import 'package:sanad/application/auth/auth_service.dart';
import 'package:sanad/domain/models/app_user.dart';
import 'package:sanad/domain/models/user_role.dart';
import '../support/laravel_auth_fixture.dart';

// Test-only profile fixture; never invokes a real provider.
class DashboardTestAuth extends AuthService {
  DashboardTestAuth() : this._(LaravelAuthFixture());
  DashboardTestAuth._(LaravelAuthFixture f)
    : super(api: f.api, tokenStore: f.tokens);
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
