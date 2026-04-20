# Testing Patterns

**Analysis Date:** 2026-04-20

## Test Framework

**Runner:**
- `flutter test` for Dart tests under `test/`
- Node built-in assertions / ad hoc script execution for backend tests under `functions/test/`
- `pytest` for device-driven smoke automation under `tests/`

**Assertion Library:**
- Flutter uses `package:flutter_test/flutter_test.dart`
- Backend tests use `node:assert/strict`
- Pytest uses standard `assert` statements and reusable flow/page objects

**Run Commands:**
```bash
flutter test                                      # Run Dart tests in test/
pytest tests/test_smoke_parent_home.py            # Run Appium smoke test (after Appium/device setup)
npm run test:firestore-rules                      # Repo-level firestore rules check (script currently points at a missing file)
cd functions && npm run build                     # Compile backend before running tests that import ../lib/*
```

## Test File Organization

**Location:**
- `test/` - Dart unit/widget tests grouped by feature or service
- `functions/test/` - Backend assertion scripts against built JS modules
- `tests/` - Python/Appium device smoke automation and helper flows

**Naming:**
- Dart: `*_test.dart`
- Backend: `*.test.mjs`
- Pytest: `test_*.py`

**Structure:**
```text
test/
  core/location/current_publish_policy_test.dart
  features/pipeline/tracking_pipeline_test.dart
  features/safe_route/...
  services/background_tracking_status_policy_test.dart

functions/test/
  authorized_notifications.test.mjs
  trusted_location.test.mjs
  zone_access.test.mjs

tests/
  test_smoke_parent_home.py
  flows/
  driver_factory.py
```

## Test Structure

**Suite Organization:**
```dart
group('FeatureName', () {
  test('handles the expected scenario', () {
    // arrange
    // act
    // assert
  });
});
```

**Patterns:**
- Dart tests commonly use local builder/helper functions inside the test file instead of shared fixture packages
- Backend tests are plain functions executed sequentially, then finish with a success `console.log`
- Pytest smoke tests compose reusable `StartupFlow`, `LoginFlow`, and `HomeAssertions` objects

## Mocking

**Framework:**
- No `mockito`, `mocktail`, `sinon`, or equivalent mocking framework is currently wired into the repo
- Tests lean toward pure-function inputs, lightweight builders, and real policy classes where possible

**Patterns:**
- Dart tests prefer simple object factories and deterministic input snapshots
- Backend tests import compiled modules from `functions/lib/` and validate pure logic with explicit objects
- Pytest smoke automation interacts with a real app/device environment rather than mocking UI state

**What to Mock:**
- External APIs and Firebase boundaries would need custom seams or fakes; there is no shared mocking toolkit yet
- Device automation relies on environment setup instead of mocks

## Fixtures and Factories

**Test Data:**
- Dart tests create inline factory helpers such as `buildUser(...)` and `buildSnapshot(...)`
- Backend tests use inline `makeLocation(...)` helpers and explicit context objects
- Pytest stores reusable runtime config in fixtures (`tests/conftest.py`) and flow/page objects in `tests/flows/`

**Location:**
- Mostly local to each test file
- No dedicated `fixtures/` or `factories/` directory exists for Dart or backend tests

## Coverage

**Requirements:**
- No explicit coverage target or gate was found
- Coverage appears awareness-driven, not enforced by CI

**Configuration:**
- No coverage config file or CI workflow was found in the repo
- Critical logic has some focused tests, but end-to-end coverage is incomplete

## Test Types

**Unit Tests:**
- Policy and transformation logic in `test/core/`, `test/services/`, `test/features/safe_route/`
- Examples: tracking status policy, user serialization, access control, safe-route models

**Backend Logic Tests:**
- Authorization and location/safety policy tests in `functions/test/`
- These tests assume compiled JS exists in `functions/lib/`

**Smoke / Device Tests:**
- Parent-home smoke flow in `tests/test_smoke_parent_home.py`
- Uses Appium Flutter Driver, a device/emulator, and app launch helpers

## Common Patterns

**Async Testing:**
- Dart tests use synchronous expectations for pure helpers and `async`/`await` where needed
- Backend tests run plain async functions and assert on returned objects

**Error Testing:**
- Backend tests frequently use `assert.throws(...)`
- Dart tests rely on `expect(..., throws...)` patterns when needed

**Operational Gaps:**
- `package.json` references `test/firestore.rules.test.cjs`, but that file is not present
- `functions/package.json` references `test/user_auth.test.cjs`, but that file is also missing
- `.gitignore` currently ignores `test/` and `**/*_test.dart`, which can hide new test files from git if they are not already tracked

---

*Testing analysis: 2026-04-20*
*Update when test patterns change*
