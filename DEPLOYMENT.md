# SnapPrint Deployment Checklist

## Backend

Target: Railway or any Docker-capable host.

Required production environment:

```bash
ENV=production
DATABASE_URL=postgresql://...
SECRET_KEY=<64+ random hex chars>
ADMIN_USERNAME=admin
ADMIN_PASSWORD=<strong unique password>
ALLOWED_ORIGINS=https://admin.snapprint.in,https://snapprint.in
ALLOWED_HOSTS=api.snapprint.in
FRONTEND_URL=https://admin.snapprint.in

FIREBASE_CREDENTIALS_JSON=<one-line Firebase service-account JSON>
FIREBASE_CREDENTIALS_PATH=/secure/path/outside/repo/firebase-admin.json
FIREBASE_STORAGE_BUCKET=<bucket>.firebasestorage.app
FIREBASE_PROJECT_ID=<project-id>
FIREBASE_API_KEY=<firebase-web-api-key>

RAZORPAY_KEY_ID=rzp_live_...
RAZORPAY_KEY_SECRET=<live secret>

R2_ACCOUNT_ID=<cloudflare account id>
R2_ACCESS_KEY_ID=<r2 access key>
R2_SECRET_ACCESS_KEY=<r2 secret key>
R2_BUCKET_NAME=snap-photo
R2_PUBLIC_URL=https://pub-....r2.dev
DEV_BYPASS_SECRET=
```

Use `FIREBASE_CREDENTIALS_JSON` in hosted environments. If a file path is required, keep the service-account JSON outside the repository and set `FIREBASE_CREDENTIALS_PATH` to that external file.

Startup command:

```bash
alembic upgrade head && uvicorn main:app --host 0.0.0.0 --port $PORT --workers 2 --proxy-headers --forwarded-allow-ips='*' --access-log
```

Health check:

```text
/health
```

## Admin Web

Set `VITE_API_URL` to the deployed backend URL before building.

```bash
cd admin-web
npm ci
VITE_API_URL=https://api.snapprint.in npm run build
```

Deploy `admin-web/dist/` to a static host such as Vercel, Netlify, Cloudflare Pages, or S3/R2 + CDN.

## Android App

Build with production API and live Razorpay key:

```bash
./build_production.sh https://api.snapprint.in "$RAZORPAY_LIVE_KEY_ID"
```

Optional version override:

```bash
BUILD_NAME=1.0.0 BUILD_NUMBER=42 ./build_production.sh https://api.snapprint.in "$RAZORPAY_LIVE_KEY_ID"
```

Before uploading to Play Console:

- Confirm `snap_print/android/app/google-services.json` belongs to the production Firebase project.
- Provide release signing via `snap_print/android/key.properties` locally, using `snap_print/android/key.properties.example` as the template, or set `KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, and `KEY_PASSWORD` in CI.
- The production script fails if the API URL is not HTTPS, points to a local/example host, uses a non-live Razorpay key, or is missing Android signing credentials.
- Upload `build/debug-symbols/` for deobfuscated crash reports.
- Upload `snap_print/build/app/outputs/bundle/release/app-release.aab` to Play Console.

## iOS App

iOS bundle id: `com.snapprint.app`.

The iOS project now includes the required camera/photo usage descriptions and has a minimum iOS target of 13.0.

iOS Firebase still needs one final production decision before App Store release: make sure the iOS app is registered in the same Firebase project that the backend uses to verify Firebase ID tokens. The checked-in `snap_print/ios/Runner/GoogleService-Info.plist` and `snap_print/lib/firebase_options.dart` should be regenerated together so they agree.

Run:

```bash
cd snap_print
flutterfire configure --project=<firebase-project-id>
```

Then provide the Firebase iOS values as build defines and verify:

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

For App Store upload, open `snap_print/ios/Runner.xcworkspace` in Xcode, set the Apple development team/signing profile, archive `Runner`, and upload through Organizer or Transporter.

## Flutter Web App

The Flutter web target builds as a JavaScript app:

```bash
cd snap_print
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

Before serving `snap_print/build/web/`, provide the Firebase web app build defines above. The current dependency set is not WebAssembly-ready because `flutter_secure_storage_web` still uses browser APIs that Flutter's Wasm dry run flags; deploy the standard JS build unless those dependencies are changed.
