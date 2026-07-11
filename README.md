# SnapPrint

A photo product e-commerce platform — customers order custom-printed photo products through a Flutter mobile app, backed by a FastAPI service and managed through a React admin dashboard.

## Repo structure

| Path | What it is | Stack |
|---|---|---|
| [`snap_print/`](snap_print/) | Customer-facing mobile app | Flutter, Riverpod, go_router, Firebase Auth/Storage/FCM, Razorpay |
| [`backend/`](backend/) | API server | FastAPI, SQLAlchemy (async), PostgreSQL, Alembic, Firebase Admin, Razorpay, Cloudflare R2 |
| [`admin-web/`](admin-web/) | Admin dashboard (active) | React 19, TypeScript, Vite, TanStack Query, Tailwind |
| [`admin/`](admin/) | Admin dashboard (early Flutter prototype, superseded by `admin-web/`) | Flutter |

Other docs: [`BUG_REPORT.md`](BUG_REPORT.md), [`FIX_LOG.md`](FIX_LOG.md), [`QA_REPORT.md`](QA_REPORT.md).

## Getting started

### Backend (`backend/`)

```bash
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # fill in DATABASE_URL, Firebase, Razorpay, R2 credentials
alembic upgrade head
uvicorn main:app --reload
```

### Admin dashboard (`admin-web/`)

```bash
cd admin-web
npm install
cp .env.example .env.local   # set VITE_API_URL to the backend URL
npm run dev
```

### Mobile app (`snap_print/`)

```bash
cd snap_print
flutter pub get
# add snap_print/android/app/google-services.json and
# snap_print/ios/Runner/GoogleService-Info.plist from your Firebase project
flutter run
```

## Environment variables

Nothing secret is committed. Every service ships a `.env.example` (or equivalent) listing the required variables as placeholders — copy it, fill in real values locally, and never commit the filled-in file. Firebase service-account JSON keys, `.env` files, and Android signing keys are excluded via `.gitignore`.

## Backend API surface

Routers live in `backend/app/routers/`: `auth`, `admin`, `products`, `categories`, `banners`, `coupons`, `cart`, `orders`, `payments`, `delivery`, `delivery_options`, `addresses`, `upload`, `realtime` (WebSocket sync).
