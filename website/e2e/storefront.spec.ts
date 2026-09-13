import { test, expect } from '@playwright/test'
import { mockApi, json, PRODUCT } from './helpers'

const SALE_PRODUCT = {
  ...PRODUCT,
  compare_at_price: 499,
  is_bestseller: true,
  sku: 'PRINT-6X4-001',
}

const REVIEW = {
  id: 'rev_1',
  product_id: PRODUCT.id,
  rating: 5,
  title: 'Superb prints',
  body: 'Loved the quality.',
  reviewer: '+91******42',
  verified_purchase: true,
  helpful_count: 3,
  voted: false,
  seller_response: 'Thanks for shopping with SnapPrint!',
  created_at: new Date().toISOString(),
}

const SUMMARY = {
  product_id: PRODUCT.id,
  avg_rating: 4.5,
  review_count: 2,
  histogram: { '1': 0, '2': 0, '3': 0, '4': 1, '5': 1 },
}

function detailMocks(extra: Record<string, (route: any) => unknown> = {}) {
  return {
    '/products/suggest': (route: any) => json(route, []),
    '/products/ratings': (route: any) => json(route, {}),
    '/products/classic-photo-prints/reviews/summary': (route: any) =>
      json(route, SUMMARY),
    '/products/classic-photo-prints/reviews': (route: any) =>
      json(route, [REVIEW]),
    '/products/classic-photo-prints/bought-together': (route: any) =>
      json(route, []),
    '/wishlist/ids': (route: any) => json(route, { product_ids: [] }),
    '/products': (route: any) =>
      json(route, { items: [SALE_PRODUCT], total: 1, page: 1, limit: 20 }),
    '/products/*': (route: any) => json(route, SALE_PRODUCT),
    ...extra,
  }
}

// Test 13: sale pricing + bestseller badge render on cards and detail.
test('sale badges and MRP show on listing and detail', async ({ page }) => {
  await mockApi(page, detailMocks())
  await page.goto('/products')
  await expect(page.getByText('Bestseller').first()).toBeVisible()
  await expect(page.getByText(/% off/).first()).toBeVisible()

  await page.goto('/products/classic-photo-prints')
  await expect(page.getByText(/M\.R\.P\./).first()).toBeVisible()
  await expect(page.getByText('40% off').first()).toBeVisible()
})

// Test 14: ratings summary + verified review + seller response render.
test('product detail shows ratings, verified review and seller reply', async ({
  page,
}) => {
  await mockApi(page, detailMocks())
  await page.goto('/products/classic-photo-prints')
  await expect(
    page.getByRole('heading', { name: /ratings & reviews/i }),
  ).toBeVisible()
  await expect(page.getByText('Verified Purchase').first()).toBeVisible()
  await expect(page.getByText(/Response from SnapPrint/).first()).toBeVisible()
  await expect(page.getByText('Superb prints').first()).toBeVisible()
})

// Test 15: helpful vote updates the count.
test('helpful vote registers on a review', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('snapprint-auth-token', 'test-jwt-token')
  })
  await mockApi(
    page,
    detailMocks({
      '/reviews/rev_1/helpful': (route: any) =>
        json(route, { id: 'rev_1', helpful_count: 4, voted: true }),
    }),
  )
  await page.goto('/products/classic-photo-prints')
  await page.getByRole('button', { name: /helpful/i }).first().click()
  await expect(page.getByRole('button', { name: /helpful \(4\)/i })).toBeVisible()
})

// Test 16: signed-in customer can submit a review.
test('customer can submit a review', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('snapprint-auth-token', 'test-jwt-token')
  })
  let posted: any = null
  const mine = { ...REVIEW, id: 'rev_mine', title: 'My headline', helpful_count: 0, voted: false, seller_response: null }
  await mockApi(
    page,
    detailMocks({
      '/products/classic-photo-prints/reviews': (route: any) => {
        if (route.request().method() === 'POST') {
          posted = route.request().postDataJSON()
          return json(route, mine, 201)
        }
        return json(route, [REVIEW, mine])
      },
    }),
  )
  await page.goto('/products/classic-photo-prints')
  await page.getByPlaceholder('Headline').fill('My headline')
  await page
    .getByPlaceholder(/what did you like/i)
    .fill('Great colours and fast delivery.')
  await page.getByRole('button', { name: /submit review/i }).click()
  await expect(page.getByText('Thanks! Your review is live.')).toBeVisible()
  expect(posted.rating).toBe(5)
  expect(posted.title).toBe('My headline')
})

// Test 17: wishlist heart saves and the wishlist page lists it.
test('wishlist heart saves and lists the product', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('snapprint-auth-token', 'test-jwt-token')
  })
  let saved = false
  await mockApi(
    page,
    detailMocks({
      '/wishlist/ids': (route: any) =>
        json(route, { product_ids: saved ? [PRODUCT.id] : [] }),
      '/wishlist/classic-photo-prints': (route: any) => {
        if (route.request().method() === 'POST') {
          saved = true
          return json(route, { product_id: PRODUCT.id, saved: true }, 201)
        }
        saved = false
        return json(route, {}, 204)
      },
      '/wishlist': (route: any) => json(route, saved ? [SALE_PRODUCT] : []),
    }),
  )
  await page.goto('/products/classic-photo-prints')
  await page.getByRole('button', { name: /add to wishlist/i }).click()
  await expect(
    page.getByRole('button', { name: /remove from wishlist/i }),
  ).toBeVisible()

  await page.goto('/wishlist')
  await expect(page.getByText('Classic Photo Prints').first()).toBeVisible()
})

// Test 18: search autocomplete suggests and navigates.
test('search autocomplete suggests products', async ({ page }) => {
  await mockApi(
    page,
    detailMocks({
      '/products/suggest': (route: any) =>
        json(route, [
          {
            id: PRODUCT.id,
            name: PRODUCT.name,
            category: PRODUCT.category,
            base_price: PRODUCT.base_price,
            image: null,
          },
        ]),
    }),
  )
  await page.goto('/products')
  await page.getByLabel(/search products/i).fill('clas')
  await expect(page.getByRole('option', { name: /classic photo prints/i })).toBeVisible()
  await page.getByRole('option', { name: /classic photo prints/i }).click()
  await expect(page).toHaveURL(/\/products\/classic-photo-prints/)
})

// Test 19: frequently bought together renders from history.
test('frequently bought together renders', async ({ page }) => {
  await mockApi(
    page,
    detailMocks({
      '/products/classic-photo-prints/bought-together': (route: any) =>
        json(route, [{ ...PRODUCT, id: 'square-photo-prints', name: 'Square Photo Prints' }]),
    }),
  )
  await page.goto('/products/classic-photo-prints')
  await expect(
    page.getByRole('heading', { name: /frequently bought together/i }),
  ).toBeVisible()
  await expect(page.getByText('Square Photo Prints').first()).toBeVisible()
})

// Test 20: customer can request a return from My Orders.
test('my orders supports return requests', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('snapprint-auth-token', 'test-jwt-token')
  })
  const confirmedOrder = {
    id: 'ord_return123456',
    total_price: 299,
    status: 'confirmed',
    created_at: new Date().toISOString(),
    item_count: 1,
    delivery_address: '1 Test St, Bengaluru - 560001',
    estimated_delivery: null,
    tracking_events: [],
  }
  let posted: any = null
  await mockApi(page, {
    '/orders/me': (route: any) => json(route, [confirmedOrder]),
    '/orders/*': (route: any) => json(route, confirmedOrder),
    '/returns/me': (route: any) => json(route, []),
    '/returns': (route: any) => {
      posted = route.request().postDataJSON()
      return json(route, { id: 'ret_1', status: 'requested', reason: posted.reason }, 201)
    },
  })
  await page.goto('/orders')
  await page.getByRole('button', { name: /request return/i }).click()
  await page.getByLabel(/reason/i).selectOption('damaged')
  await page.getByRole('button', { name: /submit return request/i }).click()
  await expect(page.getByText(/return requested/i).first()).toBeVisible()
  expect(posted.order_id).toBe('ord_return123456')
  expect(posted.reason).toBe('damaged')
})
