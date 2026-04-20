# External Integrations

**Analysis Date:** 2026-04-20

## APIs & External Services

**Firebase Platform:**
- Firebase Auth - Session identity for parent/guardian/child users
  - Client SDKs in `pubspec.yaml`
  - Config in `lib/firebase_options.dart`
  - App usage across `lib/repositories/auth_repository.dart`, `lib/features/sessionguard/`, and `lib/services/firebase_auth_service.dart`
- Firebase Cloud Functions - Callable and trigger-backed backend
  - Entry point: `functions/src/index.ts`
  - Client access via `cloud_functions` and service wrappers such as `lib/services/location/mapbox_gateway_service.dart`
- Firebase Cloud Messaging - Push notifications and background message handling
  - Client setup in `lib/main.dart`, `lib/services/notifications/notification_service.dart`, and `lib/services/notifications/sos_notification_service.dart`
- Firebase App Check - Activated in `lib/services/firebase_app_check_service.dart`

**Mapbox:**
- Used for map rendering, geocoding, route search, and trace matching
  - Client public token read from `.env` or `--dart-define` in `lib/main.dart`
  - Backend secret token defined in `functions/src/config.ts`
  - Backend integration in `functions/src/functions/mapbox.ts`, `functions/src/services/mapboxGateway.ts`, and `functions/src/services/safeRouteDirectionsService.ts`

**Email:**
- Resend - Transactional email delivery from backend
  - Secret: `RESEND_API_KEY` in `functions/src/config.ts`
  - Sender config: `MAIL_FROM`
  - Function: `functions/src/functions/send_email.ts`

**Social Sign-In Providers:**
- Google Sign-In and Facebook Auth packages are installed in `pubspec.yaml`
  - Client integration is routed through `lib/repositories/auth_repository.dart`
  - UI affordances exist in auth screens under `lib/views/auth/`

**Task Queue / Scheduling:**
- Google Cloud Tasks - SOS reminder queue
  - Queue/runtime config in `functions/src/config.ts`
  - Related worker logic in backend services and SOS flows

## Data Storage

**Databases:**
- Cloud Firestore - Primary structured data store
  - Rules: `firestore.rules`
  - Indexes: `firestore.indexes.json`
  - App-side usage across repositories in `lib/repositories/`
- Firebase Realtime Database - Live location and some zone/tracking data
  - Rules: `database.rules.json`
  - App-side usage in `lib/repositories/location/location_repository_impl.dart` and `lib/repositories/zones/zone_repository.dart`

**File Storage:**
- Firebase Storage - User/media storage
  - Rules: `storage.rules`
  - App usage in `lib/services/image_service.dart` and related media/chat paths

**Caching / Local State:**
- Shared Preferences / secure local storage on device
  - Used via `lib/services/storage_service.dart`, `flutter_secure_storage`, and tracking runtime storage in `lib/background/tracking_runtime_store.dart`

## Authentication & Identity

**Auth Provider:**
- Firebase Auth - Core auth/session provider
  - Email/password is clearly supported
  - Parent/guardian/child role and profile state are stored in Firestore-backed repositories

**Identity / Membership:**
- Family, profile, and membership repositories coordinate account relationships
  - `lib/repositories/user/profile_repository.dart`
  - `lib/repositories/user/family_repository.dart`
  - `lib/repositories/user/membership_repository.dart`
- Backend access control mirrors these constraints in services such as `functions/src/services/zoneAccess.ts` and `functions/src/services/locationAccess.ts`

## Monitoring & Observability

**Logs:**
- Flutter uses `debugPrint`
- Backend uses `console.log` / `console.warn`
- Firebase Functions logs can be retrieved via `functions/package.json` script `npm run logs`

**Error Tracking / Analytics:**
- No dedicated crash-reporting or analytics SDK was observed
- Operational visibility is mostly log-driven

## CI/CD & Deployment

**Hosting / Backend Deploy:**
- Firebase deployment scripts live in `functions/package.json`
- Functions are deployed manually with Firebase CLI commands such as `firebase deploy --only functions`

**CI Pipeline:**
- No `.github/workflows/` or similar CI pipeline was observed in the repo
- Test and deploy steps appear to be run manually or from a developer workstation

## Environment Configuration

**Development:**
- `.env` provides the Mapbox public token for the Flutter client
- Firebase mobile configuration is committed in platform-specific config files
- Backend secrets are expected from Firebase Functions params/secrets, not committed plaintext

**Production:**
- Firebase project: `kidmanager-b4a8f`
- Backend region defaults to `asia-southeast1`
- Android appears to be the most operationally customized platform

## Webhooks & Callbacks

**Incoming Platform Callbacks:**
- FCM callbacks handled through `FirebaseMessaging` listeners in the client
- Native Android/iOS callbacks enter Flutter through method channels such as `tracking_service`, `device_timezone`, `watcher_config`, and `notification_intent`

**Outgoing Notifications / Fan-out:**
- Backend fan-out for SOS, tracking, birthdays, zone events, and family chat is handled in `functions/src/services/` and exported functions/triggers
- Safe-route and notification cleanup jobs also run from backend triggers and scheduled flows

---

*Integration audit: 2026-04-20*
*Update when adding/removing external services*
