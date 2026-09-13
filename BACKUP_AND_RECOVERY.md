# SnapPrint — Backup & Recovery

**Date:** 2026-09-13
**Applies to:** production launch. Code/config items the agent could do are done
(migrations are reversible, data handling is documented); cloud-side switches
below need infrastructure access.

---

## 1. PostgreSQL (primary data store)

### Recommended setup — REQUIRES OWNER ACTION
1. Use a managed database with automated backups (e.g. Railway Postgres
   backups, AWS RDS automated snapshots, or equivalent).
2. Enable **daily automated backups** with **7-day minimum retention**
   (30 days recommended once order volume grows).
3. Enable **point-in-time recovery (PITR)** / WAL archiving where the provider
   supports it.
4. Before every production deploy that includes a migration:
   - Take a manual snapshot.
   - Run `alembic upgrade head` against production; on failure run
     `alembic downgrade -1` and restore from the snapshot if data was touched.
5. Quarterly: restore a backup into a scratch database and run the backend
   test suite's read paths (`GET /orders/me`, product list) against it.

### What is already safe in code
- All schema changes ship as Alembic migrations with `downgrade()` paths
  (`backend/alembic/versions/`), including the latest
  `i1a2b3c4d5e6_contact_messages.py`.
- Order/payment writes are transactional with row-level locking; payment
  intents are idempotent (`consumed` state), so a retry after a crash cannot
  double-create orders or double-charge.
- Account deletion anonymises rather than hard-deletes paid order history,
  preserving financial records.

---

## 2. Cloudflare R2 (customer photos, delivery proofs)

### Recommended setup — REQUIRES OWNER ACTION
1. Keep the bucket **private** (the app serves images through the signed
   `/media` gateway — no public access needed).
2. Enable **R2 object versioning / extended retention** if available on the plan,
   or set up a scheduled `rclone sync` of the bucket to a second region/account
   weekly.
3. Retain customer uploads for **30 days after order delivery**, then delete
   (this matches the published Privacy Policy — automation of the 30-day purge
   is a Phase-2 job; until then run the existing `delete_prefixes` utility on a
   schedule).

### Recovery
- Media loss does not lose order records (orders store the key reference and
  price snapshot). Re-upload requires customer cooperation — treat R2 restores
  as best-effort and disclose accordingly.

---

## 3. Firebase (Auth identities)

- Firebase Authentication user records live in Google's infrastructure (covered
  by Google Cloud backups). No owner backup job required.
- Keep a record of the Firebase project id (`snapprint-5076c`) and at least two
  project owners so access cannot be lost with one account — REQUIRES OWNER ACTION.
- The backend is the source of truth for roles/purchase history; a Firebase-side
  incident does not lose order data.

---

## 4. Secrets & configuration

- Store **all** production env values (see `backend/.env.example`,
  `website/.env.example`) in the hosting provider's secret manager —
  REQUIRES OWNER ACTION. Never keep the only copy in a local `.env`.
- After any credential rotation, restart/redeploy the API and verify
  `/health` plus `POST /auth/verify` before announcing completion.

---

## 5. Recovery contacts & runbook order

1. API down → check host status → redeploy last known-good build →
   `GET /health` must return 200 with DB reachable.
2. DB unreachable → fail over / restore latest snapshot → `alembic upgrade head`
   → verify order reads.
3. Payments failing → check Razorpay dashboard status + key validity
   (test keys in prod config cause startup refusal — check deploy logs).
4. Media 404s → check R2 credentials + `PUBLIC_API_URL`; keys rotate without
   code changes.
