# Independent password recovery validation and progress

Implement the user's current specification in the existing checkout. It supersedes the prior neutral-decoy navigation contract and signup-screen reuse. No dependency/schema/provider changes.

1. Tests first: separate email eligibility endpoint must return an explicit boolean, create no attempts/jobs/tokens and share existing recovery throttles. Phone mismatch must return a generic recovery error and create no attempt/job; valid pairs must return explicit confirmation. Keep reset proof, expiry, replay, purpose and revocation tests.
2. Laravel: add `/auth/password/eligibility` with `EmailInputRequest`; reuse server eligibility rules and timebox. Reject ineligible/mismatched pairs at `/password/forgot` before creating an attempt. Add `recovery_confirmed: true` to actual start/send acknowledgements; recheck account binding before queue reservation. Existing send/verify/reset purposes and limits remain.
3. Flutter: strictly validate response code/data/boolean confirmation. Email validates remotely before opening a dedicated `RecoveryPhoneScreen`. The phone screen copies only the existing phone UI, picker and formatter into recovery-owned widgets/state. It starts a real attempt and queues the first send before opening the existing OTP screen with its server resend time; OTP must not dispatch twice on entry. Transient send retries reuse the same pending attempt.
4. Remove recovery branches and imports from `SignUpScreen`; restore signup's original PopScope type. Signup-owned widgets remain untouched.
5. Add `RecoveryStep` and a recovery-only four-segment/back header matching existing segment dimensions and colors. Use email/phone/OTP/reset states, including OTP's conditional recovery presentation only. Reset Back discards the consumed verification proof and returns to phone through eligibility validation; entering phone never sends automatically.
6. Regression tests: unknown/eligible email, invalid/mismatched phone, explicit-confirmation fail-closed, server/network errors, one dispatch, four progress states, back navigation, locale/RTL, country selection, keyboard/small devices, signup/login regression and proof protections.
7. Run full Flutter analysis/tests and guarded PostgreSQL Laravel tests; independent final review. Update the report with exact files, new contract, enumeration tradeoff and live-provider/visual verification limits.

Security decision: eligibility and explicit phone rejection intentionally disclose whether details qualify. Generic errors, no registered phone/profile disclosure, shared throttles and the existing timebox reduce exposure; they do not eliminate enumeration. Neither eligibility nor UI navigation grants reset authority.

Execution ledger:

- RED observed: missing eligibility endpoint; mismatch incorrectly returned neutral 202; no explicit real-attempt confirmation; Flutter tests still found signup integration. Implemented the new explicit contract and dedicated UI; regression tests passed.
- Email eligibility never creates an attempt/job/token. Phone match and queue acknowledgement are separately validated before navigation. Missing booleans/confirmations fail closed.
- Recovery-owned phone/picker/progress files added; signup source and visual widgets match original HEAD after removing obsolete integration. No schema/dependency/provider changes by this task.
- Geometry/style comparisons for phone entry passed in English and Arabic. All four progress states, country selection, keyboard/small viewport, purpose-bound reset, Back behavior and retry/cooldown were exercised.
- Independent review found an asynchronous edited-email race. A delayed-response regression failed before the fix and passed after snapshotting/invalidation. Added lost-send-acknowledgement/cooldown coverage and backend assertion that cooldown refusal enqueues no extra job.
- Final Flutter analysis: no issues. Full Flutter suite: 186 passed.
- Relevant Laravel authentication suite: 123 passed / 1683 assertions. Latest recovery-only verification: 21 passed / 361 assertions.
- Earlier full Laravel run: 165 passed / 1923 assertions. Latest comprehensive run after unrelated caregiver-link files appeared: 176 tests, 165 passed and 11 failures in CaregiverLinkSchemaTest. Left unrelated schema work untouched; failure names and details are in docs/unified-otp-recovery-report.md.
- Backend API documentation and implementation report updated with the explicit enumeration tradeoff. Live provider delivery/physical-device pixel parity were not claimed tested.
