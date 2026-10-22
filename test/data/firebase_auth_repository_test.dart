import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/application/auth/auth_failure.dart';
import 'package:sanad/data/repositories/firebase_auth_repository.dart';

void main() {
  group('Firebase authentication error mapping', () {
    test('maps duplicate email and invalid credentials safely', () {
      expect(
        _map('email-already-in-use').type,
        AuthFailureType.emailAlreadyInUse,
      );
      expect(
        _map('invalid-credential').type,
        AuthFailureType.invalidCredentials,
      );
      expect(_map('wrong-password').type, AuthFailureType.invalidCredentials);
    });

    test('maps network errors without exposing Firebase details', () {
      final failure = _map('network-request-failed');
      expect(failure.type, AuthFailureType.network);
      expect(failure.toString(), 'AuthFailure(network-request-failed)');
      expect(failure.toString(), isNot(contains('private server detail')));
    });
  });
}

AuthFailure _map(String code) => mapFirebaseAuthException(
  FirebaseAuthException(code: code, message: 'private server detail'),
  StackTrace.current,
);
