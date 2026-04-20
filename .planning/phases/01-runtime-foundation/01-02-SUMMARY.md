---
phase: 01-runtime-foundation
plan: 02
subsystem: runtime
tags: [flutter, android, tracking, lifecycle]
requires: []
provides:
  - Config-aware tracking service startup and restart behavior in `TrackingBackgroundService`
  - Explicit foreground reclaim of tracking ownership on app resume
  - Regression coverage for tracking lifecycle sync and native service handoff behavior
affects: [03-tracking-and-safety-flows, background-tracking, android-service]
tech-stack:
  added: []
  patterns: [config-aware service dedupe, foreground reclaim before local publishing, testable tracking sync helper]
key-files:
  created:
    - test/features/sessionguard/tracking_warmup_controller_test.dart
    - test/services/tracking_background_service_test.dart
  modified:
    - lib/features/sessionguard/tracking_warmup_controller.dart
    - lib/viewmodels/location/child_location_view_model.dart
    - lib/background/tracking_background_service.dart
    - lib/main.dart
    - android/app/src/main/kotlin/com/example/kid_manager/TrackingForegroundService.kt
key-decisions:
  - "Treat `TrackingRuntimeStore` plus persisted config as the source of truth for whether a background runtime should survive foreground startup."
  - "Make resumed foreground sessions explicitly stop the native tracking service before local publishing resumes."
patterns-established:
  - "Tracking handoff decisions are computed through a pure sync helper before controller side effects run."
  - "Equivalent background-service start requests dedupe against persisted runtime config and running state."
requirements-completed: [CORE-02]
duration: 36min
completed: 2026-04-20
---

# Phase 1: Runtime Foundation Summary

**Config-aware background tracking handoff that dedupes service starts and lets foreground sessions reclaim ownership on resume**

## Performance

- **Duration:** 36 min
- **Started:** 2026-04-20T13:02:00+07:00
- **Completed:** 2026-04-20T13:38:00+07:00
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments
- Added a testable tracking sync helper so lifecycle routing only reschedules tracking work when key ownership or requested mode actually changes.
- Made background-service startup config-aware, including dedupe for equivalent requests and restart behavior when persisted runtime config changes.
- Stopped blindly killing the native tracking service on every foreground startup and aligned the Android running bit with real stop behavior.

## Task Commits

No atomic task commits were created in this execution. The work remains in the current tree because the repository already contained unrelated uncommitted changes.

## Files Created/Modified
- `lib/features/sessionguard/tracking_warmup_controller.dart` - Added a pure handoff decision helper and stricter idempotency checks for self-tracking sync.
- `lib/viewmodels/location/child_location_view_model.dart` - Reclaimed foreground ownership by stopping the background service before local publishing resumes.
- `lib/background/tracking_background_service.dart` - Added current-user test hooks, config-aware dedupe, restart-on-change, and publisher-ready reset on stop.
- `lib/main.dart` - Replaced unconditional service shutdown with a config-aware startup guard.
- `android/app/src/main/kotlin/com/example/kid_manager/TrackingForegroundService.kt` - Cleared the native running flag on stop so Flutter does not trust stale service state.
- `test/features/sessionguard/tracking_warmup_controller_test.dart` - Covered lifecycle resync and idempotent self-tracking decisions.
- `test/services/tracking_background_service_test.dart` - Covered equivalent-start dedupe, restart-on-config-change, and stop cleanup behavior.

## Decisions Made

- Kept `TrackingBackgroundService.startForCurrentUser()` as the only Flutter-side native start path and pushed ownership checks into persisted config plus running-state inspection.
- Preserved the distinction between foreground and service-backed publishers instead of collapsing them into one generic tracking path.

## Deviations from Plan

- `lib/background/background_tracking_runtime.dart` and `android/app/src/main/kotlin/com/example/kid_manager/TrackingServiceChannel.kt` did not need code changes because the faulty ownership contract was fixed in the service wrapper, startup gate, view model, and native service stop path.

---

**Total deviations:** 1 auto-contained deviation
**Impact on plan:** No scope creep. The intended runtime contract was achieved without broadening the Android bridge surface.

## Issues Encountered

- `dart format` and `flutter analyze` were not runnable from the sandboxed workspace because the local Flutter SDK and pub cache live outside the repo. Targeted Flutter tests were used as the executable verification path.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Tracking ownership now has direct regression coverage for lifecycle sync and background-service handoff behavior.
- Phase 1 can move to `01-03` to clean up the broader local verification harness and complete the runtime-foundation phase.

---
*Phase: 01-runtime-foundation*
*Completed: 2026-04-20*
