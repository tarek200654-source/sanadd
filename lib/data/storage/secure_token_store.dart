import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/sanctum_token.dart';
import '../../domain/repositories/token_store.dart';

/// Share one instance per app. Operations serialize on its single secure record.
final class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage, DateTime Function()? now})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.unlocked_this_device,
              synchronizable: false,
            ),
          ),
      _now = now ?? DateTime.now;

  static const recordKey = 'sanad.sanctum.session.v1';
  final FlutterSecureStorage _storage;
  final DateTime Function() _now;
  Future<void> _tail = Future<void>.value();

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) async {
      try {
        return await action();
      } on PlatformException {
        throw const TokenStorageException();
      } on MissingPluginException {
        throw const TokenStorageException();
      } on FormatException {
        throw const TokenStorageException();
      }
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace stack) {});
    return result;
  }

  Future<SanctumToken?> _read() async {
    final raw = await _storage.read(key: recordKey);
    if (raw == null) return null;
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid secure record.');
    }
    final token = SanctumToken.fromJson(json);
    if (token.isExpired(_now())) {
      await _storage.delete(key: recordKey);
      return null;
    }
    return token;
  }

  @override
  Future<SanctumToken?> read() => _serial(_read);

  @override
  Future<void> save(SanctumToken token) => _serial(() async {
    if (token.isExpired(_now())) throw const TokenStorageException();
    await _storage.write(key: recordKey, value: jsonEncode(token.toJson()));
  });

  @override
  Future<void> clear() => _serial(() => _storage.delete(key: recordKey));

  @override
  Future<void> clearIfMatches(SanctumToken expected) => _serial(() async {
    final current = await _read();
    if (current?.value == expected.value) await _storage.delete(key: recordKey);
  });
}
