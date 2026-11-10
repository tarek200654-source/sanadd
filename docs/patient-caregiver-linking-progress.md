# Patient–Caregiver linking progress

Approved plan: Phase 3A schema/authorization → 3B APIs → 3C Flutter → 3D verification.

- [x] 3A: additive PostgreSQL schema, transaction service and authorization.
- [x] 3B: authenticated APIs, concurrency tests and Postman collection.
- [x] 3C: shared dedicated section, Home/Profile entries, confirmation and history.
- [x] 3D: regression checks, independent review and handoff.

## Constraints and rulings

- Preserve all existing uncommitted authentication and unrelated changes. Work in the explicitly approved existing directories; no commits, branches or dependency installations.
- All automated database operations use the existing guarded `sanad_test_db` harness. Never apply migrations to `sanad_db` automatically; no live external provider calls or real relationships.
- History is included in Flutter per the implementation approval. Home and Profile open the same section; all five bottom tabs remain intact.
- Invitation creation consumes the API's exact username, not a client-supplied user ID. Public summaries contain name/username only.
- Slot counts are independent of pagination/history filters. Uncertain mutations require a successful server refresh before retry.
- Reuse installed dependencies; AGENTS.md's generic Boost installation bootstrap is outside this approved feature scope, consistent with prior repository implementation rulings.

## Evidence

- 3A RED: 11 schema/policy tests failed on absent table. GREEN: 11 passed, 108 assertions against isolated PostgreSQL schemas. Unique live pair/slot indexes and null-safe lifecycle constraints verified.
- 3B RED: 9 API tests failed on absent routes. GREEN: combined schema/API/concurrency checkpoint: 25 passed, 473 assertions. Five synchronized two-process races verified duplicate invitations, last-slot competition, accept/cancel, double acceptance and double revocation. Earlier invalid lookup correctly counts toward throttling; test expectation corrected.
- 3C RED: service/controller and dedicated-screen tests failed on missing implementations. GREEN: 11 focused Flutter tests passed (logic, transport, pagination/history, uncertain mutation reconciliation, session/token changes, English/Arabic confirmation, lifecycle UI, responsive/keyboard layout and both Home/Profile navigation entries). Scroll interaction tests explicitly wait for layout and build offscreen list entries before tapping.
- Ruling: add optional structured GET query parameters to the existing ApiClient. ApiConfig deliberately rejects embedded query strings; bounded list pagination/history needs a safe transport interface without loosening origin/path validation.

- Read-only PostgreSQL preflight: local PostgreSQL 18.6, `sanad_test_db`, `sanad_app`, zero leftover schemas.
- Installed PHP is Herd PHP 8.5 (requires sandbox escalation); Flutter SDK from `android/local.properties`: `D:\FlutterDart\SDKS\flutter`.

## Final verification

- Full Laravel suite: **190 passed, 2397 assertions**. After additional constraint/three-active-caregiver tests and extending test-schema cleanup diagnostics, final focused `--filter 'CaregiverLink|PostgresTest'`: **50 passed, 544 assertions**, including 30 relationship cases and five synchronized two-process races. Backend production code was unchanged after the full run; the expensive full suite was not repeated for test-only additions.
- Final full Flutter suite: **203 passed**. The full suite was repeated once after review fixes changed shared transport/reconciliation. Final focused relationship suite: **17 passed**; relationship plus existing network transport tests also passed during review verification.
- Full Flutter analysis: **No issues found**. Logs: `artifacts/phase3-flutter-all-tests.log`, `artifacts/phase3-flutter-analyze.log`, `artifacts/phase3-flutter-focused.log`.
- PHP syntax passed for all 19 touched PHP files; final Pint `--test` passed. Final changed-file whitespace check passed.
- Postman static verification passed: valid JSON, 13 requests, all script syntax, blank credentials and loopback-only origin guards. Test command: `node tests/verify-phase3-postman.cjs`; no HTTP sent.
- Final PostgreSQL read-only preflight: `sanad_test_db`, local PostgreSQL 18.6, `sanad_app`, **zero remaining test schemas**, including the new link-race namespace.
- Independent read-only review found an important pagination/reconciliation issue. RED regression reproduced it; fixed by requiring a full replacement refresh before unlocking writes. Review confirmed the fix with no remaining Critical/Important findings. Added a separate transport regression: no HTTP dispatch when the captured session token differs from the current token.
- Ruling: expected-token binding is an optional addition to existing GET/POST transport; existing auth callers remain unchanged. Relationship requests use it to prevent an old screen's action from being sent under a replacement account.
- Only `emulator-5554` is attached; no physical Android device. Physical-device UI/backend smoke testing and live delivery were not performed. No real relationships, notifications, commits, pushes or deployments were created.

## Changed files — Phase 3 only

Paths are relative to their respective repository root. Earlier and concurrently present authentication/UI edits are excluded from this inventory and preserved. No Phase 3 files were removed.

Flutter added:

- `lib/application/caregiving/caregiver_links_service.dart`
- `lib/application/caregiving/caregiver_links_controller.dart`
- `lib/domain/models/caregiver_link.dart`
- `lib/core/localization/caregiving_localizations.dart`
- `lib/presentation/screens/caregiver_links_screen/caregiver_links_screen.dart`
- `test/caregiving/caregiver_links_test.dart`
- `test/caregiving/caregiver_links_screen_test.dart`
- `docs/patient-caregiver-linking-progress.md`

Flutter modified:

- `lib/data/network/api_client.dart`
- `lib/data/network/api_exception.dart`
- `lib/presentation/screens/home_screen/home_screen.dart`
- `lib/utils/routes.dart`

Laravel added:

- `database/migrations/2026_11_08_000000_create_caregiver_links_table.php`
- `app/Enums/CaregiverLinkStatus.php`
- `app/Models/CaregiverLink.php`
- `app/Application/Caregiving/CaregiverLinks.php`
- `app/Application/Caregiving/LinkFailure.php`
- `app/Policies/CaregiverLinkPolicy.php`
- `app/Policies/PatientDataPolicy.php`
- `app/Http/Controllers/CaregiverLinkController.php`
- `app/Http/Requests/CaregiverLinkRequest.php`
- `app/Http/Resources/CaregiverLinkResource.php`
- `tests/Feature/CaregiverLinkSchemaTest.php`
- `tests/Feature/CaregiverLinkApiTest.php`
- `tests/Feature/CaregiverLinkConcurrencyTest.php`
- `tests/Support/CaregiverLinkTables.php`
- `tests/caregiver-race-worker.php`
- `tests/verify-phase3-postman.cjs`
- `postman/SANAD-Phase-3.postman_collection.json`
- `docs/patient-caregiver-linking.md`

Laravel modified:

- `routes/api.php` (preserving the existing recovery-eligibility route)
- `bootstrap/app.php`
- `app/Providers/AppServiceProvider.php`
- `tests/Support/PostgresTestDatabase.php` (include link-race schemas in read-only cleanup diagnostics)

## Schema, routes and manual testing

Full schema, exact routes, response/error contracts, authorization/concurrency details, Postman instructions and the physical-device checklist are in backend `docs/patient-caregiver-linking.md`.

## Remaining manual steps

Migration remains pending against `sanad_db`. No physical-device relationships or notifications will be created automatically.

From `sanad_backend`, after manually confirming the intended local database and reviewing migration SQL:

```powershell
& 'C:\Users\Ouffaa\.config\herd\bin\php85\php.exe' artisan migrate --database=pgsql --path=database/migrations/2026_11_08_000000_create_caregiver_links_table.php
```

Do not consider Phase 3 operational on `sanad_db` until this deliberate migration and approved-account manual verification are complete. Future health APIs need endpoint-specific permissions in addition to the active-link eligibility gate. Push notifications are not implemented.
