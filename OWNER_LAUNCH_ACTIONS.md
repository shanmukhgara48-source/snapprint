# SnapPrint — Owner Launch Actions

**Date:** 2026-09-13
Everything the code cannot do for itself. No secret values are included here —
create/rotate them in the dashboards named below.

---

## 1. Credentials

### 1.1 Firebase production credentials — REQUIRES OWNER ACTION
- **Where:** Firebase Console → project `snapprint-5076c`.
- **What:**
  1. Authentication → Sign-in method → enable **Phone**.
  2. Authentication → Settings → Authorized domains → add production + preview domains.
  3. Project Settings → Service accounts → generate new private key → set backend
     `FIREBASE_CREDENTIALS_JSON` (one line) or mount file + `FIREBASE_CREDENTIALS_PATH`.
  4. Project Settings → General → web app config → set website `VITE_FIREBASE_*`
     (API key, auth domain, project id `snapprint-5076c`, storage bucket, sender id, app id).
  5. Keep at least two project owners.
- **Verify:** real OTP → `POST /auth/verify` 200; `/auth` SMS arrives; session survives refresh.

### 1.2 Razorpay live credentials — REQUIRES OWNER ACTION
- **Where:** Razorpay Dashboard → live activation (KYC + bank account).
- **What:** copy `rzp_live_*` pair → backend `RAZORPAY_KEY_ID`/`RAZORPAY_KEY_SECRET`,
  website `VITE_RAZORPAY_KEY_ID` (public key only).
- **Verify:** controlled real payment (small amount) → order in `/orders` and dashboard → refund it.
  Do NOT run unplanned live charges as "testing".

### 1.3 Cloudflare R2 — REQUIRES OWNER ACTION
- **Where:** Cloudflare dashboard → R2.
- **What:** rotate the access/secret key pair quoted in earlier audit docs; update backend
  `R2_ACCOUNT_ID`/`R2_ACCESS_KEY_ID`/`R2_SECRET_ACCESS_KEY`. Keep the bucket **private**.
- **Verify:** upload a photo on a product page; thumbnail loads via `/media/...?sig=`.

### 1.4 Backend secrets — REQUIRES OWNER ACTION
- **Where:** hosting provider secret manager.
- **What:** fresh 64+ hex `SECRET_KEY`
  (`python -c "import secrets; print(secrets.token_hex(32))"`), strong unique
  `ADMIN_PASSWORD`, rotate Hugging Face token (AI features only).
- **Verify:** production deploy logs show none of the fail-fast errors in `backend/main.py`.

### 1.5 Production database credentials — REQUIRES OWNER ACTION
- **Where:** managed Postgres provider.
- **What:** provision instance, set backend `DATABASE_URL`, run `alembic upgrade head`,
  enable daily backups + PITR (see `BACKUP_AND_RECOVERY.md`).
- **Verify:** `/health` 200 with DB reachable; test read paths on a scratch restore quarterly.

## 2. Business Information — REQUIRES OWNER CONTENT

- **Where:** `website/src/config/business.ts` (11 fields).
- **What:** real legal entity name, registered address, support/privacy emails, support
  phone + hours, jurisdiction, policy last-reviewed date, cancellation window, claim
  window, refund timeline. Get Razorpay's required details right — live activation reviews them.
- **Verify:** zero "pending confirmation" notices on Contact/Terms/Privacy/Shipping/Refund.

## 3. Infrastructure

| Item | Where | Verify |
|---|---|---|
| Domains + DNS + TLS | Registrar + host (Firebase Hosting/Railway) | `https://` site + API, valid certs |
| Hosting env | Provider env settings | `ENV=production`, https-only origins/hosts, empty `DEV_BYPASS_SECRET`, no startup errors |
| R2 delivery | Nothing to toggle (signed gateway) | `PUBLIC_API_URL=https://<api>` set |
| Monitoring | Uptime monitor (e.g. UptimeRobot/Better Stack) on `GET /health`; error tracker (Sentry) DSN when added | Alert drill: stop API, confirm page |
| Backups | Per `BACKUP_AND_RECOVERY.md` | Manual snapshot before first deploy |

## 4. External Dashboards

- [ ] Firebase: Phone on, domains authorised, web config issued, service key issued
- [ ] Razorpay: live activated, keys issued, webhook review (not required — verify-then-place covers confirmation), ₹1 drill + refund done
- [ ] Cloudflare: keys rotated, bucket private
- [ ] Hosting: env vars set, migrations run, domains + TLS live
- [ ] Support inbox: someone owns `GET /admin/contact-messages` triage
- [ ] Legal: policies reviewed by counsel where required (marked REQUIRES OWNER REVIEW in code comments where applicable)
