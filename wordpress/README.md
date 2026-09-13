# SnapPrint on WordPress

Serve the SnapPrint React storefront **inside** a WordPress page via the
`snapprint-app` plugin (`[snapprint_app]` shortcode). No theme changes needed.

## How it works

- `npm run build:wp` builds the app with `VITE_WP_EMBED=true` and
  `--base=/wp-content/plugins/snapprint-app/app/`, outputting straight into
  `wordpress/snapprint-app/app/`. All JS/CSS/image URLs point inside the plugin.
- The plugin enqueues the hashed bundle + Razorpay Checkout.js and renders
  `<div id="root">` wherever the shortcode sits.
- In embed mode the app does **not** touch `<head>` (your SEO plugin keeps
  ownership) and the router uses the page URL as its base.

## Deploy steps (cPanel / any WP host)

1. **Build** (from `website/`):
   ```bash
   # Point at the live backend (defaults to local /api proxy if unset):
   VITE_API_URL=https://snapprint-backend-production.up.railway.app \
   VITE_DEMO_OTP=123456 \
   npm run build:wp
   ```
   Re-run + re-upload whenever you change either value (Vite bakes env at build time).
2. **Package**: zip the `wordpress/snapprint-app/` folder contents
   (the zip must contain `snapprint-app.php` at its root).
3. **Install**: WP Admin → Plugins → Add New → Upload Plugin → choose the zip → Activate.
   (Or SFTP the folder to `wp-content/plugins/`.)
4. **Page**: Pages → Add New, slug e.g. `shop`, content just `[snapprint_app]`, Publish.
5. Open `https://your-site.com/shop/` — the storefront renders inline.

## Notes & limits

- **Backend still required.** Catalogue/auth/cart/payment call the FastAPI backend.
  Until it is live the app shows its offline/error states (same as standalone).
- **Deep links**: in-app navigation works; refreshing on a sub-route
  (`/shop/products/xyz`) 404s unless you add a catch-all. Optional mu-plugin
  (`wp-content/mu-plugins/snapprint-rewrites.php`) — replace `shop` with your slug:
  ```php
  <?php
  add_action('init', function () {
      add_rewrite_rule('^shop(/.*)?$', 'index.php?pagename=shop', 'top');
  });
  ```
  Then WP Admin → Settings → Permalinks → Save Changes (flushes rewrites).
- **Demo OTP**: the build above bakes `VITE_DEMO_OTP=123456` (any number + that
  code signs in). Empty it and rebuild before real launch.
- **Razorpay test key**: `VITE_RAZORPAY_KEY_ID=rzp_test_…` at build time
  (same variable as the standalone `.env`).
- **Cache**: after re-uploading a new build, purge any WP/caching-plugin + CDN
  cache for the shop page.
