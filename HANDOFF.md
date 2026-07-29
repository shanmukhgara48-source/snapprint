# SnapPrint — Project Handoff Report
_Generated 2026-07-27, for continuation by another coding assistant (Codex). Verify anything time-sensitive (ports, IPs, running processes) against live state before trusting it._

## 1. What this is
SnapPrint is a photo-printing e-commerce product: a Flutter mobile app (customer + delivery-partner roles in one binary), a FastAPI backend, and a React admin panel. Monorepo, single git history.

## 2. Repo layout
- `snap_print/` — Flutter app (customer + delivery partner)
- `backend/` — FastAPI async backend (SQLAlchemy + asyncpg + PostgreSQL + Alembic)
- `admin-web/` — React (Vite + TanStack Query) admin panel — **this is the one in active use**
- `admin/` — legacy Flutter-web admin panel, superseded by `admin-web/`, never removed (open decision, see §8)
- `scripts/` (untracked, new) — includes `seed_printo_catalog.dart`

## 3. Current git state
- Branch: `feature/admin-web-react`, up to date with `origin/feature/admin-web-react`
- **Modified, not committed:** `firestore.rules`, iOS/macOS xcconfig + Xcode project files, and five customer-facing Dart files: `product_model.dart`, `product_entity.dart`, `customization_screen.dart` (+523/-lines, the biggest diff), `payment_screen.dart`, `product_detail_screen.dart`, `product_card.dart`
- **Untracked, new:** `lib/features/ai_photo_edit/` (see §4), `ios/Podfile`, `macos/Podfile*`, `scripts/`
- Nothing has been committed yet this session — all of the above is sitting in the working tree
- Recent commits (newest first): environment/Firebase config update, backend pytest suite + CodeQL, license/security/contributing/CI docs, root README, realtime-sync test hardening, auth/FCM refactor, production-audit bug fixes, WebSocket realtime + bulk admin ops, banners/categories CRUD

## 4. Architecture / key tech
- **Flutter**: Riverpod + GoRouter, role-based routing (customer vs. delivery partner)
- **Backend**: FastAPI, async SQLAlchemy + asyncpg, PostgreSQL, Alembic migrations
- **Auth**: Firebase Phone Auth (OTP). Token verification is done server-side via the Identity Toolkit REST endpoint (not the Admin SDK) — see gotcha in §6
- **Product catalog**: in transition. `ProductEntity`/`ProductModel` were just extended (uncommitted) with `startingPrice`, `minConfig`, `sizeDetails`, `sourceUrl`, `priceSource`, `confidenceScore` — this looks like in-progress work to ingest/verify product data from an external catalog (the Printo seed script), with a confidence score per scraped field. Not yet fully wired through every screen — worth checking what actually consumes these new fields before extending further.
- **Uploads**: Cloudflare R2, presigned PUT URLs via boto3
- **Payments**: Razorpay Flutter SDK, test mode
- **NEW feature, uncommitted**: `lib/features/ai_photo_edit/` — Gemini-powered photo editing (`gemini_image_service.dart` calls `gemini-2.5-flash-image` via REST with an `x-goog-api-key` header and `String.fromEnvironment('GEMINI_API_KEY')`), plus `ai_photo_edit_screen.dart` and `doodle_canvas.dart`. Wired into the customization flow as an "Edit with Gemini AI ✦" entry point with preset chips (e.g. "Black & White").
- **Realtime**: WebSocket event bus, `/ws/app` (Firebase token) and `/ws/admin` (admin JWT), first-message auth handshake

## 5. How to run it locally
**Backend:**
```bash
cd backend && venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
```
Use `backend/venv/` (Mac arm64) — **not** `backend/.venv/` (a stale Windows virtualenv).

**Flutter — required `--dart-define`s:**
- `SNAPPRINT_API_URL` — backend base URL. Defined in `snap_print/lib/core/network/api_endpoints.dart:6-9`, defaults to `http://10.0.2.2:8000` (Android emulator loopback) if unset.
- `RAZORPAY_KEY_ID` — Razorpay test key
- `GEMINI_API_KEY` — for the AI photo-edit feature (see current blocker in §7)

**Emulator:** `SNAPPRINT_API_URL=http://10.0.2.2:8000` (the emulator's host-loopback alias) works out of the box if the backend is running on the Mac.

**Physical device over USB:** `10.0.2.2` does **not** work — instead:
```bash
adb reverse tcp:8000 tcp:8000
flutter run -d <device_id> --dart-define=SNAPPRINT_API_URL=http://127.0.0.1:8000 --dart-define=GEMINI_API_KEY=<key>
```
This was verified working this session on a Samsung SM-M426B (Android 13, serial `RZCR404Z9MK`).

**Toolchain note:** Flutter SDK lives at `~/flutter/bin/flutter`, not on `PATH`.

## 6. Config/credential gotchas (don't re-diagnose these from scratch)
- **`FIREBASE_API_KEY` in `backend/.env` must be the "Browser key"**, not the Android-restricted key from `google-services.json`. Using the Android key causes every authenticated backend call to silently 401 ("session expired" in the app), because Google's Identity Toolkit REST verify endpoint rejects Android-restricted keys server-side.
- **Firebase project ID mismatch**: `FIREBASE_CREDENTIALS_PATH` service account was (as of last audit) for project `snap-print-7146d`, while the actual Firebase project is `snapprint-5076c`. This silently breaks anything using the Admin SDK directly (role claims, account deletion, FCM push) even though REST-based token verification still works. Needs a fresh service-account key from the Firebase Console for `snapprint-5076c` if not already fixed.
- **SHA-1 fingerprints**: both debug and release keystore SHA-1s must be registered against the Firebase Android app, or phone-auth OTP requests get blocked with "Requests from this Android client application are blocked."
- **R2 bucket/account has been rotated before** — if photo previews 404, check `R2_PUBLIC_URL` in `backend/.env` actually matches the current bucket/account.
- Actual current secret values live in `backend/.env` — check there rather than trusting any specific value carried over from an old session.

## 7. Testing status as of this session (2026-07-27)
**Emulator (Android 16 / API 36, `emulator-5554`) — standard 12-step manual flow (launch → home → category → product → Customize → upload → Gemini AI edit → B&W chip → result → Accept → Add to Cart → Cart → Checkout):**
- Steps 1–6 (launch through opening the Gemini AI edit screen): **PASS**
- Step 7 (tap "Black & White" chip): **PARTIAL** — UI/request flow is correct, but the specific Gemini key supplied for testing is malformed (56 chars vs. the standard 39) and Google's API rejects it directly (`400 API_KEY_INVALID`, confirmed via curl independent of the app). Not an app bug.
- Steps 8–9 (B&W result / Accept): not tested, blocked by the same key issue
- Steps 10–12 (Add to Cart / Cart / Checkout): **not completed** — the emulator's host Mac ran out of memory mid-session, escalating from adb commands taking minutes to a SystemUI ANR to a whole-device `system_server` ANR. This is a host-resource issue specific to that machine/session, not an app defect.

**Physical device (Samsung SM-M426B, Android 13, serial `RZCR404Z9MK`) — this session:**
- USB detection → initially unauthorized → authorized after user tapped "Allow" on-device
- Latest debug APK built and installed (`flutter build apk --debug` + `adb install -r -g`); had to `adb uninstall com.snapprint.app` first because a previously-installed build had a different signing key (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`)
- App launched via `flutter run` with `adb reverse` forwarding + `SNAPPRINT_API_URL=http://127.0.0.1:8000`; an existing Firebase session auto-logged back in (phone `+91**********`, no OTP needed)
- Home screen rendered, but **Categories and Recent Orders sections appeared empty** in a screenshot taken right after launch (`GET /categories`, `/products?featured=true`, `/products?trending=true` were all fired per the Flutter logs, but responses weren't confirmed) — **first thing to check**: whether this is a real empty-response/data issue on this connection path or just a load-timing/empty-state artifact. Not yet root-caused.
- The 12-step manual walkthrough was paused at this point (before Categories/products could be confirmed) to produce this handoff report instead.

**No automated test suite exists for what was described as "25 customer persona tests":** `test/integration/customer_flow_test.dart` does not exist anywhere in the repo, and none of the specific persona names mentioned (e.g. "Priya Sharma", "Rahul Mehta") appear anywhere. This needs either an explicit persona spec from the user, or to be designed and written from scratch — don't assume it already exists.

**Existing test assets that do exist:**
- `snap_print/integration_test/qa_admin_api.dart`, `qa_realtime_sync_test.dart`
- `backend/tests/test_health.py` (pytest suite added recently, per git log — currently just health-check coverage, not full API coverage)

## 8. Known open issues (carried over from prior audits — re-verify before trusting, don't re-run full audits from scratch)
- Production readiness scored **83/100** as of the last full audit (2026-07-02)
- Google Maps for delivery tracking never renders — backend never sends lat/lng (open, unfixed)
- iOS Firebase not configured (needs Firebase Console access, not just code)
- Delivery OTP has no server-side validation
- Legacy `admin/` Flutter-web directory — open decision on whether to delete now that `admin-web/` (React) is the one in use
- 9 `admin-web` pages are still mock-data only (Reports, Photo Uploads, Print Queue, Offers, Support, Reviews, Security, System Logs, Backup) — acceptable for now since only the mobile app ships to Google Play, but flagged as unfinished
- Category/product naming: live app shows lowercase "frames" category / "Photo Frame" product, not "Frames & Wall Decor" / "Classic Photo Frames" as some test specs expect — traced to `scripts/seed_printo_catalog.dart` not being runnable due to a Dart SDK toolchain bug, so the intended seed data was never loaded
- Gradle (8.13.0) and Android Gradle Plugin (8.9.1) are both flagged by Flutter as soon-to-be-unsupported; upgrade paths are in `android/gradle/wrapper/gradle-wrapper.properties` and `android/settings.gradle`
- `minSdk=24`, `targetSdk=36` (Android 15), current build `versionName=1.0.0+1`

## 9. Explicit constraints from the user for any continuation work
- Do **not** change Razorpay, Firebase Auth, or GoRouter
- `flutter analyze` must pass after any fix
- Prefer fixing root causes over working around environment issues; if something looks like host/emulator resource exhaustion rather than an app bug, say so rather than "fixing" it with app-code changes

## 10. Suggested immediate next steps
1. Get a valid Gemini API key (current one fails Google's own validation, `400 API_KEY_INVALID`) to unblock AI photo-edit testing end-to-end
2. Investigate the empty Categories/Recent Orders on the physical-device Home screen (§7) — check actual HTTP response bodies for `/categories` and `/products` over the `adb reverse` connection
3. Get the real 25-persona test spec from the user (or agree to write one from scratch) before attempting `test/integration/customer_flow_test.dart` — it doesn't exist yet
4. Decide what to do with the currently uncommitted working-tree changes (14 modified files + the new `ai_photo_edit` feature) — nothing from this session has been committed
5. Run `flutter analyze` as a baseline before making further changes, per the user's standing constraint
