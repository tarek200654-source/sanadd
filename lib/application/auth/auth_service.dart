import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firestore_user_repository.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/registration_data.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';
import 'auth_service_exception.dart';

class AuthService {
  const AuthService({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  }) : _authRepository = authRepository,
       _userRepository = userRepository;

  factory AuthService.firebase() {
    return AuthService(
      authRepository: FirebaseAuthRepository(),
      userRepository: FirestoreUserRepository(),
    );
  }

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  String? get currentUserId => _authRepository.currentUserId;

  Stream<String?> authStateChanges() => _authRepository.authStateChanges();

  Future<bool> isUsernameAvailable(String username) =>
      _userRepository.isUsernameAvailable(username);

  Future<AppUser> register(RegistrationData registration) async {
    final uid = await _authRepository.createAccount(
      email: registration.email.trim(),
      password: registration.password,
    );
    final user = AppUser(
      uid: uid,
      name: registration.fullName,
      email: registration.email.trim(),
      role: registration.role,
      username: registration.username.trim(),
      firstName: registration.firstName.trim(),
      lastName: registration.lastName.trim(),
      country: registration.country.trim(),
      region: registration.region.trim(),
      address: registration.address.trim(),
      phoneNumber: registration.phoneNumber.trim(),
    );

    try {
      await _userRepository.createUser(user);
      return user;
    } catch (error, stackTrace) {
      Object? rollbackError;
      StackTrace? rollbackStackTrace;

      try {
        await _authRepository.deleteCurrentAccount();
      } catch (error, stackTrace) {
        rollbackError = error;
        rollbackStackTrace = stackTrace;
      }

      final failureType =
          error is UserRepositoryException &&
              error.type == UserRepositoryFailureType.usernameTaken
          ? AuthServiceFailureType.usernameTaken
          : AuthServiceFailureType.profileCreationFailed;
      throw AuthServiceException(
        rollbackError == null
            ? failureType
            : AuthServiceFailureType.registrationRollbackFailed,
        cause: error,
        causeStackTrace: stackTrace,
        rollbackError: rollbackError,
        rollbackStackTrace: rollbackStackTrace,
      );
    }
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final uid = await _authRepository.signIn(email: email, password: password);

    try {
      final user = await _userRepository.getUser(uid);
      if (user == null ||
          user.uid != uid ||
          !user.hasCompleteRegistrationProfile) {
        throw const AuthServiceException(
          AuthServiceFailureType.missingUserProfile,
        );
      }
      return user;
    } catch (error, stackTrace) {
      try {
        await _authRepository.signOut();
      } catch (_) {
        // Preserve the original incomplete-account/profile error.
      }

      if (error is AuthServiceException) rethrow;

      throw AuthServiceException(
        AuthServiceFailureType.profileReadFailed,
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
  }

  Future<AppUser?> restoreCurrentUser() async {
    final uid = _authRepository.currentUserId;
    if (uid == null || uid.isEmpty) return null;

    try {
      final user = await _userRepository.getUser(uid);
      if (user == null ||
          user.uid != uid ||
          !user.hasCompleteRegistrationProfile) {
        await _authRepository.signOut();
        return null;
      }
      return user;
    } catch (_) {
      try {
        await _authRepository.signOut();
      } catch (_) {
        // Invalid or unavailable profiles must not keep a partial session.
      }
      return null;
    }
  }

  Future<void> signOut() => _authRepository.signOut();
}
