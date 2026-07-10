# Optimus CGM Flutter

Optimus CGM is a Flutter application for continuous glucose monitoring workflows. It provides customer, doctor, and admin workspaces with glucose charts, daily readings, meal impact logging, AI-style coaching summaries, sensor setup, alerts, privacy controls, reports, support flows, and reorder/order history.

## Current Product Surface

- Role-based login for customer, doctor, and admin preview workspaces.
- Customer onboarding with consent, safety terms, and sensor setup path.
- Dashboard with current glucose, chart preview, alerts, meal focus, logbook preview, coaching, and sensor status.
- Full chart and daily readings screens, including previous-date logbook navigation.
- Meal logging with meal score and recent meal history.
- Privacy, alert thresholds, report export, support, account, and dark-mode controls.
- Sensor activation flow with browser preview and native SDK path.
- Doctor patient review and admin operations dashboards.

## Run Locally

```powershell
flutter pub get
flutter run -d chrome
```

For the existing static web preview:

```powershell
flutter build web --no-pub
```

Then refresh the local preview URL, for example:

```text
http://127.0.0.1:8088/#/dashboard
```

## Verification

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter test --no-pub --update-goldens test\golden_screens_test.dart
flutter build web --no-pub
```

Golden snapshots live in `test/goldens/`. Temporary comparison artifacts should not be committed from `test/failures/`.

## Environment

Runtime environment is selected with compile-time values:

```powershell
flutter build web --dart-define=APP_ENV=production --dart-define=CGM_APP_ID=... --dart-define=CGM_APP_SECRET=...
```

All environments use the deployed Railway API by default:

```text
https://optimus-cgm-backend-production.up.railway.app/api
```

To use another backend (for example, a local Laravel server), provide the full
API URL including `/api`:

```powershell
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Supported `APP_ENV` values:

- `development`: preview defaults, backend demo sign-in, and verbose logging.
- `staging`: staging runtime behavior using the configured API base URL.
- `production`: production runtime behavior using the configured API base URL.

## Firebase And Notifications

Firebase Analytics, Crashlytics, and Messaging are initialized when Firebase is configured. Without Firebase app options or native config files, the app runs safely in preview mode.

Production setup checklist:

- Add Android `google-services.json`.
- Add iOS `GoogleService-Info.plist`.
- Add web Firebase options if building web with Firebase enabled.
- Run `flutterfire configure` for project-specific options.
- Confirm notification topics and backend push-token registration endpoints.

## Backend

Repository providers synchronize with the deployed Railway backend by default.
The API base URL is defined in `lib/core/env/app_environment.dart` and can be
overridden at build/run time with `API_BASE_URL`.

Expected backend surfaces include:

- `/auth/sign-in`, `/auth/sign-out`, `/auth/session`, `/auth/refresh`
- `/patients`
- `/patients/{id}/readings`
- `/patients/{id}/meals`
- `/patients/{id}/sensors`
- `/patients/{id}/interpretations`
- `/patients/{id}/orders`
- `/patients/{id}/alerts`
- `/patients/{id}/alert-settings`
- `/patients/{id}/reports`

## Native CGM SDK

The browser preview can show the activation flow but cannot connect to a physical sensor. Android and iOS builds use the native CGM SDK bridge through `CgmSdkService`.

## Release Notes

Before release:

- Run analyzer, tests, goldens, and production build.
- Confirm Firebase config and push notification delivery.
- Confirm backend API contracts and authentication token handling.
- Validate accessibility at mobile and desktop sizes.
- Remove transient build/test failure artifacts.



Critical fixes
Authentication is currently only a UI bypass.
The login screen lets anyone continue as Customer, Doctor, or Admin without backend authentication. [login_screen.dart (line 227)](C:/Users/SurajPawar/OneDrive - Care IO, Inc/SurajPawar/ReactNative/optimus_cgm_flutter/lib/screens/auth/login_screen.dart:227)
Additionally, the public backend registration endpoint accepts role=doctor or role=admin. Someone could register themselves as an administrator. [AuthController.php (line 43)](C:/Users/SurajPawar/OneDrive - Care IO, Inc/SurajPawar/New folder/test/test/app/Http/Controllers/Auth/AuthController.php:43)
Backend authentication bypass is unsafe for real production data.
When AUTH_BYPASS=true, protected endpoints do not require a token. The X-Bypass-User-Id header can also select another user, potentially allowing impersonation. [BypassAuth.php (line 19)](C:/Users/SurajPawar/OneDrive - Care IO, Inc/SurajPawar/New folder/test/test/app/Http/Middleware/BypassAuth.php:19)
It is acceptable temporarily for development, but it must not be exposed when real patients use the system.
The deployed Railway API is currently unhealthy.
Current public checks:
/up → 200
/api/patients → 500
Therefore, the health endpoint is working, but the deployed API/database/authentication configuration is not currently working correctly. Local changes still need deployment and Railway logs must be reviewed.
High-priority reliability and privacy fixes
Failed reading uploads are not automatically retried.
Readings are cached locally, but after an upload failure there is no persistent pending-upload queue. Restored cached readings are displayed but are not automatically uploaded again. [app_state.dart (line 1083)](C:/Users/SurajPawar/OneDrive - Care IO, Inc/SurajPawar/ReactNative/optimus_cgm_flutter/lib/state/app_state.dart:1083)
Multiple backend devices are supported, but Flutter supports only one active Bluetooth sensor at a time.
The app has one global cgmSensorSn. The backend sensor cache is keyed only by serial number, not by patientId + serialNumber. Switching patients or receiving delayed callbacks could associate data incorrectly.
The native SDK includes the reading serial number, but CgmBloodSugarReading currently discards that serial and uses the globally selected serial instead. [cgm_sdk_service.dart (line 289)](C:/Users/SurajPawar/OneDrive - Care IO, Inc/SurajPawar/ReactNative/optimus_cgm_flutter/lib/services/cgm_sdk_service.dart:289)
Consent settings are local only.
Changing sensor-data consent does not send it to the backend, and reading uploads do not check whether sensorData consent is enabled. [app_state.dart (line 410)](C:/Users/SurajPawar/OneDrive - Care IO, Inc/SurajPawar/ReactNative/optimus_cgm_flutter/lib/state/app_state.dart:410)
Glucose readings are cached unencrypted.
Glucose values, patient IDs and sensor IDs are stored in SharedPreferences. Android backup protection is also not explicitly disabled. Health data should use encrypted storage. [glucose_reading_cache.dart (line 47)](C:/Users/SurajPawar/OneDrive - Care IO, Inc/SurajPawar/ReactNative/optimus_cgm_flutter/lib/core/cache/glucose_reading_cache.dart:47)
The CGM SDK secret is embedded in Flutter source.
The SDK secret can be extracted from the installed application and should be rotated/restricted or replaced with a vendor-supported server-issued credential flow. [app_environment.dart (line 55)](C:/Users/SurajPawar/OneDrive - Care IO, Inc/SurajPawar/ReactNative/optimus_cgm_flutter/lib/core/env/app_environment.dart:55)
Other required work
Push notifications are incomplete: Flutter calls /push-tokens, but the Laravel route does not exist, the request does not include the stored bearer token, and Firebase configuration files are absent.
Reading creation and alert creation are not transactional. If alert creation fails after inserting a reading, retry deduplication can leave that reading permanently without its alert.
Sensor-session validation confirms patient ownership but does not ensure the supplied session and device belong to each other.
Granular doctor-sharing permissions are stored but not enforced.
Several backend jobs, listeners, policies, repositories and services are empty scaffolds.
The API health endpoint does not check database connectivity, which is why Railway reports healthy while /api/patients returns 500.
Verification results
Flutter static analysis: passed with no issues.
Focused Laravel authentication/patient tests: all 11 passed.
Full Laravel suite: 12 passed, one unrelated example-page test failed because OneDrive denied Laravel permission to rename a compiled Blade file.
Full Flutter suite: three failures:Flaky sensorDaysRemaining calculation expected 5 but returned 4.
Dashboard golden screenshot mismatch.
AI screen golden screenshot mismatch.

The serial registration, backend device ownership check, stable clientReadingId, duplicate protection, reading history merge, and removal of hardcoded glucose readings are all correctly present.
# Firebase push configuration

Push notifications can be configured without committing
`google-services.json` or `GoogleService-Info.plist`. Supply the Firebase
project values at run/build time:

```text
--dart-define=FIREBASE_API_KEY=...
--dart-define=FIREBASE_PROJECT_ID=...
--dart-define=FIREBASE_MESSAGING_SENDER_ID=...
--dart-define=FIREBASE_ANDROID_APP_ID=...
--dart-define=FIREBASE_IOS_APP_ID=...
--dart-define=FIREBASE_STORAGE_BUCKET=...
--dart-define=FIREBASE_IOS_BUNDLE_ID=...
```

When these values and the native APNs/FCM signing capabilities are not
configured, push messaging remains disabled and the rest of the app continues
to run.
