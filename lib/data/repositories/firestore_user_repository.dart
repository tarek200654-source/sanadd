import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/app_user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/validation/username_policy.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _usernames =>
      _firestore.collection('usernames');

  @override
  Future<bool> isUsernameAvailable(String username) async {
    if (!UsernamePolicy.isValid(username)) {
      throw const UserRepositoryException(
        UserRepositoryFailureType.invalidData,
      );
    }
    try {
      final reservation = await _usernames
          .doc(UsernamePolicy.canonicalize(username))
          .get();
      return !reservation.exists;
    } on FirebaseException catch (error, stackTrace) {
      throw UserRepositoryException(
        UserRepositoryFailureType.unavailable,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> createUser(AppUser user) async {
    _validateUid(user.uid);

    final data = user.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();

    try {
      final username = user.username;
      if (username == null || !UsernamePolicy.isValid(username)) {
        throw const UserRepositoryException(
          UserRepositoryFailureType.invalidData,
        );
      }
      final reservationRef = _usernames.doc(
        UsernamePolicy.canonicalize(username),
      );
      final userRef = _users.doc(user.uid);
      await _firestore.runTransaction((transaction) async {
        final reservation = await transaction.get(reservationRef);
        final existingUser = await transaction.get(userRef);
        if (reservation.exists) {
          throw const UserRepositoryException(
            UserRepositoryFailureType.usernameTaken,
          );
        }
        if (existingUser.exists) {
          throw const UserRepositoryException(
            UserRepositoryFailureType.invalidData,
          );
        }
        transaction.set(userRef, data);
        transaction.set(reservationRef, {'reserved': true});
      });
    } on UserRepositoryException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      throw UserRepositoryException(
        UserRepositoryFailureType.unavailable,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<AppUser?> getUser(String uid) async {
    _validateUid(uid);

    try {
      final snapshot = await _users.doc(uid).get();
      if (!snapshot.exists) return null;

      final data = snapshot.data();
      if (data == null) {
        throw const UserRepositoryException(
          UserRepositoryFailureType.invalidData,
        );
      }

      return AppUser.fromFirestore(
        uid: snapshot.id,
        data: _normalizeFirestoreData(data),
      );
    } on UserRepositoryException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      throw UserRepositoryException(
        UserRepositoryFailureType.unavailable,
        cause: error,
        stackTrace: stackTrace,
      );
    } on Object catch (error, stackTrace) {
      throw UserRepositoryException(
        UserRepositoryFailureType.invalidData,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Map<String, dynamic> _normalizeFirestoreData(
    Map<String, dynamic> data,
  ) {
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      return {...data, 'createdAt': createdAt.toDate()};
    }
    return data;
  }

  static void _validateUid(String uid) {
    if (uid.trim().isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'UID must not be empty.');
    }
  }
}
