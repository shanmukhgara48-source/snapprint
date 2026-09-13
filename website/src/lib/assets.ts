/**
 * Base-aware asset URL. The app can be served from the domain root
 * (Firebase Hosting, BASE_URL='/') or from a WordPress plugin directory
 * (BASE_URL='/wp-content/plugins/snapprint-app/app/'). Always resolve
 * bundled assets through this helper instead of hardcoding '/...'.
 */
export function appAsset(path: string): string {
  const base = import.meta.env.BASE_URL || '/'
  const normalizedBase = base.endsWith('/') ? base : `${base}/`
  return `${normalizedBase}${path.replace(/^\//, '')}`
}
