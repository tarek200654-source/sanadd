import '../models/app_user.dart';

abstract interface class UserRepository {
  Future<bool> isUsernameAvailable(String username);

  Future<void> createUser(AppUser user);

  Future<AppUser?> getUser(String uid);
}

enum UserRepositoryFailureType { unavailable, invalidData, usernameTaken }

class UserRepositoryException implements Exception {
  const UserRepositoryException(this.type, {this.cause, this.stackTrace});

  final UserRepositoryFailureType type;
  final Object? cause;
  final StackTrace? stackTrace;

  String get code => switch (type) {
    UserRepositoryFailureType.unavailable => 'user-profile-unavailable',
    UserRepositoryFailureType.invalidData => 'invalid-user-profile',
    UserRepositoryFailureType.usernameTaken => 'username-taken',
  };

  @override
  String toString() => 'UserRepositoryException($code)';
}
