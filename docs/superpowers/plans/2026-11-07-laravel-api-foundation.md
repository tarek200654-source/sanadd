# Phase 2C.1 — Laravel API foundation

Scope: the supplied Phase 2C.1 specification. Implement in this Flutter checkout only; read Laravel contracts, never change its source/database. Preserve pre-existing uncommitted changes, all screens/routes/localization and active Firebase/Wexora behavior. Work in place within the user-named project; no extra checkout or dependency upgrades unrelated to this task.

Decisions: promote existing http 1.6 to a direct dependency; add flutter_secure_storage 10.x. Use data/network for configuration, transport and safe exceptions; domain/models for token/session/OTP values; domain/repositories for token-store interface; data/storage for platform storage; data/mappers for Laravel snake_case to existing AppUser/RegistrationData. Do not implement an alternative AuthService/repository orchestration yet.

- [x] Write focused tests first for URL policy, JSON/errors, request timeout/network failure, Bearer selection, 401 invalidation, expiry, secure-store behavior and backend model contracts. Observed missing implementation failures before creating production files.
- [x] Implement API configuration and client with debug-only local HTTP, no redirects/cross-origin paths, explicit authenticated requests, stable machine codes and no sensitive logging.
- [x] Store token+expiry in one protected storage record, with read/save/clear and serialized compare-and-clear so a late 401 cannot erase a replacement token. No SharedPreferences/fallback storage. Expose storage failures safely; do not silently treat them as logout.
- [x] Add strict typed token/session/OTP parsers and mapper reuse of existing user/registration models. OTP attempt/proof secrets remain memory-only and never confer an authenticated session.
- [x] Configure Android network/backup protection and iOS Keychain entitlement references; document native test limitations and absent desktop targets. No platform scaffolding/UI integration.
- [x] Final focused run: 32 passed. Formatting and whole-project Flutter analyze passed (no issues). XML parsed and entitlement references verified. Configuration, future restoration semantics and classified Firebase cleanup inventory recorded in docs/laravel-api-foundation.md.

Verification: use injected mocked HTTP and secure-storage plugin test backing only. No real backend/Wexora calls. Review focus: expired token never sent; authenticated 401 only clears matching token; network/422/503/public 401 retain tokens; malformed payloads do not leak secrets; HTTPS policy cannot be disabled in release/profile.
