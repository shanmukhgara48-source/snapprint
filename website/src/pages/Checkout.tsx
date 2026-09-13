import React, { useState, useEffect } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { usePrintPlan } from '../context/PrintPlan'
import { formatPrice } from '../data/products'
import { deliveryOptions } from '../data/delivery'
import { api, getAuthToken } from '../services/api'
import { isValidEmail, isValidPin, normalizeIndianPhone } from '../lib/validation'
import { ArrowRightIcon } from '../components/Icons'
import { Reveal } from '../components/Reveal'
import { Seo } from '../components/Seo'
import { AntiGravityWrap } from '../components/antiGravity/AntiGravityWrap'
import { useToastOptional } from '../context/Toast'

export function Checkout() {
  const { items, checkoutData, setCheckoutData } = usePrintPlan()
  const navigate = useNavigate()
  const toast = useToastOptional()
  const [formData, setFormData] = useState({
    email: checkoutData?.email || '',
    firstName: checkoutData?.firstName || '',
    lastName: checkoutData?.lastName || '',
    address: checkoutData?.address || '',
    city: checkoutData?.city || '',
    state: checkoutData?.state || '',
    pin: checkoutData?.pin || '',
    phone: checkoutData?.phone || '',
  })
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [serverTotal, setServerTotal] = useState(0)
  const [serverSubtotal, setServerSubtotal] = useState(0)
  const [serverDiscount, setServerDiscount] = useState(0)
  const [deliveryType, setDeliveryType] = useState(
    checkoutData?.deliveryType || 'free',
  )
  const [addressId, setAddressId] = useState(checkoutData?.addressId || '')
  const [addresses, setAddresses] = useState<any[]>([])
  const [couponCode, setCouponCode] = useState(checkoutData?.couponCode || '')
  const [couponApplied, setCouponApplied] = useState(false)
  const [giftWrap, setGiftWrap] = useState(checkoutData?.giftWrap || false)
  const [giftMessage, setGiftMessage] = useState(checkoutData?.giftMessage || '')
  const [serverGiftCharge, setServerGiftCharge] = useState(0)
  const [quoteError, setQuoteError] = useState('')
  const [quoteKey, setQuoteKey] = useState(0)

  const selectedDelivery =
    deliveryOptions.find((d) => d.type === deliveryType) ??
    deliveryOptions[0]!

  useEffect(() => {
    async function init() {
      const token = getAuthToken()
      if (!token) {
        navigate('/auth')
        return
      }
      try {
        const addrs = await api.getAddresses()
        setAddresses(addrs)
        if (!addressId && addrs.length > 0) {
          const def = addrs.find((a: any) => a.is_default) || addrs[0]
          setAddressId(def.id)
        }
      } catch (err: any) {
        console.error('Checkout address load failed:', err)
      } finally {
        setLoading(false)
      }
    }
    init()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // Server-authoritative quote; re-runs on cart/delivery/coupon changes.
  useEffect(() => {
    async function quote() {
      if (items.length === 0 || !getAuthToken()) return
      try {
        setQuoteError('')
        const cartItems = items.map((item) => ({
          product_id: item.productId,
          qty: item.units,
          size: item.size,
          ...(item.imageUrl ? { image_url: item.imageUrl } : {}),
        }))
        const result = await api.calculateCart(
          cartItems,
          deliveryType,
          couponCode.trim() || undefined,
          giftWrap,
        )
        setServerTotal(result.total)
        setServerSubtotal(result.subtotal)
        setServerDiscount(result.discount || 0)
        setServerGiftCharge(result.gift_wrap_charge || 0)
        setCouponApplied(result.coupon_applied)
      } catch (err: any) {
        setQuoteError(
          err?.message ||
            'Could not confirm the order total. Please check your cart.',
        )
      }
    }
    quote()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [items, deliveryType, giftWrap, quoteKey])

  async function applyCoupon() {
    if (!couponCode.trim()) return
    setQuoteKey((k) => k + 1)
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData((prev) => ({ ...prev, [e.target.name]: e.target.value }))
    if (errors[e.target.name]) {
      setErrors((prev) => ({ ...prev, [e.target.name]: '' }))
    }
  }

  const validate = () => {
    const newErrors: Record<string, string> = {}
    if (!isValidEmail(formData.email))
      newErrors.email = 'Enter a valid email address'
    if (!formData.firstName.trim()) newErrors.firstName = 'First name required'
    if (!formData.lastName.trim()) newErrors.lastName = 'Last name required'
    if (formData.address.trim().length < 8)
      newErrors.address = 'Enter your full street address'
    if (!formData.city.trim()) newErrors.city = 'City required'
    if (!formData.state.trim()) newErrors.state = 'State required'
    if (!isValidPin(formData.pin))
      newErrors.pin = 'Enter a valid 6-digit PIN code'
    if (!normalizeIndianPhone(formData.phone))
      newErrors.phone = 'Enter a valid 10-digit Indian mobile number'
    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!validate()) return
    if (items.length === 0) {
      navigate('/products')
      return
    }
    setSubmitting(true)
    try {
      // Persist the shipping address server-side so payment/order can
      // reference a verified address id (never a free-text guest address).
      let resolvedAddressId = addressId
      const needsNewAddress =
        !resolvedAddressId ||
        !addresses.some((a: any) => a.id === resolvedAddressId)
      if (needsNewAddress) {
        const created = await api.createAddress({
          full_address: `${formData.firstName} ${formData.lastName}, ${formData.address}, ${formData.state}`.trim(),
          city: formData.city.trim(),
          pincode: formData.pin.trim(),
          is_default: addresses.length === 0,
        })
        resolvedAddressId = created.id
        setAddressId(created.id)
        setAddresses((prev) => [...prev, created])
      }
      const normalizedPhone =
        normalizeIndianPhone(formData.phone) || formData.phone.trim()
      setCheckoutData({
        ...formData,
        phone: normalizedPhone,
        addressId: resolvedAddressId,
        couponCode: couponCode.trim() || undefined,
        deliveryType,
        giftWrap,
        giftMessage: giftWrap ? giftMessage.trim().slice(0, 500) || undefined : undefined,
      })
      navigate('/payment')
    } catch (err: any) {
      toast?.notifyError(
        err?.message || 'Could not save your address. Please try again.',
      )
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) {
    return (
      <div className="wrap py-12 text-center">
        <p className="text-muted" role="status">
          Loading checkout...
        </p>
      </div>
    )
  }
  if (items.length === 0) {
    return (
      <div className="empty-state wrap">
        <h1>Your cart is empty</h1>
        <Link to="/products" className="shop-button">
          Continue Shopping <ArrowRightIcon />
        </Link>
      </div>
    )
  }

  const inputClass = (field: string) =>
    `w-full p-3 border ${errors[field] ? 'border-red-500' : 'border-border'} rounded focus:border-accent outline-none bg-surface`

  return (
    <div className="wrap py-12">
      <Seo
        title="Checkout | SnapPrint"
        description="Enter your shipping details to complete your SnapPrint order."
        path="/checkout"
        noindex
      />
      <div className="breadcrumbs mb-8">
        <Link to="/">Home</Link>
        <span>/</span>
        <Link to="/card">Your cart</Link>
        <span>/</span>
        <span>Checkout</span>
      </div>

      <Reveal>
        <h1 className="hero-title mb-10">Checkout</h1>
      </Reveal>

      {quoteError && (
        <div
          className="mb-6 rounded-lg border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800"
          role="alert"
        >
          {quoteError}{' '}
          <button
            className="underline"
            onClick={() => setQuoteKey((k) => k + 1)}
          >
            Retry
          </button>
        </div>
      )}

      <div className="grid grid-cols-1 gap-12 lg:grid-cols-12">
        <div className="lg:col-span-7">
          <form onSubmit={handleSubmit} className="space-y-8" noValidate>
            <Reveal delay={100}>
              <section>
                <h2 className="text-2xl font-display mb-4">
                  Contact Information
                </h2>
                <div className="space-y-4">
                  <div>
                    <label
                      htmlFor="email"
                      className="text-muted mb-1 block text-sm"
                    >
                      Email
                    </label>
                    <input
                      type="email"
                      id="email"
                      name="email"
                      autoComplete="email"
                      value={formData.email}
                      onChange={handleChange}
                      className={inputClass('email')}
                      aria-invalid={Boolean(errors.email)}
                    />
                    {errors.email && (
                      <p className="mt-1 text-sm text-red-500" role="alert">
                        {errors.email}
                      </p>
                    )}
                  </div>
                  <div>
                    <label
                      htmlFor="phone"
                      className="text-muted mb-1 block text-sm"
                    >
                      Phone (10-digit Indian mobile)
                    </label>
                    <input
                      type="tel"
                      id="phone"
                      name="phone"
                      autoComplete="tel"
                      inputMode="numeric"
                      placeholder="98765 43210"
                      value={formData.phone}
                      onChange={handleChange}
                      className={inputClass('phone')}
                      aria-invalid={Boolean(errors.phone)}
                    />
                    {errors.phone && (
                      <p className="mt-1 text-sm text-red-500" role="alert">
                        {errors.phone}
                      </p>
                    )}
                  </div>
                </div>
              </section>
            </Reveal>

            <Reveal delay={200}>
              <section>
                <h2 className="text-2xl font-display mb-4">Shipping Address</h2>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label
                      htmlFor="firstName"
                      className="text-muted mb-1 block text-sm"
                    >
                      First Name
                    </label>
                    <input
                      type="text"
                      id="firstName"
                      name="firstName"
                      autoComplete="given-name"
                      value={formData.firstName}
                      onChange={handleChange}
                      className={inputClass('firstName')}
                    />
                    {errors.firstName && (
                      <p className="mt-1 text-sm text-red-500" role="alert">
                        {errors.firstName}
                      </p>
                    )}
                  </div>
                  <div>
                    <label
                      htmlFor="lastName"
                      className="text-muted mb-1 block text-sm"
                    >
                      Last Name
                    </label>
                    <input
                      type="text"
                      id="lastName"
                      name="lastName"
                      autoComplete="family-name"
                      value={formData.lastName}
                      onChange={handleChange}
                      className={inputClass('lastName')}
                    />
                    {errors.lastName && (
                      <p className="mt-1 text-sm text-red-500" role="alert">
                        {errors.lastName}
                      </p>
                    )}
                  </div>
                  <div className="col-span-2">
                    <label
                      htmlFor="address"
                      className="text-muted mb-1 block text-sm"
                    >
                      Address
                    </label>
                    <input
                      type="text"
                      id="address"
                      name="address"
                      autoComplete="street-address"
                      value={formData.address}
                      onChange={handleChange}
                      className={inputClass('address')}
                    />
                    {errors.address && (
                      <p className="mt-1 text-sm text-red-500" role="alert">
                        {errors.address}
                      </p>
                    )}
                  </div>
                  <div>
                    <label
                      htmlFor="city"
                      className="text-muted mb-1 block text-sm"
                    >
                      City
                    </label>
                    <input
                      type="text"
                      id="city"
                      name="city"
                      autoComplete="address-level2"
                      value={formData.city}
                      onChange={handleChange}
                      className={inputClass('city')}
                    />
                    {errors.city && (
                      <p className="mt-1 text-sm text-red-500" role="alert">
                        {errors.city}
                      </p>
                    )}
                  </div>
                  <div>
                    <label
                      htmlFor="state"
                      className="text-muted mb-1 block text-sm"
                    >
                      State
                    </label>
                    <input
                      type="text"
                      id="state"
                      name="state"
                      autoComplete="address-level1"
                      value={formData.state}
                      onChange={handleChange}
                      className={inputClass('state')}
                    />
                    {errors.state && (
                      <p className="mt-1 text-sm text-red-500" role="alert">
                        {errors.state}
                      </p>
                    )}
                  </div>
                  <div>
                    <label
                      htmlFor="pin"
                      className="text-muted mb-1 block text-sm"
                    >
                      PIN Code
                    </label>
                    <input
                      type="text"
                      id="pin"
                      name="pin"
                      autoComplete="postal-code"
                      inputMode="numeric"
                      maxLength={6}
                      value={formData.pin}
                      onChange={handleChange}
                      className={inputClass('pin')}
                    />
                    {errors.pin && (
                      <p className="mt-1 text-sm text-red-500" role="alert">
                        {errors.pin}
                      </p>
                    )}
                  </div>
                  {addresses.length > 0 && (
                    <div>
                      <label
                        htmlFor="saved-address"
                        className="text-muted mb-1 block text-sm"
                      >
                        Saved Address
                      </label>
                      <select
                        id="saved-address"
                        value={addressId}
                        onChange={(e) => setAddressId(e.target.value)}
                        className="w-full rounded border border-border bg-surface p-3"
                      >
                        <option value="">Use the address above (new)</option>
                        {addresses.map((a: any) => (
                          <option key={a.id} value={a.id}>
                            {a.full_address} {a.is_default ? '(Default)' : ''}
                          </option>
                        ))}
                      </select>
                    </div>
                  )}
                  <div className="col-span-2">
                    <label
                      htmlFor="delivery-type"
                      className="text-muted mb-1 block text-sm"
                    >
                      Delivery option
                    </label>
                    <select
                      id="delivery-type"
                      value={deliveryType}
                      onChange={(e) => setDeliveryType(e.target.value)}
                      className="w-full rounded border border-border bg-surface p-3"
                    >
                      {deliveryOptions.map((d) => (
                        <option key={d.type} value={d.type}>
                          {d.label} ·{' '}
                          {d.price ? formatPrice(d.price) : 'Free'} ·{' '}
                          {d.daysLabel}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div className="col-span-2">
                    <label
                      htmlFor="coupon"
                      className="text-muted mb-1 block text-sm"
                    >
                      Coupon code (optional)
                    </label>
                    <div className="flex gap-2">
                      <input
                        type="text"
                        id="coupon"
                        value={couponCode}
                        onChange={(e) =>
                          setCouponCode(e.target.value.toUpperCase())
                        }
                        placeholder="WELCOME50"
                        className="w-full rounded border border-border bg-surface p-3 uppercase outline-none focus:border-accent"
                      />
                      <button
                        type="button"
                        onClick={applyCoupon}
                        className="shrink-0 rounded border border-border px-4 text-sm"
                      >
                        Apply
                      </button>
                    </div>
                    {couponApplied && (
                      <p className="mt-1 text-sm text-green-700" role="status">
                        Coupon applied — discount reflected in the total.
                      </p>
                    )}
                  </div>
                </div>
              </section>
            </Reveal>

            <Reveal delay={250}>
              <section aria-label="Gift options">
                <h2 className="text-2xl font-display mb-4">
                  Gift wrap <small className="text-muted text-sm">Optional</small>
                </h2>
                <label className="flex cursor-pointer items-start gap-3 rounded border border-border bg-surface p-4">
                  <input
                    type="checkbox"
                    checked={giftWrap}
                    onChange={(e) => setGiftWrap(e.target.checked)}
                    className="mt-1 h-4 w-4 accent-[#966c24]"
                  />
                  <span>
                    <strong className="block text-sm">
                      🎁 Wrap this order as a gift
                      {serverGiftCharge > 0 && giftWrap
                        ? ` · ${formatPrice(serverGiftCharge)}`
                        : ''}
                    </strong>
                    <span className="text-muted text-sm">
                      Premium wrapping for all the photos in this order. Add a
                      personal message for the card.
                    </span>
                  </span>
                </label>
                {giftWrap && (
                  <div className="mt-3">
                    <label
                      htmlFor="gift-message"
                      className="text-muted mb-1 block text-sm"
                    >
                      Gift message (optional, max 500 characters)
                    </label>
                    <textarea
                      id="gift-message"
                      value={giftMessage}
                      onChange={(e) => setGiftMessage(e.target.value.slice(0, 500))}
                      placeholder="Happy birthday! Love, …"
                      rows={3}
                      maxLength={500}
                      className="w-full rounded border border-border bg-surface p-3 outline-none focus:border-accent"
                    />
                  </div>
                )}
              </section>
            </Reveal>

            <Reveal delay={300}>
              <button
                type="submit"
                disabled={submitting}
                className="shop-button mt-6 w-full justify-center py-4 text-lg"
              >
                {submitting ? 'Saving…' : 'Proceed to Payment'}{' '}
                <ArrowRightIcon />
              </button>
            </Reveal>
          </form>
        </div>

        <div className="lg:col-span-5">
          <Reveal delay={200} intensity={0.5}>
            <AntiGravityWrap intensity={4} scaleOnHover={1.01}>
              <div className="glass sticky top-24 rounded-lg p-6">
                <h2 className="text-2xl font-display mb-6 border-b border-border pb-4">
                  Order Summary
                </h2>
                <div className="mb-6 max-h-[40vh] space-y-4 overflow-y-auto pr-2">
                  {items.map((item: any) => (
                    <div
                      key={item.key}
                      className="flex items-start justify-between text-sm"
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
                <div className="space-y-3 border-t border-border pt-4 text-sm">
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
                  Server-calculated total. The amount charged always comes
                  from the backend, never from this page.
                </p>
              </div>
            </AntiGravityWrap>
          </Reveal>
        </div>
      </div>
    </div>
  )
}
