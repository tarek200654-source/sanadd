enum AuthFailureType {
  emailAlreadyInUse,
  invalidEmail,
  weakPassword,
  invalidCredentials,
  network,
  tooManyRequests,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.type, {this.cause, this.stackTrace});

  final AuthFailureType type;
  final Object? cause;
  final StackTrace? stackTrace;

  String get code => switch (type) {
    AuthFailureType.emailAlreadyInUse => 'email-already-in-use',
    AuthFailureType.invalidEmail => 'invalid-email',
    AuthFailureType.weakPassword => 'weak-password',
    AuthFailureType.invalidCredentials => 'invalid-credentials',
    AuthFailureType.network => 'network-request-failed',
    AuthFailureType.tooManyRequests => 'too-many-requests',
    AuthFailureType.unknown => 'unknown-auth-failure',
  };

  @override
  String toString() => 'AuthFailure($code)';
}
