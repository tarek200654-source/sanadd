# Unified OTP and matching WhatsApp recovery

Source of requirements: user's SANAD specification in the current conversation. Execute in the existing working directories, preserving the already authorized OTP unification and back-arrow changes. No dependencies, migrations, new screens, provider changes, or unrelated cleanup.

1. Extend Laravel credential-validation success with `masked_phone_number`, containing the supported calling code and final four digits only. Test valid/invalid credentials, supported calling codes, and absence of complete phone numbers or sessions before OTP.
2. Require canonical international `phone_number` with email at `/auth/password/forgot`. Trim consistently with registration, then validate the existing international format. Bind real recovery attempts only when the submitted number exactly matches the eligible account. Preserve decoy responses, timing, throttling, queued dispatch, purpose-bound proof, expiry and single-use reset. Update existing recovery test callers; add mismatch, missing/invalid number, no-delivery/no-proof tests.
3. Reuse `SignUpScreen`, `SignupStepsForm` step 4 and `SignupPicker` unchanged visually, selecting recovery context via existing route arguments. Email advances to this phone step without an API call; phone submission starts recovery; shared OTP success returns to the existing reset form. Back returns to phone, then email; signup navigation remains unchanged.
4. Normalize masked displays to `+20 •••••• 5678` using existing supported calling codes. Recovery uses the submitted number; signup uses registration input; login uses backend-only masked data. Test Arabic/English, country selection, short viewport/keyboard, retry/resend/error and next destinations.
5. Run Flutter analysis and tests plus guarded PostgreSQL Laravel tests. Review the diff and obsolete references. The obsolete `LoginOtpForm` was removed only after prior passing full tests; no additional deletion is planned.

Review focus: mismatched recovery numbers must never deliver or verify; masked data must not leak more than four national digits; OTP success must retain recovery proof across both route pops; country picker must remain identical; back/retry/network failures must preserve or discard the correct purpose-bound attempt.

Verification ledger:
- Prior stage: 158 Flutter tests passed; changed-file Dart analysis passed; existing OTP UI reused without design changes.
- Completed: credential-validated login masked response; required canonical recovery phone with neutral mismatch behavior; existing signup phone step reused in recovery; supported calling-code masking; no dependencies, migrations or provider edits.
- RED observed: recovery UI expected existing phone step but found OTP directly; masked calling-code assertions failed; backend mismatch test observed an unauthorized delivery; missing/invalid phone test returned 202. These passed after implementation.
- Final Flutter verification: `flutter analyze --no-pub` equivalent via installed Flutter tools snapshot: no issues. Full `flutter test --no-pub`: 170 passed.
- Final Laravel verification: full guarded PostgreSQL PHPUnit suite: 163 passed, 1922 assertions; focused authentication/recovery suite: 40 passed, 757 assertions. No live provider requests.
- Fresh independent review found no blocking security/navigation issues. Supported picker codes covered; unknown calling codes omit the prefix rather than guessing.
- Optional pixel comparison was not retained: asynchronous Google Fonts loading made image comparison unreliable in this test environment. Existing phone/picker design widgets were not modified; widget tests cover both languages, picker interaction and small-screen/keyboard navigation. Physical-device visual parity and live WhatsApp delivery remain unverified.
