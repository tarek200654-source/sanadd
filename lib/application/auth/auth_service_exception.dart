enum AuthServiceFailureType {
  missingUserProfile,
  profileReadFailed,
  profileCreationFailed,
  usernameTaken,
  registrationRollbackFailed,
}

class AuthServiceException implements Exception {
  const AuthServiceException(
    this.type, {
    this.cause,
    this.causeStackTrace,
    this.rollbackError,
    this.rollbackStackTrace,
  });

  final AuthServiceFailureType type;
  final Object? cause;
  final StackTrace? causeStackTrace;
  final Object? rollbackError;
  final StackTrace? rollbackStackTrace;

  bool get rollbackSucceeded => rollbackError == null;

  String get code => switch (type) {
    AuthServiceFailureType.missingUserProfile => 'missing-user-profile',
    AuthServiceFailureType.profileReadFailed => 'profile-read-failed',
    AuthServiceFailureType.profileCreationFailed => 'profile-creation-failed',
    AuthServiceFailureType.usernameTaken => 'username-taken',
    AuthServiceFailureType.registrationRollbackFailed =>
      'registration-rollback-failed',
  };

  @override
  String toString() => 'AuthServiceException($code)';
}
