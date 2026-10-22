# Firebase Authentication Implementation Plan

> **For agentic workers:** Implement each task in order using the test-driven-development skill. Keep each step reviewable and preserve all existing screen visuals.

**Goal:** Connect returning-user login and the separate seven-step signup flow to Firebase Auth and Firestore, including unique usernames, profile security, and restored sessions.

**Architecture:** Extend the existing application service and repository contracts. Persist the Auth UID profile and lowercase username reservation in one Firestore transaction, enforce the same contract in Firestore rules, and connect the existing login, OTP, and splash flows through injectable services.

**Tech Stack:** Flutter/Dart, Firebase Authentication, Cloud Firestore, Firestore Security Rules, Flutter unit/widget tests, Firestore Emulator rules tests.

**Spec:** `docs/superpowers/specs/2026-10-22-firebase-auth-design.md`

## Global Constraints

- Preserve the approved UI exactly; only connect behavior and localized error text.
- Usernames are 4–15 characters from `[A-Za-z0-9._]`, compared case-insensitively.
- Passwords remain opaque and unchanged; never store passwords or hashes in Firestore.
- Firestore owns uniqueness and authorization; UI checks are feedback only.
- Keep patient/caregiver role from route arguments and immutable after profile creation.
- Use local fakes/emulators only; do not create production accounts or send OTPs.

## Review Focus

- Concurrent attempts to claim the same username must leave one owner and one profile.
- Registration failures after Firebase account creation must delete that account; report rollback failure safely.
- Arabic/English names, punctuation in email local parts, and password strings containing SQL-like punctuation must be preserved.
- A login with a missing/invalid profile must sign out instead of reaching `/home`.
- A signed-in user must not read another user's private profile or change their role/username.

---

### Task 1: Registration validation and profile model

**Files:**
- Modify `lib/presentation/auth/validation/auth_validators.dart`.
- Modify `lib/domain/models/app_user.dart`.
- Create `lib/domain/models/registration_data.dart`.
- Test `test/auth/auth_validators_test.dart` and `test/domain/app_user_test.dart`.

**Interfaces:**
- `AuthValidators.validateUsername(String? value)` returns the existing validation enum or `null`.
- `RegistrationData` holds username, first/last name, email, password, role, country, region, address, and normalized phone number.
- `AppUser` serializes all profile fields except password; old optional profile fields remain readable where valid.

- [ ] Add failing tests for username boundaries/characters/case normalization, Unicode names and addresses, and profile serialization that never includes password.
- [ ] Run the targeted tests and confirm the expected failures.
- [ ] Implement the validator and profile data/model fields.
- [ ] Rerun the targeted tests.

### Task 2: Atomic username reservation and secure rules

**Files:**
- Modify `lib/domain/repositories/user_repository.dart`.
- Modify `lib/data/repositories/firestore_user_repository.dart`.
- Modify `firebase.json` and create `firestore.rules`.
- Create local Firestore rules tests and their minimal isolated Node test configuration.

**Interfaces:**
- `UserRepository.isUsernameAvailable(String username)` performs a single canonical reservation lookup.
- `UserRepository.createUser(AppUser user)` writes the profile and username reservation in one transaction.
- A typed username-conflict failure distinguishes collision from unavailable/invalid profile failures.

- [ ] Add failing unit/emulator tests for availability, duplicate claims, transaction coupling, private profile reads, owner isolation, and immutable role/username.
- [ ] Run the tests against the Firestore emulator and verify they fail for the missing behavior/rules.
- [ ] Implement the transaction and restrictive rules; allow only direct username reservation reads and deny reservation listing.
- [ ] Rerun repository tests and Firestore rules tests.

### Task 3: Auth service, rollback, and session restoration

**Files:**
- Modify `lib/application/auth/auth_service.dart`, `auth_failure.dart`, and `auth_service_exception.dart`.
- Modify `lib/domain/repositories/auth_repository.dart` only if needed by tests.
- Create `test/application/auth/auth_service_test.dart` with deterministic fake repositories.

**Interfaces:**
- `AuthService.register(RegistrationData data)` creates Auth first, stores the complete profile transactionally, and deletes the newly created account on profile failure.
- `AuthService.signIn({required String email, required String password})` returns a profile only after successful profile loading.
- `AuthService.restoreCurrentUser()` returns the current profile or signs out and returns `null` for incomplete/invalid profiles.
- `AuthService.authStateChanges()` and `signOut()` retain explicit behavior.

- [ ] Add failing service tests for successful registration, username collision rollback, profile-write rollback failure, invalid login, missing profile sign-out, and session restoration.
- [ ] Run them and confirm the expected failures.
- [ ] Implement the minimum service and typed failure mapping.
- [ ] Rerun service tests.

### Task 4: Connect existing UI logic without visual changes

**Files:**
- Modify `lib/presentation/auth/auth_route_arguments.dart`.
- Modify `lib/presentation/screens/login_screen/login_screen.dart` for returning-user login and recovery.
- Modify `lib/presentation/screens/signup_screen/signup_screen.dart` for the seven-step new-user registration flow.
- Modify `lib/presentation/screens/otp_verification_screen/otp_verification_screen.dart`.
- Modify `lib/presentation/screens/splash_screen/splash_screen.dart`.
- Modify `lib/core/localization/app_localizations.dart` for safe error messages.
- Keep signup-specific widgets under `lib/presentation/widgets/signup_screen_widgets/`; reusable auth inputs and password indicators belong under `shared_widgets/`.
- Test `test/auth/auth_screens_test.dart` and `test/auth/verification_screens_test.dart`.

- [ ] Add failing widget tests using fake AuthService for loading/duplicate-submit behavior, login success/error, OTP-backed complete registration, and splash session restoration.
- [ ] Run those tests and confirm the expected failures.
- [ ] Replace preview actions with service calls, carry the complete registration data in memory through OTP, preserve selected role, and route successful auth to the existing home route.
- [ ] Ensure no UI style/layout/asset values changed; rerun the widget tests.

### Task 5: Whole-project verification and setup report

**Files:**
- Update README only for required Firebase Console/rules-emulator setup if needed.

- [ ] Run `dart format --output=none --set-exit-if-changed .`.
- [ ] Run `flutter analyze` and fix errors/warnings introduced by this work.
- [ ] Run `flutter test`.
- [ ] Run Firestore rules tests using the local emulator.
- [ ] Run `flutter build apk --debug`.
- [ ] Inspect the diff and confirm existing UI constants, layout hierarchy, and assets were not visually changed.
