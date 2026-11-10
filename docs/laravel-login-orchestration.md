# Phase 2C.2 — Login + server WhatsApp OTP (logic only)

Historical checkpoint report. The unchanged login orchestrator is now wired through the application AuthService and existing UI; see [completed migration status](laravel-auth-migration-progress.md). The deferred tasks described below refer to the Phase 2C.2 snapshot.

Verified Flutter and backend roots. Read actual Laravel `StartLoginRequest`, `VerifyOtpRequest`, `OtpAuthenticationController`, `OtpAuthentication`, `/api/user` route and `UserResource`, plus current Flutter auth/repository/OTP/foundation code. No backend/database changes or real provider calls.

## Added files

- `lib/application/auth/laravel_login_service.dart`: isolated login orchestration, using the existing `ApiClient` and `TokenStore`. No second networking layer/repository abstraction.
- `lib/domain/models/otp_dispatch.dart`: typed, non-authenticated Laravel send acknowledgement with server expiry/resend time. Acknowledgement is not confirmation that WhatsApp delivery completed.
- `test/application/auth/laravel_login_service_test.dart`: mocked HTTP plus actual SecureTokenStore adapter using the plugin's test backing; explicit failing storage test.
- This report and `docs/superpowers/plans/2026-11-07-laravel-login-orchestration.md`.

No existing runtime source, dependencies, screens, routing, native configuration, Firebase implementation or direct Wexora implementation changed in this phase. Existing workspace changes, including Phase 2C.1, were preserved.

## Integration contract (not wired to UI)

Create one `LaravelLoginService(api: api, tokenStore: tokenStore)` per login flow, using the same shared protected TokenStore as ApiClient. The existing `AuthRepository.signIn` returns an immediate user ID and `OtpVerificationRepository` accepts a client-supplied phone/provider ID. Neither models this backend-owned pending login. They remain unchanged; do not route the new flow through their Firebase/Wexora implementations.

```dart
await login.start(email: email, password: password, language: language);
final dispatch = await login.sendOtp();
// Later, after the user enters the delivered code:
final AppUser user = await login.verifyOtp(code);
```

1. `start` posts normalized email, unchanged password and language (`en` default, caller supplies `ar` as needed) to `/api/auth/login/start`. Requires `login-started`, a login-purpose `OtpAttempt`, false authentication and false `otp_started`. Stores only the attempt in process memory, never credentials in persistent storage.
2. `sendOtp` posts only attempt ID/token to `/api/auth/otp/send`. Requires `otp-sent`, matching attempt, `otp_started: true`, `authenticated: false`, valid expiry/resend timestamps. Server controls cooldown/send limits; resends use the same method. No client-selected phone, provider ID or Wexora calls.
3. `verifyOtp` posts attempt ID/token, fixed `purpose: login` and code to `/api/auth/otp/verify`. Requires `authenticated` response code, `authenticated: true`, a valid complete `AppUser` and unexpired opaque Bearer token with expiry. It awaits protected token persistence before returning the user. Passwords/codes/attempt secrets/tokens are never logged. No tokens are minted, fabricated, decoded as JWTs, or saved from OTP preparation/proofs.

Pending attempt is exposed as `pendingAttempt` for in-memory flow state only; never log/serialize it into preferences or route restoration. `isBusy` supports disabling submissions. Overlapping start/send/verify operations are rejected with client code `auth-operation-in-progress`, including duplicate OTP verification, before any extra HTTP request. `discardPendingAttempt()` clears memory only; it is not logout. Await any active operation before discard/replacement; discard while busy is rejected, not cancellation of an HTTP request. UI must handle its lifecycle and stale callbacks during later integration.

Incorrect credentials, validation, invalid OTP, expiration, throttling and provider failures retain the existing ApiException codes/field codes for future localization. Network/timeouts do not clear an existing session or automatically retry an OTP operation. Failed sends keep the attempt so the user can retry within server limits. Verification is not gated on a client-side send-success flag: a send may time out after the provider sent the code, and the server remains authoritative.

Terminal `invalid-challenge`, `challenge-used`, and `account-changed` errors clear pending memory. `otp-expired` remains a backend decision; it may describe code expiry while the attempt can still be resent, or the whole attempt may need a fresh start. No local timers extend server validity.

A successful verification response retires the attempt even if its payload is malformed or secure storage fails, because the server may have consumed it. Malformed verification JSON also retires it. No user is returned on storage failure. Restart login rather than resubmitting the consumed OTP. An ambiguous network timeout retains the attempt without automatic retry; if the backend subsequently reports it consumed, restart. This phase does not revoke orphan server tokens or implement logout.

The resulting stored token can be used by the existing `api.get('/api/user', authenticated: true)` for future profile/restoration work; this was exercised with a mocked real-contract response. No extra profile request is needed to complete login because OTP verification already returns the user. Automatic restoration/navigation is not added here.

## Verification

Focused command:

```powershell
flutter test --no-pub test/application/auth/laravel_login_service_test.dart test/data/network test/data/storage test/data/laravel_models_test.dart --reporter expanded
```

Result: **51 passed (19 new login cases + 32 foundation cases), 0 failed, 0 skipped**. Covers start/send/resend/verify, actual protected-store adapter persistence, invalid credentials/codes, expiry/rate/provider/network/timeout failures, malformed/cross-purpose responses, no premature token storage, overlapping submissions, pending-state lifecycle, secure-storage failure and authenticated `/api/user` compatibility. All service requests are asserted local and un-authenticated until OTP completion; no Firebase/Wexora fallback exists.

`flutter analyze --no-pub`: **No issues found** (2026-11-07). Targeted `dart format --output=none --set-exit-if-changed`: passed, zero changes. `git diff --check`: passed (Git emitted LF/CRLF notices for existing working-tree files). Native builds and real device/provider delivery are outside this logic-only task.

Next smallest task: inject this service into the existing Login → OTP flow in a separately authorized UI wiring phase. Preserve visuals/localization/navigation, retain one shared service instance across the flow, pass the selected language, use server resend metadata, translate error codes, and navigate only after `verifyOtp` returns successfully. Explicitly remove the old Firebase/direct-Wexora login calls from that migrated flow; do not silently fall back to them. Signup/password recovery/logout and global session restoration remain separate tasks.
