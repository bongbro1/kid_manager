# Phase 1 Pattern Map: Runtime Foundation

## Session Shell and Bootstrap

### Target files

- `lib/features/sessionguard/session_guard.dart`
- `lib/features/sessionguard/session_bootstrap_coordinator.dart`

### Existing pattern to preserve

- `SessionGuard` is already the shell switchboard. It uses `Selector3<SessionVM, UserVm, AuthVM, _SessionGuardViewData>` and routes authenticated users to role-specific shells through `TrackingWarmupController`.
- `SessionBootstrapCoordinator._handleSnapshotChange()` is already the single auth-transition gate. Extend that flow instead of adding new auth-state listeners in unrelated widgets.

### Concrete cues

- keep shell routing based on `SessionGuardResolvedState`
- keep authenticated side effects inside `_runSessionBootstrap()`
- keep logout cleanup inside `_runPreLogoutCleanup()` and `_runSessionCleanup()`

## Tracking Lifecycle Routing

### Target files

- `lib/features/sessionguard/tracking_warmup_controller.dart`
- `lib/viewmodels/location/child_location_view_model.dart`
- `lib/background/tracking_background_service.dart`
- `lib/background/background_tracking_runtime.dart`

### Existing pattern to preserve

- `TrackingWarmupController` serializes lifecycle work with `_syncInFlight`, `_resyncRequested`, and `_lastAppliedTrackingKey`.
- `TrackingBackgroundService.startForCurrentUser()` already dedupes equivalent configs and persists `TrackingRuntimeConfig` before invoking native start.
- `ChildLocationViewModel` already distinguishes foreground publishing from service-backed publishing through `_publishingHandledByService`.

### Concrete cues

- use `snapshot.selfTrackingKey` as the idempotency key for role/lifecycle tracking changes
- keep foreground publishing inside `ChildLocationViewModel`
- keep background publishing inside `BackgroundTrackingRuntime`
- treat Android `TrackingForegroundService` as the host, not a second business-logic layer

## Notification Routing

### Target files

- `lib/services/notifications/notification_service.dart`
- `lib/services/notifications/sos_notification_service.dart`

### Existing pattern to preserve

- `NotificationService.handleTap()` already lowercases `type` and dedupes taps with `_lastHandledTapKey`.
- `SosNotificationService._isSosData()` already accepts mixed-case payloads.

### Concrete cues

- preserve `SosTapRouter.handleTap` as the single SOS navigation path
- keep local SOS display and resolve-action handling in `SosNotificationService`
- keep remote message normalization and tap dedupe in `NotificationService`

## Test Style

### Flutter tests

- Existing tests use plain `flutter_test` groups and helper builders, for example `test/services/background_tracking_status_policy_test.dart`.
- No mocking library is currently established in `pubspec.yaml`, so prefer lightweight fakes, test adapters, or method-channel stubs over introducing a new dependency in this phase.

### Functions tests

- Existing Functions tests use `node:assert/strict` and direct module imports, for example `functions/test/tracking_location_notifications.test.mjs`.
- Preserve that style for any new or extended Phase 1 backend checks.
