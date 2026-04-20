# Phase 1 Research: Runtime Foundation

## Scope

Phase 1 must make three things trustworthy before broader feature work continues:

1. session bootstrap chooses the correct shell after cold start and logout/login changes
2. only one publisher owns child tracking across foreground/background transitions
3. developers can run a small, repeatable regression harness for the runtime-critical paths

No `CONTEXT.md` exists for this phase, so this research uses `ROADMAP.md`, `REQUIREMENTS.md`, and the current brownfield code as the source of truth.

## Repository Evidence

### Bootstrap and shell selection

- `lib/features/sessionguard/session_guard.dart` derives role and shell from `SessionGuardResolvedState`, creates role-scoped `ChildLocationViewModel` providers, and routes authenticated users through `TrackingWarmupController`.
- `lib/features/sessionguard/session_bootstrap_coordinator.dart` owns authenticated side effects: profile loading, notification binding, FCM token registration, SOS notification initialization, timezone sync, storage writes, and logout cleanup.
- `lib/main.dart` initializes `NotificationService` globally and currently stops `TrackingBackgroundService` unconditionally on foreground startup.

### Tracking ownership and lifecycle handoff

- `lib/features/sessionguard/tracking_warmup_controller.dart` decides when parent current-location sharing or child/guardian self-tracking should start, stop, or resync after lifecycle changes.
- `lib/viewmodels/location/child_location_view_model.dart` contains the foreground publisher, background-service handoff, health monitor, queueing, and restart logic.
- `lib/background/tracking_background_service.dart` dedupes service starts and persists `TrackingRuntimeConfig` through `TrackingRuntimeStore`.
- `lib/background/background_tracking_runtime.dart` is the headless Flutter publisher behind the Android foreground service.
- `android/app/src/main/kotlin/com/example/kid_manager/TrackingForegroundService.kt` starts a secondary Flutter engine and exposes `isRunning` through `TrackingServiceChannel.kt`.

### Notification routing hotspots

- `lib/services/notifications/notification_service.dart` handles `onMessage`, `onMessageOpenedApp`, `getInitialMessage`, tap dedupe via `_lastHandledTapKey`, and normalizes notification `type` with `.toLowerCase()`.
- `lib/services/notifications/sos_notification_service.dart` also listens to `onMessageOpenedApp` and `getInitialMessage`; its `_isSosData()` helper lowercases payloads, but `_showFromRemoteMessage()` still checks `type != 'SOS'`.
- `functions/src/services/sosPush.ts` currently emits `data.type = "SOS"`, so the client must tolerate mixed-case payloads.

### Existing automated coverage and drift

- Existing Flutter tests already cover some location-policy building blocks:
  - `test/core/location/current_publish_policy_test.dart`
  - `test/features/pipeline/tracking_pipeline_test.dart`
  - `test/services/background_tracking_status_policy_test.dart`
- Existing Functions tests already cover runtime-adjacent backend behavior:
  - `functions/test/tracking_location_notifications.test.mjs`
  - `functions/test/sos_initial_fanout.test.mjs`
- The advertised scripts drifted away from the current file layout:
  - root `package.json` points `test:firestore-rules` at missing `test/firestore.rules.test.cjs`
  - `functions/package.json` points `test:user-auth` at missing `test/user_auth.test.cjs`
- `.gitignore` currently ignores `test/`, `tests/`, and `**/*_test.dart`, which will hide any new runtime tests unless fixed.

## Findings

### 1. Bootstrap side effects are centralized enough to stabilize without a rewrite

`SessionBootstrapCoordinator` already provides a good ownership seam. The plan should keep session-shell choice in `SessionGuard` and tighten the coordinator so logout/login transitions reset bootstrap state before a new UID can bind notifications, storage, timezone, or tracking side effects.

### 2. Notification tap ownership is duplicated and case handling is inconsistent

`NotificationService` and `SosNotificationService` both attach FCM open/tap listeners. That creates a real risk of duplicate routing during kill-state open or background resume. The Phase 1 fix should keep one normalized tap/navigation path and leave `SosNotificationService` focused on local SOS presentation plus resolve actions.

### 3. Tracking handoff already has explicit seams but not one clear publisher contract

The app already splits responsibilities into:

- `TrackingWarmupController`: lifecycle orchestration
- `ChildLocationViewModel`: foreground publishing
- `BackgroundTrackingRuntime`: background publishing
- `TrackingForegroundService`: Android host process

The missing piece is an explicit, test-backed contract for when foreground publishing must reclaim ownership and when the background service is allowed to own it.

### 4. The fastest reliable regression harness is unit-focused, not device-focused

The repo already contains Appium smoke automation in `tests/`, but it depends on a prepared device and Appium runtime. Phase 1 should not make that the mandatory gate. The default regression harness should stay runnable with `flutter test` and `node --test`, while keeping device smoke tests optional.

## Recommended Plan Split

### Plan 01-01: Session bootstrap and notification ownership

Focus on `SessionGuard`, `SessionBootstrapCoordinator`, `NotificationService`, and `SosNotificationService`.

### Plan 01-02: Tracking runtime handoff

Focus on `TrackingWarmupController`, `ChildLocationViewModel`, `TrackingBackgroundService`, `BackgroundTrackingRuntime`, `main.dart`, and Android foreground-service glue.

### Plan 01-03: Regression harness repair

Focus on `.gitignore`, package scripts, and the narrow Flutter/Functions suites that protect the behavior delivered by Plans 01-01 and 01-02.

## Validation Architecture

Phase 1 should leave behind exact commands that a developer can run locally without a device:

### Flutter checks

- `flutter analyze lib/features/sessionguard lib/services/notifications`
- `flutter analyze lib/features/sessionguard lib/viewmodels/location lib/background`
- `flutter test test/features/sessionguard/session_bootstrap_coordinator_test.dart test/services/notifications/notification_service_routing_test.dart`
- `flutter test test/features/sessionguard/tracking_warmup_controller_test.dart test/services/tracking_background_service_test.dart test/services/background_tracking_status_policy_test.dart`

### Functions checks

- `node --test functions/test/tracking_location_notifications.test.mjs`
- `node --test functions/test/sos_initial_fanout.test.mjs`

### Aggregated Phase 1 entrypoints

- `npm run test:phase1`
- `npm --prefix functions run test:phase1:functions`

## Out of Scope for Phase 1

- broad family permission redesign
- safe-route UX polish
- notification copy redesign
- device/Appium smoke automation as a required phase gate
