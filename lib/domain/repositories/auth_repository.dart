abstract interface class AuthRepository {
  String? get currentUserId;

  Stream<String?> authStateChanges();

  Future<String> createAccount({
    required String email,
    required String password,
  });

  Future<String> signIn({required String email, required String password});

  Future<void> signOut();

  Future<void> deleteCurrentAccount();
}
