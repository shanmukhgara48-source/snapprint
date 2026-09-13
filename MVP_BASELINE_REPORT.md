# SnapPrint — Baseline Report (start of 100%-launch build)

**Date:** 2026-09-13
**Context:** A prior MVP pass had already implemented the core purchase journey
(auth OTP, backend-driven catalogue, upload, server-quoted cart/checkout,
verified payment → real order, real success page, toasts, SEO basics, E2E).
This report records the verified starting state before the remaining
100%-launch phases (contact backend, account management, structured data,
admin review, DB indexes, security tests, CI, backups, monitoring).

---

## 1. Stack (verified from code)

| Layer | Technology |
|---|---|
| Website | React 19 + React Router 7 + Vite 8 + Tailwind 4 + framer-motion 13 + Firebase Web SDK 12 |
| Backend | FastAPI + SQLAlchemy (async) + Alembic + slowapi rate limits + PyJWT |
| Database | PostgreSQL (asyncpg); 15+ models; 13 migrations (head `h8d3f6a0c457`) |
| Auth | Firebase phone OTP → `POST /auth/verify` → app Bearer JWT; admin username/password → 8h JWT |
| Payments | Razorpay: server-calculated `POST /payments/razorpay/order` → Checkout.js → `POST /payments/razorpay/verify` (HMAC + capture check) → `POST /orders` (idempotent via `consumed` intents) |
| Storage | Private Cloudflare R2; signed `/media/{ns}/{user}/{file}?sig=` gateway; ownership enforced at order time |
| Hosting | Firebase Hosting / Railway configs present; backend Dockerfile + Procfile |
| Tests | Backend pytest (53 files-passing at baseline); website node:test unit (7); Playwright E2E (18 across chromium+mobile) |

## 2. Build status (measured)

- `website`: `tsc -b && vite build` — **PASS** (baseline had 14 TS errors, already fixed in prior pass).
- `backend`: imports clean; full pytest — **53/53 PASS**.
- E2E mocked-API suite — **18/18 PASS** (9 specs × chromium + Pixel 7).

## 3. Blockers carried in (all external — no code defect)

1. Firebase Admin key for `snapprint-5076c`, Phone provider, web config, authorized domains.
2. Razorpay `rzp_live_*` keys + live activation + controlled ₹1 drill.
3. Rotation of previously quoted R2/HF/secret/admin credentials.
4. Production `DATABASE_URL` + hosting env + domains/TLS.
5. All 11 `BUSINESS` legal fields empty (by design — never fabricated).

## 4. Architecture notes (verified, preserved as-is)

- Bearer-token auth (no cookies) → no CSRF layer needed; CORS allowlist enforced.
- Backend is authoritative for price/stock/coupon/shipping; frontend never decides totals.
- Media stays private; the earlier audit's "make bucket public" advice was superseded by the signed gateway.
- Admin-web JWT lives in **sessionStorage** (tab-scoped), 8h expiry, login rate-limited (5/min), role re-checked per request — kept for MVP (see report §Phase 22).

## 5. Files slated for modification in this session

- `backend/app/models/` + `alembic/versions/` (contact messages, order index)
- `backend/app/routers/` (`contact.py` new, `auth.py` GET /me, `admin.py` inbox)
- `backend/main.py` (router registration), `backend/tests/` (new suites)
- `website/src/pages/` (`Contact.tsx` form, `Account.tsx` new)
- `website/src/components/Seo.tsx` (JSON-LD), `Home.tsx`/`ProductDetail.tsx` (schema)
- `website/src/services/api.ts`, `App.tsx`, `Nav.tsx` (account surface)
- `.github/workflows/website-ci.yml` (new), `BACKUP_AND_RECOVERY.md` (new)
- `OWNER_LAUNCH_ACTIONS.md` (new), `MVP_IMPLEMENTATION_REPORT.md` (update)
