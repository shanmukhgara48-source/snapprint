# SnapPrint redesign verification

Completed 6 September 2026. Local preview: http://127.0.0.1:5173/.

## Automated checks

Validated with Node 24.13.1:

- `npm run build`: TypeScript and production Vite build passed.
- `npm run lint`: passed.
- `node --test tests/printOptions.test.ts`: 7 tests passed. Covers quantity estimates, quote-only products, per-piece bulk minimums, ambiguous MOQ pricing, real format options, catalog coverage and preview proportions.
- `git diff --check`: passed.

## Browser verification

Desktop at 1280 px, tablet at 768 px, mobile at 390 px, and the print plan at 320 px were inspected. Checked page scroll widths matched their viewports. The final clean desktop load had no console warnings/errors and no broken loaded images.

- Home: hero photography, main CTA, category discovery, product compositions and responsive navigation.
- Guide: gifting selection narrowed the set to four products; the ₹500 starting-budget option narrowed it to two. Low-to-high sorting displayed mug before frame.
- Search: an impossible search showed a helpful empty state; reset restored all 92 products.
- Product details: selecting 7×5 adjusted the print silhouette. A generated test JPEG was rendered locally; switching to “Show whole photo” used contain mode and survived a format change. Image dimensions and low-resolution advice appeared. An SVG was rejected with specific JPG/PNG/WebP guidance.
- Plan: two classic frames started at ₹826; Express added ₹99. Saved product and format choices survived reload. Adding classic prints and a quote-only frame showed ₹1,262 for known starting prices plus Express, with the quote-only item explicitly excluded.
- Download: the browser automation download event did not fire, but the actual `my-snapprint-plan.txt` file was written to Downloads and inspected. It correctly contained all three product selections, formats, quantities, Express delivery, the ₹1,262 estimate and the quote exclusion. No photo data appeared in the file.
- Removal: all temporary test selections were removed using the UI; the plan returned to its empty state.
- Existing routes: pricing, shipping-policy alias and products-services alias rendered on mobile without page overflow. An unknown product ID showed a recovery link.
- Policy appearance: the existing shipping policy renders in the shared cream/gold theme. Existing publish-date and business/contact placeholders remain for the owner to complete.
- Final preview: opened on the home page with a clean console, empty plan and normal viewport restored. The development server remains running.

## Limits

This is browser-responsive verification, not a physical-device or cross-browser certification. Payment, production fulfillment and automatic app transfer were not exercised because they remain in the existing app. The public website has no configured app URL or web checkout. The photo mockups are illustrative; variant pricing and final proofs are confirmed in the app.
