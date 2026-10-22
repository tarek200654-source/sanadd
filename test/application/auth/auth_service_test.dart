import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/application/auth/auth_service.dart';
import 'package:sanad/application/auth/auth_failure.dart';
import 'package:sanad/application/auth/auth_service_exception.dart';
import 'package:sanad/domain/models/app_user.dart';
import 'package:sanad/domain/models/registration_data.dart';
import 'package:sanad/domain/models/user_role.dart';
import 'package:sanad/domain/repositories/auth_repository.dart';
import 'package:sanad/domain/repositories/user_repository.dart';

void main() {
  late _FakeAuthRepository auth;
  late _FakeUserRepository users;
  late AuthService service;

  const registration = RegistrationData(
    username: 'patient_1',
    firstName: 'سارة',
    lastName: 'أحمد',
    email: 'sara@example.com',
    password: r"a' OR 1=1 --A1!",
    role: UserRole.patient,
    country: 'مصر',
    region: 'القاهرة',
    address: 'شارع 1',
    phoneNumber: '+201012345678',
  );

  setUp(() {
    auth = _FakeAuthRepository();
    users = _FakeUserRepository();
    service = AuthService(authRepository: auth, userRepository: users);
  });

  test(
    'register creates auth credentials and the complete password-free profile',
    () async {
      final user = await service.register(registration);

      expect(auth.createdEmail, registration.email);
      expect(auth.createdPassword, registration.password);
      expect(user.username, registration.username);
      expect(user.firstName, registration.firstName);
      expect(users.created!.toFirestore().containsKey('password'), isFalse);
    },
  );

  test(
    'profile creation failure deletes the newly created auth account',
    () async {
      users.createError = const UserRepositoryException(
        UserRepositoryFailureType.usernameTaken,
      );

      await expectLater(
        service.register(registration),
        throwsA(
          isA<AuthServiceException>().having(
            (error) => error.type,
            'type',
            AuthServiceFailureType.usernameTaken,
          ),
        ),
      );
      expect(auth.deleted, isTrue);
    },
  );

  test('login with missing profile signs out', () async {
    users.profile = null;

    await expectLater(
      service.signIn(
        email: 'sara@example.com',
        password: registration.password,
      ),
      throwsA(isA<AuthServiceException>()),
    );
    expect(auth.signedOut, isTrue);
  });

  test('login propagates safe Firebase authentication failures', () async {
    auth.signInError = const AuthFailure(AuthFailureType.network);

    await expectLater(
      service.signIn(
        email: 'sara@example.com',
        password: registration.password,
      ),
      throwsA(
        isA<AuthFailure>().having(
          (error) => error.type,
          'type',
          AuthFailureType.network,
        ),
      ),
    );
  });

  test('session restoration signs out an incomplete profile', () async {
    users.profile = const AppUser(
      uid: 'uid-1',
      name: 'سارة أحمد',
      email: 'sara@example.com',
      role: UserRole.patient,
    );

    expect(await service.restoreCurrentUser(), isNull);
    expect(auth.signedOut, isTrue);
  });

  test('session restoration returns the current profile', () async {
    users.profile = _profile();

    expect((await service.restoreCurrentUser())?.uid, 'uid-1');
  });
}

AppUser _profile() => const AppUser(
  uid: 'uid-1',
  name: 'سارة أحمد',
  email: 'sara@example.com',
  role: UserRole.patient,
  username: 'patient_1',
  firstName: 'سارة',
  lastName: 'أحمد',
  country: 'مصر',
  region: 'القاهرة',
  address: 'شارع 1',
  phoneNumber: '+201012345678',
);

class _FakeAuthRepository implements AuthRepository {
  String? createdEmail;
  String? createdPassword;
  bool deleted = false;
  bool signedOut = false;
  Object? signInError;

  @override
  String? get currentUserId => 'uid-1';

  @override
  Stream<String?> authStateChanges() => const Stream.empty();

  @override
  Future<String> createAccount({
    required String email,
    required String password,
  }) async {
    createdEmail = email;
    createdPassword = password;
    return 'uid-1';
  }

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    if (signInError != null) throw signInError!;
    return 'uid-1';
  }

  @override
  Future<void> signOut() async => signedOut = true;

  @override
  Future<void> deleteCurrentAccount() async => deleted = true;
}

class _FakeUserRepository implements UserRepository {
  AppUser? profile = _profile();
  AppUser? created;
  Object? createError;

  @override
  Future<void> createUser(AppUser user) async {
    if (createError != null) throw createError!;
    created = user;
  }

  @override
  Future<AppUser?> getUser(String uid) async => profile;

  @override
  Future<bool> isUsernameAvailable(String username) async => true;
}
