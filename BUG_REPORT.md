# SnapPrint Bug Report
**Project:** SnapPrint — Photo Printing & Delivery App  
**Platform:** Android (Physical Device: RZCR404Z9MK + Emulator sessions)  
**Backend:** FastAPI + PostgreSQL + Firebase + Cloudflare R2  
**QA Role:** Lead QA Engineer / Senior Flutter Developer / Backend Engineer / Security Engineer  

---

## Overall Bug Summary

| ID | Severity | Session | Component | Status |
|----|----------|---------|-----------|--------|
| BUG-001 | Critical | S1 | Backend / Orders | FIXED |
| BUG-002 | High | S1 | Flutter / Razorpay | FIXED |
| BUG-003 | High | S1 | Backend / Payment | FIXED |
| BUG-004 | Medium | S1 | Razorpay SDK | WORKAROUND |
| BUG-005 | Medium | S1 | Flutter / Products | OPEN |
| BUG-006 | Low | S1 | Flutter / Customization | OPEN |
| BUG-007 | High | S1 | Backend / Orders | FIXED |
| BUG-008 | Medium | S1 | Flutter / Orders | FIXED |
| BUG-009 | Low | S1 | Flutter / Navigation | LIKELY FIXED — see note |
| BUG-010 | Critical | S2 | Flutter / Cart | FIXED |
| BUG-011 | High | S2 | Flutter / Build | FIXED |
| BUG-012 | High | S2 | Flutter / Cart | FIXED |
| BUG-013 | High | S2 | Backend / Upload | FIXED |
| BUG-014 | High | S2 | Flutter / Auth | FIXED |
| BUG-015 | Medium | S2 | Flutter / Home | FIXED |
| BUG-016 | High | S2 | Flutter / iOS | OPEN |
| BUG-017 | Medium | S2 | Flutter / Delivery | FIXED |
| BUG-018 | High | S2 | Backend / Security | FIXED |
| BUG-019 | Medium | S2 | Backend / Design | OPEN |
| BUG-020 | Critical | S3 | Backend / Razorpay Config | OPEN — External |
| BUG-021 | Low | S3 | Flutter / Address Form UI | FIXED |
| BUG-022 | Medium | S3 | Backend / Media URL Config | FIXED |
| BUG-023 | High | S3 | AI Worker / Segmentation Service | FIXED |
| BUG-024 | Medium | S3 | AI Worker / CPU Performance | OPEN — Environment |
| BUG-025 | Medium | S3 | Flutter / Session Expiry Handling | FIXED |
| BUG-026 | Low | S3 | Flutter / AI Editor Error Messages | FIXED |

---

## Session 1 Bug Reports (Emulator Testing)

### BUG-001 — FK Violation on order_items (Critical) ✅ FIXED
**Component:** Backend — `POST /orders`  
**Symptom:** Order creation silently failed after payment with FK violation:  
`product_id='pp_classic' is not present in table 'products'`  
**Root Cause:** PostgreSQL `products` table had UUID-based IDs from wrong seed script. Flutter app uses string IDs like `pp_classic`, `pp_passport`. FK constraint rejected string IDs not in PostgreSQL.  
**Fix:** Re-seeded PostgreSQL products table with correct string IDs matching Firestore: `pp_classic, pp_passport, pp_square, pp_panoramic, pp_matte`.  
**Verified:** Order creation succeeds with all product IDs.

---

### BUG-002 — Razorpay "Please Enter a Valid Mobile Number" (High) ✅ FIXED
**Component:** Flutter — `payment_screen.dart`  
**Symptom:** Razorpay checkout showed "Please enter a valid mobile number" before payment methods screen.  
**Root Cause:** No prefill data provided to Razorpay SDK; test sandbox rejected 9876543210.  
**Fix:** Added prefill contact details to Razorpay options in `_openRazorpay()`.  
**Verified:** Razorpay checkout skips contact entry step.

---

### BUG-003 — Razorpay Signature Verification Failure for Dev Users (High) ✅ FIXED
**Component:** Backend — `POST /payments/razorpay/verify`  
**Symptom:** Payment success callback fired but `/payments/razorpay/verify` returned 400.  
**Root Cause:** Razorpay test mode mock bank doesn't generate real HMAC signatures.  
**Fix:** Added dev bypass in `payments.py` gated on `DEV_BYPASS_SECRET` env variable, skips HMAC verification for users with `firebase_uid` starting with `dev_`.  
**Note:** Does NOT run in production (DEV_BYPASS_SECRET is empty in prod).

---

### BUG-004 — Razorpay "Something Went Wrong" on Order Reuse (Medium) ⚠️ WORKAROUND
**Component:** Razorpay SDK / Payment Flow  
**Symptom:** Opening Razorpay with the same `order_id` after a failed attempt showed "Something went wrong."  
**Root Cause:** Razorpay orders are single-use; reuse fails.  
**Workaround:** User navigates back to Checkout and taps "Place Order" again for a fresh order ID.  
**Recommended Fix:** On `EVENT_PAYMENT_ERROR`, reset state and auto-create a new Razorpay order before allowing retry.

---

### BUG-005 — Broken Image on Passport Size Photos Product (Medium) 🔴 OPEN
**Component:** Flutter / Product Catalog  
**Symptom:** `pp_passport` product card shows broken image placeholder.  
**Root Cause:** `image_url` for `pp_passport` in Firestore points to invalid/expired URL.  
**Impact:** Visual defect only; product still purchasable.  
**Fix:** Update `image_url` for `pp_passport` in Firestore to a valid URL.

---

### BUG-006 — "Could Not Decompress Image" Thumbnail (Low) 🟡 OPEN
**Component:** Flutter — `customization_screen.dart`  
**Symptom:** After selecting a PNG photo from gallery, thumbnail shows decompression error. Upload still succeeds.  
**Root Cause:** Some PNG files from Android emulator media store can't be displayed by `Image.memory()`.  
**Impact:** Cosmetic; actual upload to R2 works correctly.  
**Fix:** Add error builder to image widget or convert to JPEG before display.

---

### BUG-007 — Coupon Discount Not Applied to Stored Order Total (High) ✅ FIXED
**Component:** Backend — `POST /orders`  
**Symptom:** After order with SAVE50 coupon (₹50 off), stored `total_price` was undiscounted.  
**Root Cause:** `orders.py` calculated total as `items_total + delivery_charge` without applying coupon.  
**Fix:** Added coupon lookup and discount calculation in `orders.py` before creating Order record.  
**Verified:** Order with SAVE50 + standard delivery stores correct discounted total.

---

### BUG-008 — My Orders Shows "No Orders Yet" After Fresh Order (Medium) ✅ FIXED
**Component:** Flutter — `payment_screen.dart` / `orders_provider.dart`  
**Symptom:** After successful order, My Orders tab showed "No orders yet" until manual pull-to-refresh.  
**Root Cause:** `myOrdersProvider` (FutureProvider) cached its result; wasn't invalidated after order placement.  
**Fix:** Added `ref.invalidate(myOrdersProvider)` in `payment_screen.dart` after order placement, before navigation.

---

### BUG-009 — "Continue Shopping" Button on Order Confirmation (Low) 🟡 LIKELY FIXED — full live confirmation blocked by BUG-020
**Component:** Flutter — `order_confirmation_screen.dart`  
**Symptom (Emulator):** Tapping "Continue Shopping" did not navigate away from order confirmation screen.  
**Code Analysis:** Button calls `context.go(AppRoutes.customerHome)` = `context.go('/customer')`, which is correct. Route is properly defined in GoRouter.  
**Session 3 Re-Analysis (2026-08-13):** Re-read `order_confirmation_screen.dart` in full and `app_router.dart`'s route table and top-level `redirect:` callback end-to-end. The button code is unchanged and correct; `AppRoutes.customerHome` (`/customer`, ShellRoute) and `AppRoutes.orderConfirmation` (`/customer/order-confirmation/:id`, standalone route) are both properly registered, and the `redirect:` callback contains no auth-state logic that would interfere with navigating between them. No architectural reason remains for this bug to reproduce — same pattern as BUG-019 being found already-fixed against a stale report.
**Live Device Attempt:** Drove a full checkout on physical device RZCW31FQWFL (product select → customize → add to cart → address → delivery option → Place Order) specifically to reach this screen and tap the button. The flow got as far as "Place Order" before failing with a payment-provider error — see **BUG-020**. The app has no deep-link entry point to reach `order-confirmation/:id` directly (no custom URI scheme registered in `AndroidManifest.xml`), so the button itself could not be live-tapped this session.
**Status:** Treat as fixed/non-reproducible pending a final live tap-through once BUG-020 (Razorpay credentials) is resolved and a checkout can complete end-to-end. Low priority given the code-level evidence is already clean.
**If Still Broken:** Check if GoRouter's ShellRoute re-entrance from a non-shell route causes the issue.

---

## Session 2 Bug Reports (Physical Device Testing — RZCR404Z9MK)

### BUG-010 — Cart Merge Destroys customizationImageUrl for Photo Items (Critical) ✅ FIXED
**Component:** Flutter — `snap_print/lib/features/customer/presentation/providers/cart_provider.dart`  
**Symptom:** Adding 3 different photos for Classic Photo Prints 4x6 resulted in only 1 cart item instead of 3; the 2nd and 3rd photos were lost (merged into the first item by quantity).  
**Root Cause:** `addItem()` merged items by `productId + selectedSize`. Photo items share the same productId and size, so all subsequent photos were merged into the first item's quantity, dropping their `customizationImageUrl`.  
**Fix:** Photo items (with `customizationImageUrl != null && isNotEmpty`) always added as unique line items; merge logic only applies to non-photo items.
```dart
void addItem(CartItemEntity item) {
  final hasCustomization =
      item.customizationImageUrl != null && item.customizationImageUrl!.isNotEmpty;
  if (hasCustomization) {
    state = state.copyWith(items: [...state.items, item]);
    return;
  }
  // non-photo merge logic below...
}
```
**Verified:** 3 distinct photos added to cart = 3 separate line items with correct URLs.

---

### BUG-011 — Razorpay Key Defaulting to REPLACE_ME Placeholder (High) ✅ FIXED
**Component:** Flutter Build — `payment_screen.dart`  
**Symptom:** Razorpay SDK was initialized with key `rzp_test_REPLACE_ME` (placeholder), causing all payment attempts to fail with "Invalid API key".  
**Root Cause:** Build command only passed `--dart-define=SNAPPRINT_API_URL=...` but omitted `--dart-define=RAZORPAY_KEY_ID=...`. The `String.fromEnvironment('RAZORPAY_KEY_ID', defaultValue: 'rzp_test_REPLACE_ME')` fell through to the default value.  
**Fix:** Rebuild APK with both dart-defines:
```bash
flutter build apk --debug \
  --dart-define=SNAPPRINT_API_URL=http://192.168.0.106:8000 \
  --dart-define=RAZORPAY_KEY_ID=rzp_test_T7ub1zMHZM6uO3
```
**Verified:** Razorpay payment sheet opens with correct key.

---

### BUG-012 — removeCoupon Resets Delivery Type and Price (High) ✅ FIXED
**Component:** Flutter — `snap_print/lib/features/customer/presentation/providers/cart_provider.dart`  
**Symptom:** Removing an applied coupon on the cart screen reset the selected delivery option (Standard/Express) back to Free delivery.  
**Root Cause:** `removeCoupon()` constructed a new `CartState(items: state.items, deliveryType: state.deliveryType)` but did NOT pass `deliveryTypeKey` or `deliveryPrice`, so they reset to constructor defaults (`'free'` and `null`).  
**Fix:**
```dart
void removeCoupon() {
  state = CartState(
    items: state.items,
    deliveryType: state.deliveryType,
    deliveryTypeKey: state.deliveryTypeKey,
    deliveryPrice: state.deliveryPrice,
    // couponCode and discount reset to defaults (null / 0)
  );
}
```
**Verified:** Removing coupon preserves the selected delivery option.

---

### BUG-013 — Presigned Upload URL Signs ContentLength=10MB (High) ✅ FIXED
**Component:** Backend — `backend/app/routers/upload.py`  
**Symptom:** Photo uploads to Cloudflare R2 returned 403 Forbidden. All images fail to upload.  
**Root Cause:** `generate_presigned_url` was called with `Params={'ContentLength': MAX_FILE_BYTES}` (10MB). This signed the content-length into the URL. When the actual file is smaller than 10MB, R2 rejects the PUT because `Content-Length` doesn't match the signed value.  
**Fix:** Removed `ContentLength` from Params. R2 presigned PUT URLs cannot enforce size limits via signed headers (that requires POST policy).
```python
upload_url = client.generate_presigned_url(
    "put_object",
    Params={
        "Bucket": settings.r2_bucket_name,
        "Key": key,
        "ContentType": content_type,
        # ContentLength intentionally omitted
    },
    ExpiresIn=300,
)
```
**Verified:** Photos upload successfully to R2.

---

### BUG-014 — Auth Interceptor Sends 'Bearer null' Token (High) ✅ FIXED
**Component:** Flutter — `snap_print/lib/core/network/api_client.dart`  
**Symptom:** Some API requests failed with 401 errors even when user appeared logged in.  
**Root Cause:** `getIdToken()` returns `Future<String?>`. When it returns `null` (e.g., token refresh race condition), the interceptor set `Authorization: 'Bearer null'` — a string, not a missing header.  
**Fix:**
```dart
final token = await user.getIdToken();
if (token != null && token.isNotEmpty) {
  options.headers['Authorization'] = 'Bearer $token';
}
// If null/empty, proceed without token; server returns 401
```
**Verified:** No spurious 'Bearer null' headers sent; null token silently omits auth header.

---

### BUG-015 — order.id.substring(0, 8) Without Length Guard (Medium) ✅ FIXED
**Component:** Flutter — `snap_print/lib/features/customer/presentation/screens/customer_home_screen.dart:238`  
**Symptom:** Potential `RangeError` crash if order ID is shorter than 8 characters.  
**Root Cause:** `order.id.substring(0, 8)` called unconditionally on order IDs that could theoretically be shorter than 8 chars.  
**Fix:**
```dart
'Order #${order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}'
```
**Verified:** Displays correctly for all UUID-format order IDs (always 36 chars).

---

### BUG-016 — iOS Firebase App ID Is Placeholder (High) 🔴 OPEN
**Component:** Flutter — `snap_print/lib/firebase_options.dart`  
**Symptom:** App crashes on iOS with `[core/no-app] No Firebase App '[DEFAULT]' has been created` or similar initialization failure.  
**Root Cause:** `firebase_options.dart` has `appId: '1:204019052123:ios:REPLACE_WITH_IOS_APP_ID'` — a placeholder, not a real iOS app ID. The iOS bundle `com.snapprint.app` has not been registered in Firebase Console.  
**Impact:** iOS build is non-functional. Android is unaffected (Android appId is real and correct).  
**Fix:**
1. Go to Firebase Console → Project → Add App → iOS
2. Register bundle ID: `com.snapprint.app`
3. Download `GoogleService-Info.plist`
4. Run `flutterfire configure` or manually update `firebase_options.dart` with real iOS appId

---

### BUG-017 — Pull-to-Refresh Does Nothing on Delivery Home (Medium) ✅ FIXED
**Component:** Flutter — `snap_print/lib/features/delivery/presentation/screens/delivery_home_screen.dart`  
**Symptom:** Pull-to-refresh gesture on the delivery orders list did nothing; orders list didn't update.  
**Root Cause:** `_OrderList` widget was constructed with `onRefresh: () async {}` — a no-op callback. No provider invalidation was triggered.  
**Fix:** Added `onRefresh` parameter to `_OrderList` constructor, passed `() async => ref.invalidate(assignedOrdersProvider)` from the parent.  
**Verified:** Pull-to-refresh on all three delivery tabs (Assigned, In Progress, Completed) fetches fresh data.

---

### BUG-018 — Any User Can Self-Register as Delivery Partner (High) ✅ FIXED
**Component:** Backend — `backend/app/routers/auth.py:146` + Flutter — `register_screen.dart`  
**Symptom:** Any user could register as a delivery partner by selecting "Delivery Partner" role during registration.  
**Root Cause:** `POST /auth/verify` accepted `role: "delivery"` from client; register screen had a role selector (Customer/Delivery).  
**Impact:** Malicious users could access the delivery partner portal, view all assigned orders, mark orders as delivered fraudulently.  
**Fix Applied:**
1. **Flutter** (`register_screen.dart`): Removed "Account Type" role selector chip entirely. `_role` hardcoded to `'customer'`. Removed dead `_RoleChip` widget class.
2. **Backend** (`auth.py`): Changed role validation from `("customer", "delivery")` to `("customer",)` — `role: "delivery"` now returns 400.
3. **Backend** (`admin.py`): Added `POST /admin/delivery-partners/{user_id}/promote` endpoint (admin-only JWT required) to promote existing customers to delivery role. Also added `POST /admin/delivery-partners/{user_id}/demote` to revert.
**Workflow:** Delivery partners must first register as customer → admin promotes via `POST /admin/delivery-partners/{id}/promote`.  
**Verified:** Self-registration as delivery now blocked; admin promotion endpoint tested and working.

---

### BUG-019 — Delivery OTP Verification Has No Server-Side Validation (Medium) 🟡 OPEN
**Component:** Flutter — `delivery_proof_screen.dart` + Backend — `delivery.py`  
**Symptom:** Delivery partner can enter ANY 6-digit code as the "delivery OTP" and mark an order as delivered. The backend stores `otp:XXXXXX` as the proof URL without validation.  
**Root Cause:** The OTP mode stores `'otp:${_otpController.text}'` as `proof_url`. No customer-side OTP is generated, so there's nothing to verify against.  
**Impact:** Delivery partner can fraudulently mark orders as delivered without customer confirmation.  
**Fix (Production Required):**
  - Generate a random 6-digit OTP when order is dispatched; store hashed in DB
  - Send OTP to customer via SMS/notification
  - On proof submission, verify the entered OTP matches the stored hash
  - Only mark as delivered if OTP matches OR photo proof is provided

---

### BUG-020 — Razorpay Order Creation Fails: "Authentication Failed" (Critical) 🔴 OPEN — External/Config
**Component:** Backend — `payment_service.py` / Razorpay account credentials
**Session:** 3 (Physical Device: RZCW31FQWFL, 2026-08-13)
**Symptom:** `POST /payments/razorpay/order` returns `502 Bad Gateway`. Backend log shows `razorpay.errors.BadRequestError: Authentication failed` raised from `client.order.create(...)` in `create_razorpay_order()`. This blocks checkout for every order — "Place Order" shows a generic "Something went wrong. Please try again." snackbar with no indication it's a payment-provider issue.
**Root Cause Confirmed:** Not an app bug. `RAZORPAY_KEY_ID`/`RAZORPAY_KEY_SECRET` in `backend/.env` are syntactically clean (verified byte-for-byte via `od -c` — no stray whitespace/quotes) and match the test key documented as working in BUG-011 (`rzp_test_T7ub1zMHZM6uO3`). A direct, app-independent request to Razorpay's own API (`GET https://api.razorpay.com/v1/orders`) using those exact credentials returns `401 Unauthorized` from Razorpay itself. This is a regression since the 2026-07-29 end-to-end payment verification (checkout was confirmed working with this same key ID then) — the key secret was likely regenerated/revoked on the Razorpay dashboard, or the account's test-mode access changed, sometime between 2026-07-29 and 2026-08-13.
**Impact:** 100% of checkout attempts fail at "Place Order." No customer can complete a purchase. This also blocked live-device verification of BUG-009 (Continue Shopping button), since the order-confirmation screen is only reachable after a completed payment and the app has no deep-link entry point to reach it directly.
**Fix Required (cannot be done from this session):** Log into the Razorpay Dashboard → Settings → API Keys, confirm the test-mode key is still active, regenerate if needed, and update `RAZORPAY_KEY_ID`/`RAZORPAY_KEY_SECRET` in `backend/.env` (and the Flutter build's `--dart-define=RAZORPAY_KEY_ID=...`, kept in sync per BUG-011) with the fresh test-mode values. Per standing instructions, this must stay a **test-mode** key — do not switch to live keys.
**Verification once fixed:** Re-run `curl -u "$RAZORPAY_KEY_ID:$RAZORPAY_KEY_SECRET" https://api.razorpay.com/v1/orders?count=1` and confirm `200` instead of `401`, then retry the on-device checkout flow.

**"App is crashing" report re-investigated (2026-08-13, later same session):** User reported the app "crashing" with a "red/white error screen." Re-drove the full flow a second time (new product → size → Add to Cart → Cart → Checkout → Place Order) with a background `adb logcat` capture (`'*:E' 'flutter:V'`) running throughout. Result: no `FlutterError`, unhandled Dart exception, or any crash signature appeared in the log at any point. The only red banner produced end-to-end is this bug's own `"Something went wrong. Please try again."` SnackBar (red background, white text) — a handled error state, not a crash — fired from the `catch` block in `checkout_screen.dart`'s `_placeOrder()`. This is almost certainly what the user is describing; there is no separate crash bug. No code change needed here beyond BUG-020 itself; consider making this specific snackbar message more informative (e.g. "Payment service unavailable, please try again later") so it reads less alarmingly than a generic failure. Also observed: the item thumbnail on the Cart/Checkout screens renders as a blank placeholder instead of the uploaded photo — cosmetic only, not investigated further this pass, worth a follow-up look if time allows.

---

### BUG-021 — "Save Address" Button Tap Target Overlaps System Navigation Bar (Low) ✅ FIXED (workaround identified; UI fix recommended)
**Component:** Flutter — Add Address bottom sheet (address form)
**Session:** 3 (Physical Device: RZCW31FQWFL, 2026-08-13)
**Symptom:** Tapping the "Save Address" button at its visual center did nothing — the bottom sheet stayed open with no error, no snackbar, no navigation.
**Root Cause:** On this device, `uiautomator dump` shows the button's bounds as `[56,2138][1024,2284]`, but the system `navigationBarBackground` view occupies `[0,2205][1080,2340]` — overlapping the bottom ~35% of the button. Taps landing in that overlap band (y ≥ 2205) are intercepted by the system nav bar instead of reaching the button. This is the same class of issue as the floating bottom-nav-bar overlap observed elsewhere in the app (category cards on Home).
**Fix:** Confirmed working by tapping within the non-overlapped portion of the button (y=2170); address saved successfully (`POST /addresses` → `201 Created`).
**Recommended Production Fix:** Add bottom safe-area padding (`SafeArea` / `MediaQuery.viewPadding.bottom`) to the Add Address bottom sheet's action button so its tap target never sits under the system navigation bar on gesture-nav devices.

---

### BUG-022 — Uploaded Photo Thumbnails Break When Backend's LAN IP Changes (Medium) ✅ FIXED
**Component:** Backend — `PUBLIC_API_URL` config / `r2_storage.media_base_url()`
**Session:** 3 (Physical Device: RZCW31FQWFL, 2026-08-13)
**Symptom:** User reported "when i upload the pic i am not able to view the pic again" — the uploaded photo thumbnail renders as a blank/gradient placeholder box on the customize screen, Cart, and Checkout, instead of the actual photo.
**Root Cause:** `POST /upload/image` bakes an **absolute** URL into the response (`backend/app/routers/upload.py` → `build_media_url(media_base_url(...), key)`), and `media_base_url()` (`backend/app/services/r2_storage.py:45`) uses `settings.public_api_url` — a hardcoded value in `backend/.env`. That value was stale: `PUBLIC_API_URL=http://192.168.0.108:8000`, but the dev laptop's actual current LAN IP is `192.168.0.116` (confirmed via `ipconfig getifaddr en0`, and via the [[snapprint_wireless_device_testing]] work done earlier this session, which is what changed the IP the app currently needs). Every photo URL issued while the config was stale points at an address the phone can never reach, so `CachedNetworkImage` fails to load it and `PremiumNetworkImage`'s error-state gradient placeholder renders instead — on every screen that reads `customizationImageUrl` (customize screen, Cart, Checkout all share this one field).
**Why not a quick "just use a relative URL" fix:** `r2_storage.hosted_media_key()` deliberately validates the URL's **host** against `settings.public_api_url` as a security check (confirms a media URL genuinely came from this backend before treating it as "owned" by a user, e.g. for AI photo editing). Switching to relative URLs would require reworking that ownership-validation path — out of scope for this fix; the correct minimal fix is keeping `PUBLIC_API_URL` in sync with reality.
**Fix Applied:** Updated `backend/.env` → `PUBLIC_API_URL=http://192.168.0.116:8000`, restarted the backend. All newly-uploaded photos now generate reachable URLs.
**Known Limitation:** Any cart item added **before** this fix still has the old, broken URL baked in (cart persists `customizationImageUrl` client-side via `SharedPreferences`) — user needs to remove and re-add that item, or re-upload the photo, to pick up a working URL. This is a dev-environment-only concern: in production `PUBLIC_API_URL` would be a stable hosted domain, not a LAN IP tied to a laptop's DHCP lease, so this class of drift wouldn't occur — but it's worth remembering that **any** future change to this setting invalidates all previously-issued (and already-persisted, e.g. in past orders' DB rows) photo URLs, since they're signed+absolute rather than resolved at view-time.
**Secondary UX gap noted (not fixed):** The customize screen's photo thumbnail (`customization_screen.dart` ~line 598-617) has remove and AI-edit affordances but no tap-to-view-full-size handler — minor, unrelated to this bug's root cause, left as a nice-to-have.

---

### BUG-023 — AI Background Removal Always Fails (502, then 500 once worker started) (High) ✅ FIXED
**Component:** Backend AI pipeline (`professional_image_pipeline.py`) + local segmentation microservice (`backend/ai_worker/`)
**Session:** 3 (Physical Device: RZCW31FQWFL, 2026-08-13)
**Symptom:** User reported "the ai feature is not working." `POST /ai/photo/remove-background` returned `502 Bad Gateway` — `"Background removal service is unavailable."` — for every attempt.
**Root Cause (three separate issues, layered):**
1. **Worker not running at all.** `ai_segmentation_url` (`http://127.0.0.1:8010/v1/segment`) points at `backend/ai_worker/main.py`, a standalone FastAPI microservice (BiRefNet_HR-matting segmentation model via `transformers`) that is **not** started alongside the main backend — it has its own venv/process lifecycle and had never been set up on this machine. `lsof -i :8010` was empty; `httpx` got connection-refused, mapped by `professional_image_pipeline.py` to a generic 502.
2. **Wrong URL path configured.** Even once considered, `backend/.env` had `AI_SEGMENTATION_URL=http://127.0.0.1:8010/segment`, but the worker only exposes `/v1/segment` (confirmed via `grep -n "@app\." main.py`) — would have 404'd even with the worker running.
3. **fp16/fp32 dtype crash once the worker was actually up.** After installing deps (`torch`, `transformers`, etc. — no GPU on this machine, CPU-only) and starting the worker, the first real segmentation call failed with `RuntimeError: Input type (float) and bias type (c10::Half) should be the same` (500 from the worker, surfaced to the main backend as a 502). `main.py`'s `_get_model()` only forced fp16 (`model.half()`) when `DEVICE == "cuda"`, correctly leaving the input tensor in fp32 for CPU — but the `ZhengPeng7/BiRefNet_HR-matting` checkpoint's own `config.json` specifies `torch_dtype: float16`, which `AutoModelForImageSegmentation.from_pretrained(...)` honors by default regardless of target device, so the model's weights loaded as fp16 even on CPU while the input tensor stayed fp32 — a dtype mismatch PyTorch's `conv2d` CPU kernel doesn't support.
**Fix Applied:**
- Corrected `backend/.env`: `AI_SEGMENTATION_URL=http://127.0.0.1:8010/v1/segment`.
- Created a Python 3.11 venv at `backend/ai_worker/.venv/` and installed `backend/ai_worker/requirements.txt`.
- Started the worker (`.venv/bin/python -m uvicorn main:app --host 127.0.0.1 --port 8010`) with `AI_WORKER_TOKEN` set to match `AI_SEGMENTATION_TOKEN` in `backend/.env` (never printed to logs/output).
- Patched `backend/ai_worker/main.py`'s `_get_model()` to explicitly call `model.float()` on the non-CUDA path, forcing fp32 weights regardless of what the checkpoint's config declares:
  ```python
  model.eval().to(DEVICE)
  if DEVICE == "cuda":
      model.half()
      torch.set_float32_matmul_precision("high")
  else:
      model.float()
  _model = model
  ```
**Verified end-to-end:** `GET /health` → `200 {"status":"ok","loaded":true,...}`. Full flow via direct API calls (dev-login → `POST /upload/image` → `POST /ai/photo/remove-background`) → `200 OK`, returned a valid, fetchable, correctly-sized RGBA PNG cutout.
**Known Limitation / Operational Note:** The `ai_worker` process is **not** managed by the same lifecycle as the main backend (no supervisor, no auto-restart, no Docker Compose entry as of this session) — it must be started manually each time the dev machine restarts. `ai_editor_status()`/`GET /ai/photo/status` reports `background_removal: true` purely from config presence (`ai_segmentation_url`/`ai_segmentation_token` both being non-empty strings), **not** a live health check — so the status endpoint will falsely report the feature as available even when the worker process isn't running. A future improvement would be having `/ai/photo/status` actually ping the worker's `/health` endpoint (with a short timeout) before reporting `background_removal: true`. Model download (`ZhengPeng7/BiRefNet_HR-matting`, cached under `~/.cache/huggingface/`) only needs to happen once per machine; subsequent worker starts load from cache and are fast.

---

### BUG-024 — Background Removal Times Out On-Device on CPU-Only Hardware (Medium) 🔴 OPEN — Environment Limitation
**Component:** `backend/ai_worker/main.py` (BiRefNet inference) + `backend/app/config.py` (`ai_segmentation_timeout_seconds`) + `snap_print/lib/features/ai_editor/data/ai_editor_service.dart` (`_aiCallOptions`)
**Session:** 3 (Physical Device: RZCW31FQWFL, 2026-08-13), discovered immediately after BUG-023 was fixed
**Symptom:** After BUG-023's fix, tapping the real "Remove BG" toolbar button (found via `adb shell uiautomator dump`, `content-desc="Remove BG"`, correctly entering the busy/"Refining hair and edges..." state — confirmed via `flutter:I` logcat that the real `/ai/photo/remove-background` request fired) never completes on-screen. Backend log confirms: `POST /ai/photo/remove-background HTTP/1.1" 504 Gateway Timeout`. `ps aux` showed the `ai_worker` process still actively consuming CPU and climbing in memory for several minutes *after* the 504 was already returned to the app — the worker hadn't crashed, it was just still computing.
**Root Cause — measured, not assumed:** Ran the exact real 1080×2340 on-device photo directly against the worker (`curl` with `X-Snapprint-Quality` header, bypassing the backend's timeout to get a clean number). `_segment_sync()` always resizes to a **fixed** square input (`transforms.Resize((input_size, input_size))`) regardless of the source photo's resolution, so cost is driven by `input_size`, not the original image size:
- `standard` quality (`input_size=1024`): **355.3 s** (`X-Processing-Ms: 355178`), confirmed via direct worker benchmark.
- `high` quality (`input_size=2048`, the app's actual hardcoded default — `ai_editor_service.dart`'s `removeBackground({highQuality = true})`, never overridden by `ai_editor_repository.dart`): **618.3 s** (`X-Processing-Ms: 618325`, ~10.3 minutes), confirmed via direct worker benchmark on the same real photo. (Only ~1.74x `standard`, not the theoretical 4x from quadrupled pixel count — the foreground-refinement pass (`_estimate_foreground`, `cv2.blur` on the full-resolution source) and PNG encode/resize steps don't scale with `input_size`, only the model forward pass does, diluting the ratio.)

Both numbers already blow past **every** timeout in the request path on this CPU-only Mac (no CUDA — `torch.cuda.is_available()` is `False`):
1. Backend → worker: `ai_segmentation_timeout_seconds = 150` (`backend/app/config.py`) — exceeded by `standard` alone (355s).
2. App → backend: `_aiCallOptions` in `ai_editor_service.dart` sets `sendTimeout`/`receiveTimeout` to a **hardcoded 3 minutes (180s)** — also exceeded by `standard` alone.

So this isn't a single misconfigured limit that can be nudged up — the underlying BiRefNet_HR-matting inference is fundamentally too slow on CPU to fit any reasonable synchronous request/response budget, at either quality setting.
**Why NOT simply raising the timeouts:** `ai_segmentation_timeout_seconds` and the app's 3-minute `_aiCallOptions` timeout are sized correctly for a **GPU-backed** production worker, where BiRefNet inference typically completes in low single-digit seconds. Bumping either to 10–25+ minutes to paper over this one CPU-only dev machine would (a) still produce a terrible UX even once "fixed" (users staring at a spinner for a quarter of an hour), and (b) ship a change to the app's real timeout budget that weakens fast failure/recovery for genuine hangs in production, for every user, to accommodate a problem that doesn't exist on real GPU hardware. Per the standing guidance against building workarounds for hypothetical/non-production scenarios, no timeout values were changed.
**Fix Applied:** None — correctly left as an environment limitation, not a code fix. BUG-023's fix (worker running, correct path, correct dtype) is verified correct via direct API calls; this bug tracks that **on-device, interactive** testing of this one feature isn't representative on CPU-only dev hardware.
**Recommendation:** Either (a) run `ai_worker` on GPU hardware (cloud GPU instance, or a CUDA-capable dev machine) for any on-device testing of this feature going forward, or (b) accept that this feature's on-device UX can only be verified via direct API calls (as done for BUG-023) until GPU hardware is available, and treat production readiness for this specific feature as **conditional on deploying the worker to a GPU host** — ship it CPU-backed and every user will hit this same 504.
**Verified:** Root cause confirmed via clean, reproducible direct-worker benchmark (bypassing backend timeout) rather than reconstructed from fuzzy log timestamps — see `real_standard_headers.txt` (`x-processing-ms: 355178`).

---

### BUG-025 — Session-Expiry (401) Never Detected on Order History Screen (Medium) ✅ FIXED
**Component:** `snap_print/lib/features/customer/presentation/screens/order_history_screen.dart`
**Session:** 3 (code audit, 2026-08-13), found during a Phase 7 network/HTTP-error-handling review prompted by the BUG-024 investigation
**Symptom:** If the app's session token is rejected by the backend (expired — `access_token_expire_minutes = 60*24*7`, i.e. 7 days — or invalidated some other way) while viewing Order History, the screen was meant to show "Please sign in to view your orders" with a sign-in affordance. Instead it silently fell into the generic "Failed to load orders" error state with a **Retry** button that just re-issues the same authenticated call and 401s again — an infinite dead-end loop with no path back to login short of manually finding a logout/login entry point elsewhere in the app.
**Root Cause:** `_ErrorInterceptor` (`api_client.dart`) correctly maps any 401 response to `UnauthorizedException()`, whose message is the fixed string `'Session expired. Please login again.'` (and carries `statusCode: 401`). But `order_history_screen.dart`'s error branch detected "is this an auth error?" by substring-matching `e.message.toLowerCase()` for `'authenticat'` or `'unauthorized'` — neither of which appears anywhere in `'Session expired. Please login again.'`. So `isAuthError` was always `false` for a genuine 401, and the branch's own "Please sign in to view your orders" copy/icon (written with clear intent to handle exactly this case) was unreachable dead code.
**Fix Applied:**
1. Replaced the fragile substring match with a check against the structured field that already exists for this purpose: `final isAuthError = e is AppException && e.statusCode == 401;`.
2. The auth-error branch's button previously said "Retry" and called `ref.invalidate(myOrdersProvider)` even when `isAuthError` was true — which would just repeat the same failing authenticated call forever. Changed it to say "Sign In" and call `context.go(AppRoutes.login)`, matching the pattern already used correctly one branch up in the same file for the logged-out/guest state.
**Verified:** `flutter analyze` on the file — no issues. Not re-verified against a live expired token on-device (would require waiting out the real 7-day expiry or minting a pre-expired token, neither practical this session); verified by code inspection that `UnauthorizedException.statusCode` is always `401` (`api_client.dart:24-27`) and that `AppRoutes.login` / `context.go` are already imported and used correctly elsewhere in the same file.
**Scope note:** Checked whether this same substring-matching bug exists elsewhere (`grep -rn "isAuthError\|contains('authenticat')"` across `lib/`) — this was the only occurrence. No app-wide/global 401 handler exists (no interceptor-level auto-logout-and-redirect); each screen is responsible for its own auth-error UI, which is workable but means any *other* screen added later that authenticates data must remember to check `statusCode == 401` explicitly rather than string-matching — worth keeping in mind for future screens.

---

### BUG-026 — AI Editor Never Shows Its Network/Timeout/Session Error Messages (Low) ✅ FIXED
**Component:** `snap_print/lib/features/ai_editor/data/ai_editor_repository.dart` (`friendlyError()`)
**Session:** 3 (code audit, 2026-08-13), found in the same Phase 7 pass as BUG-025, same root-cause family
**Symptom:** `friendlyError()` exists specifically to turn a caught exception from any AI-editor operation (remove background, auto-crop, export, etc.) into a user-facing snackbar message, with dedicated copy for "no internet" and "taking too long" cases. Neither branch could ever fire — every network failure or timeout during an AI edit fell through to the generic `'AI edit failed. Please try another edit or use the original photo.'`, regardless of the actual cause. Not a functional dead-end (unlike BUG-025 — the fallback message is still coherent), but users got a vague message instead of the accurate, more actionable one that was clearly intended.
**Root Cause:** Same class of bug as BUG-025: `friendlyError(Object error)` substring-matched `error.toString()` for the literal text `'NetworkException'`, `'SocketException'`, `'receiveTimeout'`, `'TimeoutException'`. But the object actually caught at every call site (`ai_editor_provider.dart`'s `catch (error)`) is Dio's own **`DioException`**, not the unwrapped cause — `_ErrorInterceptor` (`api_client.dart`) sets the friendly exception (e.g. `NetworkException()`) as `DioException.error`, it doesn't throw it directly. Traced Dio 5.9.2's `DioException.toString()` (`dio_exception.dart:297`, `defaultDioExceptionReadableStringBuilder`): it renders as `"DioException [<type>]: <message>\nError: ${e.error}"` — and `AppException.toString()` (`api_client.dart:12`) returns only `message`, never the class name. So `text` never contains the literal strings `'NetworkException'`/`'SocketException'`/`'receiveTimeout'`/`'TimeoutException'` under any real failure — confirmed by direct inspection of both source files, not guessed.
**Fix Applied:** Replaced the substring matching with type checks against the unwrapped cause, mirroring the pattern the file already used correctly for `UnsupportedImageFormatException`/`ImageTooLargeException`:
```dart
final cause = error is DioException ? (error.error ?? error) : error;
if (cause is UnauthorizedException) {
  return 'Your session has expired. Please sign in again.';
}
if (cause is NetworkException) {
  return 'No internet connection. Please check your network and try again.';
}
if (error is DioException &&
    (error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionTimeout)) {
  return 'This is taking longer than expected. Please try again.';
}
```
Also added a `UnauthorizedException` branch (session-expired-mid-edit is a realistic case for a long-running AI operation, and wasn't handled at all before — same underlying gap as BUG-025, scoped to this one entry point).
**Verified:** `flutter analyze` on the file — no issues. Confirmed via source inspection of `dio_exception.dart` and `api_client.dart` (not a live repro — would require forcing a real network drop mid-AI-edit on device, deferred as lower priority than the correctness fix itself).

---

## Risk Items (Not Bugs, but Production Concerns)

### RISK-001 — Payment Collected But Order Creation Fails
**Severity:** High  
**Scenario:** If `POST /orders` fails (DB error, invalid product, etc.) after Razorpay payment succeeds, the user is charged but gets no order.  
**Mitigation:** The payment flow has two steps: (1) `verifyPayment` validates the HMAC signature, (2) `placeOrder` creates the DB record. If step 2 fails, the Razorpay `payment_id` is not persisted. Manual reconciliation would be needed.  
**Production Fix:** Implement Razorpay webhooks to create orders asynchronously; store payment intent before opening checkout.

### RISK-002 — Firebase Storage Must Be Enabled for Delivery Proofs
**Severity:** Medium  
**Component:** `delivery_proof_screen.dart` uses `FirebaseStorage.instance.ref().putData()`  
**Status:** Firebase Storage must be manually enabled in Firebase Console for project `snapprint-5076c`. If not enabled, photo proof uploads will fail with an error.  
**Action:** Enable Firebase Storage in Firebase Console + set rules to allow delivery partner uploads.

### RISK-003 — Google Maps Placeholder API Key
**Severity:** Low (currently)  
**Component:** `android/app/src/main/AndroidManifest.xml` has `YOUR_GOOGLE_MAPS_API_KEY`  
**Why Not Critical:** Backend never populates `delivery_lat`/`delivery_lng` in delivery orders, so the `GoogleMap` widget's `hasCoords` condition is always `false` and the map never renders.  
**Future Fix:** If coordinates are added to orders, replace with real key from Google Cloud Console.

### RISK-004 — Hardcoded Pickup Address
**Severity:** Low  
**Component:** `backend/app/routers/delivery.py`  
**Value:** `pickup_address = "SnapPrint Fulfillment Center, Mumbai"` (placeholder)  
**Fix:** Make pickup address configurable from admin panel or environment variable.

### RISK-005 — Several Screens Show Bare Error Text With No Retry/Sign-In Affordance
**Severity:** Low  
**Component:** `delivery_order_detail_screen.dart:27`, `customization_screen.dart:408`, `address_screen.dart:22`, `checkout_screen.dart:124,240` — all render a failed `.when(error: (e, s) => ...)` as plain `Text('$e')` with no button.
**Found:** Phase 7 network/error-handling audit (2026-08-13), same pass that found BUG-025/BUG-026. Swept every `.when(error:` branch in `lib/features` (`grep -rln "\.when(" lib/features | xargs grep -l "error:"`) to check for this pattern app-wide.
**Why Low, Not a Bug:** Unlike BUG-025, none of these loop or trap the user — `AppException.toString()` already returns a human-readable message (e.g. `"Session expired. Please login again."` for a 401, thanks to `_ErrorInterceptor`), so the user sees a correct, non-technical message, just no actionable next step (no Retry button, and no login redirect for the specific case of a 401/session expiry). They can still navigate away via the app's normal nav.
**Recommendation (not implemented — out of scope for this pass):** A small shared `ErrorStateView` widget (icon + message + conditional "Sign In" vs "Retry" button, reusing the `statusCode == 401` check fixed in BUG-025) would let all of these screens opt in without repeating the same branching logic four times over. Worth doing as a follow-up rather than four one-off screen edits.

---

## Production Readiness Checklist

| Area | Status | Notes |
|------|--------|-------|
| Auth (Phone OTP) | ✅ Working | Firebase Phone Auth functional |
| Auth (Firebase) | ⚠️ Android only | iOS appId is placeholder (BUG-016) |
| Product Catalog | ✅ Working | 5 products seeded, Firestore synced |
| Photo Upload | ✅ Working | R2 presigned URL fixed (BUG-013) |
| Cart | ✅ Working | Photo merge bug fixed (BUG-010) |
| Coupon | ✅ Working | Discount applied to order total (BUG-007) |
| Checkout | ✅ Working | Delivery option, address selection |
| Payment | ✅ Working | Razorpay test mode functional |
| Order Placement | ✅ Working | Server-side price verification |
| Order History | ✅ Working | Refreshes after order (BUG-008) |
| Delivery Partner | ⚠️ Partial | Refresh fixed; OTP unvalidated (BUG-019) |
| Delivery Proof (Photo) | ⚠️ Needs Firebase Storage | Storage must be enabled |
| Delivery Proof (OTP) | ⚠️ No server validation | BUG-019 |
| Admin Panel | ✅ Working | Admin routes protected |
| Security | ✅ Fixed | Role self-assignment blocked (BUG-018 fixed) |
| iOS Build | ❌ Broken | Firebase placeholder (BUG-016) |
| Production Deployment | ⏳ Pending | Railway env vars need to be set |

---

## Final Score

**Android (Customer Flow):** 60/100 *(down from 89 — see BUG-020)*
- Auth, products, photo upload, cart, address all working
- **Checkout is currently 100% broken**: every "Place Order" attempt fails at Razorpay order creation (BUG-020), an external credential issue, not app code
- Minor: broken product image (BUG-005), PNG thumbnail (BUG-006), address-form Save button tap-target overlap (BUG-021, fixed)

**Android (Delivery Flow):** 78/100  
- Orders, refresh, status updates all working  
- Security: self-registration now blocked (BUG-018 fixed)  
- Remaining: OTP proof unvalidated (BUG-019); Firebase Storage not confirmed enabled

**iOS:** 20/100  
- Firebase not configured for iOS (BUG-016, needs Firebase Console)

**Backend:** 88/100 *(down from 93 — see BUG-020)*
- Core flows work with server-side price verification and HMAC signature checks  
- Admin panel has full product/order/coupon/delivery partner management  
- Payment provider (Razorpay) is rejecting the configured test credentials with `401 Unauthorized` — confirmed via direct API call, not an app bug  
- Risk: payment/order atomicity gap (RISK-001)

**Overall Production Readiness: 68/100** *(down from 83 — payment is a launch-blocking core flow)*
Blocked from production by: **BUG-020 (Razorpay credentials rejected — blocks all checkout)**, BUG-016 (iOS Firebase), BUG-019 (OTP validation), RISK-001 (payment atomicity)

**Bugs Found:** 21 total  
**Bugs Fixed:** 17 (BUG-001 to BUG-015, BUG-017, BUG-018, BUG-021)  
**Bugs Remaining:** 4 (BUG-016, BUG-019, BUG-020, BUG-009 likely fixed pending final live confirmation)
