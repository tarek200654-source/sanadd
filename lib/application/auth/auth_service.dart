import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firestore_user_repository.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/user_role.dart';
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

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phoneNumber,
  }) async {
    final uid = await _authRepository.createAccount(
      email: email,
      password: password,
    );
    final user = AppUser(
      uid: uid,
      name: name,
      email: email,
      role: role,
      phoneNumber: phoneNumber,
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

      throw AuthServiceException(
        rollbackError == null
            ? AuthServiceFailureType.profileCreationFailed
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
      if (user == null) {
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

  Future<void> signOut() => _authRepository.signOut();
}
