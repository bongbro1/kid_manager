# Technology Stack

**Analysis Date:** 2026-04-20

## Languages

**Primary:**
- Dart (`>=3.10.7 <4.0.0`) - Flutter application code in `lib/`, generated localization in `lib/l10n/`, and unit/widget tests in `test/`
- TypeScript (`^5.7.3`) - Firebase Cloud Functions source in `functions/src/`

**Secondary:**
- Kotlin - Android-native background tracking, WorkManager scheduling, and Flutter method channels in `android/app/src/main/kotlin/com/example/kid_manager/`
- Swift - iOS and macOS entry points in `ios/Runner/AppDelegate.swift` and `macos/Runner/AppDelegate.swift`
- Python - Appium/pytest mobile smoke automation in `tests/`
- JavaScript / Node test scripts - Root emulator tooling in `package.json` and assertion-driven backend tests in `functions/test/*.mjs`

## Runtime

**Environment:**
- Flutter stable channel application (`.metadata`) with a cross-platform scaffold for Android, iOS, macOS, web, Windows, and Linux
- Node.js 22 for Firebase Cloud Functions (`functions/package.json`)
- Python 3.x for optional local device automation (`tests/requirements-automation.txt`)

**Package Manager:**
- `flutter pub` / `dart pub` for the app (`pubspec.yaml`, `pubspec.lock`)
- `npm` for repo-level Firebase tooling (`package.json`, `package-lock.json`)
- `npm` for `functions/` scripts (`functions/package.json`); no committed lockfile observed under `functions/`

## Frameworks

**Core:**
- Flutter - UI runtime and app shell
- Provider - Global and feature-level state management in `lib/app.dart` and `lib/features/sessionguard/session_guard.dart`
- Firebase client SDKs - Auth, Firestore, Realtime Database, Storage, Messaging, App Check, and Callable Functions
- Firebase Cloud Functions v2 - Serverless backend exported from `functions/src/index.ts`
- Mapbox - Map rendering in the client and routing/geocoding/matching via backend functions

**Testing:**
- `flutter_test` - Dart unit and widget tests in `test/`
- Node built-in test/assert tooling - Backend service tests in `functions/test/*.mjs`
- `pytest` + Appium Flutter Driver - Android smoke automation in `tests/`

**Build/Dev:**
- Flutter toolchain - App build, run, and platform packaging
- TypeScript compiler (`tsc`) - Functions build output for Firebase deployment
- Firebase CLI - Emulators, rules checks, and deployment scripts

## Key Dependencies

**Critical:**
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_database`, `firebase_storage`, `firebase_messaging`, `cloud_functions` - Core app/backend integration
- `provider` - Primary dependency injection and state propagation mechanism
- `mapbox_maps_flutter` - Map rendering and interaction surfaces
- `location`, `geolocator`, `flutter_activity_recognition`, `workmanager` - Tracking and background execution
- `flutter_local_notifications`, `just_audio` - Notification and SOS alert UX

**Infrastructure:**
- `firebase-admin`, `firebase-functions` - Backend runtime in `functions/`
- `@google-cloud/tasks` - SOS reminder queue fan-out in `functions/src/config.ts` and related services
- `resend` - Transactional email sending in `functions/src/functions/send_email.ts`

## Configuration

**Environment:**
- `.env` plus `--dart-define` for `MAPBOX_PUBLIC_ACCESS_TOKEN` in `lib/main.dart`
- Firebase app configuration in `lib/firebase_options.dart` and `android/app/google-services.json`
- Backend secrets and runtime params in `functions/src/config.ts` (`MAPBOX_ACCESS_TOKEN`, `RESEND_API_KEY`, `MAIL_FROM`, SOS task settings)

**Build:**
- `pubspec.yaml` - Flutter dependencies, assets, fonts
- `analysis_options.yaml` - Dart lint configuration
- `firebase.json`, `firestore.rules`, `database.rules.json`, `storage.rules`, `firestore.indexes.json` - Firebase project configuration
- `functions/tsconfig.json` and `functions/tsconfig.dev.json` - Functions compilation settings

## Platform Requirements

**Development:**
- Flutter SDK on the stable channel
- Android toolchain for the most customized runtime path
- Node.js + Firebase CLI for Functions, emulators, and rules work
- Optional Python/Appium stack for device smoke tests

**Production:**
- Firebase project `kidmanager-b4a8f` for backend services and mobile config (`firebase.json`)
- Primary production emphasis appears to be Android, with additional Flutter platforms scaffolded but much less customized
- Firebase Functions region is `asia-southeast1`; RTDB-triggered work also references `us-central1` in `functions/src/config.ts`

---

*Stack analysis: 2026-04-20*
*Update after major dependency changes*
