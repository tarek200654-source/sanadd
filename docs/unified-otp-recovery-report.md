# SANAD independent password recovery report

This revision supersedes the earlier signup-screen reuse and neutral-decoy navigation design. Scope: password recovery only. Existing approved signup/login OTP masking remains in place.

## Architecture and presentation

- Recovery no longer instantiates or imports SignUpScreen, SignupStepsForm, SignupPicker, signup controllers or signup step numbering.
- RecoveryPhoneScreen owns its phone controller, country selection, request state, retry behavior and navigation. RecoveryPhoneForm and RecoveryCountryPicker copy the necessary existing phone-entry presentation into recovery-owned files. Independent colors, typography, country data and AuthFormInput remain shared.
- SignupScreen's recovery-specific branches/import were removed and its original PopScope restored. Its final content and signup visual widget files match the repository HEAD versions. No signup validation or registration behavior was redesigned.
- OtpVerificationScreen remains the single existing OTP screen. Only recovery gets the new progress header and initial-send acknowledgement handling; signup/login retain their existing OTP header and actions.
- ForgotPasswordForm preserves its input/title/typography/footer context. Its action is now localized Next / التالي and its description explains that the phone is checked next. ResetPasswordForm remains in use.

## Four-step progress and navigation

RecoveryStep owns the four states: email, phone, otp and resetPassword. RecoveryProgressHeader duplicates the signup segment style: height 4, current width 24, other widths 10, left margin 6, radius 10, 400 ms animation, and the same active/inactive colors and Back-button dimensions. It renders exactly four segments, activates all segments through the current state and is displayed on every recovery step.

| Step | Active segments | Forward action | Back action |
| --- | --- | --- | --- |
| Email | 1 | Local format + explicit server eligibility check | Existing Login view |
| Phone | 1, 2 | Canonical phone/account matching + confirmed attempt and queued send | Email |
| OTP | 1, 2, 3 | Existing server verification, producing a purpose-bound proof | Phone, discarding the pending local attempt |
| Reset | 1, 2, 3, 4 | Existing proof-authorized reset, then Login | Discard local proof/password input, recheck email eligibility and return to Phone |

Reset Back deliberately does not reuse the already verified OTP challenge. It does not send automatically; a new attempt starts only on explicit phone submission. Server-side proof expiry, binding and single-use consumption remain enforced. UI navigation or an eligibility result cannot authorize a password reset.

## Server contract

1. POST /api/auth/password/eligibility (added): EmailInputRequest validates/normalizes email. Response code recovery-eligibility-checked with data.eligible as an actual boolean. It creates no OTP attempt, job, session or token and sends no message. It returns no registered phone, role, account ID, status or verification metadata. A malformed/absent boolean is rejected by Flutter.
2. POST /api/auth/password/forgot (changed): email and canonical international phone_number are checked against current eligibility and the registered phone. Unknown, ineligible or mismatched details return generic 422 recovery-not-eligible before attempt/job creation. Only a real bound password_reset attempt returns recovery_confirmed: true with its memory-only challenge credentials. Neutral HTTP 202 alone is not accepted by Flutter.
3. POST /api/auth/password/otp/send (changed minimally): rechecks the bound eligible account before reserving a queued send; returns recovery_confirmed: true and resend_at only on accepted processing. Flutter awaits this acknowledgement on the phone step before opening OTP, then passes initialRecoveryResendAt to suppress a duplicate entry send. Retries after uncertain/transient errors reuse the same attempt and server cooldown. Queue acceptance is not proof of WhatsApp delivery.
4. Existing recovery verify and reset endpoints retain OTP/provider verification, purpose isolation, expiry/attempt limits, server proof binding, single-use reset and session revocation. Wexora, the database queue and database schema were not replaced or changed by this revision.

Eligibility and phone preparation share the existing auth-recovery throttle: 20 requests/minute/IP and 5 requests/15 minutes per normalized email+IP across both endpoints together. Existing send/verify/reset budgets and the 200 ms eligibility/preparation timebox remain in place. Login and signup routes retain their previous behavior.

## Explicit privacy tradeoff

The requested blocking outcomes intentionally permit account-eligibility enumeration. Phone-stage success/failure can also reveal whether a guessed email/phone pair qualifies. Generic localized messages, no registered-phone/profile disclosure, shared throttles, timeboxing and existing OTP limits reduce exposure; they do not eliminate enumeration, especially across distributed sources. This is a deliberate change from the previous neutral-decoy contract, authorized by the current request. Neither the boolean nor recovery_confirmed grants reset authority.

Flutter distinguishes malformed replies, connectivity/timeouts, server failures, throttling and generic ineligible details. It captures the submitted canonical email and invalidates an asynchronous result if the user edits that email while waiting, so an unchecked email cannot advance.

## Files in this revision

Modified Flutter production files:

- lib/application/auth/auth_service.dart
- lib/presentation/auth/api_error_message.dart
- lib/presentation/screens/login_screen/login_screen.dart
- lib/presentation/screens/signup_screen/signup_screen.dart (recovery integration removed; original signup restored)
- lib/presentation/screens/otp_verification_screen/otp_verification_screen.dart (recovery-only behavior/header)
- lib/presentation/widgets/login_screen_widgets/forgot_password_form.dart

Added Flutter production files:

- lib/presentation/screens/recovery_phone_screen/recovery_phone_screen.dart
- lib/presentation/widgets/recovery_widgets/recovery_phone_form.dart
- lib/presentation/widgets/recovery_widgets/recovery_country_picker.dart
- lib/presentation/widgets/recovery_widgets/recovery_progress_header.dart

Modified/added Flutter tests:

- test/application/auth/laravel_recovery_test.dart
- test/auth/laravel_recovery_flow_test.dart
- test/support/laravel_auth_fixture.dart
- test/auth/recovery_phone_design_test.dart (added)

Modified Laravel files:

- app/Application/Auth/PasswordRecovery.php
- app/Application/Auth/AuthFlowException.php
- app/Http/Controllers/PasswordRecoveryController.php
- routes/api.php
- tests/Feature/PasswordRecoveryTest.php
- docs/password-recovery.md

Documentation in Flutter:

- docs/unified-otp-recovery-report.md (this updated report)
- docs/superpowers/plans/2026-11-08-independent-recovery-validation.md (added plan/ledger)

No file was deleted in this revision. The only removed integration is recovery-specific branching/navigation inside SignupScreen and LoginScreen. The previously verified deletion of login_otp_form.dart remains from the earlier shared-OTP task. Other earlier-stage working-tree edits are retained; no unrelated caregiver-link files, migrations or Postman exports were changed by this revision.

## Verification

- Final flutter analyze --no-pub: no issues (installed Flutter tools snapshot invocation).
- Final full Flutter suite: 186 tests passed. Includes unknown/invalid email blocking, in-flight email edit, malformed eligibility response, mismatch and missing-confirmation blocking, phone formatting, country selection, dedicated-screen isolation, four segment states, Back/reset behavior, one entry send, transient/lost send acknowledgement plus cooldown, resend/expiry, Arabic/English, RTL, small screen/keyboard, signup/login/session and reset-proof regression.
- Dedicated presentation comparisons passed in both languages: same-frame field/button dimensions and positions, title/subtitle/button/country text styles, and leading-zero formatter behavior match the original signup phone step. This is automated geometry/style verification, not a physical-device pixel comparison.
- Relevant Laravel authentication suite: 123 passed / 1683 assertions. Latest recovery-only run after the generic backend message change: 21 passed / 361 assertions.
- Earlier complete Laravel suite passed 165 tests / 1923 assertions before additional unrelated caregiver-link tests appeared in the working tree. The latest comprehensive run executed 176 tests: 165 passed and 11 failed, all in CaregiverLinkSchemaTest (missing caregiver_links table/related schema expectations). These failures are outside recovery and were left untouched as requested. A separate current authentication suite is recorded below once complete.
- Independent review found an editable-email asynchronous race; a regression test reproduced it and passed after correction. No other blocking recovery/security issue was reported.
- Logs: artifacts/recovery-final-analyze.log and artifacts/recovery-final-tests.log.

Names of the 11 unrelated comprehensive-run failures, all within CaregiverLinkSchemaTest:

- test_additive_schema_preserves_users_and_enforces_three_slots
- test_database_rejects_invalid_rows_without_application_validation: bad status; live without slot; active without acceptance; pending with acceptance; terminal without metadata; terminal occupying slot; missing participant
- test_database_rejects_duplicate_live_pair_or_slot: data sets #0 and #1
- test_policy_grants_access_only_after_acceptance_and_removes_it_on_revocation

## Remaining limits and compatibility

Live Wexora delivery and a manual physical-device run were not performed; provider HTTP calls were faked in Laravel tests. No live messages, production migration, commit, push or deployment was performed. Existing queue/migration prerequisites still apply; see backend docs/password-recovery.md.

Old clients expecting neutral recovery starts must migrate to the explicit eligibility + confirmed start/send contract. Unrelated full-suite caregiver schema failures remain as described above.
