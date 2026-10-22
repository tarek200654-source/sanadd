# Firebase Authentication Design

## Intent

Connect SANAD's existing multi-step registration and login flows to Firebase Authentication and Cloud Firestore while preserving every current screen's appearance, layout, assets, animations, and RTL/LTR behavior.

## Existing UI files that need logic integration

- `lib/presentation/screens/login_screen/login_screen.dart`: use the existing `AuthService` for returning-user email/password sign-in and login recovery; use existing loading, toast, error, and navigation behavior.
- `lib/presentation/screens/signup_screen/signup_screen.dart`: own the seven-step new-user registration flow, including username, first and last name, email, password, phone, country, region, and address.
- `lib/presentation/screens/otp_verification_screen/otp_verification_screen.dart`: after the existing Wexora phone challenge succeeds, create the Firebase account and atomically save the complete profile and username reservation.
- `lib/presentation/screens/splash_screen/splash_screen.dart`: restore an existing Firebase session and profile before choosing the current onboarding destination or the existing home route.

## Required behavior

- Sign in with Firebase email and password, then load the corresponding `users/{uid}` profile. Sign out if the profile is missing or invalid.
- Register with username, first and last name, email, password, role, country, region, address, and normalized WhatsApp number. Never persist passwords or password hashes.
- Validate usernames as 4–15 English letters, digits, periods, or underscores; compare using a lowercase canonical ID. Preserve passwords exactly as entered and preserve Unicode names and addresses.
- Atomically create `users/{uid}` and `usernames/{lowercaseUsername}` in one Firestore transaction. A collision must fail and roll back the newly created Firebase Auth account.
- Restrictive Firestore rules expose no private profiles to other users, make role and username immutable after account creation, and only allow a reservation to be created alongside its matching profile. Username availability may read a single reservation document but may not list reservations.
- Use the current generic `/home` destination for both roles because the project has no separate patient/caregiver dashboards or protected routes. Treat the role as profile data only; do not treat a client-selected role as a trusted authorization claim.
- Restore Firebase's persisted session through the existing splash transition. Keep `AuthService.signOut()` available for logout; no logout UI exists in the current screens.
- Map Firebase and profile failures to safe localized messages. Do not show raw Firebase errors or log credentials or profile contents.

## Architecture decisions

- Extend the existing `AuthService`, `AuthRepository`, `UserRepository`, and `AppUser`; do not add a second authentication stack.
- Pass registration data in the existing in-memory route arguments until the Wexora OTP flow completes. Do not cache the password or write it to Firestore.
- Use dependency injection in existing screen constructors so widget tests can supply fakes; production defaults use Firebase repositories.
- Validate username uniqueness in the UI for feedback, but make the Firestore transaction and rules the authoritative uniqueness guard.
- Keep existing Wexora OTP behavior. Firebase email verification, password reset, role-specific dashboards, role claims, and backend deployment are outside this scope.

## Constraints

- No visual changes: do not change colors, type, dimensions, spacing, assets, widget composition, or animations.
- Do not modify Firebase credentials or production user data. Publish Firestore rules only with the user's explicit authorization.
- Keep the role selected on the existing role-selection route.
- Tests must use fakes or the local Firestore emulator; never send real OTP messages or create production accounts.

## Resolved registration route

The user confirmed that new users register through `SignUpScreen`, while existing users sign in through `LoginScreen`. The seven-step registration flow now belongs to `SignUpScreen`, and its dedicated widgets live under `presentation/widgets/signup_screen_widgets/`. Reusable auth inputs and password indicators live under `presentation/widgets/shared_widgets/`.
