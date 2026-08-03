# SnapPrint Release Validation Report

Date: 2026-08-03

## Final production audit update (supersedes earlier counts)

### Final verdict

**NOT PRODUCTION READY**

The verified local code is substantially stronger and all exercised automated and Android integration paths are green. Release is still blocked because the production API hostname does not resolve, live Gemini editing and the BiRefNet worker are not configured for end-to-end execution, real Razorpay outcomes were not exercised, web/iOS Firebase configuration contains placeholders, and most catalog products use generic fallback images rather than product-owned media. These are functional release gates, not cosmetic findings.

### Verification summary

| Surface | Result | Evidence |
| --- | --- | --- |
| Flutter customer tests | PASS | 141 passed; 2 deliberately opt-in live-provider tests skipped |
| Customer persona matrix | PASS (automated) | Exactly 100 deterministic persona/scenario cases passed; this is not a claim that 100 human testers completed physical-device journeys |
| Flutter customer analysis | PASS | `flutter analyze` returned zero issues |
| Android admin-to-mobile synchronization | PASS for exercised modules | Real release/debug app against local FastAPI/Postgres; product, category, banner, and coupon create/update/visibility/delete changes appeared without restarting the app |
| Backend tests | PASS | 46 of 46 passed |
| Backend dependency audit | PASS | `pip-audit` found no known vulnerabilities after upgrading `google-genai` to 2.16.0 |
| Flutter admin | PASS for static/build gates | Analysis and release web build passed |
| React admin | PASS for static/build gates | ESLint passed with five Fast Refresh warnings; production build passed; production dependency audit found zero vulnerabilities |
| Signed Android release | PASS as an artifact | APK built, installed, launched, v2 signature verified, minSdk 24, targetSdk 36, no debug banner observed |
| External production journey | BLOCKED | Production API DNS failure prevents login, catalog, checkout, payment, and order confirmation against production |

The Android synchronization run exercised actual UI interactions and a real local database/API/WebSocket stack. It created and repriced a product including its effective variant price, searched it, opened its details, changed visibility, and deleted it. It also created, hid/deactivated/disabled, and deleted categories, banners, and coupons while the app remained open. The run completed in 2 minutes 2 seconds with no SnapPrint crash or ANR in Android exit history.

### Bugs found, root cause, fix, and retest

| Severity | Bug and root cause | Fix | Verification |
| --- | --- | --- | --- |
| High | Release clients could accept an HTTP or invalid API origin, permitting unsafe or unusable production configuration. | Added absolute-URL and HTTPS enforcement in both customer and Flutter admin release clients. | Analysis/tests/build passed; an invalid release origin now fails closed. |
| High | Flutter admin stored its bearer token in plain `SharedPreferences`. | Migrated authentication storage to `flutter_secure_storage`. | Admin analysis and release web build passed. |
| High | The Android release inherited advertising-ID and AdServices permissions from Firebase Analytics. | Removed merged permissions and disabled analytics ad-ID collection/personalization metadata. | Clean rebuilt APK contains none of the three advertising/attribution permissions. |
| High | Backend tests inherited `.env` public URL and signing settings, making security tests environment-dependent. | Cleared the public URL and supplied a dedicated strong test signing key in the test fixture. | Full backend suite: 46/46 passed. |
| Medium | Product price validation accepted `NaN` and infinity because range comparisons do not reject non-finite doubles. | Added an explicit finite-number check. | Price and persona regressions passed in the 141-test suite. |
| Medium | AI intent parsing missed natural requests such as “remove the background.” | Added normalized natural-language phrase classification in Flutter and backend. | Matching Flutter/backend intent tests passed. |
| Medium | AI intent parsing treated “chair” as “hair” because it used raw substring matching. | Replaced ambiguous substring matching with token-boundary matching. | “Remove the chair” regression is classified as object removal; backend suite passed. |
| Medium | Categories could overflow or appear absent with compact width, large text, Unicode, and long names because tile geometry was fixed. | Added scalable tile extent, bounded labels, ellipsis, and explicit error/empty states. | Widget regressions passed; live Android logs showed `CategoryGrid received 9`, then 10 after admin create, then 9 after hide/delete; taps navigated correctly. |
| Medium | Several `ListTile` paths asserted on device because they had decoration without a Material ancestor. | Added transparent Material ancestors on home, profile, and checkout surfaces. | Android integration run completed without the assertion. |
| Medium | Device automation reused a persisted development session and could test the wrong initial state. | Clear secure storage/preferences at integration setup. | Repeated integration launch starts from deterministic authentication state. |
| Medium | Product sync automation changed only the base price while the active variant retained the old lower effective price. | Update the variant and assert the customer-visible effective price. | Repricing appeared correctly in mobile UI. |
| Medium | Carousel and offer automation used ambiguous/off-screen selectors and interacted with virtualized children. | Added stable keys, hit-testable selection, `ensureVisible`, and real horizontal gestures. | Product and coupon scenarios passed on the emulator. |
| Medium | Integration screenshots could leave a pending frame and timeout through the Flutter screenshot bridge. | Made framework screenshots opt-in and used ADB capture for release evidence. | Full synchronization run completed. |
| Medium | Aborted integration runs left scoped QA catalog fixtures in the database. | Added narrowly named setup/teardown cleanup for QA products, categories, banners, and coupons. | Subsequent runs began and ended without those fixtures. |
| Medium | React admin bearer sessions persisted indefinitely across browser restarts in `localStorage`. | Moved bearer state to `sessionStorage`. | Lint and production build passed; HttpOnly cookies remain the preferred future architecture. |
| Low | Google Gen AI SDK constraint was behind current and allowed an unbounded future major. | Upgraded to `google-genai>=2.16.0,<3.0.0`. | Backend tests and the post-upgrade dependency audit passed. |

### Categories root-cause proof

The investigation ruled out the backend, JSON model, repository, and Riverpod provider: each returned nine active categories. The failure was in the presentation constraints, where fixed card geometry could overflow/collapse category content on constrained layouts. The grid now derives a bounded tile extent from text scale and bounds every label. The existing loading, API-error/retry, and genuine-empty states were retained and verified so the section cannot silently render blank. During live admin synchronization the category count changed from 9 to 10 immediately after creation and returned to 9 after visibility/deletion changes, without app restart. Every active category parsed through the real Flutter repository, its image returned loadable content, and category taps opened the filtered product route.

### Product image audit

| Metric | Result |
| --- | ---: |
| Products returned by live local API | 103 |
| Products resolving to a loadable image URL | 103 |
| Broken/404 resolved image URLs | 0 |
| Products with explicit backend image arrays | 6 |
| Products using Flutter keyword/category fallback media | 97 |
| Visually verified uniquely correct product images | Not established |

Network rendering coverage is 100%, but the target of “100% correct premium product images” is **not certified**: 97 products are represented by fallback media. Correct product-owned images must be added and visually approved in admin before release.

### Performance metrics

Metrics were captured on a 2 GB Android emulator and local development services; they are not production-SLA measurements.

| Metric | Measured result |
| --- | --- |
| Signed release cold start, first launch after install | 3,083 ms |
| Subsequent force-stop cold starts | 1,125 / 927 / 844 / 680 ms; median 885.5 ms |
| Average across all five launches | 1,331.8 ms |
| Idle memory | 123,487 KB total PSS; 215,132 KB RSS |
| CPU | 3.8% first post-launch sample; 0.0% in five subsequent one-second idle samples |
| Local catalog API, 100 requests at concurrency 10 | 0 failures; 569.33 requests/s; 10 ms median; 83 ms p95/max |
| Representative 900x900 CDN image, 20 requests at concurrency 4 | 0 failures; 47 ms median; 64 ms p95/max |
| Average FPS / scroll FPS | Not validly measured: Flutter SurfaceView frames were not reported by `dumpsys gfxinfo` |
| Sustained memory-leak and battery profile | Not measured on a physical device |

The signed release APK is approximately 61.5 MB. Four recorded SnapPrint process exits were user-requested force stops used by the startup benchmark; Android recorded no SnapPrint crash or ANR. The emulator itself displayed a System UI low-resource dialog after repeated installation/benchmark cycles, so physical low-memory-device profiling remains required.

### Security findings

- No backend `.env`, Firebase Admin service-account JSON, private key, reusable test password, or server API secret is tracked. Android/iOS Firebase client configuration and Razorpay key IDs are public client identifiers, not server secrets.
- Android production cleartext traffic is disabled, and release API origins now require HTTPS.
- Flutter admin credentials now use platform secure storage; React admin uses non-persistent `sessionStorage`. React bearer tokens remain JavaScript-readable, so an HttpOnly, Secure, SameSite cookie plus CSRF protection is the stronger production follow-up.
- Android advertising-ID and AdServices permissions were removed from the release artifact.
- Authentication, authorization, private media, payment replay, upload spoofing, coupon ownership, delivery transitions, rate limits, and realtime pre-auth behavior have negative automated coverage.
- `pip-audit` and `npm audit --omit=dev` found no known production dependency vulnerabilities.
- The local backend remains in development mode and has a development bypass secret. Production startup validation must be used; that local configuration must never be deployed.

### External blockers

1. `https://api.snapprint.in` does not resolve. The signed release therefore cannot complete a production customer journey.
2. `/ai/photo/status` reports generative editing unavailable because no `GEMINI_API_KEY`/`GOOGLE_API_KEY` is configured. The code follows Google's current backend SDK/Interactions API direction, but upload/edit/enhance/background replacement/upscale/save/retry/timeout were not run against the real provider. See the [Gemini image editing guide](https://ai.google.dev/gemini-api/docs/image-generation) and [Google Gen AI Python SDK](https://googleapis.github.io/python-genai/).
3. Background-removal configuration exists, but the production BiRefNet GPU worker was not deployed and quality-tested with a licensed corpus.
4. Razorpay success, failure, cancellation, timeout, duplicate tap, retry, and network interruption are covered at mocked/contract boundaries only; no real provider transaction was executed.
5. Firebase web values and the iOS app ID contain placeholders, blocking those release targets.
6. The full login-to-order-history journey cannot be certified while production API, AI, payment, and Firebase services are unavailable.
7. Testing used an emulator, not a physical Android device. Camera/gallery, OTP, process death during payment, rotation, deep links, notifications, battery, sustained jank, and memory-leak behavior still require device-farm or physical-device runs.

### Module checklist

`PASS` means actually exercised in the stated environment; `PARTIAL` means automated/local coverage exists but a required live path is missing; `BLOCKED` means a release dependency prevents certification.

| Module | CRUD working | API working | Mobile sync verified | Status |
| --- | --- | --- | --- | --- |
| Dashboard | N/A | PASS (local) | N/A | PARTIAL: current browser E2E not rerun after final changes |
| Products | PASS | PASS | PASS | PARTIAL: 97 products still use fallback media |
| Categories | PASS | PASS | PASS | PASS |
| Banners | PASS | PASS | PASS | PASS |
| Coupons | PASS | PASS | PASS | PASS |
| Orders | PASS (automated/local) | PASS (automated/local) | Not end-to-end | BLOCKED by live payment/API |
| Users/Auth | PASS (automated/local) | PASS (automated/local) | PARTIAL | BLOCKED by production API/Firebase targets |
| Notifications | Not fully exercised | Not fully exercised | Not verified | BLOCKED |
| Delivery Settings | PASS (automated backend) | PASS (automated/local) | Not verified | PARTIAL |
| App Settings | Not fully exercised | Not fully exercised | Not verified | BLOCKED |
| AI Photo Editor | PASS for local editor | Provider unavailable | Not checkout-verified | BLOCKED |
| Payments | PASS for replay/contracts | Provider not exercised | Not end-to-end | BLOCKED |
| Cart/Checkout | PASS (automated/local) | PASS (automated/local) | PARTIAL | BLOCKED by production payment/API |
| Admin applications | PASS for exercised CRUD/builds | PASS (local) | PASS for product/category/banner/coupon | PARTIAL |

This audit must be rerun against deployable production or staging infrastructure after the blockers are resolved. A green unit suite or a signed APK alone is not sufficient to change the verdict.

### Files modified in the final audit pass

- Customer app: `snap_print/lib/core/network/api_endpoints.dart`, `snap_print/lib/core/utils/validators.dart`, `snap_print/lib/features/ai_editor/domain/prompt_edit_intent.dart`, `snap_print/lib/features/customer/presentation/widgets/category_grid.dart`, `snap_print/lib/features/customer/presentation/screens/customer_home_screen.dart`, `snap_print/lib/features/customer/presentation/screens/profile_screen.dart`, `snap_print/lib/features/customer/presentation/screens/checkout_screen.dart`, and `snap_print/android/app/src/main/AndroidManifest.xml`.
- Customer QA: `snap_print/test/qa/customer_persona_matrix_test.dart`, `snap_print/integration_test/qa_admin_api.dart`, and `snap_print/integration_test/qa_realtime_sync_test.dart`.
- Backend: `backend/app/services/ai_photo_editor.py`, `backend/tests/conftest.py`, `backend/tests/test_ai_photo_editor_service.py`, and `backend/requirements.txt`.
- Flutter admin: `admin/lib/core/api_client.dart`, `admin/pubspec.yaml`, and `admin/pubspec.lock`.
- React admin: `admin-web/src/lib/api.ts`, `admin-web/src/lib/auth.tsx`, and `admin-web/src/lib/realtime.ts`.
- Audit: `RELEASE_VALIDATION_REPORT.md`.

## Prior audit (2026-08-02; retained for traceability)

The remainder of this document records the previous audit pass. Its older test counts and environment statements are historical; the 2026-08-03 update above is authoritative.

### Executive verdict

The final local codebase has no reproducible critical or high-severity software defect in the exercised paths. Static analysis, automated tests, builds, dependency audits, database invariants, browser workflows, live local API/media checks, and bounded concurrency tests are green.

Production deployment is **on hold**, however, because several external release gates cannot be proven in this environment: the BiRefNet GPU worker and Gemini provider are not configured, real Razorpay credentials/transactions are unavailable, Firebase project credentials do not match the mobile project locally, Firebase rules have not been deployed, and the attached physical phone is locked. Those are material gates for an AI-first paid mobile product, so this report does not claim production readiness beyond the verified code and local services.

## Test execution

- 79 distinct automated tests in the final green suites: 43 backend tests and 36 Flutter tests (34 normal plus 2 opt-in live API/CDN tests).
- Backend: `43 passed` in 6.06 seconds; Python compilation and application startup passed.
- Flutter customer app: `flutter analyze` passed; 34 normal tests passed; 2 live integration tests passed.
- Android integration harness: debug APK compiled successfully after credential and URL hardening.
- Flutter legacy admin: `flutter analyze` and release web build passed.
- React admin: ESLint exited successfully with five development-only Fast Refresh warnings; release build passed; npm audit reported zero vulnerabilities.
- Browser E2E: admin login, dashboard, products, orders, order detail, hard refresh, browser back, and logout passed against the real local backend with no console errors.
- Database: Alembic is at `g7c2e5f9b346 (head)`, schema drift check passed, and all 13 data-integrity checks returned zero violations.
- Live media lifecycle: authenticated upload, signed retrieval, account deletion, and post-delete 404 passed.
- Stress: 500 health requests at concurrency 25 and 200 catalog requests at concurrency 10 completed with zero failures.
- Realtime: 25 rapid unauthenticated WebSocket disconnects completed without server exceptions after the protocol-stack upgrade.
- Release artifacts: Android APK and AAB built successfully with non-secret validation defines.

## New test suites

Backend coverage was added for admin CRUD/end-to-end behavior, AI provider failures, authentication and authorization, checkout tampering, coupon ownership, delivery state integrity, Firebase configuration, private media, cancellation/refunds/inventory, payment replay, high-resolution image processing, rate limits, realtime authentication/disconnects, segmentation metrics, and upload validation.

Flutter coverage was added for AI editor models/UI/metrics/processing/uploads, auth model parsing, cart concurrency and bounds, checkout rules, and product price fallback. The device admin-sync harness was retained, made environment-configurable, and compiled as an Android integration target.

## AI editor architecture and model decision

The original editor mixed UI state, image manipulation, upload, and provider calls; depended on a generative image API for deterministic editing; checked provider availability from client configuration; lacked a full-resolution non-destructive document model; and had no objective mask-quality harness. This explains inconsistent silhouettes, lost detail, unpredictable output dimensions, weak undo behavior, and an inability to guarantee transparent print assets.

The replacement uses `features/ai_editor/{data,domain,presentation}`, Riverpod state, a repository boundary, immutable editor operations, a full-resolution local compositor, private source/result media, backend job orchestration, progress/error contracts, drafts, and reusable controls. Generative editing remains a separate optional backend capability.

[BiRefNet high-resolution](https://huggingface.co/ZhengPeng7/BiRefNet_HR-matting) is the selected production background-removal model. Its explicit high-resolution dichotomous-segmentation design fits automatic foreground extraction and fine boundaries. [IS-Net](https://arxiv.org/abs/2203.03041) is a strong older DIS baseline but is less attractive for the final quality target. [SAM2](https://github.com/facebookresearch/sam2) is promptable and well suited to interactive selection/refinement, but it is not by itself an automatic matting pipeline. [RMBG-2.0](https://huggingface.co/briaai/RMBG-2.0) is competitive, but its published weights require separate commercial licensing; it remains a provider option rather than the default bundled worker. A future SAM-assisted correction pass can be added behind the repository without changing the editor UI.

Implemented editing includes transparent/white/black/solid/gradient/custom backgrounds; auto crop and centering; brightness, contrast, saturation, temperature, tint, vibrance, exposure, highlights, shadows, and sharpness; crop, rotate, flip, and straighten; pinch/pan/double-tap; before/after; undo/redo/reset; draft persistence; print-quality analysis; and full-resolution PNG/JPEG rendering.

## Defects, root causes, and fixes

| Severity | Defect and root cause | Fix |
| --- | --- | --- |
| Critical | Client-side AI key/provider coupling exposed credentials and made policy enforcement impossible. | Moved AI access behind authenticated/rate-limited backend routes and server configuration. |
| Critical | Order creation trusted client prices and could be reached without a verified, single-use payment intent. | Repriced server-side, bound orders to verified payment references, added uniqueness constraints and replay tests. |
| Critical | Authorization trusted mutable client role claims. | Made backend/Firebase role resolution authoritative and hardened route guards. |
| High | Uploaded customer and delivery media could be addressed too directly. | Added private object storage, expiring signed access, ownership checks, strict media namespaces, and deletion cleanup. |
| High | Background removal was generative and resolution-destructive rather than deterministic segmentation. | Added a BiRefNet HR GPU worker contract, alpha-mask validation/refinement, full-resolution compositing, and quality metrics. |
| High | Refund/cancellation paths did not atomically protect inventory and payment state. | Added idempotent refunds, cancellation rules, restock tracking, row locking, and migrations. |
| High | Coupon lookup and use were not sufficiently owner-scoped or race-safe. | Added private ownership, atomic usage limits, and restricted public exposure. |
| High | Delivery state changes allowed invalid transitions and insufficient proof controls. | Centralized the state machine, made terminal states immutable, validated assignment, and secured proof uploads. |
| High | Orders referenced mutable user addresses. | Added immutable address snapshots and migration coverage. |
| High | Upload validation relied too heavily on names/content type and mishandled HEIC. | Added byte-level decoding/limits, protected paths, HEIC/HEIF handling, and adversarial tests. |
| High | Production configuration could start with unsafe defaults. | Added fail-closed production validation for secrets, URLs, CORS, Firebase, payments, storage, and AI providers. |
| High | Python and React dependency graphs contained known vulnerabilities. | Upgraded FastAPI/Starlette/multipart/Uvicorn, replaced `python-jose` with PyJWT, removed browser AI inference and React Router; both audits now report zero. |
| High | The standalone AI worker resolved a vulnerable Starlette release, loaded mutable remote model code from `main`, required an incompatible NumPy major version, and omitted a model import. | Upgraded its web stack, pinned the reviewed model snapshot by immutable commit SHA, reject non-SHA revisions, and aligned NumPy/einops with that snapshot. |
| High | Uvicorn's legacy WebSocket adapter crashed on rapid disconnects with the installed websockets release. | Upgraded Uvicorn, selected `websockets-sansio`, and added disconnect regression coverage. |
| High | Admin exposed polished mock operational pages that did not persist real changes. | Removed mock routes/navigation and kept only backend-backed workflows. |
| Medium | Admin order filters used statuses the backend never emits. | Aligned filters/badges with `picked_up` and `out_for_delivery`; preserved active navigation on detail routes. |
| Medium | Invalid product prices could display as zero and leave add-to-cart loading forever. | Added effective-price fallback and moved loading state after validation. |
| Medium | Cart updates and checkout quantities were not consistently bounded. | Added immutable quantity rules, serialized state updates, and checkout validation. |
| Medium | Banner partial updates could create an invalid schedule; terminal delivery assignment was permitted. | Added complete-state validation and 409 conflict handling with regression tests. |
| Medium | Account deletion skipped customer media cleanup for development users. | Always remove private media prefixes; only skip external Firebase identity deletion for dev identities. |
| Medium | Local database contained stale category/price/order inconsistencies. | Added a quarantine migration and repeatable 13-invariant audit; current database is clean. |
| Medium | Admin E2E source embedded a reusable password and hardcoded emulator networking. | Replaced both with test-only Dart defines and deleted the obsolete payment-bypass helper. |
| Medium | Initial admin bundle eagerly loaded charting and route code. | Added route-level lazy loading and a minimal local history router. |

## Performance findings

- `/health`: 500 requests, concurrency 25, 0 failures, 1,130.68 requests/second, 15 ms median, 51 ms p95, 108 ms maximum.
- `/products?limit=100`: 200 requests, concurrency 10, 0 failures, 276.75 requests/second, 30 ms median, 67 ms p95, 77 ms maximum.
- Live PNG upload: 1.302 seconds; signed retrieval: 0.330 seconds.
- 12 MP full-resolution editor render: 1.243 seconds, 9.66 MP/s, approximately 467.4 MB peak process memory.
- React admin initial JS: 281.46 KB / 91.23 KB gzip; chart chunk deferred at 346.20 KB / 100.25 KB gzip.
- Release APK: approximately 61.5 MB reported by Flutter (59 MB filesystem); AAB: approximately 61.8 MB (59 MB filesystem).
- APK SHA-256: `4401c4f4ea79539d7cfc29bf00dff995c04ab0d120de0dd102257d818b10da20`.
- AAB SHA-256: `8095cbfba64ffe6aaf906f0f25bdaadd47ced4d9d1a6fb096c9313497893030b`.

The 12 MP memory peak needs physical low-memory-device validation. Cold/warm startup, battery, camera/gallery behavior, GPU inference latency, and frame-jank measurements could not be captured with the phone locked.

## Security findings

- `pip-audit`: zero known vulnerabilities in both the main API and AI worker dependency sets.
- `npm audit`: zero known vulnerabilities.
- `pip check`: no broken dependencies.
- Secret scan: no embedded private key, reusable admin password, or private credential file is tracked. Firebase client keys and Razorpay key IDs are public identifiers; server secrets remain environment-only.
- Authentication, role authorization, rate limits, payment replay, file spoofing/path handling, media ownership, coupon isolation, and realtime pre-auth behavior now have automated negative tests.
- Production cleartext traffic is disabled on Android; localhost cleartext is debug-only.

## Remaining release gates and limitations

1. Build, deploy, and benchmark the BiRefNet worker on the intended Linux AMD64/NVIDIA host, then run a licensed, representative portrait/group/pet/glass/hair/transparent-object dataset. Docker resolved the pinned CUDA base locally; its static check stopped only on the expected ARM-host versus AMD64-GPU platform mismatch. The local provider status is currently unavailable, so commercial mask accuracy is not demonstrated.
2. Configure Gemini only if generative edits will ship; `/ai/photo/status` correctly reports it unavailable without a key.
3. Resolve the local Firebase project mismatch (`snapprint-5076c` mobile configuration versus `snap-print-7146d` local backend credentials), deploy Firestore/Storage rules, and rerun authorization tests against that project.
4. Supply the real production API origin and Razorpay live key ID, execute successful/failed/cancelled/interrupted transactions in Razorpay's supported environment, and verify webhook/refund reconciliation.
5. Unlock the Samsung device and run the full physical-device persona suite, including OTP, camera/gallery, rotation, process death, offline/slow network, background/foreground, low memory/storage, notifications, deep links, payment UI, and delivery proof capture.
6. Persist a successful Razorpay callback across mobile process death before order confirmation. Backend idempotency is safe when credentials are redelivered, but client recovery is not yet proven.
7. Replace the process-local realtime broadcaster with Redis or equivalent before running more than one API worker.
8. Upgrade Gradle from 8.13 and Android Gradle Plugin from 8.9.1 before future Flutter minimums make them unsupported.
9. Address Python 3.14 deprecation warnings in SlowAPI/TestClient integrations and optionally split React provider/hook modules to remove five Fast Refresh warnings.

## Changed-file inventory

The working tree contains 149 modified or newly created files, including this report; every path is listed below. No changes were committed.

### React admin

`admin-web/package.json`, `admin-web/src/App.tsx`, `admin-web/src/components/Layout.tsx`, `admin-web/src/lib/router.tsx`, `admin-web/src/lib/types.ts`, `admin-web/src/pages/Login.tsx`, `admin-web/src/pages/customers/CustomerDetail.tsx`, `admin-web/src/pages/customers/CustomersList.tsx`, `admin-web/src/pages/orders/OrderDetail.tsx`, `admin-web/src/pages/orders/OrdersList.tsx`, `admin-web/src/pages/products/ProductsList.tsx`.

### Flutter admin

`admin/lib/features/products/products_screen.dart`, `admin/pubspec.lock`, `admin/pubspec.yaml`.

### Backend configuration and deployment

`backend/.env.example`, `backend/Dockerfile`, `backend/Procfile`, `backend/railway.toml`, `backend/requirements.txt`, `backend/main.py`, `backend/alembic/env.py`.

### Backend AI worker and migrations

`backend/ai_worker/Dockerfile`, `backend/ai_worker/README.md`, `backend/ai_worker/evaluate.py`, `backend/ai_worker/main.py`, `backend/ai_worker/requirements.txt`, `backend/alembic/versions/c3e8a1f7d902_payment_replay_protection.py`, `backend/alembic/versions/d4f9b2a8e013_private_coupon_ownership.py`, `backend/alembic/versions/e5a0c3b9f124_order_address_snapshots.py`, `backend/alembic/versions/f6b1d4e8a235_refunds_and_inventory_tracking.py`, `backend/alembic/versions/g7c2e5f9b346_quarantine_legacy_invalid_orders.py`.

### Backend application

`backend/app/config.py`, `backend/app/dependencies.py`, `backend/app/models/__init__.py`, `backend/app/models/coupon.py`, `backend/app/models/order.py`, `backend/app/models/payment_intent.py`, `backend/app/models/product.py`, `backend/app/routers/addresses.py`, `backend/app/routers/admin.py`, `backend/app/routers/ai_editor.py`, `backend/app/routers/auth.py`, `backend/app/routers/cart.py`, `backend/app/routers/coupons.py`, `backend/app/routers/delivery.py`, `backend/app/routers/media.py`, `backend/app/routers/orders.py`, `backend/app/routers/payments.py`, `backend/app/routers/realtime.py`, `backend/app/routers/upload.py`, `backend/app/schemas/address.py`, `backend/app/schemas/admin.py`, `backend/app/schemas/ai_editor.py`, `backend/app/schemas/auth.py`, `backend/app/schemas/banner.py`, `backend/app/schemas/cart.py`, `backend/app/schemas/category.py`, `backend/app/schemas/delivery.py`, `backend/app/schemas/order.py`, `backend/app/schemas/product.py`, `backend/app/services/ai_photo_editor.py`, `backend/app/services/firebase_service.py`, `backend/app/services/order_service.py`, `backend/app/services/order_status.py`, `backend/app/services/payment_service.py`, `backend/app/services/professional_image_pipeline.py`, `backend/app/services/r2_storage.py`.

### Backend validation

`backend/scripts/audit_database.py`, `backend/scripts/benchmark_image_pipeline.py`, `backend/scripts/verify_live_upload.py`, `backend/tests/conftest.py`, `backend/tests/test_admin_end_to_end.py`, `backend/tests/test_ai_photo_editor_service.py`, `backend/tests/test_auth_security.py`, `backend/tests/test_checkout_security.py`, `backend/tests/test_coupon_ownership.py`, `backend/tests/test_delivery_integrity.py`, `backend/tests/test_firebase_configuration.py`, `backend/tests/test_media_gateway.py`, `backend/tests/test_order_cancellation.py`, `backend/tests/test_payment_replay.py`, `backend/tests/test_professional_image_pipeline.py`, `backend/tests/test_rate_limits.py`, `backend/tests/test_realtime_security.py`, `backend/tests/test_segmentation_evaluation.py`, `backend/tests/test_upload_security.py`.

### Flutter platform, integration, and dependencies

`snap_print/android/app/build.gradle.kts`, `snap_print/android/app/src/main/AndroidManifest.xml`, `snap_print/android/app/src/main/res/xml/network_security_config.xml`, `snap_print/android/app/src/debug/res/xml/network_security_config.xml`, `snap_print/integration_test/qa_admin_api.dart`, `snap_print/integration_test/qa_realtime_sync_test.dart`, `snap_print/pubspec.lock`, `snap_print/pubspec.yaml`.

Flutter tooling also updated generated macOS integration metadata: `snap_print/macos/Podfile.lock`, `snap_print/macos/Runner.xcodeproj/project.pbxproj`, `snap_print/macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`, `snap_print/macos/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`, `snap_print/macos/Runner.xcworkspace/contents.xcworkspacedata`, `snap_print/macos/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

### Flutter application

`snap_print/lib/core/network/api_endpoints.dart`, `snap_print/lib/core/router/app_router.dart`, `snap_print/lib/features/ai_editor/data/ai_editor_repository.dart`, `snap_print/lib/features/ai_editor/data/ai_editor_service.dart`, `snap_print/lib/features/ai_editor/data/local_image_processor.dart`, `snap_print/lib/features/ai_editor/data/upload_repository.dart`, `snap_print/lib/features/ai_editor/domain/ai_editor_models.dart`, `snap_print/lib/features/ai_editor/domain/editor_document.dart`, `snap_print/lib/features/ai_editor/domain/editor_operation.dart`, `snap_print/lib/features/ai_editor/domain/local_image_metrics.dart`, `snap_print/lib/features/ai_editor/presentation/providers/ai_editor_provider.dart`, `snap_print/lib/features/ai_editor/presentation/screens/ai_photo_editor_screen.dart`, `snap_print/lib/features/ai_editor/presentation/widgets/editor_adjust_panel.dart`, `snap_print/lib/features/ai_editor/presentation/widgets/editor_analysis_panel.dart`, `snap_print/lib/features/ai_editor/presentation/widgets/editor_bottom_toolbar.dart`, `snap_print/lib/features/ai_editor/presentation/widgets/editor_canvas.dart`, `snap_print/lib/features/ai_editor/presentation/widgets/editor_crop_overlay.dart`, `snap_print/lib/features/ai_editor/presentation/widgets/editor_image_viewer.dart`, `snap_print/lib/features/ai_editor/presentation/widgets/editor_mask_painter.dart`, `snap_print/lib/features/ai_editor/presentation/widgets/editor_preset_sheet.dart`, `snap_print/lib/features/ai_editor/presentation/widgets/editor_processing_overlay.dart`, `snap_print/lib/features/ai_editor/presentation/widgets/editor_top_bar.dart`, `snap_print/lib/features/ai_editor/presentation/widgets/editor_transform_panel.dart`, `snap_print/lib/features/auth/data/models/user_model.dart`, `snap_print/lib/features/auth/presentation/providers/auth_provider.dart`, `snap_print/lib/features/customer/data/models/product_model.dart`, `snap_print/lib/features/customer/domain/checkout_rules.dart`, `snap_print/lib/features/customer/domain/entities/product_entity.dart`, `snap_print/lib/features/customer/presentation/providers/cart_provider.dart`, `snap_print/lib/features/customer/presentation/screens/checkout_screen.dart`, `snap_print/lib/features/customer/presentation/screens/customer_home_screen.dart`, `snap_print/lib/features/customer/presentation/screens/customization_screen.dart`, `snap_print/lib/features/customer/presentation/screens/order_confirmation_screen.dart`, `snap_print/lib/features/customer/presentation/screens/payment_screen.dart`, `snap_print/lib/features/customer/presentation/screens/product_detail_screen.dart`, `snap_print/lib/features/customer/presentation/widgets/product_card.dart`, `snap_print/lib/features/delivery/data/datasources/delivery_remote_datasource.dart`, `snap_print/lib/features/delivery/presentation/screens/delivery_order_detail_screen.dart`, `snap_print/lib/features/delivery/presentation/screens/delivery_proof_screen.dart`.

### Flutter tests

`snap_print/test/ai_editor/ai_editor_models_test.dart`, `snap_print/test/ai_editor/ai_photo_editor_screen_test.dart`, `snap_print/test/ai_editor/local_image_metrics_test.dart`, `snap_print/test/ai_editor/local_image_processor_test.dart`, `snap_print/test/ai_editor/upload_repository_test.dart`, `snap_print/test/auth/user_model_test.dart`, `snap_print/test/customer/cart_provider_test.dart`, `snap_print/test/customer/checkout_rules_test.dart`, `snap_print/test/customer/product_pricing_test.dart`.

### Release documentation

`RELEASE_VALIDATION_REPORT.md`.

## Future recommendations

Use a licensed fixed image corpus with alpha mattes and enforce MAE, boundary F-score, foreground IoU, halo rate, and full-resolution output thresholds in CI. Add Detox/Appium or Flutter integration runs on an unlocked device farm, webhook contract tests against Razorpay staging/live-supported flows, fault injection for Redis/object storage/provider outages, and nightly high-resolution memory/performance runs. Treat the external release gates above as a signed checklist; do not ship the AI editor or payments merely because provider-unavailable fallbacks behave correctly.
