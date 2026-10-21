# Standalone Wexora OTP proxy

The Flutter app calls this small Node.js server. This service calls Wexora using
the API key and linked WhatsApp session ID; neither credential is compiled into
the app. It does not use Firebase Functions, Firestore, or Firebase phone auth.

Run it with Node.js 20 or later and HTTPS in front of it:

```sh
export WEXORA_API_KEY='your-rotated-api-key'
export WEXORA_SESSION_ID='your-linked-session-id'
node server/wexora-otp.js
```

Set `WEXORA_OTP_PROXY_URL` at Flutter build time to the HTTPS origin hosting
this server, for example:

```sh
flutter run --dart-define=WEXORA_OTP_PROXY_URL=https://api.example.com
```

The Wexora key needs `otp.send` and `otp.verify` permissions. Keep the server
behind HTTPS, monitor its rate limits, and never put its credentials in Flutter
defines or app source. The server applies per-IP limits and Wexora's per-number
limits remain in force.
