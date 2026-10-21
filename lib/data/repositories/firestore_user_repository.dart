import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/app_user.dart';
import '../../domain/repositories/user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<void> createUser(AppUser user) async {
    _validateUid(user.uid);

    final data = user.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();

    try {
      await _users.doc(user.uid).set(data);
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
