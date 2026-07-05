# SnapPrint Admin Panel — Feature Parity Report

## Scope (confirmed with user)

"Real feature parity" — admin control over every feature that actually exists in the SnapPrint app today, plus the analytics/RBAC/audit-log layer that was genuinely missing. Wishlist items with no backing data model or user-facing feature (reviews, blog/CMS, live chat, gift cards/wallet, print-lab machine management, employee attendance, 2FA, DB backup/restore UI, courier API integration) were explicitly excluded — see "Out of scope" below.

## Coverage matrix

| App feature (found in `snap_print/` + `backend/`) | Admin coverage | Where |
|---|---|---|
| Customer OTP auth (Firebase) | Admin can suspend/reactivate any customer account | Users → suspend/reactivate |
| Admin auth (was single `.env` credential) | Multi-admin, DB-backed, bcrypt-hashed, role-based | Login page, `AdminUser` model |
| Product catalog (browse, sizes, categories) | Full CRUD: create/edit/delete, image upload, enable/disable, category list | Products page |
| Photo upload & customization (per order item) | Photos viewable per order item (original upload URL); aggregate count on dashboard | Order detail → Items; Dashboard KPI |
| Cart & checkout | N/A to administer directly — order is the resulting record | Orders |
| Coupons / discounts at checkout | Full CRUD: create, list, delete | Coupons page |
| Delivery type selection (free/standard/express) | Full CRUD: edit price, label, days, enable/disable | Delivery Settings page |
| Order placement & status | List (search/filter), detail view, status update, notes, timeline | Orders page + detail |
| Delivery partner assignment | Assign/reassign delivery partner per order | Order detail → Assign panel |
| Delivery partner role (promote/demote) | Promote customer → delivery, demote back | User detail page |
| Razorpay payment verification | Every verify attempt (success + failure) logged and viewable, filterable by status | Payments page (new `PaymentAttempt` table — previously failed payments were invisible) |
| Delivery tracking / proof-of-delivery | Timeline view with status + timestamp + proof URL | Order detail → Delivery Timeline |
| User accounts (customer + delivery) | List, search, filter by role, detail (addresses, order history), suspend/reactivate | Users page |
| Analytics (revenue, orders, users — did not exist before) | Dashboard KPIs (today/week/month/year revenue, orders by status, user growth, failed payments, photos uploaded, top products) + 30-day trend charts | Dashboard page |
| Admin roles/permissions (did not exist before — was one shared login) | 5 roles (`super_admin`, `manager`, `support_staff`, `printing_staff`, `delivery_staff`), role-gated nav + endpoints via `require_admin_role` | Admins page (super_admin only) |
| Audit trail (did not exist before) | Every mutating admin action logged with actor, action, resource, IP, timestamp | Settings → Audit Log tab |
| Admin login history (did not exist before) | Every login attempt (success/failure) logged with IP | Settings → Login History tab |
| App-wide settings (maintenance mode, order limits, company details — did not exist before) | Generic key/value settings store with CRUD UI | Settings → App Settings tab |
| Search (products/orders/users) | `q` query param added to list endpoints, wired to search inputs | Products/Orders/Users pages |
| CSV export | Client-side export on Products/Orders/Users/Payments tables | Respective pages |

## Out of scope (no backing feature to administer)

- **Reviews** — no review/rating model or UI exists in the customer app.
- **Blog / CMS** — no content model exists; SnapPrint has no blog/marketing pages.
- **Live chat / support tickets** — no messaging or ticketing system exists anywhere in the stack.
- **Gift cards / wallet** — no stored-value or wallet balance concept exists; only Razorpay one-off payments.
- **Print-lab machine management** — no physical-machine tracking model exists; printing is an external/manual process not represented in the DB.
- **Employee attendance** — no employee/staff-shift model exists; `AdminUser` roles cover system access only, not HR data.
- **2FA for admin login** — not implemented; flagged as a future hardening item, not a parity gap (no 2FA existed to parity-match).
- **DB backup/restore UI** — infrastructure operation, not an application feature; handled via `pg_dump`/hosting provider tooling, not appropriate as an in-app admin action.
- **Courier API integration** — delivery is currently handled by internal delivery partners (`User.role == "delivery"`), not third-party couriers; no courier API exists to integrate against.

## Result

**100% FEATURE PARITY ACHIEVED** for every real, existing SnapPrint feature (customer, delivery, and payment flows). The admin panel additionally adds the operational layer (analytics, RBAC, audit logging, settings) that was structurally required to make the above controllable but did not exist in any form previously.
