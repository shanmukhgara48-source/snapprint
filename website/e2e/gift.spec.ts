import { test, expect } from '@playwright/test'
import { mockApi, json } from './helpers'

const CART = [
  {
    key: 'classic-photo-prints:6x4',
    productId: 'classic-photo-prints',
    size: '6x4',
    units: 1,
  },
]

const ADDRESS = {
  id: 'addr_1',
  full_address: 'Test User, 1 Test Road, Karnataka',
  city: 'Bengaluru',
  pincode: '560001',
  is_default: true,
}

function quoteMock(route: any) {
  const body = route.request().postDataJSON() ?? {}
  const gift = body.gift_wrap === true
  // Distinctive fee (not the real 49) so assertions can't collide with the
  // static delivery-option labels rendered on the same page.
  return json(route, {
    items: [],
    subtotal: 299,
    delivery_charge: 0,
    gift_wrap_charge: gift ? 79 : 0,
    discount: 0,
    total: gift ? 378 : 299,
    coupon_applied: false,
    delivery_options: [],
  })
}

// Test 21: gift wrap toggle requotes with the server fee.
test('checkout gift wrap adds the server fee to the total', async ({
  page,
}) => {
  // NOTE: addInitScript functions are stringified — values must be passed
  // as an argument, closure references (CART) do not cross into the page.
  await page.addInitScript((cart) => {
    localStorage.setItem('snapprint-auth-token', 'test-jwt-token')
    localStorage.setItem('snapprint-plan-v1', JSON.stringify(cart))
  }, CART)
  await mockApi(page, {
    '/addresses': (route: any) => json(route, [ADDRESS]),
    '/cart/calculate': quoteMock,
  })

  await page.goto('/checkout')
  // Gift section animates in on scroll (Reveal) — bring it into view first.
  await page
    .getByRole('heading', { name: /gift wrap/i })
    .scrollIntoViewIfNeeded()
  await expect(
    page.getByRole('heading', { name: /gift wrap/i }),
  ).toBeVisible()

  // No gift charge before opting in.
  await expect(page.getByText('🎁 Gift wrap').first()).toBeHidden()

  await page.getByRole('checkbox', { name: /wrap this order as a gift/i }).check()
  await expect(page.getByLabel(/gift message/i)).toBeVisible()
  await expect(page.getByText('🎁 Gift wrap').first()).toBeVisible()
  await expect(page.getByText('₹79').first()).toBeVisible()
})

// Test 22: gift choice + message flow through to payment.
test('gift wrap and message reach the payment summary', async ({ page }) => {
  await page.addInitScript((cart) => {
    localStorage.setItem('snapprint-auth-token', 'test-jwt-token')
    localStorage.setItem('snapprint-plan-v1', JSON.stringify(cart))
  }, CART)
  await mockApi(page, {
    '/addresses': (route: any) => json(route, [ADDRESS]),
    '/cart/calculate': quoteMock,
  })

  await page.goto('/checkout')
  const giftBox = page.getByRole('checkbox', { name: /wrap this order as a gift/i })
  await giftBox.scrollIntoViewIfNeeded()
  await giftBox.check()
  await page.getByLabel(/gift message/i).fill('Happy birthday!')

  await page.getByLabel(/^email/i).fill('customer@example.org')
  await page.getByLabel(/phone \(10-digit/i).fill('9876543210')
  await page.getByLabel(/first name/i).fill('Test')
  await page.getByLabel(/last name/i).fill('Customer')
  await page.getByLabel(/^address/i).fill('1 Test Road, Indiranagar')
  await page.getByLabel(/^city/i).fill('Bengaluru')
  await page.getByLabel(/^state/i).fill('Karnataka')
  await page.getByLabel(/pin code/i).fill('560038')
  await page.getByRole('button', { name: /proceed to payment/i }).click()

  await expect(page).toHaveURL(/\/payment/)
  await expect(page.getByText('🎁 Gift wrap').first()).toBeVisible()
  await expect(page.getByText('₹378').first()).toBeVisible()
})
