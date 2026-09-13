import type { Page, Route } from '@playwright/test'

export const PRODUCT = {
  id: 'classic-photo-prints',
  name: 'Classic Photo Prints',
  category: 'Photo Prints',
  category_id: 'photo-prints',
  base_price: 299,
  sizes: [
    { label: '6x4', price: 299 },
    { label: '8x6', price: 499 },
  ],
  images: [],
  description: 'Classic prints',
  sort_order: 0,
  stock_quantity: 100,
  tracks_inventory: false,
  is_featured: true,
  is_trending: true,
  is_orderable: true,
  is_active: true,
}

export const ORDER = {
  id: 'ord_real123456',
  total_price: 299,
  status: 'confirmed',
  created_at: new Date().toISOString(),
  item_count: 1,
  delivery_address: '1 Test St, Bengaluru - 560001',
  estimated_delivery: new Date(Date.now() + 5 * 864e5).toISOString(),
  tracking_events: [{ status: 'confirmed', timestamp: new Date().toISOString() }],
}

/** Route mock for the SnapPrint API (Vite proxies /api → backend in dev). */
export async function mockApi(
  page: Page,
  handlers: Record<string, (route: Route) => unknown>,
) {
  await page.route('**/api/**', async (route) => {
    const url = new URL(route.request().url())
    const path = url.pathname.replace(/^\/api/, '') || '/'
    for (const [key, handler] of Object.entries(handlers)) {
      if (path === key || (key.endsWith('*') && path.startsWith(key.slice(0, -1)))) {
        return handler(route)
      }
    }
    return route.abort()
  })
  // Fallback: same handlers without the /api prefix (preview server).
  // Only intercept API-style fetches — never document navigations.
  await page.route(/\/products(\?|\/|$).*/, async (route) => {
    if (route.request().resourceType() === 'document') {
      return route.fallback()
    }
    const url = new URL(route.request().url())
    if (url.pathname.startsWith('/api')) return route.fallback()
    const path = url.pathname
    if (path === '/products' || path.startsWith('/products?')) {
      const h = handlers['/products']
      if (h) return h(route)
    }
    const m = path.match(/^\/products\/(.+)$/)
    if (m) {
      const h = handlers['/products/*']
      if (h) return h(route)
    }
    return route.fallback()
  })
}

export const json = (route: Route, body: unknown, status = 200) =>
  route.fulfill({
    status,
    contentType: 'application/json',
    body: JSON.stringify(body),
  })

export async function signedIn(page: Page) {
  await page.addInitScript(() => {
    localStorage.setItem('snapprint-auth-token', 'test-jwt-token')
    localStorage.setItem(
      'snapprint-plan-v1',
      JSON.stringify([
        {
          key: 'classic-photo-prints:6x4',
          productId: 'classic-photo-prints',
          size: '6x4',
          units: 1,
        },
      ]),
    )
  })
}
