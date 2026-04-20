# Codebase Concerns

**Analysis Date:** 2026-04-20

## Tech Debt

**Mixed architectural styles across Flutter code:**
- Issue: Legacy layer-based folders (`lib/views/`, `lib/viewmodels/`, `lib/repositories/`, `lib/services/`) coexist with newer feature slices such as `lib/features/safe_route/`
- Why: The app has evolved incrementally without a single migration pass
- Impact: New work placement is inconsistent, cross-feature reasoning is slower, and refactors often need to span multiple patterns
- Fix approach: Pick a neighborhood-first rule for each subsystem and gradually consolidate high-churn areas around one placement model

**Background tracking ownership spans Flutter and Android:**
- Issue: Runtime ownership is split across `lib/background/`, `lib/features/sessionguard/`, `lib/viewmodels/location/child_location_view_model.dart`, and Android-native services
- Why: Reliable background tracking required platform-specific fallbacks and retries
- Impact: Lifecycle bugs are hard to reason about, especially when auth/session changes while tracking is live
- Fix approach: Establish a single source of truth for publisher ownership and document state transitions with tests

**Notification handling is distributed across multiple services:**
- Issue: `NotificationService`, `SosNotificationService`, and `SessionBootstrapCoordinator` all participate in message initialization and tap routing
- Why: General notifications and SOS flows were implemented separately
- Impact: Duplicate startup handling and route/tap regressions are easy to introduce
- Fix approach: Consolidate initialization responsibilities and define one canonical tap-routing contract

## Known Bugs

**Duplicated initial-message handling across notification paths:**
- Symptoms: Cold-start push taps can be processed by more than one listener
- Trigger: App launch from push while both general notification and SOS services initialize
- Files: `lib/services/notifications/notification_service.dart`, `lib/services/notifications/sos_notification_service.dart`, `lib/main.dart`
- Workaround: None observed beyond dedupe keys in the general notification service
- Root cause: Multiple services call `FirebaseMessaging.instance.getInitialMessage()`

**Stale test scripts in package manifests:**
- Symptoms: Running advertised test scripts fails immediately because referenced files are missing
- Trigger: `npm run test:firestore-rules` at repo root or `npm run test:user-auth` in `functions/`
- Files: `package.json`, `functions/package.json`
- Workaround: Run the existing tests manually instead of the broken scripts
- Root cause: Test manifests drifted away from current test file layout

**Workspace hygiene issue from interrupted tooling:**
- Symptoms: A stray top-level file named `{console.error(e)` exists outside repo conventions
- Trigger: Prior interrupted command or malformed redirection
- Files: `{console.error(e)`
- Workaround: Ignore it unless it is confirmed needed
- Root cause: Accidental file creation

## Security Considerations

**Client-visible env file packaged as an asset:**
- Risk: `.env` is listed under Flutter assets in `pubspec.yaml`
- Current mitigation: The expected contents appear limited to a public Mapbox token
- Recommendations: Keep only explicitly public values there; move anything sensitive to runtime secrets or backend params

**Role enforcement exists in multiple places:**
- Risk: Parent/guardian/child access rules must stay aligned between client-side gating and backend checks
- Current mitigation: Access-control services exist on both sides of the stack
- Recommendations: Treat backend checks as authoritative and add regression tests for guardian/child edge cases

**Firebase rules and backend access must evolve together:**
- Risk: Data model changes can outpace `firestore.rules`, `database.rules.json`, or backend service checks
- Current mitigation: Rules files are present and some backend authorization tests exist
- Recommendations: Add a working rules test harness and keep rules coverage current when collections/fields change

## Performance Bottlenecks

**Heavy tracking view models and listeners:**
- Problem: `ChildLocationViewModel` owns GPS, activity recognition, upload queues, zone checks, and UI notification throttling in one large class
- Files: `lib/viewmodels/location/child_location_view_model.dart`
- Cause: Incremental feature growth around a central tracking state owner
- Improvement path: Split pipeline, publisher, and UI concerns into smaller services with focused tests

**Backend live-tracking and safety fan-out can amplify reads/writes:**
- Problem: Tracking, safe-route, and notification systems all react to location churn
- Files: `functions/src/services/trackingLocationNotifications.ts`, `functions/src/services/safeRouteMonitoringService.ts`, `functions/src/services/sosInitialFanout.ts`
- Cause: Safety logic is intentionally reactive and cross-cutting
- Improvement path: Measure noisy paths, add idempotency/aggregation, and tune write frequency against product needs

## Fragile Areas

**Session bootstrap and logout cleanup:**
- Why fragile: Auth state, timezone sync, push initialization, storage, and app-management watches all converge in one coordinator
- Files: `lib/features/sessionguard/session_bootstrap_coordinator.dart`
- Common failures: Residual listeners after logout, duplicate bootstrap work, ordering bugs between profile load and side effects
- Safe modification: Change one responsibility at a time and add targeted tests around auth transitions
- Test coverage: Partial; no end-to-end regression suite covers the full bootstrap/logout graph

**Notification + SOS routing:**
- Why fragile: Separate services react to the same FCM lifecycle events with overlapping responsibilities
- Files: `lib/services/notifications/notification_service.dart`, `lib/services/notifications/sos_notification_service.dart`, `lib/services/notifications/sos_tap_router.dart`
- Common failures: Duplicate tap handling, wrong route focus, mismatched notification type casing
- Safe modification: Unify normalization and cold-start ownership before adding more alert types
- Test coverage: Limited unit coverage; no full notification-routing harness observed

**Ignore rules for tests and docs:**
- Why fragile: `.gitignore` currently lists `test/`, `**/*_test.dart`, and `README.md`
- Common failures: New tests or docs appear locally but never get staged
- Safe modification: Audit ignore rules before adding new automated coverage or project docs
- Test coverage: Not applicable, but high maintenance risk

## Dependencies at Risk

**Mapbox access split across client and backend:**
- Risk: Client public token and backend secret must both remain valid and appropriately scoped
- Impact: Maps may render while routing/geocoding silently fail, or vice versa
- Migration plan: Centralize operational checks and surface token/config health in diagnostics

**Manual test/deploy workflow:**
- Risk: No CI workflow was observed, and some advertised test scripts are stale
- Impact: Regressions can slip in and backend deploy confidence is lower than it should be
- Migration plan: Restore working scripts first, then add CI around Dart tests, backend tests, and rules checks

## Missing Critical Features

**No working automated rules test harness in the tracked scripts:**
- Problem: Security rules exist, but the documented repo-level script points at a missing file
- Current workaround: Manual rule review and ad hoc emulator usage
- Blocks: Reliable regression testing for Firestore rules changes
- Implementation complexity: Medium

**No centralized observability layer:**
- Problem: Debugging depends on log inspection and local reproduction
- Current workaround: `debugPrint`, function logs, and ad hoc audit documents
- Blocks: Fast diagnosis of field issues in tracking, notifications, and safe-route flows
- Implementation complexity: Medium

## Test Coverage Gaps

**Session/bootstrap/logout graph:**
- What's not tested: The full authenticated boot sequence and cleanup behavior
- Risk: Listener leaks and duplicate init logic go unnoticed
- Priority: High
- Difficulty to test: Requires coordinated auth, push, and storage state

**Notification cold-start routing:**
- What's not tested: Interaction among `getInitialMessage()`, `onMessageOpenedApp`, and SOS-specific routing
- Risk: Push taps may open the wrong place or process twice
- Priority: High
- Difficulty to test: Requires integration-style device or harness coverage

**Android-native tracking bridges:**
- What's not tested: Kotlin services, worker scheduling, and method-channel edge cases
- Risk: Background tracking diverges from Flutter expectations
- Priority: High
- Difficulty to test: Requires Android instrumentation or device-level automation

---

*Concerns audit: 2026-04-20*
*Update as issues are fixed or new ones discovered*
