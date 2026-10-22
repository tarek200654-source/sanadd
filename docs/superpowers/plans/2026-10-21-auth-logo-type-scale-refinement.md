# SANAD Auth Logo and Type Scale Refinement Plan

> **For agentic workers:** Execute this focused plan in the current workspace using the test-first workflow. Keep every existing validation and route contract intact.

**Goal:** Bring the existing Login and Sign Up screens closer to the supplied mobile references by rendering the real black SANAD logo and improving readable type and control proportions, while keeping shared auth screens visually consistent.

**Architecture:** Reuse the existing `AuthHeader`, `AuthTextField`, `AuthPasswordField`, `AuthPageLayout`, `SanadButton`, localization, theme, and route arguments. Add a small reusable auth-logo widget that uses the existing padded PNG without changing the asset, then tune shared auth metrics and the two screen compositions without changing auth behavior.

**Tech Stack:** Existing Flutter/Dart, Material widgets, `flutter_test`, current Android build; no dependency changes.

**Spec:** User-provided `SANAD — Authentication UI Visual Fidelity & Logo Refinement` brief and the two supplied Login/Sign Up images. The brief mentions a third reference and current-screen captures, but neither is attached in this turn.

## Global Constraints

- Preserve current validation, navigation, role/language state, password rules, phone normalization, terms acknowledgement, SMS-unavailable behavior, and preview-only verification.
- Use `assets/images/sanad_logo.png` unchanged; render its artwork black with transparency and aspect ratio preserved.
- Keep existing SANAD colors and Poppins/Tajawal localization; show only the selected language and preserve LTR credential input.
- Do not add backend calls, packages, unsupported privacy claims, or unrelated changes.
- Keep SafeArea, keyboard insets, scrolling, accessible tap targets, and text scaling functional.

## Review Focus

- Logo transparency, visible artwork size, and non-distorted aspect ratio — test the logo asset, color filter, and widget bounds.
- Type-size/readability regression across compact and standard controls — test actual label/input/button styles and dimensions.
- Long Sign Up form on 318×644 and with keyboard open — test scroll reachability and absence of layout exceptions.
- Arabic RTL with LTR email/phone/password input — retain locale-specific screen checks and assert credential direction.
- Password requirements visibility and preview-only behavior — retain existing behavior tests unchanged unless geometry requires an expectation update.

---

### Task 1: Add a reusable black SANAD logo to the auth header

**Files:**
- Create: `lib/presentation/widgets/auth/sanad_auth_logo.dart`
- Modify: `lib/presentation/widgets/auth/auth_header.dart`
- Test: `test/auth/auth_widgets_test.dart`

**Interfaces:** `SanadAuthLogo({double visibleWidth = 120})` renders the existing `AppAssets.sanadLogo` with a black `srcIn` color filter and a clipped, proportional viewport that accounts for the PNG's transparent padding. `AuthHeader` uses it where the current SANAD text capsule is shown; other header titles remain localized text.

- [x] Add a widget test asserting the image asset path, black color filter, `BoxFit.cover` cropping of transparent padding, centered visible mark, and target header bounds.
- [x] Run that test and confirm it fails because the current header renders a SANAD text capsule.
- [x] Implement `SanadAuthLogo` and replace only the current branded text capsule with the image.
- [x] Run the focused widget test and existing header tests; update the previous text-brand assertion to verify the image semantics instead.

### Task 2: Raise shared auth typography and control dimensions

**Files:**
- Modify: `lib/presentation/widgets/auth/auth_text_field.dart`
- Modify: `lib/presentation/widgets/auth/password_requirements.dart`
- Modify: `lib/presentation/widgets/auth/auth_header.dart`
- Modify: `lib/presentation/widgets/sanad_button.dart` only if its accessible auth sizing needs a shared adjustment.
- Test: `test/auth/auth_widgets_test.dart`

**Interfaces:** Keep public widget APIs and behavior stable; adjust compact label/input typography and field geometry, heading/supporting text defaults, inline error readability, and checklist text sizes to the new auth type scale.

- [x] Add focused assertions for 14 px field labels, 15 px input text, 52–56 px controls, and larger readable password-requirement text.
- [x] Run focused tests and confirm existing compact sizes/styles fail those new assertions.
- [x] Apply the smallest shared style/geometry changes while retaining 48 dp icon control targets and current caller overrides.
- [x] Run the focused widget tests, including password visibility and checklist visibility behavior.

### Task 3: Refine Login and Sign Up layout proportions

**Files:**
- Modify: `lib/presentation/screens/login_screen/login_screen.dart`
- Modify: `lib/presentation/screens/signup_screen/signup_screen.dart`
- Test: `test/auth/auth_screens_test.dart`

**Interfaces:** Consume the shared logo, type scale, and field metrics from Tasks 1–2. Preserve screen controllers, validators, submit preview, route arguments, country-code default, checkbox, and form state.

- [x] Add/adjust tests for readable Login/Sign Up headings and bottom actions, 54 px Login / 54–56 px Sign Up actions, and compact-form scroll reachability with keyboard insets.
- [x] Run focused tests and confirm the existing 19 px/18 px headings and 50 px controls fail the new visual assertions.
- [x] Increase heading/supporting/label/input sizes, tune field gaps and phone-selector proportions, and keep Sign Up requirements hidden until relevant.
- [x] Run existing auth screen tests for validation, role/email preservation, English/Arabic directionality, and keyboard-open reachability.

### Task 4: Inspect all auth screens and complete rendered verification

**Files:**
- Modify only auth screen/shared widget files if a verified visual issue requires a targeted correction.
- Verify: all files in `lib/presentation/screens/{login_screen,signup_screen,verification_method_screen,otp_verification_screen}`.

- [x] Run focused auth tests, then `flutter analyze`, the full `flutter test` suite, and `flutter build apk --debug`.
- [x] Capture rendered Login and Sign Up at 318×644 and 390×844, closed/open keyboard, plus Arabic and English; inspect against the provided references.
- [x] Check verification/OTP shared visual consistency, no overflow, and unchanged unavailable/preview behavior; report any unavailable emulator/capture separately.

## Completion evidence

- The supplied Login and Sign Up references were compared against rendered Android captures at compact (318×644 logical) and standard (390×844 logical) sizes. Arabic RTL and English LTR were checked; keyboard-open form entry and short-screen scrolling were exercised.
- Shared verification and OTP screens were rendered and exercised for email selection, SMS-unavailable feedback, six-digit LTR entry, and honest preview-only submission. The current request supplied no separate reference images for these two screens, so they were checked for consistency and behavior rather than screenshot-matched.
- Verification passed: `flutter analyze` (no issues), `flutter test` (55 tests), and `flutter build apk --debug` (success).
- The emulator was restored to its original 1344×2992 physical size after compact/standard QA.
