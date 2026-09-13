import { API_BASE, isDemoOtpEnabled, isDevBypassEnabled } from '../config/env'

const TOKEN_STORAGE_KEY = 'snapprint-auth-token'
const REQUEST_TIMEOUT_MS = 20000

let _authToken: string | null = null

function readStoredToken(): string | null {
  try {
    return localStorage.getItem(TOKEN_STORAGE_KEY)
  } catch {
    return null
  }
}

// Restore session on module load so refresh keeps the user signed in.
if (typeof localStorage !== 'undefined') {
  _authToken = readStoredToken()
}

export function setAuthToken(token: string | null) {
  _authToken = token
  try {
    if (token) localStorage.setItem(TOKEN_STORAGE_KEY, token)
    else localStorage.removeItem(TOKEN_STORAGE_KEY)
  } catch {
    /* storage unavailable — session lasts for this tab only */
  }
}

export function getAuthToken(): string | null {
  if (!_authToken) _authToken = readStoredToken()
  return _authToken
}

export function clearAuthToken() {
  setAuthToken(null)
}

/** Normalised API error — safe to display (never leaks stack traces). */
export class ApiError extends Error {
  status: number
  constructor(message: string, status: number) {
    super(message)
    this.name = 'ApiError'
    this.status = status
  }
}

function friendlyMessage(status: number, detail: string): string {
  // Never surface raw browser-internal errors (e.g. Safari's "The string did
  // not match the expected pattern") — they mean nothing to customers.
  if (
    /did not match the expected pattern|not correctly encoded|parameter 1 is not of type|invalid enum|not a valid/i.test(
      detail,
    )
  ) {
    console.error('[api] browser-level error surfaced as:', detail)
    return 'Something went wrong in the browser. Please reload the page and try again.'
  }  if (detail && detail !== `API error: ${status}`) return detail
  if (status === 0) return 'You appear to be offline. Check your connection and try again.'
  if (status === 401) return 'Your session has expired. Please sign in again.'
  if (status === 403) return 'You do not have permission to do that.'
  if (status === 404) return 'We could not find what you asked for.'
  if (status === 409) return 'This conflicts with an existing record. Please refresh and try again.'
  if (status === 413) return 'That file is too large. Please choose a smaller one.'
  if (status === 415) return 'That file type is not supported.'
  if (status === 429) return 'Too many attempts. Please wait a moment and try again.'
  if (status >= 500) return 'Something went wrong on our side. Please try again shortly.'
  return 'Something went wrong. Please try again.'
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    // Purchase-channel attribution: backend stores this on the order as
    // source="website" so the admin dashboard can show per-channel sales
    // while stock decrements centrally (10 → 9 → 8 across app + web).
    'X-Client-Source': 'website',
    ...((options.headers as Record<string, string>) || {}),
  }
  const token = getAuthToken()
  if (token) headers['Authorization'] = `Bearer ${token}`

  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS)
  let res: Response
  try {
    res = await fetch(`${API_BASE}${path}`, {
      ...options,
      headers,
      signal: controller.signal,
    })
  } catch (err: any) {
    clearTimeout(timeout)
    if (err?.name === 'AbortError') {
      throw new ApiError('The request timed out. Please try again.', 0)
    }
    throw new ApiError(
      'You appear to be offline. Check your connection and try again.',
      0,
    )
  } finally {
    clearTimeout(timeout)
  }

  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    const detail =
      typeof body?.detail === 'string' ? body.detail : `API error: ${res.status}`
    // Expired/invalid session: drop the stale token so guards redirect.
    if (res.status === 401) clearAuthToken()
    throw new ApiError(friendlyMessage(res.status, detail), res.status)
  }

  // 204 No Content
  if (res.status === 204) return undefined as T
  // Guard against misrouted responses (e.g. a hosting fallback serving HTML
  // for /api on a misconfigured deploy) — never hand a parse error to the UI.
  const contentType = res.headers.get('content-type') || ''
  if (!contentType.includes('application/json')) {
    throw new ApiError(
      'The server returned an unexpected response. Please try again shortly.',
      res.status,
    )
  }
  try {
    return await res.json()
  } catch {
    throw new ApiError(
      'The server returned an unreadable response. Please try again shortly.',
      res.status,
    )
  }
}

export const api = {
  getProducts(category?: string, page?: number) {
    const params = new URLSearchParams()
    if (category) params.set('category', category)
    if (page) params.set('page', String(page))
    const q = params.toString()
    return request<{ items: any[]; total: number; page: number; limit: number }>(
      `/products${q ? '?' + q : ''}`,
    )
  },

  getProduct(id: string) {
    return request<any>(`/products/${id}`)
  },

  getOrders() {
    return request<any[]>('/orders/me')
  },

  getOrder(id: string) {
    return request<any>(`/orders/${id}`)
  },

  getAddresses() {
    return request<any[]>('/addresses')
  },

  createAddress(payload: {
    full_address: string
    city: string
    pincode: string
    is_default?: boolean
  }) {
    return request<any>('/addresses', {
      method: 'POST',
      body: JSON.stringify(payload),
    })
  },

  async uploadImage(
    file: File,
    onProgress?: (percent: number) => void,
  ) {
    const formData = new FormData()
    formData.append('file', file)
    onProgress?.(10)
    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), 90000)
    try {
      const res = await fetch(`${API_BASE}/upload/image`, {
        method: 'POST',
        headers: getAuthToken()
          ? { Authorization: `Bearer ${getAuthToken()}` }
          : {},
        body: formData,
        signal: controller.signal,
      })
      if (!res.ok) {
        const body = await res.json().catch(() => ({}))
        const detail =
          typeof body?.detail === 'string'
            ? body.detail
            : `Upload error: ${res.status}`
        if (res.status === 401) clearAuthToken()
        throw new ApiError(friendlyMessage(res.status, detail), res.status)
      }
      onProgress?.(100)
      const uploadType = res.headers.get('content-type') || ''
      if (!uploadType.includes('application/json')) {
        throw new ApiError(
          'The server returned an unexpected response. Please try again shortly.',
          res.status,
        )
      }
      return res.json()
    } catch (err: any) {
      if (err instanceof ApiError) throw err
      if (err?.name === 'AbortError') {
        throw new ApiError('Upload timed out. Please try again.', 0)
      }
      throw new ApiError(
        'Upload failed. Check your connection and try again.',
        0,
      )
    } finally {
      clearTimeout(timeout)
    }
  },

  /**
   * DEV/DEMO-ONLY bypass. Allowed in development builds, or in any build
   * while explicit demo mode (VITE_DEMO_OTP) is switched on. Production
   * checkout must use verifyFirebase() with a real Firebase ID token —
   * empty VITE_DEMO_OTP before launch to close this path entirely.
   */
  async devLogin(phone: string, secret: string) {
    if (!isDevBypassEnabled() && !isDemoOtpEnabled()) {
      throw new ApiError(
        'Dev login is disabled in this build. Please sign in with OTP.',
        403,
      )
    }
    const data = await request<{ dev_token: string; user: any }>(
      '/auth/dev-login',
      {
        method: 'POST',
        body: JSON.stringify({ phone, secret }),
      },
    )
    setAuthToken(data.dev_token)
    return data
  },
  async verifyFirebase(idToken: string, phone: string) {
    const data = await request<{ access_token: string; user: any }>(
      '/auth/verify',
      {
        method: 'POST',
        body: JSON.stringify({ id_token: idToken, phone, role: 'customer' }),
      },
    )
    setAuthToken(data.access_token)
    return data
  },

  getMe() {
    return request<any>('/auth/me')
  },

  deleteAccount() {
    return request<void>('/auth/me', { method: 'DELETE' })
  },

  submitContact(payload: {
    name: string
    email: string
    subject: string
    message: string
  }) {
    return request<{ ok: boolean }>('/contact', {
      method: 'POST',
      body: JSON.stringify(payload),
    })
  },

  async createRazorpayOrder(
    items: Array<{ product_id: string; qty: number; size: string; image_url?: string }>,
    addressId: string,
    deliveryType: string,
    couponCode?: string,
  ) {
    const data = await request<{
      razorpay_order_id: string
      amount: number
      currency: string
      order_id: string
    }>('/payments/razorpay/order', {
      method: 'POST',
      body: JSON.stringify({
        items,
        address_id: addressId,
        delivery_type: deliveryType,
        coupon_code: couponCode || undefined,
      }),
    })
    return data
  },

  async verifyRazorpayPayment(
    razorpayPaymentId: string,
    razorpayOrderId: string,
    razorpaySignature: string,
  ) {
    return request<{ ok: boolean; payment_id: string; order_id?: string }>(
      '/payments/razorpay/verify',
      {
        method: 'POST',
        body: JSON.stringify({
          razorpay_payment_id: razorpayPaymentId,
          razorpay_order_id: razorpayOrderId,
          razorpay_signature: razorpaySignature,
        }),
      },
    )
  },

  async calculateCart(
    items: Array<{
      product_id: string
      qty: number
      size: string
      image_url?: string
    }>,
    deliveryType: string,
    couponCode?: string,
  ) {
    return request<{
      items: any[]
      subtotal: number
      delivery_charge: number
      discount: number
      total: number
      coupon_applied: boolean
      delivery_options: any[]
    }>('/cart/calculate', {
      method: 'POST',
      body: JSON.stringify({
        items,
        delivery_type: deliveryType,
        coupon_code: couponCode || undefined,
      }),
    })
  },

  async placeOrder(payload: {
    items: Array<{
      product_id: string
      qty: number
      size: string
      image_url?: string
      price: number
    }>
    address_id: string
    delivery_type: string
    coupon_code?: string
    razorpay_payment_id?: string
    razorpay_order_id?: string
    razorpay_signature?: string
    source?: string
  }) {
    return request<{ id: string; total_price: number; status: string }>(
      '/orders',
      {
        method: 'POST',
        body: JSON.stringify({ source: 'website', ...payload }),
      },
    )
  },

  // ── Amazon-parity: reviews, wishlist, returns, search ──

  getReviewSummary(productId: string) {
    return request<{
      product_id: string
      avg_rating: number
      review_count: number
      histogram: Record<string, number>
    }>(`/products/${productId}/reviews/summary`).then((s) => {
      // Never let a malformed payload crash the product page — the reviews
      // section degrades to empty instead (a greedy route mock in tests once
      // returned a product here).
      if (!s || typeof s.avg_rating !== 'number' || typeof s.review_count !== 'number') {
        throw new ApiError('The server returned an unreadable response. Please try again shortly.', 200)
      }
      return s
    })
  },

  getReviews(productId: string, sort: 'helpful' | 'recent' = 'helpful') {
    return request<
      Array<{
        id: string
        product_id: string
        rating: number
        title: string
        body: string
        reviewer: string
        verified_purchase: boolean
        helpful_count: number
        voted: boolean
        seller_response: string | null
        created_at: string
      }>
    >(`/products/${productId}/reviews?sort=${sort}`).then((r) =>
      Array.isArray(r) ? r : [],
    )
  },

  createReview(productId: string, payload: { rating: number; title: string; body: string }) {
    return request<any>(`/products/${productId}/reviews`, {
      method: 'POST',
      body: JSON.stringify(payload),
    })
  },

  voteHelpful(reviewId: string) {
    return request<{ id: string; helpful_count: number; voted: boolean }>(
      `/reviews/${reviewId}/helpful`,
      { method: 'POST' },
    )
  },

  getBatchRatings(ids: string[]) {
    if (ids.length === 0) return Promise.resolve({} as Record<string, { avg: number; count: number }>)
    return request<Record<string, { avg: number; count: number }>>('/products/ratings', {
      method: 'POST',
      body: JSON.stringify({ ids }),
    }).then((r) => (r && typeof r === 'object' ? r : {}))
  },

  getBoughtTogether(productId: string) {
    return request<any[]>(`/products/${productId}/bought-together`).then((r) =>
      Array.isArray(r) ? r : [],
    )
  },

  suggestProducts(q: string) {
    return request<Array<{ id: string; name: string; category: string; base_price: number; image: string | null }>>(
      `/products/suggest?q=${encodeURIComponent(q)}`,
    ).then((r) => (Array.isArray(r) ? r : []))
  },

  getWishlist() {
    return request<any[]>('/wishlist').then((r) => (Array.isArray(r) ? r : []))
  },

  getWishlistIds() {
    return request<{ product_ids: string[] }>('/wishlist/ids').then((r) => ({
      product_ids: Array.isArray(r?.product_ids) ? r.product_ids : [],
    }))
  },

  addToWishlist(productId: string) {
    return request<{ product_id: string; saved: boolean }>(`/wishlist/${productId}`, {
      method: 'POST',
    })
  },

  removeFromWishlist(productId: string) {
    return request<void>(`/wishlist/${productId}`, { method: 'DELETE' })
  },

  requestReturn(orderId: string, reason: string, details?: string) {
    return request<{
      id: string
      status: string
      reason: string
    }>('/returns', {
      method: 'POST',
      body: JSON.stringify({ order_id: orderId, reason, details }),
    })
  },

  getMyReturns() {
    return request<
      Array<{
        id: string
        order_id: string
        reason: string
        status: string
        admin_note: string | null
        created_at: string
      }>
    >('/returns/me').then((r) => (Array.isArray(r) ? r : []))
  },
}
