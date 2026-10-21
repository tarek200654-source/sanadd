import 'package:firebase_auth/firebase_auth.dart';

import '../../application/auth/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  @override
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  @override
  Stream<String?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((user) => user?.uid);
  }

  @override
  Future<String> createAccount({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null || uid.isEmpty) {
        throw const AuthFailure(AuthFailureType.unknown);
      }
      return uid;
    } on FirebaseAuthException catch (error, stackTrace) {
      throw _mapFirebaseAuthException(error, stackTrace);
    }
  }

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null || uid.isEmpty) {
        throw const AuthFailure(AuthFailureType.unknown);
      }
      return uid;
    } on FirebaseAuthException catch (error, stackTrace) {
      throw _mapFirebaseAuthException(error, stackTrace);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (error, stackTrace) {
      throw _mapFirebaseAuthException(error, stackTrace);
    }
  }

  @override
  Future<void> deleteCurrentAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    try {
      await user.delete();
    } on FirebaseAuthException catch (error, stackTrace) {
      throw _mapFirebaseAuthException(error, stackTrace);
    }
  }
}

AuthFailure _mapFirebaseAuthException(
  FirebaseAuthException error,
  StackTrace stackTrace,
) {
  final type = switch (error.code) {
    'email-already-in-use' => AuthFailureType.emailAlreadyInUse,
    'invalid-email' => AuthFailureType.invalidEmail,
    'weak-password' => AuthFailureType.weakPassword,
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' ||
    'invalid-login-credentials' => AuthFailureType.invalidCredentials,
    'network-request-failed' => AuthFailureType.network,
    'too-many-requests' => AuthFailureType.tooManyRequests,
    _ => AuthFailureType.unknown,
  };

  return AuthFailure(type, cause: error, stackTrace: stackTrace);
}
