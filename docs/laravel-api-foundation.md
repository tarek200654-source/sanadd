# Phase 2C.1 — Flutter Laravel foundation

Historical checkpoint report. Phases 2C.3–2C.8 now integrate these components and retire the legacy adapters; see [current migration status](laravel-auth-migration-progress.md). Descriptions of active Firebase and future wiring below refer to the Phase 2C.1 snapshot.

The actual roots were verified: Flutter `C:\Users\Ouffaa\Desktop\SANAD\sanad` (`pubspec.yaml`, `lib/main.dart`) and Laravel sibling `sanad_backend` (`artisan`, `routes/api.php`). Laravel source was read as the contract; its files/database were not changed. This foundation is deliberately not instantiated by the active app yet. Existing Firebase authentication, Wexora screens, routes, localization and UI continue to operate unchanged.

## Structure and use

- `data/network/ApiConfig`: an origin without `/api`, compile-time `SANAD_API_BASE_URL`, 20-second request timeout. Debug defaults to Android emulator `http://10.0.2.2:8000`, otherwise `http://127.0.0.1:8000`. Physical Android devices must supply a private LAN origin. HTTP is accepted only for loopback/private IPv4 addresses in debug. Profile/release require explicit HTTPS; passing `production: false` cannot bypass this build-mode policy. No production hostname is embedded.
- `data/network/ApiClient`: injected `http.Client`, JSON requests/responses, explicit `authenticated: true`, no redirects or alternate-origin paths, no retries/logging/cookie session management. Returns the complete JSON object; returns null for 204 logout. Supports the different raw health response. Timeout covers network send and body collection. Network/timeout exceptions are sanitized.
- `data/network/ApiException`: status, stable code, immutable field `errors` and `error_codes`. Unknown server failures become `server-error` (status-specific fallback for 401/422/429). Debug exception bodies are discarded. `toString` contains only HTTP status. Existing `AuthFailure` categories can be reused with `toAuthFailure`; validation field codes remain separate for later localized form feedback. No server messages are displayed automatically and no localization is changed.
- `domain/repositories/TokenStore` / `data/storage/SecureTokenStore`: read/save/clear and compare-and-clear operations over one secure JSON record containing token type, value and UTC expiry. Missing/expired tokens yield no session; expired records are deleted. Corrupt/locked/unavailable storage raises a sanitized `TokenStorageException` rather than falling back to ordinary preferences. Only this record is cleared; unrelated secure records survive. Operations are serialized; share one instance throughout the future app container.
- `SanctumToken`, `OtpAttempt`, `OtpProof`: strict string/role/purpose/timezone parsing, secret-redacted `toString`. Sanctum tokens are opaque, never decoded as JWTs. Attempts/proofs are memory-only and cannot be parsed as authenticated sessions. Signup proof and password-reset proof have separate keys/purposes; login verification returns a session directly.
- `data/models/AuthSession`: parses an authenticated response into existing `AppUser` plus token. `LaravelUserMapper` maps string `id` to `uid`, `first_name`, `last_name`, `phone_number`, `created_at` to existing domain fields and back. It preserves nullable legacy profile fields and patient/caregiver roles. Laravel IDs are not Firebase UIDs; do not reuse old profile caches across authorities.
- `LaravelRegistrationMapper`: serializes existing `RegistrationData` into backend snake_case, with explicit confirmation. Trims profile fields and canonicalizes email; never trims passwords. This is mapping only, not signup integration.

Instantiate later in the app's composition layer, not inside screens:

```dart
final tokenStore = SecureTokenStore();
final api = ApiClient(
  config: ApiConfig.fromEnvironment(),
  tokenStore: tokenStore,
);
// Future restoration: api.get('/api/user', authenticated: true).
// Future OTP completion: AuthSession.fromJson(response['data']), then save token.
// Dispose the shared client once when its owning container closes.
```

Example future debug launch options (these do not switch the existing screens to Laravel):

```powershell
flutter run --dart-define=SANAD_API_BASE_URL=http://10.0.2.2:8000
flutter run --dart-define=SANAD_API_BASE_URL=http://192.168.1.20:8000
```

The LAN address is an example to replace with the developer machine's address. Laravel must listen on the appropriate local interface and Windows must permit that connection; no backend configuration was changed here. The existing backend queue worker remains necessary for recovery OTP delivery.

## Native secure storage

Dependencies: `http` **1.6.0** promoted from transitive to direct, and `flutter_secure_storage` **10.3.4** added with its platform dependencies. Existing package versions are preserved in the lockfile. No new state framework.

The chosen plugin uses platform-protected storage; the adapter uses its Android cipher defaults and iOS Keychain with `unlocked_this_device`, no iCloud synchronization. Android backup is disabled to avoid restoring token ciphertext without its device key. Debug-only cleartext traffic supports local Laravel without changing profile/release policy. The current Flutter Android minimum is 24, above the plugin minimum 23. The iOS Runner references `Runner.entitlements` for Debug/Profile/Release with the plugin's Keychain setup. See [the installed version's official setup documentation](https://pub.dev/packages/flutter_secure_storage/versions/10.3.4).

Native Keychain/Keystore operation and signing need a device smoke test when integration begins; mocked tests do not establish native security behavior. iOS builds cannot be verified on this Windows machine. No Windows/Linux/macOS/web runner exists in this project; none was scaffolded. The desktop origin works in transport tests and is ready for an eventual supported runner; do not claim a desktop app is enabled. Existing iOS ATS/local-network policy was not broadened: a physical iOS LAN HTTP test may require a separately scoped debug transport exception/permission; use trusted local HTTPS otherwise.

## Session semantics for the next phase

No API response saves a token automatically. Only successful server OTP completion (`authenticated: true`, profile, Bearer token, expiry) can be orchestrated into a stored session. Recovery returns a proof, never a login token.

Authenticated requests read protected storage, reject missing/expired tokens before HTTP, and attach Bearer explicitly. A protected 401 clears only the token used by that request, even for malformed proxy JSON. A late 401 cannot remove a newly saved replacement token. Public invalid-credential 401s do not touch an existing token. Network failures, timeout, 422, 429, and 5xx retain tokens. Storage errors remain explicit. Revocation is detected by the server's 401; a local token is not proof of authentication. No refresh endpoint is invented.

Future restoration must call `GET /api/user`, parse `data.user` and expose a session only after success. A temporary network failure should preserve the saved token and expose a retry/offline state; it must not navigate to an authenticated screen based only on local storage. Future explicit logout must coordinate `POST /api/auth/logout` and local clearance. None of this orchestration/navigation is wired in this phase.

## Backend source contract inspected

| Source/endpoints | Contract relevant to foundation |
|---|---|
| availability/email, availability/username | 200 `{code, data: {available}}` |
| `/auth/login`, `/auth/register/prepare` | Prepared only, `authenticated: false`; never session models |
| `/auth/signup/start`, `/auth/login/start` | 201 `data` contains attempt UUID/token, purpose, UTC expiry, false authentication |
| `/auth/otp/send`, `/auth/otp/verify` | Send 202; signup verification returns `verification_proof`; login verification returns authenticated session |
| `/auth/register` | 201 authenticated profile/token after signup proof only |
| `/auth/password/forgot`, `/password/otp/send`, `/password/otp/verify`, `/password/reset` | Neutral 202 attempt, queued send, `reset_proof`, final false authentication/login required |
| `/api/user`, `/auth/logout` | Protected profile inside `data.user`; logout 204 |
| `AuthApiResponse`, `UserResource`, `AuthFlowException` | Stable machine codes, field error codes, snake_case profile, string ID, ISO UTC expiry |

All auth paths above are under `/api/auth`; `/api/user` is outside that prefix. Generic get/post transport is implemented; endpoint-specific orchestration is deferred.

## Firebase cleanup inventory — after replacement verification only

Actual Dart imports/queries show Firebase Auth and Firestore used for authentication, profile storage and identity reservations (`users`, `usernames`, `emails`). No independent health/hardware/AI Firebase consumer was found. Keep everything operational now.

| Classification | Item | Later action |
|---|---|---|
| Remove after migration | `lib/data/repositories/firebase_auth_repository.dart`, `test/data/firebase_auth_repository_test.dart` | Delete Firebase adapter/error mapper and replace its coverage with Laravel behavior tests. |
| Remove after migration | `lib/data/repositories/firestore_user_repository.dart`; auth-only `firestore.rules`, `firebase.rules-test.json`, `tooling/firestore-rules-tests/` and its Firebase test dependencies | Retire profile/identity reservation code after backend parity and data-transition review. Do not delete remote data as part of client cleanup. |
| Remove after migration | Firebase imports/factory in `application/auth/auth_service.dart`; `AuthService.firebase()` defaults in login/signup/OTP/splash/home screens | Replace orchestration and call sites, preserving UI; do not delete screens or generic service/error types indiscriminately. |
| Remove after migration | `AppUser.fromFirestore`, `toFirestore`, Firebase-specific mapping/docs | Retain `AppUser`, roles and registration domain values; remove only obsolete persistence behavior after auditing `fromMap` tests/callers. |
| Remove after migration | `firebase_auth`, `cloud_firestore`, `firebase_core`, transitive Firebase packages | No unrelated runtime consumers currently evidenced. Recheck all imports/native usage immediately before removal. |
| Remove after migration | Firebase initialization/imports in `main.dart`; `lib/firebase_options.dart`; Android `google-services.json` and Google services Gradle plugin declarations | Remove only after final usage audit. Regenerate plugin registration/resolution through Flutter tooling, not manual edits. |
| Retain because other features depend on it | `shared_preferences`, locale controller, splash first-run preferences | Used for locale/onboarding, not Sanctum tokens. |
| Retain because shared domain/UI depends on it | `AppUser`, `RegistrationData`, `UserRole`, username policy, localized validation, assets/fonts, screens/routes | Keep generic components; remove Firebase-specific comments/methods only where obsolete. |
| Requires further investigation | iOS Swift package/project Firebase resolution entries and any native Firebase configuration; generated registrants | Audit native references on macOS after Dart dependency removal. No `ios/Runner/GoogleService-Info.plist` exists at the inspected path. |
| Requires further investigation | `firebase.json` | Already deleted in the working tree before this task; not restored or changed by this work. Audit remaining emulator/deployment configuration before final cleanup. |
| Requires further investigation | Existing application/domain/widget fixtures and historic Firebase design documents | Retain generic tests; replace Firebase assumptions and archive outdated docs when Laravel flow is integrated. |

The direct Flutter Wexora adapter and its credential build setup are unchanged and still required by the current screens. A later server-OTP integration must retire direct client-provider calls and credential inclusion after the replacement is verified. Final app must have exactly one authentication authority: Laravel + Sanctum; this temporary foundation is not a second active flow.

## Changed-file inventory

Created Dart files:

- `lib/data/network/api_config.dart`, `api_client.dart`, `api_exception.dart`
- `lib/data/storage/secure_token_store.dart`
- `lib/data/models/auth_session.dart`
- `lib/data/mappers/laravel_user_mapper.dart`, `laravel_registration_mapper.dart`
- `lib/domain/models/auth_json.dart`, `sanctum_token.dart`, `otp_attempt.dart`, `otp_proof.dart`
- `lib/domain/repositories/token_store.dart`
- `test/data/network/api_config_test.dart`, `api_client_test.dart`, `api_exception_test.dart`
- `test/data/storage/secure_token_store_test.dart`, `test/data/laravel_models_test.dart`

Created native/docs: `ios/Runner/Runner.entitlements`, this report and `docs/superpowers/plans/2026-11-07-laravel-api-foundation.md`.

Modified: `pubspec.yaml`, `pubspec.lock`, `android/app/src/main/AndroidManifest.xml`, `android/app/src/debug/AndroidManifest.xml`, `ios/Runner.xcodeproj/project.pbxproj`. Package resolution also refreshes ignored generated plugin metadata/registrants. Pre-existing changes to `main.dart`, bottom navigation, deleted `firebase.json`, and Postman folders are outside this change and were preserved.

## Verification / next task

Focused tests mock HTTP and use the secure-storage plugin's test backing or explicit platform-failure fake. No live Laravel/Wexora/production requests and no database access.

Verified on 2026-11-07:

- `flutter test --no-pub test/data/network test/data/storage test/data/laravel_models_test.dart --reporter expanded`: **32 passed, 0 failed, 0 skipped**. Covers JSON/profile/session/OTP/error parsing, Authorization selection, missing/expired/revoked tokens, public and protected 401s, replacement-token race, network/timeout retention, secure record lifecycle/platform failures and URL restrictions.
- `flutter analyze --no-pub`: **No issues found**. Initial new-code lint findings were corrected before this final run.
- Targeted `dart format`: new Dart files/tests formatted. `git diff --check`: passed; Git only emitted existing LF/CRLF conversion notices.
- Android manifests and iOS entitlements parsed as XML; exactly three Runner entitlement references verified.
- Full existing widget suite and native builds/device secure-storage tests were not run; requested checks were focused tests plus whole-project analysis. Existing uncommitted source/UI changes were left alone.

Next smallest task: add endpoint-specific Laravel authentication orchestration for one login challenge through server OTP, persisting a token only after successful verification; verify it with mocks before changing screen dependencies. Do not force the old direct-sign-in `AuthRepository` interface onto a pending-OTP response.
