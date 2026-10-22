# SANAD Authentication UI Design

## Intent

Add a calm, responsive, bilingual authentication presentation flow for SANAD without connecting it to Firebase Authentication, Firestore, email/SMS delivery, or a protected dashboard.

## Goals

- Implement Login, Create Account, Verification Method, and OTP presentation screens.
- Preserve the selected `UserRole` and the signup email through typed route arguments.
- Reuse SANAD's existing theme, fonts, logo asset, localization, `SanadButton`, and `onGenerateRoute` architecture.
- Provide local validation, live password requirements, accessible interaction states, and honest UI-preview feedback.
- Keep inputs suitable for later Firebase/custom-provider integration without storing or logging credentials.

## Non-goals and anti-goals

- No Firebase Auth calls, Firestore writes, email delivery, SMS requests, account creation, or real verification.
- No fake success route, authenticated session, resend countdown, or delivery claim.
- No second routing architecture, new dependencies, legal/compliance claims, or changes to unrelated screens.

## Decisions

- Add typed `AuthRouteArguments` with `UserRole` and optional email; routes remain in `AppRoutes.onGenerateRoute`.
- Start auth at `/login` after Role Selection. Role Selection remains the source of truth for the selected role and uses normal push navigation so its back path is retained.
- Use a small presentation validation layer for email, phone, full name, password requirements, and confirmation matching.
- Use a country-code dropdown with Egypt (+20) as the default and a small built-in list; the number field remains LTR and keeps the user's displayed formatting separate from its normalized validation value.
- Use existing `AppColor`, `SanadBrand`/SANAD logo asset, Poppins/Tajawal theme behavior, Material icons, and no new packages.
- Use scrollable SafeArea layouts with keyboard-aware bottom padding. Compact password requirements stay hidden until focus/input/validation requires them.

## Acceptance checks

- English is LTR and Arabic is RTL; email, phone, and OTP content stays LTR inside Arabic.
- All four screens provide localized labels, errors, helper text, status feedback, and button states.
- `flutter analyze` has no introduced errors/warnings; focused validator and auth widget tests pass; existing tests are updated only where the intended role-to-auth transition changes their expectation.
