# SnapPrint Production Readiness Audit

**Date:** 2026-07-29 – 2026-07-30
**Method:** Live emulator testing (device `RZCR404Z9MK`), backend log cross-verification (no trusted client-only claims), direct code inspection, and a targeted code-quality/security grep pass. Runs independently of, and cross-checks, a concurrent Codex CLI audit pass.

---

## 1. Blocking bugs (fix before real users touch this)

### 1.1 Firebase project mismatch — breaks checkout for every real-OTP user
`backend/.env` → `FIREBASE_CREDENTIALS_PATH` points to a service-account key for project `snap-print-7146d`, but the app mints tokens for `snapprint-5076c`. `verify_id_token` checks token audience against the credentialed project, so **every** `POST /auth/verify` from a real phone-OTP session returns 401 — confirmed by decoding a token seconds after mint and curling it directly.

- **Impact:** Any customer signed in via real OTP can browse but cannot Add to Cart, checkout, place an order, edit profile, or use the AI editor. The Home screen still looks fully signed-in because the display name comes from a separate direct Firestore read — this bug is invisible unless you inspect network calls.
- **Why invisible in normal testing:** the sync call is wrapped in `try { ... } catch (e) { dev.log(...) }` in `auth_provider.dart` (`_syncBackend`, lines ~76-97) — `dev.log` never reaches the visible console.
- **Fix (cannot be done from this environment):** generate a new service-account key for `snapprint-5076c` in Firebase Console → Project Settings → Service Accounts, update `FIREBASE_CREDENTIALS_PATH`.
- **Also worth fixing once unblocked:** surface a real "session sync failed" state instead of silently swallowing the error; de-duplicate the 3-4 concurrent `/auth/verify` calls fired on every cold start/hot restart.
- Full history: memory `project_snapprint_auth_r2_fix.md`.

### 1.2 R2 public preview URLs return 403
Presigned `PUT` uploads succeed; `GET` on the resulting `R2_PUBLIC_URL` (`pub-ef4df885fff646269360a39b8f5d5bc6.r2.dev/...`) 403s. Upload pipeline itself is correct (confirmed: pick → upload → `_uploadedUrls` populate → Add to Cart enables) — only the public-read preview is broken, so every customized-photo thumbnail renders as a grey placeholder.
- **Fix:** Cloudflare dashboard → enable r2.dev public access on bucket `snap-photo`, confirm `R2_PUBLIC_URL` still matches. Not a code fix.

---

## 2. Confirmed working (positive findings, verified not assumed)

### 2.1 Razorpay checkout — genuinely functional end-to-end
Full live walkthrough (Cart → Checkout → hosted payment → OTP/3DS → Success → "Order Placed!") **plus independent backend log verification**, not just a UI screenshot:
- `POST /payments/razorpay/verify` → real server-side HMAC signature check on `razorpay_payment_id`/`razorpay_order_id`/`razorpay_signature`, returns `{"ok": true}` only after genuine verification.
- `POST /orders` → `201 Created`, correct `status: "confirmed"` and `total_price`.
- Independent follow-up `GET /orders/{id}` confirms persistence.
- **Caveat:** this run used the `dev-login` bypass token, not a real Firebase OTP session — payment plumbing is proven sound, but it's currently gated behind the broken auth path in §1.1 for real users.
- QA note for future passes: Razorpay's sandbox rejects the standard test Visa (`4111 1111 1111 1111`) as "international" — merchant-account BIN restriction, not an app bug. Use domestic test Mastercard `5267 3181 8797 5449` + the bank simulator's explicit Success/Failure buttons instead.

### 2.2 AI Photo Editor — graceful degradation confirmed
Falls back correctly when the Gemini call fails (`ai_photo_editor.py:114`, `except Exception: gemini = {}`), merging with baseline analysis instead of erroring the request.

### 2.3 Several earlier suspicions reconfirmed as non-issues
- **Portrait-orientation lock** (`main.dart:19-21`) is intentional (`SystemChrome.setPreferredOrientations([...portraitUp, portraitDown])`) — rotation "doing nothing" is correct behavior, not a bug.
- Customize button flow, photo-picker UI reflection, and the `dev-login` dart-define requirement were all re-checked and are working as designed.
- Backgrounding/foregrounding the app mid-session: no state loss, no crash.
- Rapid-tap on product cards (5x in <1s): no navigation-stack corruption, no duplicate screens — a single back-press returns cleanly to the list.

---

## 3. Moderate-severity findings

### 3.1 Silent error swallowing on the Home screen
`customer_home_screen.dart` (lines 237, 553, 594, 649) and `category_grid.dart` (line 33) all use `error: (e, s) => const SizedBox.shrink()` in Riverpod `AsyncValue.when()`. Confirmed live with wifi/data disabled via adb: Categories, Recent Orders, Products, Search, and Offers sections all render as blank empty space on any backend/network failure — no error message, no offline banner, no retry button.
- **Mitigation already present:** `RefreshIndicator` at line 147 lets users pull-to-refresh and recover, but only if they know to try — first impression on a real network failure is a confusing empty page.
- **Contrast:** `product_detail_screen.dart` and `product_list_screen.dart` both do this correctly — explicit "Failed to load" message + Retry button. Home screen should be brought in line with these.

### 3.2 Misleading "+" affordance on product cards
`product_card.dart:23-24` wraps the entire card (image, title, price, and the circular "+" icon at bottom-right) in one `GestureDetector` with a single `onTap` that always navigates to Product Details. The "+" icon visually promises one-tap add-to-cart but has no independent handler — tapping it just opens the detail screen like tapping anywhere else on the card. Low severity, but a real UX mismatch between affordance and behavior; either wire it to a real quick-add action or remove the icon.

---

## 4. Lower-priority / informational

- **Leaked internal metadata in product descriptions**: some catalog descriptions include sourcing/verification notes not meant for customers, e.g. visible on "Classic Photo Prints": *"Source: https://printo.in/... Verification: confidence High; Category Price Only – Configurator Not Accessible."* This reads as internal QA scratch text left in customer-facing copy — data-quality cleanup, not a code bug.
- **Checkout screen RenderFlex overflow by ~1px** — minor UI bug, cosmetic only.
- **Category capitalization inconsistency** for mugs-related categories, plus benign `ListTile` ink-splash debug warnings — cosmetic, no functional impact.
- **Admin-web stores JWT in `localStorage`** (`admin-web/src/lib/auth.tsx`, `lib/api.ts`, `lib/realtime.ts`) rather than an httpOnly cookie — standard pattern for many admin panels but technically XSS-exposed; worth hardening later, not urgent for a hackathon/early-stage deployment.
- **13 bare `except Exception` blocks in backend** — reviewed all of them individually; every one is deliberate non-fatal/best-effort handling (FCM push failures, optional Firebase custom-claims sync, non-critical delivery estimate lookups) and most are commented as such. No silent-failure bugs found here; one instance (`admin.py:622`, FCM notify-on-confirm) could use the same explanatory comment its siblings have, but behavior is correct.
- **No secrets found hardcoded in tracked source** (backend `app/`, Flutter `lib/`, admin-web `src/`) beyond the expected client-embedded Firebase Android API key in `firebase_options.dart`, which is meant to be public per Firebase's own design (restricted server-side by SHA-1/package-name, not by secrecy).

---

## 5. Unresolved / blocked investigations

- **Admin → app real-time sync**: could not be verified. The only plausible admin credential found (`ADMIN_USERNAME`/`ADMIN_PASSWORD` in `backend/.env`) was tested with explicit user authorization and confirmed **invalid** (401) — it's stale and unreferenced anywhere in `backend/app/` (real admin auth is a separate DB-backed `AdminUser` + bcrypt + JWT flow in `routers/auth.py`). Direct database access to look up a real admin account remains out of scope for this session. **Action needed:** user must supply valid admin credentials, or reset/create an `AdminUser` row, for this to be tested.
- **QA test products still live**: `'QA Neg'` and `'QA Mug 1783514919603'` need to be deactivated manually:
  ```sql
  UPDATE products SET is_active = false, is_featured = false, is_trending = false
  WHERE name IN ('QA Neg', 'QA Mug 1783514919603');
  ```

---

## 6. Priority summary

| # | Finding | Severity | Owner action needed |
|---|---|---|---|
| 1.1 | Firebase project mismatch blocks all real-OTP checkout | 🔴 Blocker | New service-account key for `snapprint-5076c` |
| 1.2 | R2 public preview 403 | 🔴 Blocker | Enable r2.dev public access in Cloudflare dashboard |
| 3.1 | Home screen silently swallows errors | 🟡 Moderate | Code fix — reuse product-screen error pattern |
| 3.2 | "+" icon on product cards is non-functional | 🟡 Quick win | Wire to real quick-add or remove |
| §5 | Admin login unverifiable | 🟡 Blocked on owner | Valid admin credentials needed |
| §5 | QA test products still live in catalog | 🟡 Quick win | Run the SQL above |
| §4 | Internal QA text leaked into product descriptions | 🟢 Nice-to-have | Content cleanup |
| §4 | Checkout 1px overflow, category capitalization | 🟢 Nice-to-have | Cosmetic polish |
| §4 | Admin JWT in localStorage | 🟢 Nice-to-have | Consider httpOnly cookie later |

**Bottom line:** payments, AI editing, and the core browse/customize/order flow are all genuinely solid and server-verified. The two 🔴 items are both environment/config fixes (not code rewrites) and are the only things standing between this and being usable by real customers.
