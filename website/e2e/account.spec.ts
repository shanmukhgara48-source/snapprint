import { test, expect } from '@playwright/test'
import { mockApi, json, ORDER } from './helpers'

// Contact form: validation → submit → success.
test('contact form validates and submits', async ({ page }) => {
  let submitted: any = null
  await mockApi(page, {
    '/contact': (route) => {
      submitted = route.request().postDataJSON()
      return json(route, { ok: true }, 201)
    },
  })
  await page.goto('/contact')
  await page.getByLabel(/message/i).fill('short')
  await page.getByRole('button', { name: /send message/i }).click()
  await expect(page.getByText(/10\+ characters/i)).toBeVisible()

  await page.getByLabel(/^name/i).fill('Test Customer')
  await page.getByLabel(/email/i).fill('customer@example.org')
  await page.getByLabel(/subject/i).fill('Help with my order')
  await page.getByLabel(/message/i).fill('Please help me change my delivery address.')
  await page.getByRole('button', { name: /send message/i }).click()
  await expect(page.getByText(/message received/i)).toBeVisible()
  expect(submitted.email).toBe('customer@example.org')
})

// Account page: profile, orders link, logout.
test('account shows profile and logs out', async ({ page }) => {
  await mockApi(page, {
    '/auth/me': (route) =>
      json(route, {
        id: 'user-1',
        firebase_uid: 'uid-1',
        phone: '+919876543210',
        role: 'customer',
        is_active: true,
      }),
    // Auth-aware like the real backend: no bearer token → 401.
    '/orders/me': (route) =>
      route.request().headers()['authorization']
        ? json(route, [ORDER])
        : route.fulfill({
            status: 401,
            contentType: 'application/json',
            body: JSON.stringify({ detail: 'Not authenticated' }),
          }),
    '/orders/*': (route) => json(route, ORDER),
  })
  // NOTE: set session via evaluate (not addInitScript) so a later logout
  // really clears it — init scripts re-run on every navigation.
  await page.goto('/')
  await page.evaluate(() => {
    localStorage.setItem('snapprint-auth-token', 'test-jwt-token')
  })
  await page.goto('/account')
  await expect(page.getByText('+919876543210').first()).toBeVisible()
  await page.locator('#main').getByRole('button', { name: /^logout$/i }).click()
  await expect(page).toHaveURL(/\/auth/)
  // Session cleared: protected pages redirect to sign in.
  await page.goto('/orders')
  await expect(page).toHaveURL(/\/auth/)
})
