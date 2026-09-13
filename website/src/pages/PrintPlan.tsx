import { useEffect, useMemo, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { usePrintPlan } from '../context/PrintPlan'
import { catalogProducts, formatPrice } from '../data/products'
import { deliveryOptions } from '../data/delivery'
import { startingAmount } from '../lib/printOptions'
import { api, getAuthToken } from '../services/api'
import { ProductVisual } from '../components/ProductVisual'
import { Seo } from '../components/Seo'
import { appAsset } from '../lib/assets'
import { ArrowRightIcon, PackageIcon, ShieldCheckIcon } from '../components/Icons'
import { ProductCard } from '../components/ProductCard'
import { useToastOptional } from '../context/Toast'

export function PrintPlan() {
  const { items, remove, update, storageAvailable } = usePrintPlan()
  const navigate = useNavigate()
  const toast = useToastOptional()
  const [delivery, setDelivery] = useState('free')
  const [serverTotal, setServerTotal] = useState<number | null>(null)
  const [serverError, setServerError] = useState('')
  const [validating, setValidating] = useState(false)
  const [quoteKey, setQuoteKey] = useState(0)
  const selectedDelivery =
    deliveryOptions.find((d) => d.type === delivery) ?? deliveryOptions[0]!

  const displayProduct = (productId: string, snapshot?: any) =>
    snapshot ??
    catalogProducts.find((p) => p.id === productId) ?? {
      id: productId,
      name: 'SnapPrint product',
      categoryId: 'photo-prints',
      categoryName: 'Photo Prints',
      basePrice: 0,
      sizes: [],
      summary: '',
      minimum: 'Minimum order: 1',
      quantity: '',
      finish: '',
      delivery: '',
      isFeatured: false,
      isTrending: false,
      imageUrl: appAsset('images/memories-still-life.jpg'),
    }

  const subtotal = items.reduce((sum, item) => {
    const product = displayProduct(item.productId, item.product)
    const estimate =
      'basePrice' in product ? startingAmount(product as any, item.units) : 0
    return sum + (estimate ?? 0)
  }, 0)

  const cartSignature = useMemo(
    () =>
      JSON.stringify(
        items.map((i) => [i.productId, i.size, i.units, i.imageUrl || '']),
      ),
    [items],
  )

  // Server-side validation: authoritative price/availability/coupons.
  // Guests see a client estimate; the exact total is confirmed at checkout.
  useEffect(() => {
    async function validate() {
      if (items.length === 0) {
        setServerTotal(null)
        return
      }
      if (!getAuthToken()) {
        setServerTotal(null)
        return
      }
      setValidating(true)
      setServerError('')
      try {
        const quote = await api.calculateCart(
          items.map((item) => ({
            product_id: item.productId,
            qty: item.units,
            size: item.size,
            ...(item.imageUrl ? { image_url: item.imageUrl } : {}),
          })),
          delivery,
        )
        setServerTotal(quote.total)
      } catch (err: any) {
        setServerTotal(null)
        setServerError(
          err?.message ||
            'Could not confirm live pricing. Estimates shown; exact total at checkout.',
        )
      } finally {
        setValidating(false)
      }
    }
    validate()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [cartSignature, delivery, quoteKey])

  const hasQuote = items.some((item) => {
    const product = displayProduct(item.productId, item.product)
    return 'basePrice' in product
      ? startingAmount(product as any, item.units) === null
      : true
  })

  const recommendations = catalogProducts
    .filter(
      (p) =>
        [
          'square-photo-prints',
          'photo-fridge-magnet-combo-set-of-4',
          'personalised-white-photo-mug',
          'classic-photo-frames',
        ].includes(p.id) && !items.some((item) => item.productId === p.id),
    )
    .slice(0, 3)

  function proceed() {
    const missingPhoto = items.find(
      (i) => !i.imageUrl && !i.previewUrl,
    )
    if (missingPhoto) {
      // Photos are optional per product, but confirm intent once.
      toast?.notify(
        'Tip: add your photo on the product page so your print is personal.',
        'info',
      )
    }
    navigate('/checkout')
  }

  return (
    <div className="plan-page wrap">
      <Seo
        title="Your cart | SnapPrint"
        description="Review your SnapPrint cart before secure checkout."
        path="/card"
        noindex
      />
      <div className="breadcrumbs">
        <Link to="/">Home</Link>
        <span>/</span>
        <span>Your cart</span>
      </div>
      <p className="eyebrow">GOOD THINGS ARE TAKING SHAPE</p>
      <h1>Your memories, in the making.</h1>
      <p className="page-description">
        A little collection of things you’d love to create.{' '}
        {storageAvailable
          ? 'Saved on this device, ready when you are.'
          : 'Available for this visit. Download your cart to keep it; this browser cannot save it.'}
      </p>
      {items.length === 0 ? (
        <div className="empty-state">
          <PackageIcon />
          <h2>Your next favourite thing starts here.</h2>
          <p>Add a product and format to build your own cart.</p>
          <Link to="/products" className="shop-button">
            Browse all products <ArrowRightIcon />
          </Link>
        </div>
      ) : (
        <div className="plan-layout">
          <div className="plan-items">
            {items.map((item) => {
              const product = displayProduct(item.productId, item.product)
              const estimate =
                'basePrice' in product
                  ? startingAmount(product as any, item.units)
                  : null
              return (
                <article className="plan-item" key={item.key}>
                  <Link to={`/products/${product.id}`}>
                    <ProductVisual
                      product={product as any}
                      photo={item.previewUrl || undefined}
                      size={item.size}
                    />
                  </Link>
                  <div>
                    <Link to={`/products/${product.id}`}>
                      <h2>{product.name}</h2>
                    </Link>
                    <p>{item.size}</p>
                    <p className="field-note">
                      Minimum per group: {product.minimum}
                    </p>
                    {item.imageUrl ? (
                      <p className="field-note text-green-700">
                        ✓ Photo attached
                      </p>
                    ) : (
                      <p className="field-note">
                        No photo attached yet — add one on the product page.
                      </p>
                    )}
                    <div className="stepper">
                      <button
                        aria-label={`Remove one set of ${product.name}`}
                        disabled={item.units === 1}
                        onClick={() => update(item.key, item.units - 1)}
                      >
                        −
                      </button>
                      <output>{item.units}</output>
                      <button
                        aria-label={`Add one set of ${product.name}`}
                        disabled={item.units === 20}
                        onClick={() => update(item.key, item.units + 1)}
                      >
                        +
                      </button>
                    </div>
                  </div>
                  <div className="plan-item-price">
                    <strong>
                      {serverTotal !== null
                        ? 'See total →'
                        : estimate !== null
                          ? `From ${formatPrice(estimate)}`
                          : 'Quote required'}
                    </strong>
                    <button
                      className="text-link"
                      aria-label={`Remove ${product.name} from cart`}
                      onClick={() => remove(item.key)}
                    >
                      Remove
                    </button>
                  </div>
                </article>
              )
            })}
            <Link className="text-link" to="/products">
              ← Add another memory
            </Link>
            <div className="plan-privacy">
              <ShieldCheckIcon />
              <p>
                Your photos stay yours. Uploaded photos are stored securely
                and attached to your order only.
              </p>
            </div>
          </div>
          <aside className="plan-summary">
            <p className="eyebrow">YOUR CART AT A GLANCE</p>
            <h2>A little closer to real.</h2>
            {serverError && (
              <div
                className="mb-3 rounded-lg border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800"
                role="status"
              >
                {serverError}{' '}
                <button
                  className="underline"
                  onClick={() => setQuoteKey((k) => k + 1)}
                >
                  Retry
                </button>
              </div>
            )}
            <div className="summary-row">
              <span>
                {serverTotal !== null
                  ? 'Server-confirmed total'
                  : 'Products, starting from'}
              </span>
              <strong>
                {validating
                  ? 'Checking…'
                  : serverTotal !== null
                    ? formatPrice(serverTotal)
                    : subtotal
                      ? formatPrice(subtotal)
                      : 'Quote required'}
              </strong>
            </div>
            {hasQuote && serverTotal === null && (
              <p className="field-note">
                Some items need their quantity pricing confirmed and are
                excluded from this estimate.
              </p>
            )}
            {!getAuthToken() && (
              <p className="field-note">
                <Link to="/auth" className="text-link">
                  Sign in
                </Link>{' '}
                to confirm live pricing before checkout.
              </p>
            )}
            <label htmlFor="delivery-choice">Delivery preference</label>
            <select
              id="delivery-choice"
              value={delivery}
              onChange={(e) => setDelivery(e.target.value)}
            >
              {deliveryOptions.map((d) => (
                <option value={d.type} key={d.type}>
                  {d.label} · {d.price ? formatPrice(d.price) : '₹0'} ·{' '}
                  {d.daysLabel}
                </option>
              ))}
            </select>
            <div className="summary-row total">
              <span>Starting estimate{hasQuote && '*'}</span>
              <strong>
                {validating
                  ? 'Checking…'
                  : serverTotal !== null
                    ? formatPrice(serverTotal)
                    : subtotal
                      ? formatPrice(subtotal + selectedDelivery.price)
                      : 'Quote required'}
              </strong>
            </div>
            <p className="field-note">
              {hasQuote ? '* Plus quote-only items. ' : ''}Size, finish,
              quantity, taxes and delivery availability are confirmed during
              checkout before payment.
            </p>
            <button className="shop-button" onClick={proceed}>
              Proceed to Checkout <ArrowRightIcon />
            </button>
            <div className="app-handoff">
              <h3>Fast, secure checkout</h3>
              <p>
                Complete your purchase securely. You will have a chance to
                review your order before final payment.
              </p>
            </div>
          </aside>
        </div>
      )}
      {items.length > 0 && recommendations.length > 0 && (
        <section className="shop-section">
          <div className="section-heading">
            <div>
              <p className="eyebrow">ONE FOR YOU. ONE FOR SOMEONE YOU LOVE.</p>
              <h2>A lovely little extra.</h2>
              <p>
                Build your own gift pairing. Each product is priced separately.
              </p>
            </div>
          </div>
          <div className="product-grid">
            {recommendations.map((p) => (
              <ProductCard product={p} key={p.id} />
            ))}
          </div>
        </section>
      )}
    </div>
  )
}
