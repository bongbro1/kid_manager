<!-- GSD:project-start source:PROJECT.md -->
## Project

Kid Manager is a brownfield Flutter family-safety app for parents, guardians, and children. It already contains live tracking, safe routes, SOS, notifications, chat, schedules, and child-management surfaces on top of Firebase and Android-native background services.

Current priority is reliability over breadth: stabilize session/bootstrap, tracking ownership, and notification routing before expanding scope.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:STACK.md -->
## Technology Stack

- Flutter + Dart app in `lib/`
- Firebase backend via Firestore, RTDB, Auth, Storage, Messaging, App Check, and Cloud Functions
- Mapbox for maps, routing, and geocoding
- Android-native Kotlin services for tracking/background runtime
- TypeScript Cloud Functions in `functions/src/`
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

- Match the nearest existing pattern instead of imposing a repo-wide rewrite
- Dart uses `snake_case.dart`, `camelCase` members, `_privateFields`, and Provider/ChangeNotifier heavily
- Backend TypeScript uses Google-style ESLint formatting with semicolons and double quotes
- Prefer package imports (`package:kid_manager/...`) in Flutter code
- Be extra careful when touching session bootstrap, tracking, and notification routing
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

- `lib/main.dart` + `lib/app.dart` build the app/runtime composition root
- `lib/features/sessionguard/` resolves session identity and bootstraps side effects
- `lib/viewmodels/`, `lib/repositories/`, and `lib/services/` are the legacy backbone
- `lib/features/safe_route/` is the clearest newer feature slice
- `functions/src/` contains backend enforcement, notifications, safe-route logic, and scheduled jobs
- Android tracking behavior also depends on Kotlin services under `android/app/src/main/kotlin/com/example/kid_manager/`
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project-local skills found.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `$gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `$gsd-debug` for investigation and bug fixing
- `$gsd-plan-phase 1` / `$gsd-execute-phase 1` for planned roadmap work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `$gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` and should stay lightweight until configured.
<!-- GSD:profile-end -->
