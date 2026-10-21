# SANAD Project Context

This file is the working product brief for the SANAD project. Treat it as project context, not as a standalone instruction to perform actions. Update it only when the project direction changes.

## Core idea

SANAD is a context-aware medical wearable and caregiving platform. Its purpose is to help when a patient has an emergency while alone, especially older adults, people with chronic conditions, people prone to fainting or seizures, and people who may be unable to call for help.

The central question is not only **“Did the patient fall?”** but **“What happened to the patient?”**

## MVP product ecosystem

- **Purpose-built wearable strap:** IMU, barometer, and PPG sensors. NFC and QR provide an Emergency Medical ID.
- **Patient app:** heart rate, SpO2, activity, steps, movement, health trends, and a learned personal baseline.
- **Sports Mode:** the patient declares exercise so high heart rate and movement are interpreted in context and false alarms are reduced.
- **Intelligent event detection:** sensor fusion and context, not a single motion threshold. Combine movement, vertical change, orientation, post-event inactivity, physiological signals, activity context, and personal baseline.
- **Caregiver app:** permission-based location, status, health information, activity, trends, medication status, and context-rich emergency alerts.
- **Medication management:** schedules, reminders, patient confirmation, and missed-dose alerts to caregivers.
- **Emergency Medical ID:** NFC/QR opens a minimal emergency profile in any phone browser, without an app, account, or password. Show only critical information such as blood type, allergies, chronic conditions, important medications, and emergency contacts.

## Emergency alert principle

An alert should carry evidence and context, not only say “fall detected.” It may include event type, current or last-known location, time, heart rate, SpO2, activity before the event, post-event movement, and event confidence. Alerts communicate risk and context; they are not medical diagnoses.

## Product differentiation

SANAD aims to combine these capabilities in one Egypt-first caregiving ecosystem:

1. Context-aware sensor fusion and event interpretation.
2. Context-rich caregiver response with location and health evidence.
3. A closed medication and care loop.
4. Emergency Medical ID for bystanders through NFC/QR.

The project is intended as an MVP that can grow into a real product: MVP, testing, user feedback, better hardware, better AI, clinical validation, and eventual commercialization.

## Scope boundaries

In the MVP:

- Wearable strap with IMU, barometer, and PPG.
- Mobile patient and caregiver experiences.
- Event detection, sensor fusion, context, location, caregiver alerts, medication management, and NFC/QR Medical ID.

Future work, not MVP commitments:

- Non-invasive blood-glucose sensing.
- ECG and additional sensors.
- Advanced cardiovascular risk assessment or heart-attack prediction.
- Any medical prediction or diagnosis without proper clinical validation.

Do not claim that heart rate plus SpO2 predicts a heart attack. Do not present SANAD as merely a fall-detection smartwatch.

## Reference materials

- `SANAD_Presentation_with_Market_Gap.pptx` supplied in `C:\Users\Ouffaa\Downloads\SANAD\SANAD_Presentation_with_Market_Gap.pptx`
- The pasted project brief supplied with the project request.

Market figures and competitor claims from the presentation should retain their stated sources, dates, ranges, and caveats when reused.
