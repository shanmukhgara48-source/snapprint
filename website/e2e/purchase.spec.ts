import { test, expect } from '@playwright/test'
import { mockApi, json, ORDER } from './helpers'

// Test 5: Auth page validation + states.
test('auth validates phone before sending OTP', async ({ page }) => {
  await page.goto('/auth')
  await expect(
    page.getByRole('heading', { name: /welcome back/i }),
  ).toBeVisible()

  await page.getByPlaceholder(/98765/i).fill('123')
  await page.getByRole('button', { name: /send otp/i }).click()
  await expect(page.getByRole('alert')).toContainText(/valid 10-digit/i)
})

test('auth shows configuration error when Firebase is not configured', async ({
  page,
}) => {
  await page.goto('/auth')
  await page.getByPlaceholder(/98765/i).fill('9876543210')
  await page.getByRole('button', { name: /send otp/i }).click()
  // No Firebase web config in CI → clear message, no silent dev-login.
  await expect(page.getByRole('alert')).toContainText(/not configured/i)
})

// Test 6: Checkout validation blocks bad PIN/phone.
test('checkout blocks invalid PIN and phone', async ({ page }) => {
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
  await mockApi(page, {
    '/addresses': (route) => json(route, []),
    '/cart/calculate': (route) =>
      json(route, {
        items: [],
        subtotal: 299,
        delivery_charge: 0,
        discount: 0,
        total: 299,
        coupon_applied: false,
        delivery_options: [],
      }),
  })
  await page.goto('/checkout')
  await page.getByLabel(/pin code/i).fill('12')
  await page.getByLabel(/phone \(10-digit/i).fill('123')
  await page
    .getByRole('button', { name: /proceed to payment/i })
    .click()
  await expect(page.getByText(/valid 6-digit pin/i)).toBeVisible()
  await expect(page.getByText(/valid 10-digit indian mobile/i)).toBeVisible()
})

// Tests 7–10: payment verification → real order → success with backend id.
test('success requires a real backend order (no fake ids)', async ({
  page,
}) => {
  await page.addInitScript(() => {
    localStorage.setItem('snapprint-auth-token', 'test-jwt-token')
  })
  await mockApi(page, {
    '/orders/*': (route) => json(route, ORDER),
    '/orders/me': (route) => json(route, [ORDER]),
  })

  // No ?order param → redirected away, never a generated ORD- number.
  await page.goto('/success')
  await expect(page).not.toHaveURL(/\/success$/)
  await expect(page.locator('body')).not.toContainText(/ORD-\d+/)

  // Real order id → backend order displayed.
  await page.goto('/success?order=ord_real123456')
  await expect(page.getByText(/payment successful/i)).toBeVisible()
  await expect(page.getByText(/#ORD_/i)).toBeVisible()
})

// Test 11: My Orders lists the created order.
test('my orders displays backend orders', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('snapprint-auth-token', 'test-jwt-token')
  })
  await mockApi(page, {
    '/orders/me': (route) => json(route, [ORDER]),
    '/orders/*': (route) => json(route, ORDER),
  })
  await page.goto('/orders')
  await expect(page.getByText(/#ORD_/i).first()).toBeVisible()
})

// Test 12: another customer's order is never visible (backend 404 → error).
test('unauthorized order access shows error, not data', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('snapprint-auth-token', 'test-jwt-token')
  })
  await mockApi(page, {
    '/orders/me': (route) => json(route, []),
    '/orders/*': (route) =>
      route.fulfill({
        status: 404,
        contentType: 'application/json',
        body: JSON.stringify({ detail: 'Order not found' }),
      }),
  })
  await page.goto('/orders/someone-elses-order-id')
  await expect(page.getByRole('alert')).toBeVisible()
  await expect(page.locator('body')).not.toContainText(/ORD-\d+/)
})
