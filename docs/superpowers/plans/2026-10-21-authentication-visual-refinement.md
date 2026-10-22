# SANAD Authentication UI Visual Refinement Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine all four existing SANAD authentication screens to match the available compact mobile references while preserving their current behavior.

**Architecture:** Retain `AuthPageLayout`, `AuthHeader`, the shared auth fields/cards, `SanadButton`, route arguments, and existing screen state. Add compact visual options to the existing shared widgets, then tune each screen’s hierarchy and spacing without changing backend or navigation behavior.

**Tech Stack:** Existing Flutter/Dart and Material widgets, hand-written localizations, `flutter_test`, Android Gradle build; no new dependencies.

**Spec:** `docs/superpowers/specs/2026-10-21-authentication-visual-refinement-design.md` and the user’s screenshot-refinement request.

## Global Constraints

- Preserve all existing auth validation and presentation-only behavior.
- Use existing SANAD colors and Arabic/English fonts; show only the selected language.
- Keep SMS unavailable, email selected, and OTP actions honest preview-only states.
- Keep RTL/LTR layout and force only mixed-direction credentials to LTR.
- Maintain touch targets of at least 48 dp where practical, SafeArea, and scroll behavior.
- Add no packages, backend calls, unsupported claims, or unrelated screen changes.

## Review Focus

- 318×644 initial Sign Up: primary action must be visible without the keyboard and no overflow occurs.
- Focused password requirements on short screens: checklist remains readable and scrollable without hiding field errors.
- Arabic versus English: back affordance and text alignment follow locale while email, phone, password, and OTP values remain LTR.
- Keyboard-open states: compact content scrolls and no CTA overlaps the keyboard.
- SMS preview: card remains visibly unavailable, tapping gives localized feedback, and email remains selected.

---

### Task 1: Pin compact-screen layout behavior

**Files:**
- Modify: `test/auth/auth_screens_test.dart`
- Modify: `test/auth/verification_screens_test.dart`

**Interfaces:** Consumes the existing four screen widgets and current test harnesses; no production API changes.

- [x] Add compact-size screen tests at `Size(318, 644)` that assert Login, Sign Up, and Verification primary actions are visible at rest and that all four screens produce no framework layout exception; extend them to standard/tall sizes and representative insets.
- [x] Add Arabic compact rendering assertions for directional heading alignment, back-arrow direction, and LTR field/OTP content.
- [x] Run focused tests and verify the new layout expectations fail against the current composition.

### Task 2: Refine shared auth presentation widgets

**Files:**
- Modify: `lib/presentation/widgets/auth/auth_header.dart`
- Modify: `lib/presentation/widgets/auth/auth_text_field.dart`
- Modify: `lib/presentation/widgets/auth/password_requirements.dart`
- Modify: `lib/presentation/widgets/auth/verification_method_card.dart`
- Modify: `lib/presentation/widgets/auth/otp_input.dart`
- Modify: `lib/presentation/widgets/sanad_button.dart`
- Modify: `test/auth/auth_widgets_test.dart`

**Interfaces:** Consumes current localization/theme and validation model. Produces `AuthHeader({String? topBarTitle, IconData? trailingIcon, IconData? heroIcon, bool centerTitle = false, double titleFontSize = 20})`, `AuthTextField({bool labelAbove = false, bool compact = false, Widget? suffixIcon})`, `AuthPasswordField({bool labelAbove = false, bool compact = false, bool showLockIcon = false})`, `VerificationMethodCard({String? valueText, String? unavailableLabel})`, width-aware `OtpInput`, and `SanadButton({double height = 60})`. Defaults preserve current consumers; auth screens opt into compact sizing.

- [x] Add widget tests named `auth button honors compact accessible height`, `compact labeled field stays within reference height`, `verification card shows masked value`, and `OTP cells fit reference content width`.
- [x] Run the focused widget tests and verify the geometry assertions fail before implementation.
- [x] Implement compact presentation while preserving existing default behavior for consumers outside the auth screens.
- [x] Run `flutter test test/auth/auth_widgets_test.dart`.

### Task 3: Refine Login and Sign Up composition

**Files:**
- Modify: `lib/presentation/screens/login_screen/login_screen.dart`
- Modify: `lib/presentation/screens/signup_screen/signup_screen.dart`
- Modify: `lib/core/localization/app_localizations.dart` only for new localized visible labels/semantics.
- Modify: `test/auth/auth_screens_test.dart`

**Interfaces:** Consumes Task 2's `AuthHeader`, `AuthTextField`, `AuthPasswordField`, and `SanadButton` options; preserves existing controllers, validators, route arguments, and submit callbacks.

- [x] Add assertions for Sign Up’s compact initial viewport in English and Arabic, including login/heading direction and LTR credentials.
- [x] Run the focused screen tests and verify the compact action bounds fail against the current screen composition.
- [x] Implement the centered Login welcome mark and compact hierarchy; place the action before the privacy reassurance and account navigation.
- [x] Compact Sign Up header, fields, country selector row, terms/privacy section, and footer. Keep the requirement checklist hidden initially and preserve its focus/error visibility rules.
- [x] Run `flutter test test/auth/auth_screens_test.dart`.

### Task 4: Refine Verification Method and OTP composition

**Files:**
- Modify: `lib/presentation/screens/verification_method_screen/verification_method_screen.dart`
- Modify: `lib/presentation/screens/otp_verification_screen/otp_verification_screen.dart`
- Modify: `test/auth/verification_screens_test.dart`

**Interfaces:** Consumes Task 2's compact header/card/button/OTP widgets; keeps `AuthRouteArguments`, `maskEmail`, SMS feedback, OTP callbacks, and preview-only copy unchanged.

- [x] Add assertions that the masked email is presented inside the selected email card and that the action remains visible at compact size.
- [x] Run the focused verification tests and verify the new action-bound assertion fails against the current composition.
- [x] Implement compact verification and OTP headings, illustration scale, method-card hierarchy, and bottom action spacing.
- [x] Run `flutter test test/auth/verification_screens_test.dart`.

### Task 5: Final visual and build verification

**Files:**
- Modify: only auth files if a verified visual/layout issue requires correction.

- [x] Run `flutter analyze` and the complete `flutter test` suite.
- [x] Build the Android debug application.
- [x] Capture and inspect Login, Sign Up, Verification Method, and OTP at 318×644 on the local emulator; test 318×644, 390×844, and 480×960 with representative insets, keyboard-open Sign Up, and Arabic RTL in widget tests.
- [x] Review the auth refinement for preserved validation/navigation, no backend calls, no unsupported claims, and no unrelated changes.
