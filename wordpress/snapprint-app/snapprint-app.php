<?php
/**
 * Plugin Name: SnapPrint App
 * Description: Embeds the SnapPrint photo-print storefront via the [snapprint_app] shortcode.
 * Version: 1.0.0
 * Requires at least: 6.0
 * Requires PHP: 7.4
 *
 * Usage: create a WordPress page (e.g. slug "shop") and put [snapprint_app] in it.
 * The API backend URL and demo OTP are baked in at build time
 * (see wordpress/README.md) — rebuild with `npm run build:wp` to change them.
 */

if (!defined('ABSPATH')) exit;

define('SNAPPRINT_APP_DIR', plugin_dir_path(__FILE__) . 'app/');
define('SNAPPRINT_APP_URL', plugin_dir_url(__FILE__) . 'app/');
define('SNAPPRINT_APP_VERSION', '1.0.0');

/** Find the hashed entry asset (index-*.js / index-*.css) in the app build. */
function snapprint_app_entry($ext) {
    static $cache = array();
    if (isset($cache[$ext])) return $cache[$ext];
    $found = null;
    $assets = SNAPPRINT_APP_DIR . 'assets/';
    if (is_dir($assets)) {
        foreach (scandir($assets) as $file) {
            if (preg_match('/^index-[A-Za-z0-9_-]+\.' . preg_quote($ext, '/') . '$/', $file)) {
                $found = $file;
                break;
            }
        }
    }
    $cache[$ext] = $found;
    return $found;
}

function snapprint_app_shortcode($atts) {
    $atts = shortcode_atts(array('base' => ''), $atts, 'snapprint_app');

    // Router basename: the URL of the page(s) hosting the app. Defaults to
    // the current page path so [snapprint_app] works on any page slug.
    $base = trim($atts['base']);
    if ($base === '') {
        global $wp;
        $path = isset($wp->request) ? '/' . trim($wp->request, '/') : '/';
        $base = $path === '/' ? '/' : rtrim($path, '/');
    }

    $js = snapprint_app_entry('js');
    if (!$js) {
        if (current_user_can('manage_options')) {
            return '<p><strong>SnapPrint:</strong> app build not found. Run <code>npm run build:wp</code> and copy <code>dist</code> into the plugin <code>app/</code> folder (see README).</p>';
        }
        return '<p>SnapPrint shop is temporarily unavailable. Please try again later.</p>';
    }
    $css = snapprint_app_entry('css');

    wp_register_script('razorpay-checkout', 'https://checkout.razorpay.com/v1/checkout.js', array(), null, true);
    wp_enqueue_script('razorpay-checkout');
    wp_enqueue_script('snapprint-app', SNAPPRINT_APP_URL . 'assets/' . $js, array(), SNAPPRINT_APP_VERSION, true);
    if ($css) {
        wp_enqueue_style('snapprint-app', SNAPPRINT_APP_URL . 'assets/' . $css, array(), SNAPPRINT_APP_VERSION);
    }
    wp_add_inline_script(
        'snapprint-app',
        'window.__SNAPPRINT_BASENAME__ = ' . wp_json_encode($base) . ';',
        'before'
    );

    return '<div id="root"></div>';
}
add_shortcode('snapprint_app', 'snapprint_app_shortcode');

/**
 * Optional deep-link support: with plain WP rewrites, refreshing
 * /shop/products/xyz would 404. If you need refreshable deep links, add the
 * mu-plugin snippet from wordpress/README.md (it routes /<shop-slug>/* back
 * to the shop page so the client router takes over).
 */
