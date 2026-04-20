# Quick Task 260420-a01 Research

## Scope

Implement Android SOS alert escalation for the existing Flutter app while keeping iOS unchanged.

## Findings

- The current SOS Android path is split:
  - backend FCM sends a top-level `notification` payload plus `data` in `functions/src/services/sosPush.ts`
  - `SosNotificationService` only creates a local SOS alert when the app is already in the foreground
  - `main.dart` background handler skips any message that already contains a `notification` payload
- This means Android background/terminated SOS alerts currently rely on the system-rendered FCM notification path, which cannot be upgraded into a full-screen local SOS flow inside Flutter.
- The app is on `flutter_local_notifications: ^17.0.0` / resolved `17.2.4`.
  - Version `17.2.4` supports full-screen intent notifications and background notification action callbacks.
  - Version `17.2.4` does not include the newer Dart APIs for Do Not Disturb bypass (`bypassDnd`, `channelBypassDnd`, `hasNotificationPolicyAccess()`, `requestNotificationPolicyAccess()` were added later in `19.2.0`).
- Because of that plugin gap, DND-bypass channel management must be done in native Android code if we want to stay on the current plugin version and avoid a wider dependency upgrade.
- Android full-screen intent still requires manifest/activity wiring and is constrained on Android 14+ by system/user policy. It is best-effort, not guaranteed.
- Android DND bypass still does not override the device's ordinary silent/ringer mode in all OEM/device combinations. The honest promise is "strongest available within Android limits," not "always rings."

## Recommended implementation

1. Introduce a native Android SOS alert bridge in `MainActivity` to:
   - check notification policy access
   - open the system DND-policy settings screen
   - (re)create an SOS channel with `setBypassDnd(true)` when access is granted
2. Move Android SOS delivery to a local-notification escalation path whenever possible:
   - keep iOS and unknown-platform delivery behavior unchanged
   - send Android-targeted SOS push as high-priority data-first payload so the Flutter background isolate can build the urgent local alert
3. Upgrade the local Android SOS notification itself:
   - new channel version
   - full-screen intent
   - alarm category
   - explicit vibration pattern
   - public visibility
   - honest fallback when policy access is missing
4. Update user-facing copy to mention:
   - Android emergency access/DND access is optional but recommended
   - behavior depends on system settings/device behavior
   - iOS muted-mode bypass is not implemented

## Risks

- Existing installs may already have `sos_channel_v2` created without bypass-DND; channel settings are sticky. A new channel id is needed for reliable migration.
- Android data-only FCM delivery is still subject to OEM battery restrictions. This is acceptable because the app already documents battery optimization guidance.
- Full-screen intent on Android 14+ may require explicit user approval or be restricted by Play/device policy.

## Validation approach

- Flutter tests for SOS routing should keep passing.
- Add focused Dart tests for any new SOS escalation decision helpers.
- Add/extend Node tests to pin Android-vs-iOS SOS payload composition if backend routing is changed.
