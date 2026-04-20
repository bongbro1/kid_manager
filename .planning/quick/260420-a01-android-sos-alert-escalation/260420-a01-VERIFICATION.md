---
quick_task: 260420-a01
slug: android-sos-alert-escalation
type: verification
status: complete
completed: 2026-04-20
---

# Quick Task 260420-a01 Verification

## Automated Checks

- `cmd /c npm run build` in `functions/` - passed
- `node test\\sos_push_payloads.test.mjs` in `functions/` - passed
- `node test\\sos_initial_fanout.test.mjs` in `functions/` - passed
- `flutter analyze --no-pub` on the changed SOS/permission Dart files - passed
- `flutter test test/services/notifications/notification_service_routing_test.dart -r compact` - passed
- `flutter build apk --debug` - passed and produced `build/app/outputs/flutter-apk/app-debug.apk`

## Notes

- `flutter_facebook_auth:macos` still emits plugin metadata warnings during Flutter test/build startup. These warnings were pre-existing and did not block the Android SOS work.
- Android compile verification reached and compiled `MainActivity.kt`, so the new native SOS bridge, manifest entries, and notification-channel logic were included in a real debug APK build.

## Recommended Manual Android Test

1. Install the new debug build on an Android device.
2. Open the app and ensure normal notification permission is granted.
3. Open the SOS settings entrypoint from the onboarding/prelaunch flow and grant Notification Policy Access.
4. On Android 14+, also allow full-screen intents for the app when prompted by settings.
5. Trigger an SOS from another family account while the receiver app is foregrounded, backgrounded, and locked.
6. Confirm the receiver sees the SOS full-screen/heads-up alert, hears the custom SOS sound, and gets the vibration pattern.
7. Revoke Notification Policy Access and repeat; verify SOS still appears loudly as a best-effort alert without claiming silent-mode bypass.
8. If available, test one device with Do Not Disturb on and note whether the device honors the bypass-DND channel setting.

## Limits Confirmed During Verification

- Android behavior remains permission-aware and vendor-dependent.
- iOS behavior was intentionally left unchanged beyond comments and honest copy.
