# SnapPrint Flutter App

Customer and delivery mobile app for SnapPrint.

## Local Checks

```bash
flutter pub get
flutter analyze
flutter test
```

## Android Release Build

From the repository root:

```bash
./build_production.sh https://api.snapprint.in "$RAZORPAY_LIVE_KEY_ID"
```

The script requires:

- `SNAPPRINT_API_URL` or the first CLI argument set to an HTTPS production API URL.
- `RAZORPAY_KEY_ID` or the second CLI argument set to a live `rzp_live_...` key.
- Android upload signing through `android/key.properties` or the CI env vars `KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, and `KEY_PASSWORD`.

Use `android/key.properties.example` as the local signing template. Do not commit the real keystore or `key.properties`.

Optional version override:

```bash
BUILD_NAME=1.0.0 BUILD_NUMBER=42 ./build_production.sh https://api.snapprint.in "$RAZORPAY_LIVE_KEY_ID"
```

Output:

```text
snap_print/build/app/outputs/bundle/release/app-release.aab
build/debug-symbols/
```

## iOS Release Build

Before App Store release, register `com.snapprint.app` in the production Firebase project and supply its iOS client values at build time:

```bash
flutterfire configure --project=<firebase-project-id>
```

Then run a no-codesign build:

```bash
flutter build ios --release --no-codesign \
  --dart-define=SNAPPRINT_API_URL=https://api.snapprint.in \
  --dart-define=RAZORPAY_KEY_ID="$RAZORPAY_LIVE_KEY_ID" \
  --dart-define=SNAPPRINT_FIREBASE_IOS_API_KEY=<ios-api-key> \
  --dart-define=SNAPPRINT_FIREBASE_IOS_APP_ID=<ios-app-id> \
  --dart-define=SNAPPRINT_FIREBASE_IOS_MESSAGING_SENDER_ID=<sender-id> \
  --dart-define=SNAPPRINT_FIREBASE_IOS_PROJECT_ID=<project-id> \
  --dart-define=SNAPPRINT_FIREBASE_IOS_STORAGE_BUCKET=<bucket>
```

Use Xcode with `ios/Runner.xcworkspace` for the signed archive/upload.

## Web Release Build

```bash
flutter build web --release \
  --dart-define=SNAPPRINT_API_URL=https://api.snapprint.in \
  --dart-define=RAZORPAY_KEY_ID="$RAZORPAY_LIVE_KEY_ID" \
  --dart-define=SNAPPRINT_FIREBASE_WEB_API_KEY=<web-api-key> \
  --dart-define=SNAPPRINT_FIREBASE_WEB_APP_ID=<web-app-id> \
  --dart-define=SNAPPRINT_FIREBASE_WEB_MESSAGING_SENDER_ID=<sender-id> \
  --dart-define=SNAPPRINT_FIREBASE_WEB_PROJECT_ID=<project-id> \
  --dart-define=SNAPPRINT_FIREBASE_WEB_AUTH_DOMAIN=<project-id>.firebaseapp.com \
  --dart-define=SNAPPRINT_FIREBASE_WEB_STORAGE_BUCKET=<bucket>
```

Deploy `build/web/` only after providing the Firebase web app values above. The current dependency set builds for the standard JavaScript web target, but Flutter's Wasm dry run reports unsupported browser APIs from `flutter_secure_storage_web`.
