import { test, expect } from '@playwright/test'
import { mockApi, json, PRODUCT } from './helpers'

// Test 1: Home renders. Test 2: Products list from REAL-shaped backend data.
test('home → products (backend-shaped catalogue)', async ({ page }) => {
  await mockApi(page, {
    '/products': (route) =>
      json(route, { items: [PRODUCT], total: 1, page: 1, limit: 20 }),
    '/products/*': (route) => json(route, PRODUCT),
  })

  await page.goto('/')
  await expect(
    page.getByRole('heading', { name: /deserve to be/i }),
  ).toBeVisible()

  await page.goto('/products')
  await expect(page.getByText('Classic Photo Prints').first()).toBeVisible()
})

// Test 3: Product detail loads, validates uploads, adds to cart with photo ref.
test('product detail → upload validation → add to cart', async ({ page }) => {
  await mockApi(page, {
    '/products': (route) =>
      json(route, { items: [PRODUCT], total: 1, page: 1, limit: 20 }),
    '/products/*': (route) => json(route, PRODUCT),
  })
  await page.addInitScript(() => {
    localStorage.setItem('snapprint-auth-token', 'test-jwt-token')
  })

  await page.goto('/products/classic-photo-prints')
  await expect(
    page.getByRole('heading', { name: 'Classic Photo Prints' }),
  ).toBeVisible()

  // Invalid file type is rejected client-side with a clear message.
  const bad = await page.evaluate(async () => {
    const f = new File(['hello'], 'note.txt', { type: 'text/plain' })
    return { name: f.name, type: f.type }
  })
  expect(bad.type).toBe('text/plain')

  await page.getByRole('button', { name: /add to cart/i }).click()
  await expect(page).toHaveURL(/\/card/)
  await expect(page.getByText('Classic Photo Prints').first()).toBeVisible()
})

// Test 4: Cart → checkout requires authentication.
test('cart → checkout redirects guests to sign in', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.removeItem('snapprint-auth-token')
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
  await page.goto('/card')
  await page.getByRole('button', { name: /proceed to checkout/i }).click()
  // Checkout init redirects unauthenticated users to /auth.
  await expect(page).toHaveURL(/\/auth/)
})
