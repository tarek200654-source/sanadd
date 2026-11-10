# Laravel authentication migration progress

Execution: 2026-11-07. Approved phases 2C.3–2C.8; Flutter root only. No live WhatsApp or backend/database writes. Existing working-tree changes retained.

| Phase | Status | Evidence |
|---|---|---|
| 2C.1 / 2C.2 | Completed | Existing foundation/login reused; 51 focused tests passed during preflight. |
| 2C.3 Login UI | Completed | 2 mocked Login/OTP widget tests passed; existing login logic retained. |
| 2C.4 Signup | Completed | 7 focused signup logic/widget cases passed, both roles. |
| 2C.5 Recovery | Completed | 4 recovery logic cases + 1 full mocked recovery widget flow passed. |
| 2C.6 Session / logout | Completed | 7 session cases + 3 startup/route cases passed. Seven-step signup additionally verified: both roles + debounce (3 cases). |
| 2C.7 Cleanup | Completed | All migrated flows passed before retirement. 142 focused cases and clean analysis after cleanup. No remaining active Firebase/direct-Wexora imports, dependencies, initialization or client credential configuration. |
| 2C.8 Final verification | Completed | Final full suite: 154 passed, 0 failures/skips; analysis clean; formatting check: 54 files, zero changes. Android APK rebuilt/installed/launched after the final fix; emulator health 200. Real OTP and iOS checks intentionally remain manual. |

## Decisions

- Preserve the 51-tested LaravelLoginService; delegate login through the final AuthService facade. Temporarily use a Laravel facade alongside untouched legacy service until remaining flows pass, then retire the legacy implementation and use the AuthService name.
- Startup network errors retain token and show Splash retry. Logout network errors retain session and show existing failure message.
- Recovery needs six digits/WhatsApp text and the established full password policy. No other visual redesign.
- Automated tests use mocked HTTP/storage. No real OTP requests, queue workers, PostgreSQL changes or remote Firebase deletion.

## Changes and verification

The per-phase entries below record exact checkpoint commands/results and changed-file groups. Pre-existing edits include main.dart, bottom navigation, Firebase config deletion and the Phase 2C.1 foundation; do not overwrite unrelated changes.

## Checkpoint evidence

- Preflight: `flutter test --no-pub test/application/auth/laravel_login_service_test.dart test/data/network test/data/storage test/data/laravel_models_test.dart --reporter expanded` — 51 passed, original foundation/Login reused.
- 2C.3: new mocked Login/OTP widget tests — 2 passed; actual server role reached Home without pre-OTP storage.
- 2C.4: signup logic + both-role OTP widgets — 7 passed. Complete seven-step signup UIs for Patient/Caregiver plus 450ms email debounce — another 3 passed.
- 2C.5: recovery logic/full UI — 5 passed; later proof-expiry and English/Arabic small-screen+keyboard/back regressions also passed.
- 2C.6: session logic + startup/navigation — 10 passed. Additional Home profile-retry/401 regression passed after using the same guarded loader for every retry and blocking dashboard content until profile validation.
- Migrated legacy UI/onboarding/validation coverage retained: focused run of `test/auth/auth_screens_test.dart`, `verification_screens_test.dart`, `test/widget_test.dart` and `test/application/auth/auth_service_test.dart` — 30 passed. Existing health/dashboard layout tests were also retained.
- Cleanup checkpoint: `flutter test --no-pub test/auth test/application/auth test/domain test/data/network test/data/storage test/data/laravel_models_test.dart --reporter expanded` — 142 passed. Further new regressions are included in the final full suite.
- Focused review resolved: Home retry after revocation; expired cached signup proof; terminal recovery proof restart. These were reproduced by tests before fixing. Added visible recovery Back, scrollable six-digit entry and a minimal Wrap for an existing Arabic footer overflow at 318px.
- Final expiry routing: server 410 during send now returns to entry with a localized message, never automatically starts/sends another attempt. Code-only OTP expiry still allows resend; whole-attempt expiry and consumed proofs restart the flow. Route result typing was made generic without changing route names/animations.
- Final verification: `flutter analyze --no-pub` — no issues; `dart format --output=none --set-exit-if-changed` over the migration/new Dart files — 54 files, zero changes; `git diff --check` — passed. The unrelated bottom-navigation edit was explicitly excluded from formatting.
- `flutter test --no-pub --reporter expanded` — **154 passed, 0 failed, 0 skipped**. Full suite ran twice total: an initial 153-test passing checkpoint, then this required final rerun after reproducing/fixing the expired-attempt routing edge case. Other runs were focused checkpoints.
- No real WhatsApp, signup, login, password-reset, logout, database migration or data deletion was executed against the live backend. Automated HTTP is mocked.

## Source files created in 2C.3–2C.8

- `lib/application/auth/auth_scope.dart`
- `lib/presentation/auth/api_error_message.dart`
- `test/support/laravel_auth_fixture.dart`
- `test/application/auth/laravel_signup_test.dart`
- `test/application/auth/laravel_recovery_test.dart`
- `test/application/auth/laravel_session_test.dart`
- `test/auth/laravel_login_flow_test.dart`
- `test/auth/laravel_signup_flow_test.dart`
- `test/auth/laravel_seven_step_signup_test.dart`
- `test/auth/laravel_recovery_flow_test.dart`
- `test/auth/laravel_session_navigation_test.dart`
- This progress file. The temporary Laravel facade filename was consolidated into existing `auth_service.dart`; no parallel facade remains.

## Source/configuration modified

- `lib/application/auth/auth_service.dart`: Laravel facade; delegates Login to unchanged Phase 2C.2 service, implements signup/recovery/session/logout using the existing client/store/models.
- `lib/main.dart`, `lib/utils/routes.dart`, `lib/presentation/auth/auth_route_arguments.dart`: one app-owned scope, typed route results with existing animation, display-only arguments.
- Existing screens: `login_screen`, `signup_screen`, `otp_verification_screen`, `splash_screen`, `home_screen` Dart files.
- Existing widgets: `login_otp_form.dart`, `forgot_password_form.dart`, `login_footer_links.dart`. Six digits, neutral WhatsApp text, functional Back and minimal overflow fixes; original styles/fonts/colors/assets preserved.
- `lib/core/localization/app_localizations.dart`: removed three unused preview-only messages; active Arabic/English strings and directionality remain.
- `docs/laravel-api-foundation.md`, `docs/laravel-login-orchestration.md`: historical phase reports linked to this final migration status.
- `lib/domain/models/app_user.dart`, `registration_data.dart`, `lib/domain/validation/username_policy.dart`: removed Firebase persistence coupling/docs while preserving general models and validation.
- `pubspec.yaml`, `pubspec.lock`: removed Firebase core/auth/Firestore and their seven transitive Firebase packages; no unrelated upgrades or new packages.
- `android/app/build.gradle.kts`, `android/settings.gradle.kts`: removed Google services plugin. Both iOS SwiftPM `Package.resolved` files: removed the 13 obsolete Firebase dependency pins; native source had no independent consumer.
- Existing tests: `test/application/auth/auth_service_test.dart`, `test/auth/auth_screens_test.dart`, `verification_screens_test.dart`, `dashboard_fixture.dart`, `test/domain/app_user_test.dart`, `user_role_test.dart`, `test/widget_test.dart` now use Laravel/generic models instead of obsolete Firebase/Wexora fixtures.
- Ignored local IDE launch XML now uses only SANAD_API_BASE_URL; ignored Firebase IDE package references removed. Existing secure-storage/native foundation remains in place.

## Retired files (after passing replacement checkpoints)

- `lib/data/repositories/firebase_auth_repository.dart`
- `lib/data/repositories/firestore_user_repository.dart`
- `lib/data/repositories/wexora_otp_repository.dart`
- `lib/domain/repositories/auth_repository.dart`, `user_repository.dart`
- `lib/application/auth/auth_service_exception.dart`
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `firebase.rules-test.json`, `firestore.rules`
- `test/data/firebase_auth_repository_test.dart`; useful orchestration/profile/UI coverage was migrated instead of dropped.
- `tooling/firestore-rules-tests/` — auth-only rules tests/configuration and generated dependencies.
- `server/wexora-otp.js`, `server/README.md` — verified-unused legacy proxy only. Searches of both projects found no runtime consumer; the backend Phase 2B document explicitly says Flutter bypasses it and Laravel has an independent adapter. No port 8787 listener was present. No independent backend service was deleted.
- Ignored Flutter-local `wexora.local.json` credential file. No values were printed. Laravel server credentials remain untouched.

`firebase.json` was already deleted before this task; its deletion was preserved. Existing bottom-navigation changes and unrelated Postman folders were not edited. Full-suite visual previews were generated under `artifacts/`; test/build logs and the Android smoke screenshot are under ignored `build/`.

## Actual Android smoke test and remaining manual checks

- Existing Pixel_8_Pro emulator launched as `emulator-5554`, Android 14/API 34, x86_64.
- `flutter run --no-pub --no-resident -d emulator-5554 --dart-define=SANAD_API_BASE_URL=http://10.0.2.2:8000`: debug APK built, installed and launched. Initial screen inspected from an ADB screenshot: Arabic Login rendered successfully, not a storage/configuration error screen.
- The same command was executed again after the last functional route fix: incremental build/install/launch exited 0; app process was confirmed running. This is startup/native compatibility smoke coverage, not live authentication-flow completion.
- ADB TCP request from the emulator to `10.0.2.2:8000/api/health`: **HTTP 200**, SANAD health response, environment local. This verifies emulator connectivity; it is not a claim that a real OTP was exercised through the app.
- Credentials were not entered. No OTP send/verify action was triggered. Manual checks still require a deliberate test account and permission: real signup/login WhatsApp delivery, recovery queue delivery/reset, restart after real token persistence, and backend revocation after logout.
- Recovery live testing requires the existing server worker: `php artisan queue:work database --queue=auth-recovery --tries=1 --timeout=60`. This command was documented, not run here.
- iOS native build/Keychain device validation requires macOS and remains manual. No production deployment/configuration was performed.
- Remote Firebase records remain intact. No account-data migration was performed; real authentication now requires a Laravel account or new Laravel signup.

Final architecture: Flutter UI → shared application AuthService → existing Laravel API client → Laravel backend → PostgreSQL/Wexora; Sanctum tokens in SecureTokenStore only. Pending attempts/proofs remain memory-only. No Firebase fallback or direct client Wexora integration remains.
