import { useState, useEffect, useCallback, useRef } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { usePrintPlan } from '../context/PrintPlan'
import { formatPrice } from '../data/products'
import { deliveryOptions } from '../data/delivery'
import { api, getAuthToken } from '../services/api'
import { RAZORPAY_KEY_ID } from '../config/env'
import { RazorpayIcon } from '../components/RazorpayIcon'
import { Reveal } from '../components/Reveal'
import { Seo } from '../components/Seo'
import { AntiGravityWrap } from '../components/antiGravity/AntiGravityWrap'
import { useToastOptional } from '../context/Toast'

export function Payment() {
  const { items, checkoutData, clearCart } = usePrintPlan()
  const navigate = useNavigate()
  const toast = useToastOptional()
  const [isProcessing, setIsProcessing] = useState(false)
  const [paymentError, setPaymentError] = useState('')
  const [loading, setLoading] = useState(true)
  const [serverTotal, setServerTotal] = useState<number>(0)
  const [serverSubtotal, setServerSubtotal] = useState<number>(0)
  const [serverDiscount, setServerDiscount] = useState<number>(0)
  const [serverGiftCharge, setServerGiftCharge] = useState<number>(0)
  const [quoteFailed, setQuoteFailed] = useState(false)
  const finalizedRef = useRef(false)

  const deliveryType = checkoutData?.deliveryType || 'free'
  const selectedDelivery =
    deliveryOptions.find((d) => d.type === deliveryType) ??
    deliveryOptions[0]!
  const addressId = checkoutData?.addressId || ''
  const couponCode = checkoutData?.couponCode || ''
  const giftWrap = checkoutData?.giftWrap || false
  const giftMessage = checkoutData?.giftMessage || ''

  // Guard: must arrive here with auth + checkout data + a real address id.
  useEffect(() => {
    async function init() {
      try {
        if (!getAuthToken()) {
          navigate('/auth', { replace: true })
          return
        }
        if (items.length === 0) {
          navigate('/products', { replace: true })
          return
        }
        if (!checkoutData || !addressId) {
          // No verified address — send back to checkout to create one.
          navigate('/checkout', { replace: true })
          return
        }
        const cartItems = items.map((item) => ({
          product_id: item.productId,
          qty: item.units,
          size: item.size,
          ...(item.imageUrl ? { image_url: item.imageUrl } : {}),
        }))
        const quote = await api.calculateCart(
          cartItems,
          deliveryType,
          couponCode || undefined,
          giftWrap,
        )
        setServerTotal(quote.total)
        setServerSubtotal(quote.subtotal)
        setServerDiscount(quote.discount || 0)
        setServerGiftCharge(quote.gift_wrap_charge || 0)
      } catch (err: any) {
        setQuoteFailed(true)
        setPaymentError(
          err?.message ||
            'Could not confirm your order total. Please go back and retry.',
        )
      } finally {
        setLoading(false)
      }
    }
    init()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const initiateRazorpayPayment = useCallback(async () => {
    if (loading || isProcessing || quoteFailed) return
    if (!RAZORPAY_KEY_ID) {
      setPaymentError(
        'Online payment is not configured yet. Please contact support.',
      )
      return
    }
    if (typeof (window as any).Razorpay === 'undefined') {
      setPaymentError(
        'Payment library could not load. Check your connection and retry.',
      )
      return
    }
    setIsProcessing(true)
    setPaymentError('')

    try {
      const cartItems = items.map((item) => ({
        product_id: item.productId,
        qty: item.units,
        size: item.size,
        ...(item.imageUrl ? { image_url: item.imageUrl } : {}),
      }))

      // 1. Server calculates the authoritative amount and creates the
      //    Razorpay order. The browser never decides the amount.
      const orderData = await api.createRazorpayOrder(
        cartItems,
        addressId,
        deliveryType,
        couponCode || undefined,
        giftWrap,
      )

      const options: any = {
        key: RAZORPAY_KEY_ID,
        amount: orderData.amount,
        currency: orderData.currency,
        name: 'SnapPrint',
        description: 'SnapPrint photo order',
        order_id: orderData.razorpay_order_id,
        prefill: {
          name:
            `${checkoutData?.firstName || ''} ${checkoutData?.lastName || ''}`.trim(),
          email: checkoutData?.email || '',
          contact: checkoutData?.phone || '',
        },
        theme: { color: '#966c24' },
        modal: {
          ondismiss: function () {
            setIsProcessing(false)
          },
        },
        handler: async function (response: any) {
          // Guard against double-handler invocation.
          if (finalizedRef.current) return
          try {
            // 2. Backend verifies the Razorpay HMAC signature + capture.
            const verifyResult = await api.verifyRazorpayPayment(
              response.razorpay_payment_id,
              response.razorpay_order_id,
              response.razorpay_signature,
            )
            if (!verifyResult.ok) {
              throw new Error('Payment verification failed.')
            }
            // 3. Backend atomically finalises the SnapPrint order
            //    (server prices, stock, coupon, idempotent on retry).
            //    source="website" lets the admin dashboard attribute this
            //    sale to the website vs the mobile app.
            const placeResult = await api.placeOrder({
              items: cartItems.map((item: any) => ({
                product_id: item.product_id,
                qty: item.qty,
                size: item.size,
                ...(item.image_url ? { image_url: item.image_url } : {}),
                price: 0, // ignored server-side; prices are re-verified
              })),
              address_id: addressId,
              delivery_type: deliveryType,
              ...(couponCode ? { coupon_code: couponCode } : {}),
              razorpay_payment_id: response.razorpay_payment_id,
              razorpay_order_id: response.razorpay_order_id,
              razorpay_signature: response.razorpay_signature,
              source: 'website',
              gift_wrap: giftWrap,
              ...(giftWrap && giftMessage ? { gift_message: giftMessage } : {}),
            })
            finalizedRef.current = true
            // 4. Only now: clear the cart and show the REAL order.
            clearCart()
            navigate(`/success?order=${placeResult.id}`, { replace: true })
          } catch (err: any) {
            finalizedRef.current = false
            setIsProcessing(false)
            const message =
              err?.message ||
              'Payment verification or order creation failed.'
            setPaymentError(
              `${message} If money was debited, it will reflect in My Orders once confirmed — do not pay again without checking.`,
            )
            toast?.notifyError(message)
          }
        },
      }

      const rzp = new (window as any).Razorpay(options)
      rzp.on('payment.failed', function (response: any) {
        setIsProcessing(false)
        setPaymentError(
          `Payment failed: ${response.error?.description || 'Unknown error'}. No order was created.`,
        )
      })
      rzp.open()
    } catch (err: any) {
      setIsProcessing(false)
      setPaymentError(err?.message || 'Failed to initiate payment.')
    }
  }, [
    items,
    checkoutData,
    loading,
    isProcessing,
    quoteFailed,
    addressId,
    deliveryType,
    couponCode,
    giftWrap,
    giftMessage,
    navigate,
    clearCart,
    toast,
  ])

  if (loading) {
    return (
      <div className="wrap py-12 text-center">
        <p className="text-muted" role="status">
          Preparing checkout...
        </p>
      </div>
    )
  }

  if (items.length === 0) return null

  return (
    <div className="wrap py-12">
      <Seo
        title="Payment | SnapPrint"
        description="Complete your SnapPrint payment securely via Razorpay."
        path="/payment"
        noindex
      />
      <Reveal>
        <div className="mx-auto max-w-2xl">
          <h1 className="hero-title mb-4 text-center">Complete Payment</h1>
          <p className="text-muted mb-10 text-center">
            You're almost there. Total to pay:{' '}
            <strong className="text-ink">{formatPrice(serverTotal)}</strong>
          </p>

          {paymentError && (
            <div
              className="mb-6 rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-800"
              role="alert"
            >
              {paymentError}
            </div>
          )}

          <AntiGravityWrap intensity={4} scaleOnHover={1.01}>
            <div className="glass bg-surface rounded-xl p-8 shadow-lg">
              <div className="space-y-6">
                <div>
                  <label className="text-muted mb-1 block text-sm">
                    Order Summary
                  </label>
                  <div className="space-y-2 text-sm">
                    {items.map((item) => (
                      <div
                        key={item.key}
                        className="flex items-start justify-between"
                      >
                        <div className="flex-1 pr-4">
                          <p className="font-semibold text-ink">
                            {item.product?.name || 'Product'}
                          </p>
                          <p className="text-muted">
                            {item.size} × {item.units}
                          </p>
                          {item.imageUrl && (
                            <p className="text-xs text-green-700">
                              ✓ Photo attached
                            </p>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                  <div className="mt-4 space-y-3 border-t border-border pt-4 text-sm">
                    <div className="flex justify-between">
                      <span className="text-muted">Subtotal</span>
                      <span>{formatPrice(serverSubtotal)}</span>
                    </div>
                    {serverDiscount > 0 && (
                      <div className="flex justify-between text-green-700">
                        <span>Coupon discount</span>
                        <span>−{formatPrice(serverDiscount)}</span>
                      </div>
                    )}
                    <div className="flex justify-between">
                      <span className="text-muted">
                        Shipping ({selectedDelivery.label})
                      </span>
                      <span>
                        {selectedDelivery.price === 0
                          ? 'Free'
                          : formatPrice(selectedDelivery.price)}
                      </span>
                    </div>
                    {serverGiftCharge > 0 && (
                      <div className="flex justify-between">
                        <span className="text-muted">🎁 Gift wrap</span>
                        <span>{formatPrice(serverGiftCharge)}</span>
                      </div>
                    )}
                  </div>
                  <div className="font-display mt-4 flex items-center justify-between border-t border-border pt-4 text-lg">
                    <span>Total</span>
                    <span>{formatPrice(serverTotal)}</span>
                  </div>
                  <p className="field-note mt-2">
                    Server-calculated total. Razorpay will charge exactly this
                    amount.
                  </p>
                </div>

                <div className="flex flex-col gap-3">
                  <button
                    type="button"
                    onClick={initiateRazorpayPayment}
                    disabled={isProcessing || quoteFailed}
                    className="shop-button flex w-full items-center justify-center gap-2 py-4 text-lg"
                  >
                    {isProcessing ? (
                      <>
                        <span className="animate-spin" aria-hidden="true">
                          ⟳
                        </span>
                        Processing...
                      </>
                    ) : (
                      <>
                        <RazorpayIcon />
                        Pay {formatPrice(serverTotal)} with Razorpay
                      </>
                    )}
                  </button>
                  <Link
                    to="/checkout"
                    className="text-muted text-center transition-colors hover:text-ink"
                  >
                    Cancel & Return
                  </Link>
                </div>
              </div>
            </div>
          </AntiGravityWrap>

          <p className="text-muted mt-8 flex items-center justify-center gap-2 text-center text-sm">
            <svg
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              aria-hidden="true"
            >
              <rect x="3" y="5" width="18" height="14" rx="2" />
              <path d="M3.5 6.5l8.5 6 8.5-6" />
            </svg>
            Secure encrypted connection via Razorpay
          </p>
        </div>
      </Reveal>
    </div>
  )
}
