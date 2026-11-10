import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/data/storage/secure_token_store.dart';
import 'package:sanad/domain/models/sanctum_token.dart';
import 'package:sanad/domain/repositories/token_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 11, 7);
  late SecureTokenStore store;
  const platformStorage = FlutterSecureStorage();
  SanctumToken token(String value) =>
      SanctumToken(value: value, expiresAt: now.add(const Duration(hours: 1)));

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    store = SecureTokenStore(storage: platformStorage, now: () => now);
  });

  test('missing record has no session', () async {
    expect(await store.read(), isNull);
  });
  test(
    'saves token and expiry as one secure record then clears only that key',
    () async {
      await platformStorage.write(key: 'unrelated', value: 'keep');
      await store.save(token('1|test-token'));
      final record = jsonDecode(
        (await platformStorage.read(key: SecureTokenStore.recordKey))!,
      );
      expect(record['token'], '1|test-token');
      expect(record['expires_at'], '2026-11-07T01:00:00.000Z');
      expect((await store.read())?.value, '1|test-token');
      await store.clear();
      expect(await store.read(), isNull);
      expect(await platformStorage.read(key: 'unrelated'), 'keep');
    },
  );
  test('expired record is removed', () async {
    await platformStorage.write(
      key: SecureTokenStore.recordKey,
      value: jsonEncode({
        'token': 'expired-token',
        'token_type': 'Bearer',
        'expires_at': now.toIso8601String(),
      }),
    );
    expect(await store.read(), isNull);
    expect(await platformStorage.read(key: SecureTokenStore.recordKey), isNull);
    await expectLater(
      store.save(SanctumToken(value: 'expired', expiresAt: now)),
      throwsA(isA<TokenStorageException>()),
    );
  });
  test(
    'malformed record fails without insecure fallback or credential logging',
    () async {
      await platformStorage.write(
        key: SecureTokenStore.recordKey,
        value: 'private-token',
      );
      try {
        await store.read();
        fail('Expected error');
      } on TokenStorageException catch (error) {
        expect(error.toString(), isNot(contains('private-token')));
      }
    },
  );
  test(
    'serializes replacement and compare-clear without deleting the new token',
    () async {
      final old = token('old-token');
      await store.save(old);
      await Future.wait([
        store.save(token('new-token')),
        store.clearIfMatches(old),
      ]);
      expect((await store.read())?.value, 'new-token');
      await store.clearIfMatches(token('new-token'));
      expect(await store.read(), isNull);
    },
  );
  test('platform failures are explicit and sanitized', () async {
    final failing = SecureTokenStore(
      storage: const UnavailableStorage(),
      now: () => now,
    );
    await expectLater(failing.read(), throwsA(isA<TokenStorageException>()));
    await expectLater(
      failing.save(token('test-token')),
      throwsA(isA<TokenStorageException>()),
    );
    await expectLater(failing.clear(), throwsA(isA<TokenStorageException>()));
  });
}

class UnavailableStorage extends FlutterSecureStorage {
  const UnavailableStorage();
  Never unavailable() =>
      throw PlatformException(code: 'locked', message: 'private-token');
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => unavailable();
  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => unavailable();
  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => unavailable();
}
