# Architecture

**Analysis Date:** 2026-04-20

## Pattern Overview

**Overall:** Brownfield Flutter mobile app with a Firebase serverless backend and Android-native background tracking extensions.

**Key Characteristics:**
- Provider/ChangeNotifier-driven app shell with a large composition root in `lib/app.dart`
- Mixed architecture styles: legacy layer-based folders (`views/`, `viewmodels/`, `repositories/`, `services/`) alongside cleaner feature slices such as `lib/features/safe_route/`
- Event-driven runtime for session bootstrap, background tracking, FCM notifications, and SOS fan-out
- Firebase as the primary system of record, with both Firestore and Realtime Database used in parallel

## Layers

**Bootstrap / Composition Layer:**
- Purpose: Initialize Flutter, Firebase, App Check, notifications, storage, and Provider wiring
- Contains: `lib/main.dart`, `lib/app.dart`, `lib/features/sessionguard/session_guard.dart`, `lib/features/sessionguard/session_bootstrap_coordinator.dart`
- Depends on: Firebase setup, repositories, services, and view models
- Used by: Every runtime path, including background entry points

**Presentation Layer:**
- Purpose: Render app shells, screens, widgets, overlays, and UI flows
- Contains: `lib/views/`, `lib/widgets/`, selected `lib/features/*/presentation/`
- Depends on: View models, localization, and service abstractions
- Used by: Parent, guardian, and child runtime shells

**State / Orchestration Layer:**
- Purpose: Hold session state, derived UI state, subscriptions, and long-lived listeners
- Contains: `lib/viewmodels/`, `lib/features/safe_route/presentation/viewmodels/`, `lib/viewmodels/location/`, `lib/viewmodels/zones/`
- Depends on: Repositories and services
- Used by: Screens/widgets via Provider

**Domain / Core Layer:**
- Purpose: Centralize reusable policy, validation, tracking logic, and stable primitives
- Contains: `lib/core/`, `lib/features/safe_route/domain/`, `lib/services/access_control/`
- Depends on: Mostly pure Dart or narrowly scoped services
- Used by: View models, repositories, and background runtime

**Data / Service Layer:**
- Purpose: Connect app logic to Firebase, device APIs, files, and business services
- Contains: `lib/repositories/`, `lib/services/`, `lib/background/`
- Depends on: Firebase SDKs, platform channels, and package integrations
- Used by: View models, session bootstrap, and background runtime

**Backend Layer:**
- Purpose: Server-enforced access checks, notifications, safe-route logic, scheduled tasks, and integrations
- Contains: `functions/src/functions/`, `functions/src/services/`, `functions/src/triggers/`, `functions/src/utils/`
- Depends on: `firebase-admin`, `firebase-functions`, Mapbox, Google Cloud Tasks, Resend
- Used by: Flutter client via Callable Functions, FCM, and backend triggers

## Data Flow

**App Startup and Session Resolution:**
1. `lib/main.dart` initializes Flutter bindings, Firebase, App Check, notifications, env vars, and Mapbox token setup
2. `MyApp` in `lib/app.dart` builds the repository/service/provider graph
3. `StartupGate` and `SessionGuard` decide whether to show flash, auth, or the authenticated shell
4. `SessionBootstrapCoordinator` loads the user profile, binds notifications, syncs timezone, starts role-specific watches, and primes background services
5. `AppShell` renders parent, guardian, or child mode

**Child Tracking Pipeline:**
1. `ChildLocationViewModel` in `lib/viewmodels/location/child_location_view_model.dart` receives GPS/activity input
2. `TrackingPipeline` and core policy helpers in `lib/core/location/` decide current vs history sends, throttling, and indoor suppression
3. `LocationRepository` implementations write current/history state to Firebase
4. `TrackingBackgroundService` and Android services in `android/app/src/main/kotlin/com/example/kid_manager/` take over when background execution is required
5. Parent/guardian map surfaces consume the resulting live and historical data

**Safety / Notification Flow:**
1. Backend services in `functions/src/services/` and triggers in `functions/src/triggers/` emit notifications, safe-route state, and SOS fan-out
2. FCM arrives in the client through `NotificationService`, `SosNotificationService`, and `FcmPushReceiverService`
3. Tap handling routes into `SosTapRouter`, notification detail state, or chat/map screens
4. View models and overlays (`lib/widgets/sos/`, `lib/widgets/notifications/`) render actionable UI

## Key Abstractions

**Repository:**
- Purpose: Encapsulate Firebase/data-access concerns behind feature-oriented APIs
- Examples: `lib/repositories/user_repository.dart`, `lib/repositories/location/location_repository_impl.dart`, `lib/repositories/chat/family_chat_repository.dart`
- Pattern: Thin facades over Firebase SDKs plus a few orchestration helpers

**ViewModel / ChangeNotifier:**
- Purpose: Own mutable UI/session state, listeners, and async commands
- Examples: `AuthVM`, `UserVm`, `ParentLocationVm`, `ChildLocationViewModel`, `NotificationVM`
- Pattern: Stateful ChangeNotifier classes injected through Provider

**Service:**
- Purpose: Handle device APIs, background tasks, permissions, notifications, and domain helpers
- Examples: `lib/services/location/location_service.dart`, `lib/services/notifications/notification_service.dart`, `lib/services/access_control/access_control_service.dart`
- Pattern: Direct package/platform integration with imperative APIs

**Feature Slice (Safe Route):**
- Purpose: Provide a more explicit domain/data/presentation split for a complex subsystem
- Examples: `lib/features/safe_route/domain/`, `lib/features/safe_route/data/`, `lib/features/safe_route/presentation/`
- Pattern: Clean Architecture-inspired submodule embedded in an otherwise layer-based repo

## Entry Points

**Flutter App:**
- Location: `lib/main.dart`
- Triggers: Mobile/web/desktop app launch
- Responsibilities: Environment setup, Firebase init, notification bootstrap, runApp

**Background Tracking Entrypoint:**
- Location: `lib/background/background_tracking_entrypoint.dart`
- Triggers: Background isolate / tracking runtime
- Responsibilities: Firebase/App Check bootstrap and background runtime handoff

**Firebase Backend:**
- Location: `functions/src/index.ts`
- Triggers: Callable functions, Firestore/RTDB triggers, scheduled jobs
- Responsibilities: Export backend endpoints and triggers

**Android Native Services:**
- Location: `android/app/src/main/kotlin/com/example/kid_manager/`
- Triggers: Foreground service, boot receiver, WorkManager, method channels
- Responsibilities: Keep tracking and supervision features alive outside the Flutter foreground UI

## Error Handling

**Strategy:** Catch errors at runtime boundaries, log them, and push friendly state into view models; backend uses `HttpsError` for client-visible failures.

**Patterns:**
- Dart UI/runtime code relies heavily on `try/catch`, `_error` fields, and `debugPrint`
- Backend services validate inputs via helper functions such as `mustString`, `mustNumber`, and `validateLatLng`, then throw `HttpsError`
- Session/bootstrap paths retry selected failures rather than failing hard (`SessionBootstrapCoordinator`)

## Cross-Cutting Concerns

**Localization:**
- App localization files in `lib/l10n/`
- Notification-specific localization adapters in `lib/services/notifications/zone_i18n.dart` and related helpers

**Permissions and Device State:**
- Permission onboarding in `lib/features/permissions/`
- Device-specific channels for timezone, tracking, watcher config, and battery

**Security / Access Control:**
- Firebase Auth + Firestore role documents drive parent/guardian/child permissions
- Access policies live in both app services (`lib/services/access_control/`) and backend checks (`functions/src/services/`)

---

*Architecture analysis: 2026-04-20*
*Update when major patterns change*
