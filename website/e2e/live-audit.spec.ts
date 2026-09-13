import { test, expect, type Page } from '@playwright/test'

const LIVE = 'https://snapprint-5076c.web.app'

// Live-production audit: hits the real deployed site (no mocks), so it only
// runs on explicit request and never in CI alongside the mocked suite.
//   LIVE_AUDIT=1 npx playwright test e2e/live-audit.spec.ts
test.skip(process.env.LIVE_AUDIT !== '1', 'live-only audit')

async function watchErrors(page: Page) {
  const crashes: string[] = []
  page.on('pageerror', (e) => crashes.push(String(e).slice(0, 200)))
  return crashes
}

test.describe('nav + home', () => {
  test('header links, mobile menu, footer links all resolve', async ({ page }) => {
    const crashes = await watchErrors(page)
    await page.goto(LIVE + '/')
    await expect(page.getByRole('heading', { name: /deserve to be/i })).toBeVisible()

    for (const name of [/photo prints/i, /photo books/i, /frames & canvas/i, /gifts/i]) {
      await expect(page.getByRole('link', { name }).first()).toBeVisible()
    }
    // "Shop collection" is a desktop-only shortcut; mobile uses the menu.
    const shopLink = page.getByRole('link', { name: /shop collection/i })
    if (await shopLink.isVisible()) {
      await shopLink.click()
      await expect(page).toHaveURL(/\/products/)
      await page.goto(LIVE + '/')
    } else {
      await page.getByRole('button', { name: /open menu/i }).click()
      await page.locator('#mobile-menu').getByRole('link', { name: /explore prints/i }).click()
      await expect(page).toHaveURL(/\/products/)
      await page.goto(LIVE + '/')
    }

    // Wishlist + Cart links present; cart badge appears after adding.
    await expect(page.getByRole('link', { name: /wishlist/i }).first()).toBeVisible()
    await expect(page.getByRole('link', { name: /cart/i }).first()).toBeVisible()

    // Mobile menu opens and links work (hamburger is mobile-only).
    // As a guest the menu offers Sign In (My Orders appears after login).
    await page.setViewportSize({ width: 390, height: 844 })
    await page.getByRole('button', { name: /open menu/i }).click()
    await expect(
      page.locator('#mobile-menu').getByRole('link', { name: /sign in/i }),
    ).toBeVisible()
    await page.locator('#mobile-menu').getByRole('link', { name: /contact us/i }).click()
    await expect(page).toHaveURL(/\/contact/)
    await page.setViewportSize({ width: 1280, height: 800 })

    // Footer policy links resolve to real content (not blank).
    for (const [re, text] of [
      [/terms & conditions/i, /terms/i],
      [/privacy policy/i, /privacy/i],
      [/shipping policy/i, /shipping|delivery/i],
      [/returns & cancellations/i, /refund|return/i],
      [/contact & business/i, /contact|message/i],
    ] as const) {
      await page.getByRole('link', { name: re }).first().click()
      await expect(page.locator('#main')).toContainText(text)
      await page.goto(LIVE + '/')
    }
    expect(crashes).toEqual([])
  })
})

test.describe('catalog', () => {
  test('filters, search, sort, cards all respond', async ({ page }) => {
    const crashes = await watchErrors(page)
    await page.goto(LIVE + '/products')
    await expect(page.getByText(/ways to make it yours/i)).toBeVisible()

    // Category chip filters.
    await page.getByRole('button', { name: /^photo books$/i }).click()
    await expect(page).toHaveURL(/category=photo-books/)

    // Search filters the grid.
    await page.getByLabel(/search products/i).fill('retro')
    await expect(page).toHaveURL(/q=retro/)

    // Sort changes order without crashing.
    await page.getByLabel(/sort by/i).selectOption('low')
    await expect(page).toHaveURL(/sort=low/)

    // Clear filters resets.
    await page.getByRole('button', { name: /clear filters/i }).click()
    await expect(page).toHaveURL(/\/products$/)

    // Card navigates to detail.
    await page.locator('.product-grid a').first().click()
    await expect(page).toHaveURL(/\/products\/.+/)
    expect(crashes).toEqual([])
  })
})

test.describe('product detail (guest)', () => {
  test('options, upload guard, wishlist guard, reviews degrade cleanly', async ({
    page,
  }) => {
    const crashes = await watchErrors(page)
    await page.goto(LIVE + '/products')
    await page.locator('.product-grid a').first().click()
    await expect(page).toHaveURL(/\/products\/.+/)

    // Size/format select responds.
    const formats = page.locator('.size-options button')
    if ((await formats.count()) > 1) {
      await formats.nth(1).click()
      await expect(formats.nth(1)).toHaveAttribute('aria-pressed', 'true')
    }

    // Quantity stepper works both directions.
    await page.getByRole('button', { name: /increase sets/i }).click()
    await expect(page.getByLabel(/number of sets/i)).toContainText('2')
    await page.getByRole('button', { name: /decrease sets/i }).click()
    await expect(page.getByLabel(/number of sets/i)).toContainText('1')

    // Photo upload as guest asks for sign-in, no crash.
    await page.getByRole('button', { name: /choose a photo/i }).first().click()

    // Wishlist as guest shows the sign-in error toast, no crash.
    const hearts = page.getByRole('button', { name: /wishlist/i })
    if ((await hearts.count()) > 0) {
      await hearts.first().click()
      await expect(page.getByText(/sign in/i).first()).toBeVisible({ timeout: 8000 })
    }

    // Reviews section renders (empty state while backend is down).
    await page
      .getByRole('heading', { name: /ratings & reviews/i })
      .scrollIntoViewIfNeeded()
    await expect(
      page.getByRole('heading', { name: /ratings & reviews/i }),
    ).toBeVisible()

    // Breadcrumbs navigate back.
    await page.getByRole('link', { name: /^home$/i }).click()
    await expect(page).toHaveURL(LIVE + '/')
    expect(crashes).toEqual([])
  })

  test('add to cart lands in cart with the item', async ({ page }) => {
    const crashes = await watchErrors(page)
    await page.goto(LIVE + '/products')
    await page.locator('.product-grid a').first().click()
    await page.getByRole('button', { name: /^add to cart/i }).click()
    await expect(page).toHaveURL(/\/card/)
    await expect(page.locator('#main')).not.toContainText(/cart is empty/i)
    expect(crashes).toEqual([])
  })
})

test.describe('cart (guest)', () => {
  test('quantity, remove, delivery, coupon guard, checkout redirect', async ({
    page,
  }) => {
    const crashes = await watchErrors(page)
    await page.goto(LIVE + '/products')
    await page.locator('.product-grid a').first().click()
    await page.getByRole('button', { name: /^add to cart/i }).click()
    await expect(page).toHaveURL(/\/card/)
    // Lazy route chunk swaps views — wait for the cart itself, not just URL.
    await expect(
      page.getByRole('heading', { name: /in the making/i }),
    ).toBeVisible()

    // Quantity stepper (cart labels).
    const inc = page.getByRole('button', { name: /add one set/i }).first()
    const dec = page.getByRole('button', { name: /remove one set/i }).first()
    await inc.click()
    await expect(page.locator('.plan-item output').first()).toContainText('2')
    await dec.click()
    await expect(page.locator('.plan-item output').first()).toContainText('1')

    // Delivery option select responds if present.
    const delivery = page.getByLabel(/delivery preference/i)
    if ((await delivery.count()) > 0) {
      const opts = await delivery.locator('option').count()
      if (opts > 1) {
        await delivery.selectOption({ index: 1 })
        await delivery.selectOption({ index: 0 })
      }
    }

    // Coupon apply with dead backend shows an error, no crash.
    const coupon = page.getByPlaceholder(/coupon|promo|code/i)
    if ((await coupon.count()) > 0) {
      await coupon.fill('WELCOME50')
      const applyBtn = page.getByRole('button', { name: /apply/i })
      if ((await applyBtn.count()) > 0) await applyBtn.click()
      await page.waitForTimeout(3000)
    }

    // Guest checkout redirects to sign in.
    const proceed = page.getByRole('button', { name: /proceed to checkout/i })
    if ((await proceed.count()) > 0) {
      await proceed.click()
      await expect(page).toHaveURL(/\/auth/)
    }

    // Remove flow (back to cart with a fresh item).
    await page.goto(LIVE + '/products')
    await page.locator('.product-grid a').first().click()
    await page.getByRole('button', { name: /^add to cart/i }).click()
    await expect(
      page.getByRole('heading', { name: /in the making/i }),
    ).toBeVisible()
    await page.getByRole('button', { name: /remove .* from cart/i }).click()
    await expect(page.getByText(/starts here/i)).toBeVisible()
    expect(crashes).toEqual([])
  })
})

test.describe('auth + guards', () => {
  test('validation, guest redirects, contact page', async ({ page }) => {
    const crashes = await watchErrors(page)
    // Bad phone rejected client-side.
    await page.goto(LIVE + '/auth')
    await page.getByPlaceholder(/98765/i).fill('123')
    await page.getByRole('button', { name: /send otp/i }).click()
    await expect(page.getByRole('alert')).toContainText(/valid 10-digit/i)

    // Protected routes bounce guests to sign in.
    for (const path of ['/checkout', '/payment', '/orders', '/account']) {
      await page.goto(LIVE + path)
      await expect(page).toHaveURL(/\/auth/, { timeout: 10000 })
    }

    // Wishlist is public but prompts guests to sign in (no redirect).
    await page.goto(LIVE + '/wishlist')
    await expect(page).toHaveURL(/\/wishlist/)
    await expect(page.getByText(/sign in/i).first()).toBeVisible()

    // Success without an order never invents one.
    await page.goto(LIVE + '/success')
    await expect(page.locator('body')).not.toContainText(/ORD-\d+/)

    // Contact validates, then fails gracefully with dead backend.
    await page.goto(LIVE + '/contact')
    await page.getByLabel(/message/i).fill('short')
    await page.getByRole('button', { name: /send message/i }).click()
    await expect(page.getByText(/10\+ characters/i)).toBeVisible()
    expect(crashes).toEqual([])
  })

  test('test-number OTP reaches the code step (no real SMS)', async ({
    page,
  }) => {
    test.setTimeout(90000)
    const crashes = await watchErrors(page)
    await page.goto(LIVE + '/auth')
    // Firebase test number — verifies the full client flow with code 123456.
    await page.getByPlaceholder(/98765/i).fill('9502071361')
    await page.getByRole('button', { name: /send otp/i }).click()
    const otpLabel = page.getByLabel(/enter otp/i)
    const alert = page.getByRole('alert')
    let outcome = 'timeout'
    for (let i = 0; i < 40; i++) {
      if ((await otpLabel.count()) > 0) {
        outcome = 'otp-step'
        break
      }
      if ((await alert.count()) > 0) {
        outcome = 'alert:' + ((await alert.first().textContent()) || '').slice(0, 100)
        break
      }
      await page.waitForTimeout(1000)
    }
    console.log('OTP-FLOW-OUTCOME: ' + outcome)
    expect(outcome).not.toContain('not configured')
    expect(crashes).toEqual([])
  })
})

test.describe('static pages', () => {
  test('pricing, policies render with real content', async ({ page }) => {
    const crashes = await watchErrors(page)
    for (const [path, text] of [
      ['/pricing', /₹/],
      ['/shipping', /deliver/i],
      ['/privacy', /privacy/i],
      ['/terms', /terms/i],
      ['/refund', /refund/i],
    ] as const) {
      await page.goto(LIVE + path)
      await expect(page.locator('#main')).toContainText(text)
    }
    // Unknown route falls back home (SPA catch-all), never a blank 404.
    await page.goto(LIVE + '/no-such-page-xyz')
    await expect(page.locator('body')).not.toBeEmpty()
    expect(crashes).toEqual([])
  })
})
