# Android Automation Smoke Test for `kid_manager`

## Stack
- Python 3.11+
- pytest
- Appium 2
- appium-flutter-driver

## Install
1. Install Android Studio and Android SDK.
2. Connect a device with USB debugging enabled, or start an Android emulator.
3. Install Node.js 18+.
4. Install Appium 2:
   - `npm install -g appium`
5. Install the Flutter Appium driver:
   - `appium driver install --source=npm appium-flutter-driver`
6. Create a virtual environment:
   - `python -m venv .venv`
   - `.venv\Scripts\activate`
7. Install Python dependencies:
   - `pip install -r tests/requirements-automation.txt`

## Required Environment Variables
- `APPIUM_URL=http://127.0.0.1:4723`
- `DEVICE_NAME=Android Emulator`
- `UDID=<optional-real-device-udid>`
- `FLUTTER_DEVICE_ID=<optional-adb-device-id>`
- `FLUTTER_BIN=<optional-full-path-to-flutter-or-flutter.bat>`
- `ADB_BIN=<optional-full-path-to-adb-or-adb.exe>`
- `APP_PACKAGE=com.example.kid_manager`
- `APP_ACTIVITY=.MainActivity`
- `APK_PATH=<optional-debug-or-profile-apk>`
- `TEST_EMAIL=<parent-test-email>`
- `TEST_PASSWORD=<parent-test-password>`
- `APP_LANGUAGE=vi`
- `LAUNCH_FROM_SOURCE=true`
- `AUTO_PREPARE_ANDROID_PERMISSIONS=true`
- `FLUTTER_TARGET=lib/main_automation.dart`
- `FLUTTER_RUN_TIMEOUT=240`
- `VM_SERVICE_SETTLE_TIME=5`
- `TEXT_ENTRY_EMULATION=true`
- `OBSERVATORY_RETRY_BACKOFF_MS=3000`
- `OBSERVATORY_MAX_RETRY_COUNT=30`

If `APK_PATH` is omitted, the script launches the installed app using `APP_PACKAGE` and `APP_ACTIVITY`.
If `LAUNCH_FROM_SOURCE=true`, the test starts the latest code directly with `flutter run --machine` and Appium attaches to the emitted Observatory / VM service URL.
On Windows, if `flutter` is not in PATH, set `FLUTTER_BIN`, for example:
- `FLUTTER_BIN=D:\flutter_windows_3.38.3-stable\flutter\bin\flutter.bat`
If `AUTO_PREPARE_ANDROID_PERMISSIONS=true`, the test will use ADB before launch to pre-grant runtime permissions and best-effort special access for:
- notifications
- location/background location
- media/images
- usage access
- battery optimization whitelist
- accessibility service

## Run
1. Start the Appium server:
   - `appium`
2. Run the smoke test:
   - `pytest -s tests/test_smoke_parent_home.py`

## Notes
- The Flutter Appium driver is intended for Flutter `debug` or `profile` builds.
- The repo now includes `lib/main_automation.dart` for automation runs. Use it through `FLUTTER_TARGET` or leave the default as-is.
- `LAUNCH_FROM_SOURCE=true` means you do not need to manually build an APK first, but Flutter still compiles the latest source transiently during `flutter run`.
- `AUTO_PREPARE_ANDROID_PERMISSIONS=true` is best-effort. On some OEM devices, special access pages may still behave differently from stock Android.
- `TEXT_ENTRY_EMULATION` is retained as a config flag, but the startup call is currently disabled because the installed `appium-flutter-driver` crashes with a null socket when `setTextEntryEmulation` is sent immediately after session creation.
- In practice, the test still uses Flutter-side text input automation, so the real soft keyboard usually will not appear on Android while the script is typing.
- If you do not want any Flutter-driver instrumentation at all, use Appium `UiAutomator2` as a black-box strategy instead of `appium-flutter-driver`.
- Failure artifacts are written to:
  - `artifacts/screenshots/`
  - `artifacts/pagesource/`
