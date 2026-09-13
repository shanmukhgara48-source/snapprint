/**
 * Centralised, browser-safe environment access.
 *
 * SECURITY RULES (do not weaken):
 * - Only VITE_* values are ever bundled into client JS. Never add a server
 *   secret (Razorpay secret, Firebase Admin key, R2 secret, DB password,
 *   backend signing secret, admin password, HF token) as a VITE_* variable.
 * - The dev-login bypass is honoured ONLY in local development builds
 *   (`import.meta.env.DEV`). Production builds ignore VITE_DEV_* entirely,
 *   so a stray secret baked into a prod bundle can never activate the bypass.
 */

export const API_BASE = import.meta.env.VITE_API_URL || '/api'
export const APP_URL = import.meta.env.VITE_APP_URL || 'http://localhost:4173'
export const RAZORPAY_KEY_ID = import.meta.env.VITE_RAZORPAY_KEY_ID || ''

export const FIREBASE_CONFIG = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || '',
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || '',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || '',
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || '',
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || '',
  appId: import.meta.env.VITE_FIREBASE_APP_ID || '',
} as const

export function isFirebaseConfigured(): boolean {
  return Boolean(
    FIREBASE_CONFIG.apiKey &&
      FIREBASE_CONFIG.authDomain &&
      FIREBASE_CONFIG.projectId &&
      FIREBASE_CONFIG.appId,
  )
}

/** True only for local `vite dev` / development builds. Never true in prod. */
export function isDevBuild(): boolean {
  return Boolean(import.meta.env.DEV)
}

/**
 * Dev bypass is available ONLY when running a development build AND a dev
 * secret is configured. Production startup paths must never call devLogin().
 */
export function isDevBypassEnabled(): boolean {
  return (
    isDevBuild() && Boolean(import.meta.env.VITE_DEV_SECRET)
  )
}

/**
 * DEMO MODE — temporary stand-in until real Firebase credentials exist.
 * Set VITE_DEMO_OTP (e.g. "123456") to accept that code for any valid phone
 * number via the dev-login endpoint. Explicitly owner-requested, visibly
 * badged in the UI, flagged by getProductionConfigWarnings(), and MUST be
 * emptied before production launch.
 */
export const DEMO_OTP = import.meta.env.VITE_DEMO_OTP || ''

export function isDemoOtpEnabled(): boolean {
  return DEMO_OTP.length >= 4
}

/**
 * WordPress-embed build (`VITE_WP_EMBED=true` + `--base=<plugin path>`).
 * The app renders inside a WP page via shortcode: our head/SEO management
 * goes inert (Yoast/RankMath own the document head) and the router uses the
 * shortcode-provided basename (window.__SNAPPRINT_BASENAME__).
 */
export const IS_WP_EMBED = import.meta.env.VITE_WP_EMBED === 'true'

export function getWpBasename(): string {
  if (!IS_WP_EMBED) return '/'
  const w = window as any
  const base =
    typeof w.__SNAPPRINT_BASENAME__ === 'string' && w.__SNAPPRINT_BASENAME__
      ? w.__SNAPPRINT_BASENAME__
      : '/'
  return base.endsWith('/') && base.length > 1 ? base.slice(0, -1) : base
}

export function getDevCredentials(): { phone: string; secret: string } {
  return {
    phone: import.meta.env.VITE_DEV_PHONE || '',
    secret: import.meta.env.VITE_DEV_SECRET || '',
  }
}

/**
 * Fail-fast prod sanity check for the customer journey. Called once at app
 * boot: warns (never throws) so a missing optional key degrades gracefully,
 * but missing Razorpay key blocks the payment step with a clear message.
 */
export function getProductionConfigWarnings(): string[] {
  if (isDevBuild()) return []
  const warnings: string[] = []
  if (!RAZORPAY_KEY_ID) {
    warnings.push('VITE_RAZORPAY_KEY_ID is not set — payment is unavailable.')
  } else if (!RAZORPAY_KEY_ID.startsWith('rzp_live_')) {
    warnings.push(
      'VITE_RAZORPAY_KEY_ID is not a live key — real payments are disabled until a rzp_live_* key is configured. REQUIRES OWNER ACTION.',
    )
  }
  if (!isFirebaseConfigured()) {
    warnings.push(
      'Firebase web config is incomplete — phone OTP sign-in is unavailable. REQUIRES OWNER ACTION.',
    )
  }
  if (isDemoOtpEnabled()) {
    warnings.push(
      'DEMO OTP mode is ON — remove VITE_DEMO_OTP before launch.',
    )
  }
  return warnings
}
