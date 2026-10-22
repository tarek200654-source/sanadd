# SANAD Authentication UI Visual Refinement

## Source references

Available attachments are `login_screen.png`, `signup_screen.png`, and `Verification_Method.png` from `C:\Users\Ouffaa\Pictures\Screenshots`. No separate OTP screen image is present in the task attachments; OTP will follow the same compact header, typography, pale surfaces, and dark action styling using the existing OTP content and behavior.

Screenshot copy is visual reference only. The app shows one selected language at a time. Unsupported HIPAA/GDPR and end-to-end encryption statements in the references are excluded; the existing neutral privacy reassurance stays. Email remains the only selectable verification method and SMS stays unavailable, even though the method reference visually selects SMS.

## Intent

Bring the existing four authentication screens closer to the attached 318×644 mobile compositions while preserving the already implemented auth presentation flow and its behavior.

## Visual direction

- Reuse `AppColor`, Poppins/Tajawal, the current cream-white/blue-gray palette, the near-black primary action, and existing Material icons.
- Use a short top bar, compact centered or directional screen heading, smaller supporting copy, pale rounded inputs/cards, and a 48–52 dp dark pill action.
- Login gains a small welcome/health mark, compact labeled inputs, and the order: form, forgot-password link, primary action, neutral privacy reassurance, account navigation.
- Sign Up uses a compact title/header and dense labeled fields. The country selector shares the phone row. Password requirements remain hidden at rest and use compact, live status rows when focused or invalid.
- Verification places the masked email inside its selected method card, keeps the unavailable SMS card visibly disabled, and retains the preview-only notice and bottom action.
- OTP keeps the six editable LTR cells, preview notice, and unavailable resend status, using the same compact page rhythm.
- Use SafeArea, scrolling, and available-height distribution. Keep touch targets accessible and avoid device-specific fixed heights.

## Behavior and exclusions

Preserve current validation, password rules and strength guidance, show/hide toggles, phone normalization, terms acknowledgement, role/email route arguments, Arabic/English localization, SMS feedback, and OTP paste/edit/delete behavior. Do not add backend calls, fake delivery or verification, packages, compliance claims, or legal documents.

## Acceptance

- Login, Sign Up, verification method, and OTP retain all current behavior and render without overflow at the reference size plus standard and tall sizes.
- The compact Sign Up action is visible at rest at 318×644; focused password requirements may scroll naturally.
- Arabic layout is RTL with LTR email, phone, passwords, and OTP values; English remains LTR.
- Current analyzer, widget/validator tests, and Android debug build pass. If local emulator capture remains available, inspect the final rendered screens at 318×644 and record the comparison.
