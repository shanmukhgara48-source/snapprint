# admin-web — status

A standalone React + Vite + TypeScript + Tailwind v4 SPA implementing the
"SnapPrint Admin" design, living alongside the existing Flutter admin app
(`admin/`, untouched) and the FastAPI backend (`backend/`).

## Run it

```bash
cd admin-web
cp .env.example .env
npm install
npm run dev
```

Backend must have `http://localhost:5173` in `ALLOWED_ORIGINS` (CORS). Note:
`backend/main.py` reads `ALLOWED_ORIGINS` via `os.getenv(...)` directly — it is
**not** loaded from `backend/.env` automatically (only `pydantic Settings`
reads that file). Either `export ALLOWED_ORIGINS=...` before starting uvicorn,
or add a `load_dotenv()` call in `main.py` if you want `.env` to be sufficient.

Login uses the real `admin_users` table (`POST /auth/admin/login`) — use one
of the existing rows (e.g. `admin` / the password in `backend/.env`'s
`ADMIN_PASSWORD`, if that's what was used to seed it).

## Real vs. mock, page by page

| Page | Backend wiring |
|---|---|
| Dashboard | **Real** — `/admin/analytics/dashboard` + `/admin/analytics/charts` |
| Analytics | **Real** — `/admin/analytics/charts` |
| Products | **Real**, full CRUD — `/admin/products` |
| Categories | **Real**, full CRUD — dedicated `categories` table, `/admin/categories` |
| Orders (list + detail) | **Real** — `/admin/orders`, status update, notes, delivery-partner assign |
| Customers (list + detail) | **Real** — `/admin/users`, suspend/reactivate, promote/demote to delivery |
| Coupons | **Real**, full CRUD including edit — `/admin/coupons` (PUT) |
| Delivery Settings | **Real**, full CRUD — `/admin/delivery-settings` |
| Payments | **Real**, read-only — `/admin/payments` |
| Employees (Admins) | **Real** — `/admin/admins` (super_admin only) |
| Settings → App Settings | **Real** — `/admin/settings` |
| Settings → Audit Log | **Real** — `/admin/audit-logs` (super_admin/manager only) |
| Settings → Login History | **Real** — `/admin/login-history` (super_admin/manager only) |
| Reports | **Mock** — numbers exist elsewhere (Dashboard/Analytics), but there's no report-generation/export endpoint |
| Photo Uploads | **Mock gallery** — real photo URLs exist per order item (Order detail → Items), but there's no endpoint that aggregates all uploads |
| Print Queue | **Mock** — no physical-printer/job model in the backend |
| Offers | **Mock** — distinct from Coupons; no promotional-banner model exists |
| Support | **Mock** — no ticketing/messaging system exists anywhere in the stack |
| Reviews | **Mock** — no review/rating model exists |
| Notifications | **Real** — `/admin/notifications/broadcast` (FCM topic `all_users`) + `/admin/notifications/history` |
| Security | **Mock toggles** — no 2FA/IP-allowlist/session-timeout enforcement exists |
| System Logs | **Mock** — this is infra/server logs, not the (real) admin audit trail |
| Backup | **Mock** — DB backup/restore is an infra operation (`pg_dump`/hosting tooling), not an app feature |

Every mock page/section has a yellow "Mock data" banner and mutations there
reset on reload — they exist so the full nav from the design can be clicked
through, not because they're production features.

## Next priority

Fold Reports into the Dashboard's existing analytics endpoints as CSV
export (the underlying numbers are already real, just not exportable).
