# Codebase Structure

**Analysis Date:** 2026-04-20

## Directory Layout

```text
kid_manager/
├── android/            # Android app config, Kotlin services, manifest/resources
├── assets/             # Fonts, icons, sounds, templates, zone/map media
├── functions/          # Firebase Cloud Functions backend
├── ios/                # iOS runner scaffold
├── lib/                # Flutter application source
├── linux/              # Linux runner scaffold
├── macos/              # macOS runner scaffold
├── test/               # Dart unit/widget tests
├── tests/              # Python/Appium smoke automation
├── web/                # Web runner scaffold
├── windows/            # Windows runner scaffold
├── artifacts/          # Generated screenshots/page sources and test artifacts
├── audit_code/         # Ad hoc review/audit documents
├── firebase.json       # Firebase project wiring
├── pubspec.yaml        # Flutter manifest
├── package.json        # Repo-level Firebase/rules tooling
└── README.md           # Large architecture/audit note file (currently gitignored)
```

## Directory Purposes

**`lib/`:**
- Purpose: Main Flutter product code
- Contains: App bootstrap, screens, widgets, repositories, services, view models, feature slices
- Key files: `lib/main.dart`, `lib/app.dart`, `lib/features/sessionguard/session_guard.dart`, `lib/firebase_options.dart`
- Subdirectories:
  - `background/` - Tracking/runtime bootstrap and service state
  - `core/` - Shared policies, constants, and primitives
  - `features/` - Feature-sliced modules such as `safe_route/`, `permissions/`, `map_engine/`, `sessionguard/`
  - `repositories/`, `services/`, `viewmodels/` - Legacy layer-based architecture
  - `views/`, `widgets/` - Screens and reusable UI

**`functions/src/`:**
- Purpose: Backend source before TypeScript compilation
- Contains: Exported functions, domain services, triggers, scripts, helpers, i18n payloads
- Key files: `functions/src/index.ts`, `functions/src/config.ts`, `functions/src/bootstrap.ts`
- Subdirectories:
  - `functions/` - Callable/HTTP/scheduled entry points
  - `services/` - Shared backend logic
  - `triggers/` - Event-driven flows such as safe-route processing
  - `scripts/` - One-off maintenance scripts
  - `i18n/` - Backend localization payloads

**`android/app/src/main/kotlin/com/example/kid_manager/`:**
- Purpose: Android-specific runtime glue
- Contains: `TrackingForegroundService.kt`, `TrackingBootReceiver.kt`, `SupervisionSyncWorker.kt`, `UsageSyncManager.kt`, multiple `MethodChannel` registrations
- Key files: `MainActivity.kt`, `TrackingServiceChannel.kt`, `DeviceTimeZoneChannel.kt`
- Subdirectories: Flat package layout under the app package

**`test/`:**
- Purpose: First-party Dart tests that run under `flutter test`
- Contains: Feature, service, model, and policy tests
- Key files: `test/features/pipeline/tracking_pipeline_test.dart`, `test/features/safe_route/...`, `test/services/background_tracking_status_policy_test.dart`

**`tests/`:**
- Purpose: End-to-end smoke automation against a device/emulator
- Contains: Appium config, driver creation, startup/login/home flows, pytest fixtures
- Key files: `tests/test_smoke_parent_home.py`, `tests/driver_factory.py`, `tests/flutter_source_launcher.py`

**`assets/`:**
- Purpose: Runtime media and packaged files
- Contains: Fonts, icons, sounds, stickers, videos, spreadsheets, map imagery, localized zone strings
- Key files: `assets/fonts/`, `assets/sounds/sos.mp3`, `assets/templates/schedule_template.xlsx`

## Key File Locations

**Entry Points:**
- `lib/main.dart`: Flutter app entry
- `lib/main_automation.dart`: Alternate entry path for automation/instrumentation
- `functions/src/index.ts`: Firebase backend export surface
- `android/app/src/main/kotlin/com/example/kid_manager/MainActivity.kt`: Android-native method-channel bootstrap

**Configuration:**
- `pubspec.yaml`: Flutter dependencies, assets, fonts
- `analysis_options.yaml`: Dart lint rules
- `firebase.json`: Firebase app/functions/rules configuration
- `functions/package.json`: Backend runtime scripts and engine version
- `functions/tsconfig.json`: Backend TypeScript compiler options
- `.env`: Local client-side env file for Mapbox public token

**Core Logic:**
- `lib/features/sessionguard/`: Session resolution and bootstrap
- `lib/viewmodels/location/`: Live and historical tracking state
- `lib/repositories/location/`: Firebase-backed tracking persistence
- `lib/features/safe_route/`: Safe-route domain/data/presentation slice
- `functions/src/services/`: Backend access control, notifications, location, safe-route, quota logic

**Testing:**
- `test/`: Dart tests
- `functions/test/`: Backend assertion-based tests that import built JS modules
- `tests/`: Python/Appium smoke automation

**Documentation / Working Notes:**
- `README.md`: Long-form audit and architecture notes
- `audit_code/`: Additional review docs
- `.planning/`: GSD planning artifacts after initialization

## Naming Conventions

**Files:**
- `snake_case.dart` for Dart source (`child_location_view_model.dart`, `schedule_import_service.dart`)
- `PascalCase.kt` for Kotlin classes (`TrackingForegroundService.kt`)
- `camelCase.ts` / `camelCase.tsx` are not used; backend files still favor `camelCase.ts`-style names such as `safeRouteDirectionsService.ts`
- Dart tests use `*_test.dart`; backend tests use `.test.mjs`

**Directories:**
- Lowercase or snake_case at the top level (`viewmodels/`, `safe_route/`, `memory_day/`)
- Feature folders often nest by concern (`presentation/`, `domain/`, `data/`) only where newer slices were introduced

**Special Patterns:**
- Generated localization output lives in `lib/l10n/app_localizations*.dart`
- Firebase backend build output is expected in `functions/lib/` and is ignored by git
- There is a stray top-level file named `{console.error(e)` that does not match repo conventions and should be treated as accidental workspace debris

## Where to Add New Code

**New Product Feature:**
- Primary code: Prefer the nearest existing neighborhood
- If extending safe route: `lib/features/safe_route/`
- If extending legacy flows: `lib/views/`, `lib/widgets/`, `lib/viewmodels/`, `lib/repositories/`, `lib/services/`
- Tests: `test/` for Dart coverage, `functions/test/` for backend logic, `tests/` for device smoke flows when needed

**New Backend Capability:**
- Entry point: `functions/src/functions/` or `functions/src/triggers/`
- Shared logic: `functions/src/services/`
- Tests: `functions/test/`

**New Platform Hook:**
- Android behavior: `android/app/src/main/kotlin/com/example/kid_manager/`
- iOS/macOS behavior: `ios/Runner/` or `macos/Runner/`
- Flutter channel wrapper: `lib/services/` or `lib/background/`

**Utilities / Shared Policy:**
- Reusable domain or app primitives: `lib/core/`
- Cross-feature services: `lib/services/`
- Simple helpers: `lib/helpers/` or `lib/utils/` depending on the surrounding neighborhood

## Special Directories

**`.dart_tool/`:**
- Purpose: Flutter/Dart generated tooling state
- Source: Flutter toolchain
- Committed: No

**`build/`:**
- Purpose: Flutter build output
- Source: Local builds
- Committed: No

**`node_modules/`:**
- Purpose: Repo-level JS dependencies for Firebase/rules tooling
- Source: `npm install`
- Committed: No

**`artifacts/`:**
- Purpose: Test screenshots, page sources, and other run artifacts
- Source: Local automation
- Committed: Mostly no; currently ignored for screenshots/pagesource paths

**`audit_code/`:**
- Purpose: Human-authored audits and play-policy notes
- Source: Manual analysis
- Committed: Yes

---

*Structure analysis: 2026-04-20*
*Update when directory structure changes*
