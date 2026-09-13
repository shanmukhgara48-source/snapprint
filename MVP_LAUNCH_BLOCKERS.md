# SnapPrint MVP — Launch Blockers (Owner Actions)

**Date:** 2026-09-13
**Status:** Code implementation complete. The items below require dashboard access,
credentials, or business decisions that cannot be performed from the codebase.

> No secret values are included in this document. Previously committed secrets
> must be treated as compromised — rotate them even if they "still work".

---

## 1. Credentials — ROTATE / SUPPLY

### 1.1 Firebase Admin service account — REQUIRES OWNER ACTION
- **What:** The backend verifies phone-OTP logins with `firebase_admin`.
  It needs a service-account key for Firebase project **`snapprint-5076c`**.
- **Steps:**
  1. Open Firebase Console → project `snapprint-5076c` → Project Settings → Service accounts.
  2. Generate a new private key (JSON).
  3. On the hosting environment, set `FIREBASE_CREDENTIALS_JSON` to the entire
     JSON on one line (preferred), **or** mount the file outside the repo and set
     `FIREBASE_CREDENTIALS_PATH` to its absolute path.
  4. Set `FIREBASE_PROJECT_ID=snapprint-5076c` and `FIREBASE_API_KEY` (Web API key
     from Project Settings → General).
  5. The backend refuses production startup if the key's `project_id` does not
     match `FIREBASE_PROJECT_ID` (see `backend/main.py` fail-fast checks).
- **Verify:** `POST /auth/verify` with a real phone OTP returns 200 and an
  `access_token` (previously returned 401 for all real users).

### 1.2 Firebase Web config (website OTP) — REQUIRES OWNER ACTION
- **What:** The website sends/validates SMS codes with the Firebase Web SDK.
- **Steps:**
  1. Firebase Console → project `snapprint-5076c` → Authentication → Sign-in method → enable **Phone**.
  2. Project Settings → General → Your apps → register the web app, copy the config.
  3. Set website env: `VITE_FIREBASE_API_KEY`, `VITE_FIREBASE_AUTH_DOMAIN`,
     `VITE_FIREBASE_PROJECT_ID=snapprint-5076c`, `VITE_FIREBASE_STORAGE_BUCKET`,
     `VITE_FIREBASE_MESSAGING_SENDER_ID`, `VITE_FIREBASE_APP_ID`.
  4. Authentication → Settings → Authorized domains → add the production domain
     (e.g. `snapprint.in`) and any preview domains.
- **Verify:** On `/auth`, entering a real number sends an SMS; entering the code
  signs in and lands on `/`.

### 1.3 Razorpay production keys — REQUIRES OWNER ACTION
- **What:** Both backend and website still reference test keys.
- **Steps:**
  1. Razorpay Dashboard → complete live activation (KYC + bank account).
  2. Copy the **live** key pair (`rzp_live_*`).
  3. Backend env: `RAZORPAY_KEY_ID=rzp_live_*`, `RAZORPAY_KEY_SECRET=<secret>`.
  4. Website env: `VITE_RAZORPAY_KEY_ID=rzp_live_*` (public key only — never the secret).
  5. The backend refuses production startup with non-`rzp_live_` keys.
- **Verify:** Complete a real ₹1 test payment end-to-end, confirm the order in
  `/orders` and in the Razorpay dashboard. Then refund it.

### 1.4 Previously exposed secrets — REQUIRES OWNER ACTION — ROTATE CREDENTIAL
The following were found in committed `.env` files at audit time. They are now
gitignored and gated, but **rotation is still required** (values may exist in
git history or caches):
- Cloudflare R2 access/secret key pair → regenerate in Cloudflare dashboard,
  update backend `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`.
- Hugging Face API token → regenerate at huggingface.co/settings/tokens,
  update backend `HF_API_TOKEN` (only needed for AI editing, not MVP checkout).
- Backend `SECRET_KEY` → generate `python -c "import secrets; print(secrets.token_hex(32))"`
  (64+ hex chars; production startup enforces length).
- Backend `ADMIN_PASSWORD` → set a strong unique password (startup rejects the default).
- Razorpay test secret → harmless after live switch, but rotate anyway.

### 1.5 AI segmentation worker (optional for MVP) — REQUIRES OWNER ACTION IF USED
- Backend requires `AI_SEGMENTATION_URL` (https) + `AI_SEGMENTATION_TOKEN` in
  production. Photo-product checkout does **not** need it; if AI background
  removal is not deployed yet, either deploy the worker per
  `backend/ai_worker/README.md` or keep it out of the MVP scope.

---

## 2. Infrastructure

### 2.1 Production database — REQUIRES OWNER ACTION
- Provision managed PostgreSQL, set backend `DATABASE_URL` (startup rejects the
  `localhost` default). Run `alembic upgrade head` on first deploy. Enable
  automated backups + point-in-time recovery.

### 2.2 Hosting environment variables — REQUIRES OWNER ACTION
Set on the production host (all `https`, no localhost):
- `ENV=production`
- `DATABASE_URL`, `SECRET_KEY`, `FRONTEND_URL=https://<site>`,
  `PUBLIC_API_URL=https://<api>`, `ALLOWED_ORIGINS=https://<site>`,
  `ALLOWED_HOSTS=<api-host>`, `DEV_BYPASS_SECRET=` (empty),
  plus sections 1.1–1.4 values. Backend startup fails fast listing any missing key.

### 2.3 Media delivery — NO dashboard change needed (already secure by design)
- Uploads are stored **private** in R2 and served through the backend's signed
  `/media/{namespace}/{user_id}/{filename}?sig=...` gateway (`backend/app/routers/media.py`).
  Do **not** make the bucket public — the audit's "enable public access" advice
  was superseded by this safer design.
- Owner action: only ensure `PUBLIC_API_URL` is the public https API origin so
  generated media URLs resolve. No Cloudflare public-access toggle required.

### 2.4 Domain / DNS / TLS — REQUIRES OWNER ACTION
- Point the site domain (e.g. `snapprint.in`) and API domain (e.g. `api.snapprint.in`)
  at the hosts. TLS is terminated by the hosting/CDN layer (Firebase Hosting /
  Railway both provide it) — do not configure HTTPS inside the Vite dev server.

---

## 3. Business Information — REQUIRES OWNER CONTENT

`website/src/config/business.ts` centralises every legal/business value. **All 11
fields are currently empty** and render as neutral "pending confirmation" notices:
- `legalEntityName`, `registeredAddress`, `supportEmail`, `privacyEmail`,
  `supportPhone`, `supportHours`, `jurisdiction`, `policyLastUpdated`,
  `cancellationWindow`, `claimWindow`, `refundTimeline`.
- Fill with REAL verified data (get Razorpay's required details right — live
  activation reviews these pages). Never invent values.
- Previously displayed contact details on `/contact` were unverified and have
  been removed in favour of this config.

---

## 4. External Dashboard Configuration Checklist

- [ ] Firebase: Phone provider enabled; authorized domains include production origin
- [ ] Firebase: service-account key issued for `snapprint-5076c`
- [ ] Razorpay: live mode activated; `rzp_live_*` keys issued
- [ ] Razorpay: real ₹1 payment → order → refund drill completed
- [ ] Cloudflare R2: rotated keys; bucket remains **private**
- [ ] Hosting: all production env vars set; `ENV=production`; bypass empty
- [ ] Hosting: custom domains + TLS verified; `https://` origins only in CORS
- [ ] Business info filled in `website/src/config/business.ts`
- [ ] Order-confirmation email/SMS copy decided (backend FCM hook exists; SMTP
      provider is a Phase-2 addition — currently no email is sent)

---

## 5. Pre-Launch Verification (after the above)

1. `POST /auth/verify` with a real OTP → 200.
2. Browse `/products` (backend catalogue), upload a photo, add to cart.
3. `/cart/calculate` returns the total shown at checkout.
4. Razorpay live payment → `/payments/razorpay/verify` ok → `POST /orders` 201.
5. `/success?order=<id>` shows the real order; same order appears in `/orders`.
6. Opening another user's `/orders/<id>` returns 404 (no cross-account leak).
7. Policy pages show real business data; zero "pending confirmation" notices.
8. Backend `/health` → 200; prod startup logs show no missing-env errors.
