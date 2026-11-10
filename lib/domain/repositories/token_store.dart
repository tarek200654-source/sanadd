import '../models/sanctum_token.dart';

abstract interface class TokenStore {
  Future<SanctumToken?> read();
  Future<void> save(SanctumToken token);
  Future<void> clear();

  /// Prevent an old in-flight request from clearing a replacement session.
  Future<void> clearIfMatches(SanctumToken expected);
}

final class TokenStorageException implements Exception {
  const TokenStorageException();

  @override
  String toString() => 'TokenStorageException(secure-storage-unavailable)';
}
