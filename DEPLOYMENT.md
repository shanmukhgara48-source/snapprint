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
./build_production.sh https://api.snapprint.in rzp_live_xxxxx
```

Before uploading to Play Console:

- Confirm `snap_print/android/app/google-services.json` belongs to the production Firebase project.
- Provide release signing via `snap_print/android/key.properties` locally or `KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, and `KEY_PASSWORD` in CI.
- Upload `build/debug-symbols/` for deobfuscated crash reports.

## iOS App

iOS is not production-ready until Firebase has a real iOS app for bundle id `com.snapprint.app`.

Run:

```bash
cd snap_print
flutterfire configure --project=<firebase-project-id>
```

Then verify `snap_print/lib/firebase_options.dart` no longer contains `REPLACE_WITH_IOS_APP_ID`.
