# SANAD Authentication UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete bilingual SANAD authentication UI flow with local validation and truthful UI-preview behavior, without backend authentication.

**Architecture:** Keep `MaterialApp.onGenerateRoute` as the sole navigation mechanism. Add a small auth presentation module with typed route arguments, validation helpers, reusable auth widgets, and four screens. Extend the existing hand-written localization and use the current theme/colors/fonts/assets.

**Tech Stack:** Flutter/Dart 3.11, Material 3, existing `flutter_test`, `shared_preferences` test setup, no new packages.

**Spec:** `docs/superpowers/specs/2026-10-21-authentication-ui-design.md`

## Global Constraints

- UI implementation only: no Firebase Authentication, Firestore, email delivery, SMS service, account creation, or actual verification.
- Preserve the established `onGenerateRoute`, localization, theme, role model, and existing Firebase configuration.
- Keep email, phone, OTP, and password-manager input handling safe and directionally correct; never log or persist credentials.
- Use SafeArea, scrollable/keyboard-aware layouts, accessible tap targets, and responsive constraints.
- All visible strings and feedback must be localized in Arabic and English; do not show both languages at once.

## Review Focus

- Password requirement boundaries: exactly 8 characters must fail, exactly 9 with all classes must pass, and every individual class must update live.
- Mixed-direction credentials: Arabic layout must retain LTR email, phone, and six-digit OTP ordering.
- Incomplete presentation flow: valid forms must never enter Home or claim account/code success.
- Small screens and keyboard: long signup content must scroll without RenderFlex overflow.
- Unavailable SMS: tapping it must provide localized feedback without selecting, sending, or navigating.

---

### Task 1: Auth validation and route data contracts

**Files:**
- Create: `lib/presentation/auth/auth_route_arguments.dart`
- Create: `lib/presentation/auth/validation/auth_validators.dart`
- Create: `test/auth/auth_validators_test.dart`

**Interfaces:**
- Produces `AuthRouteArguments({required UserRole role, String? email})`, `AuthValidators`, `PasswordValidation`, and `PasswordRequirement` for screens/widgets.

- [ ] **Step 1: Write failing validator tests** for trimmed required names, email format, phone digit bounds, all five password requirements, strength guidance, and exact confirm-password matching.
- [ ] **Step 2: Run `flutter test test/auth/auth_validators_test.dart`** and confirm failure because the new validator library is absent.
- [ ] **Step 3: Implement the typed route argument and pure validation helpers** with no UI or backend dependencies.
- [ ] **Step 4: Run the focused validator test and confirm all cases pass.**
- [ ] **Step 5: Commit** `feat: add authentication validation contracts`.

### Task 2: Localized auth strings and reusable auth widgets

**Files:**
- Modify: `lib/core/localization/app_localizations.dart`
- Create: `lib/presentation/widgets/auth/auth_header.dart`
- Create: `lib/presentation/widgets/auth/auth_text_field.dart`
- Create: `lib/presentation/widgets/auth/password_requirements.dart`
- Create: `lib/presentation/widgets/auth/verification_method_card.dart`
- Create: `lib/presentation/widgets/auth/otp_input.dart`
- Create: `test/auth/auth_widgets_test.dart`

**Interfaces:**
- Consumes Task 1 validation models and current `AppColor`/`AppAssets`/`SanadButton` conventions.
- Produces reusable localized widgets for text/password fields, password checklist/strength, verification cards, and six-digit OTP entry.

- [ ] **Step 1: Write failing widget tests** for hidden-then-visible password requirements, live completion indicators, accessible password toggles, and six-digit OTP focus/paste/delete behavior.
- [ ] **Step 2: Run `flutter test test/auth/auth_widgets_test.dart`** and confirm failure because the auth widgets are absent.
- [ ] **Step 3: Add localized strings and implement the shared widgets** with LTR overrides for credentials/OTP, semantics, and no password logging/storage.
- [ ] **Step 4: Run the focused widget test and confirm it passes at English and Arabic locales.**
- [ ] **Step 5: Commit** `feat: add localized authentication widgets`.

### Task 3: Login, signup, and role-preserving navigation

**Files:**
- Create: `lib/presentation/screens/login_screen/login_screen.dart`
- Create: `lib/presentation/screens/signup_screen/signup_screen.dart`
- Modify: `lib/presentation/screens/role_selection/role_selection_screen.dart`
- Modify: `lib/utils/routes.dart`
- Modify: `test/widget_test.dart`
- Create: `test/auth/auth_screens_test.dart`

**Interfaces:**
- Consumes Task 1 route/validation contracts and Task 2 widgets/localization.
- Produces `/login` and `/signup`; valid login shows a localized not-connected message; valid signup pushes `/verification-method` with the entered email and selected role.

- [ ] **Step 1: Write failing screen tests** for role-to-login navigation, login required/invalid validation and no Home navigation, signup required/terms/password validation, and valid signup preserving email/role to the next route.
- [ ] **Step 2: Run `flutter test test/auth/auth_screens_test.dart test/widget_test.dart`** and confirm failure from missing routes/screens.
- [ ] **Step 3: Implement routes, role transition, login, and signup** using SafeArea + scrollable keyboard-aware layouts, local form validation, password visibility, country code selection, and no backend calls.
- [ ] **Step 4: Run the focused screen tests and existing widget tests; confirm all pass.**
- [ ] **Step 5: Commit** `feat: implement login and signup presentation`.

### Task 4: Verification method and OTP presentation

**Files:**
- Create: `lib/presentation/screens/verification_method_screen/verification_method_screen.dart`
- Create: `lib/presentation/screens/otp_verification_screen/otp_verification_screen.dart`
- Create: `test/auth/verification_screens_test.dart`
- Modify: `lib/utils/routes.dart`

**Interfaces:**
- Consumes Task 1 route arguments and Task 2 verification/OTP widgets.
- Produces `/verification-method` and `/otp-verification` with email masking, email-only selection, localized unavailable-SMS feedback, and truthful OTP preview behavior.

- [ ] **Step 1: Write failing verification tests** for masked email, SMS unavailable feedback, email selection/continue, OTP incomplete error, and six-digit not-connected feedback without success navigation.
- [ ] **Step 2: Run `flutter test test/auth/verification_screens_test.dart`** and confirm failure from missing screens/routes.
- [ ] **Step 3: Implement both screens** with typed route data, responsive SafeArea layouts, no active resend countdown, and no fake provider behavior.
- [ ] **Step 4: Run the focused verification tests and confirm all pass in both locale directions.**
- [ ] **Step 5: Commit** `feat: add verification presentation flow`.

### Task 5: Whole-project verification

**Files:**
- Modify: any auth files needed for analyzer/test fixes only.

- [ ] **Step 1: Run `flutter analyze` and fix introduced analyzer errors/warnings without changing unrelated code.**
- [ ] **Step 2: Run `flutter test` and confirm the full suite passes.**
- [ ] **Step 3: Run a debug Android build or the repository's available build command and record the result.**
- [ ] **Step 4: Review the diff for backend calls, password persistence/logging, unsupported claims, localization gaps, and accidental unrelated changes.**
