# Coding Conventions

**Analysis Date:** 2026-04-20

## Naming Patterns

**Files:**
- Dart source uses `snake_case.dart` across `lib/`
- Dart tests use `*_test.dart` in `test/`
- Backend tests use `.test.mjs` in `functions/test/`
- Android native classes use `PascalCase.kt`

**Functions:**
- Dart and TypeScript functions use `camelCase`
- Async functions do not carry a special prefix; `Future<>` / `Promise<>` types communicate async behavior
- Event handlers and lifecycle methods use descriptive verbs such as `handleTap`, `startLocationSharing`, `watchFamilyMembers`, `syncUserTimeZone`

**Variables:**
- Private Dart members use `_underscorePrefix`
- Public members and locals use `camelCase`
- Constants use `camelCase` in many Dart classes, but true global/static constants frequently use `UPPER_SNAKE_CASE` on the backend (`SOS_DAILY_LIMIT`, `TASK_QUEUE`)

**Types:**
- Classes, enums, and typedef-like models use `PascalCase`
- No `I` prefix for interfaces or abstract contracts
- Enum values follow the host language style (`UserRole.parent`, string values like `"parent"`)

## Code Style

**Formatting:**
- Dart code is Flutter-style with 2-space indentation, single quotes, and trailing commas on multiline widget/data literals
- TypeScript code in `functions/` follows the Google/TypeScript ESLint style with semicolons and double quotes
- Large files are common, especially in view models and services; extraction is uneven across the repo

**Linting:**
- Dart linting comes from `analysis_options.yaml` and `package:flutter_lints/flutter.yaml`
- Repo-specific Dart rules enable `avoid_print`, `cancel_subscriptions`, `close_sinks`, `unawaited_futures`, and `use_build_context_synchronously`
- Backend linting lives in `functions/` via ESLint + `eslint-config-google`

## Import Organization

**Order:**
1. External packages (`package:flutter/...`, `firebase-functions/...`)
2. Internal package imports (`package:kid_manager/...`)
3. Relative imports (`./config`, `../services/...`) where used in TypeScript or a few Dart files

**Grouping:**
- Blank lines usually separate package groups
- Flutter files often keep one import per line and prefer package imports over deep relative paths
- Backend files group external imports first, then project-relative imports

**Path Aliases:**
- None observed; the Flutter app relies on `package:kid_manager/...`
- The backend uses relative TypeScript imports

## Error Handling

**Patterns:**
- UI/runtime code uses `try/catch`, `debugPrint`, and view-model `_error` state rather than a centralized error abstraction
- Backend code validates inputs early and throws `HttpsError` for user-visible failures
- Session/bootstrap flows retry selected failures instead of immediately surfacing them to the user

**Error Types:**
- Throw on invalid auth/session state, missing required identifiers, or malformed backend inputs
- Return nullable/empty values for common not-found or non-critical paths
- Log context near the integration boundary before bubbling or swallowing

## Logging

**Framework:**
- `debugPrint` dominates the Flutter app
- `console.log` / `console.warn` appear in backend and test utilities

**Patterns:**
- Logs are operational and imperative, not structured JSON
- Tracking, notifications, and session bootstrap are the noisiest logging areas
- There is no dedicated observability SDK such as Sentry in the repo

## Comments

**When to Comment:**
- Comments explain platform edge cases, permission behavior, or lifecycle nuances
- Many comments are bilingual or written in Vietnamese
- TODOs are lightweight inline notes, not issue-linked work items

**Documentation Style:**
- Public API docblocks are uncommon
- Inline comments are more common in native/background code than in simple widget code

**TODO Comments:**
- Examples include auth/social placeholders in `lib/views/auth/start_screen.dart` and navigation placeholders in notification detail widgets
- No strict ownership or ticket format is enforced

## Function Design

**Size:**
- Small helpers exist, but several view models and services are very large and stateful
- Lifecycle-heavy classes own timers, stream subscriptions, and throttling logic internally

**Parameters:**
- Constructors often accept optional overrides for testability while defaulting to singleton SDK instances
- Named parameters are common in Dart APIs and backend helper inputs

**Return Values:**
- Guard clauses are common
- Imperative methods often return `Future<void>`
- Repository/query methods typically return typed models, streams, or nullable results

## Module Design

**Exports:**
- Named exports are the default
- Flutter screens/widgets rely on direct file imports rather than barrel files
- `export` is used sparingly, for example in `lib/repositories/user_repository.dart`

**Architectural Guidance for New Work:**
- Extend the nearest existing pattern instead of forcing a global rewrite
- If touching `safe_route`, stay inside its `data/domain/presentation` slice
- If touching older flows, match the repository/service/viewmodel/widget split already in place

---

*Convention analysis: 2026-04-20*
*Update when patterns change*
