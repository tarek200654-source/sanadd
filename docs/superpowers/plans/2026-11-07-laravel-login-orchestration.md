# Phase 2C.2 — Login orchestration

Implement only the supplied login + OTP specification in the existing Flutter checkout. Verified both project roots and read Laravel routes/requests/controller/service, UserResource, existing AuthService/repositories, Wexora repository, ApiClient/models and SecureTokenStore. No changes to backend/database, old implementations, UI/navigation, packages or other auth features.

Design: one application-layer LaravelLoginService using the existing ApiClient and TokenStore, plus a small OtpDispatch domain response model for expiry/resend metadata. Existing AuthRepository and Wexora interface assume direct authentication/provider challenges and cannot represent a server-owned pending login without changing existing behavior, so leave them intact. No new repository/network stack or Firebase fallback.

- [x] Add mocked tests first and observe missing implementation failures.
- [x] Implement start(email,password,language), sendOtp(), verifyOtp(code) returning existing AppUser only after authenticated response validation and awaited token persistence. Pending secrets remain memory-only. Preserve complete-profile requirements of existing AuthService.
- [x] Serialize transitions with a busy guard, reject overlapping submissions, discard pending state on replacement/idle discard/consumed success, preserve server errors and old sessions on failures. No client OTP success flag, fabricated token, direct Wexora call or auto-retry.
- [x] Focused login + Phase 2C.1 tests: 51 passed (19 new cases). Formatting and Flutter analyze passed with no issues. Results/UI boundaries recorded in docs/laravel-login-orchestration.md. No broad audits/native builds.

Explicit choices: send is a separate operation so UI can handle resend/errors without losing the server attempt. Server owns expiry/cooldown/attempt limits. An ambiguous network timeout leaves the attempt available, without automatically resubmitting OTP. After a successful verify HTTP response the attempt is retired even if malformed or secure storage fails; a fresh login is required, because the server may have consumed it. Discard during an active request is rejected to prevent stale completions overwriting new state.
