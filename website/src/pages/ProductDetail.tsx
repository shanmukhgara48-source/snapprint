import { useEffect, useRef, useState } from 'react'
import { Link, useParams, useNavigate } from 'react-router-dom'
import { api, getAuthToken } from '../services/api'
import { formatPrice, catalogProducts, type CatalogProduct } from '../data/products'
import { deliveryOptions } from '../data/delivery'
import { productFormats, startingAmount } from '../lib/printOptions'
import { toCatalogProduct, isOutOfStock, saleInfo, stockLabel, type BackendProduct } from '../lib/products'
import { Reviews } from '../components/Reviews'
import { useWishlist } from '../context/Wishlist'
import { usePrintPlan } from '../context/PrintPlan'
import { ProductVisual } from '../components/ProductVisual'
import { ProductCard } from '../components/ProductCard'
import { Seo } from '../components/Seo'
import {
  ArrowRightIcon,
  CheckIcon,
  UploadIcon,
  ShieldCheckIcon,
  TruckIcon,
} from '../components/Icons'
import { AntiGravityWrap } from '../components/antiGravity/AntiGravityWrap'
import { Reveal } from '../components/Reveal'
import { useToastOptional } from '../context/Toast'

const ACCEPTED_TYPES = ['image/jpeg', 'image/png', 'image/webp']
const MAX_BYTES = 20 * 1024 * 1024

export function ProductDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const toast = useToastOptional()
  const [product, setProduct] = useState<BackendProduct | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [related, setRelated] = useState<any[]>([])
  const [together, setTogether] = useState<CatalogProduct[]>([])
  const [size, setSize] = useState('')
  const [units, setUnits] = useState(1)
  /** Persistent media URL from POST /upload/image — attached to the cart item. */
  const [photoUrl, setPhotoUrl] = useState('')
  /** Local blob preview — display only, never sent to the server. */
  const [previewUrl, setPreviewUrl] = useState('')
  const [fit] = useState<'cover' | 'contain'>('cover')
  const [uploadError, setUploadError] = useState('')
  const [uploading, setUploading] = useState(false)
  const [uploadProgress, setUploadProgress] = useState(0)
  const inputRef = useRef<HTMLInputElement>(null)
  const uploadVersion = useRef(0)
  const { add } = usePrintPlan()
  const wishlist = useWishlist()

  useEffect(() => {
    async function fetchProduct() {
      try {
        setLoading(true)
        setError('')
        const data = await api.getProduct(id!)
        setProduct(data)
        const adapted = toCatalogProduct(data)
        const formats = productFormats(adapted)
        if (formats.length > 0) setSize(formats[0]!)
        // Related products from the same backend category.
        try {
          const rel = await api.getProducts(data.category)
          setRelated(
            (rel.items || [])
              .filter((p: any) => p.id !== data.id)
              .slice(0, 3)
              .map(toCatalogProduct),
          )
        } catch {
          setRelated(
            catalogProducts
              .filter(
                (p) =>
                  p.categoryName === adapted.categoryName &&
                  p.id !== adapted.id,
              )
              .slice(0, 3),
          )
        }
        // Frequently bought together, from real co-purchase history.
        try {
          const bt = await api.getBoughtTogether(data.id)
          setTogether((bt || []).map(toCatalogProduct))
        } catch {
          setTogether([])
        }
      } catch (err: any) {
        // Offline fallback: static catalogue so the page still renders;
        // checkout always re-validates against the server.
        const fallback = catalogProducts.find((p) => p.id === id)
        if (fallback) {
          setProduct({
            id: fallback.id,
            name: fallback.name,
            category: fallback.categoryName,
            category_id: fallback.categoryId,
            base_price: fallback.basePrice,
            sizes: fallback.sizes.map((s) => ({ label: s, price: 0 })),
            images: [fallback.imageUrl],
            description: fallback.summary,
            is_orderable: true,
          })
          const formats = productFormats(fallback)
          if (formats.length > 0) setSize(formats[0]!)
          setRelated(
            catalogProducts
              .filter(
                (p) =>
                  p.categoryId === fallback.categoryId &&
                  p.id !== fallback.id,
              )
              .slice(0, 3),
          )
        } else {
          setError(err.message || 'Product not found')
        }
      } finally {
        setLoading(false)
      }
    }
    if (id) fetchProduct()
  }, [id])

  // Revoke only the local blob preview on unmount/change — never the
  // persistent server URL.
  useEffect(() => {
    const current = previewUrl
    return () => {
      if (current.startsWith('blob:')) {
        try {
          URL.revokeObjectURL(current)
        } catch {
          /* ignore */
        }
      }
    }
  }, [previewUrl])

  async function handleUploadPhoto(file: File) {
    if (!file) return
    if (!getAuthToken()) {
      setUploadError('Please sign in to upload a photo for your order.')
      return
    }
    const version = ++uploadVersion.current
    setUploadError('')
    if (!ACCEPTED_TYPES.includes(file.type)) {
      setUploadError('Please choose a JPG, PNG or WebP photo.')
      return
    }
    if (file.size > MAX_BYTES) {
      setUploadError('Please choose a file under 20 MB.')
      return
    }
    setUploading(true)
    setUploadProgress(5)
    try {
      const preview = URL.createObjectURL(file)
      if (version === uploadVersion.current) setPreviewUrl(preview)
      else URL.revokeObjectURL(preview)
      const result = await api.uploadImage(file, (pct) => {
        if (version === uploadVersion.current) setUploadProgress(pct)
      })
      if (version !== uploadVersion.current) return
      if (!result?.public_url) {
        throw new Error('Upload did not return a media reference.')
      }
      setPhotoUrl(result.public_url)
      toast?.notifySuccess('Photo uploaded — it will be attached to your order.')
    } catch (err: any) {
      if (version === uploadVersion.current) {
        setUploadError(err.message || 'Upload failed. Please try again.')
      }
    } finally {
      if (version === uploadVersion.current) {
        setUploading(false)
        setUploadProgress(0)
      }
    }
  }

  function choosePhoto(file?: File) {
    if (!file) return
    handleUploadPhoto(file)
  }

  function clearPhoto() {
    uploadVersion.current += 1
    if (previewUrl.startsWith('blob:')) {
      try {
        URL.revokeObjectURL(previewUrl)
      } catch {
        /* ignore */
      }
    }
    setPreviewUrl('')
    setPhotoUrl('')
    setUploadError('')
    if (inputRef.current) inputRef.current.value = ''
  }

  if (loading) {
    return (
      <div className="wrap py-12 text-center">
        <p className="text-muted" role="status">
          Loading product...
        </p>
      </div>
    )
  }
  if (error || !product) {
    return (
      <div className="empty-state wrap">
        <h1>We couldn't find that print.</h1>
        <p className="text-muted">{error}</p>
        <Link to="/products" className="shop-button">
          Explore the collection <ArrowRightIcon />
        </Link>
      </div>
    )
  }

  const adapted = toCatalogProduct(product)
  const formats = productFormats(adapted)
  const displaySize = size || formats[0] || ''
  const estimate = startingAmount(adapted, units)
  // Shared stock level from the backend (decremented by mobile-app and
  // website orders alike). Re-fetched on every visit so a recent app
  // purchase (10 → 9) is visible here before adding to cart.
  const outOfStock = isOutOfStock(adapted)
  const stockText = stockLabel(adapted)
  const sale = saleInfo(adapted.basePrice, adapted.compare_at_price)
  const saved = product ? wishlist.has(adapted.id) : false

  return (
    <div className="detail-page wrap">
      <Seo
        title={`${adapted.name} | SnapPrint`}
        description={adapted.summary || `Order ${adapted.name} from SnapPrint.`}
        path={`/products/${adapted.id}`}
        type="product"
        jsonLd={[
          {
            '@context': 'https://schema.org',
            '@type': 'Product',
            name: adapted.name,
            category: adapted.categoryName,
            description: adapted.summary || undefined,
            offers: {
              '@type': 'Offer',
              priceCurrency: 'INR',
              price: adapted.basePrice > 0 ? adapted.basePrice : undefined,
              availability: 'https://schema.org/InStock',
            },
          },
          {
            '@context': 'https://schema.org',
            '@type': 'BreadcrumbList',
            itemListElement: [
              { '@type': 'ListItem', position: 1, name: 'Home', item: 'https://snapprint.in/' },
              { '@type': 'ListItem', position: 2, name: adapted.categoryName, item: `https://snapprint.in/products?category=${adapted.categoryId}` },
              { '@type': 'ListItem', position: 3, name: adapted.name },
            ],
          },
        ]}
      />
      <nav className="breadcrumbs" aria-label="Breadcrumb">
        <Link to="/">Home</Link>
        <span>/</span>
        <Link
          to={`/products?category=${encodeURIComponent(adapted.categoryId)}`}
        >
          {adapted.categoryName}
        </Link>
        <span>/</span>
        <span>{adapted.name}</span>
      </nav>
      <Reveal>
        <div className="product-layout">
          <div className="detail-gallery">
            <div className="large-preview">
              <AntiGravityWrap intensity={10} scaleOnHover={1.02}>
                <ProductVisual
                  product={adapted}
                  photo={previewUrl || undefined}
                  fit={fit}
                  size={displaySize}
                />
                <span className="preview-label">
                  {previewUrl ? 'Your photo, your story' : 'Imagine your photo here'} ✧
                </span>
              </AntiGravityWrap>
            </div>
            <p className="visual-note">
              Illustrative preview, not a print proof. Final layout and finish
              are chosen at checkout.
            </p>
            <div className="preview-actions">
              <button
                className="preview-thumb"
                aria-label="Show example photo"
                aria-pressed={!previewUrl}
                onClick={clearPhoto}
              >
                <ProductVisual product={adapted} />
              </button>
              <button
                className="add-photo-thumb"
                onClick={() => inputRef.current?.click()}
                disabled={uploading}
              >
                <UploadIcon />
                {uploading
                  ? `Uploading… ${uploadProgress}%`
                  : photoUrl
                    ? 'Choose a different photo'
                    : 'Choose a photo to preview'}
              </button>
              <input
                hidden
                type="file"
                ref={inputRef}
                accept="image/jpeg,image/png,image/webp"
                aria-label="Choose a photo for your order"
                onChange={(e) => {
                  choosePhoto(e.target.files?.[0])
                  e.target.value = ''
                }}
              />
            </div>
            {uploading && (
              <div
                role="progressbar"
                aria-valuenow={uploadProgress}
                aria-valuemin={0}
                aria-valuemax={100}
                aria-label="Photo upload progress"
                className="h-1.5 w-full overflow-hidden rounded bg-border"
              >
                <div
                  className="h-full bg-accent transition-all"
                  style={{ width: `${uploadProgress}%` }}
                />
              </div>
            )}
            {uploadError && (
              <div className="flex items-center gap-2">
                <p
                  role="alert"
                  className="error-message"
                  style={{ color: 'var(--color-danger)' }}
                >
                  {uploadError}
                </p>
                <button
                  className="text-link text-sm"
                  onClick={() => inputRef.current?.click()}
                >
                  Retry
                </button>
              </div>
            )}
            {photoUrl && (
              <div className="detail-reassurance">
                <ShieldCheckIcon />
                <p>
                  <strong>Photo uploaded.</strong> It is stored securely and
                  will be attached to your order.
                </p>
              </div>
            )}
          </div>
          <div className="product-options">
            <p className="eyebrow">{adapted.categoryName} · MADE PERSONAL</p>
            <h1>{adapted.name}</h1>
            <div className="detail-price">
              <span>
                {adapted.basePrice > 0 ? 'Starting from' : 'Custom pricing'}
              </span>
              <strong>
                {formatPrice(adapted.basePrice)}{' '}
                {sale && (
                  <>
                    <small className="text-muted line-through" style={{ fontWeight: 400 }}>
                      M.R.P. {formatPrice(sale.mrp)}
                    </small>{' '}
                    <small style={{ color: '#cc0c39' }}>{sale.percentOff}% off</small>
                  </>
                )}
              </strong>
              <small>
                {adapted.minimum} · {adapted.quantity}
              </small>
              {stockText && (
                <p
                  role="status"
                  style={{
                    marginTop: 6,
                    fontSize: 13,
                    fontWeight: 600,
                    color: outOfStock ? '#b91c1c' : '#92400e',
                  }}
                >
                  {stockText} · shared live stock with the mobile app
                </p>
              )}
            </div>
            <div className="option-block">
              <div className="option-title">
                <h2>
                  <span>01</span> Choose your format
                </h2>
              </div>
              <div className="size-options">
                {formats.map((s: string) => (
                  <button
                    key={s}
                    className={displaySize === s ? 'selected' : ''}
                    aria-pressed={displaySize === s}
                    onClick={() => setSize(s)}
                  >
                    {s}
                    {displaySize === s && <CheckIcon />}
                  </button>
                ))}
              </div>
              <p className="field-note">
                Size and finish may change the price. Your exact total is
                confirmed at checkout from server pricing.
              </p>
            </div>
            <div className="option-block">
              <h2 className="option-title">
                <span>02</span> Add your photo <small>Optional</small>
              </h2>
              <button
                className="upload-zone"
                onClick={() => inputRef.current?.click()}
              >
                <UploadIcon />
                <strong>
                  {photoUrl
                    ? 'Choose a different photo'
                    : 'Choose a photo for your order'}
                </strong>
                <span>JPG, PNG or WebP · up to 20 MB · sign-in required</span>
              </button>
            </div>
            <div className="option-block">
              <h2 className="option-title">
                <span>03</span> Make room for more
              </h2>
              <div className="quantity-line">
                <div>
                  <strong>Sets / copies</strong>
                  <p className="field-note">
                    Minimum per group: {adapted.minimum}
                  </p>
                </div>
                <div className="stepper">
                  <button
                    aria-label="Decrease sets"
                    disabled={units === 1}
                    onClick={() => setUnits(units - 1)}
                  >
                    −
                  </button>
                  <output aria-label="Number of sets">{units}</output>
                  <button
                    aria-label="Increase sets"
                    disabled={units === 20}
                    onClick={() => setUnits(units + 1)}
                  >
                    +
                  </button>
                </div>
              </div>
            </div>
            <div className="purchase-action">
              <div>
                <small>
                  {estimate !== null
                    ? 'Product estimate from'
                    : 'Final pricing in checkout'}
                </small>
                <strong>
                  {estimate !== null
                    ? formatPrice(estimate)
                    : 'Quote required'}
                </strong>
              </div>
              <button
                className="shop-button"
                disabled={outOfStock}
                title={outOfStock ? 'Out of stock' : 'Add to cart'}
                onClick={() => {
                  add({
                    productId: adapted.id,
                    size: displaySize,
                    units,
                    imageUrl: photoUrl || undefined,
                    previewUrl: previewUrl || undefined,
                    product: adapted,
                  })
                  navigate('/card')
                }}
              >
                {outOfStock ? 'Out of stock' : 'Add to cart'} <ArrowRightIcon />
              </button>
              <button
                onClick={async () => {
                  try {
                    await wishlist.toggle(adapted.id)
                    toast?.notifySuccess(saved ? 'Removed from your wishlist.' : 'Saved to your wishlist.')
                  } catch (err: any) {
                    toast?.notifyError(err.message || 'Could not update your wishlist.')
                  }
                }}
                aria-pressed={saved}
                aria-label={saved ? 'Remove from wishlist' : 'Add to wishlist'}
                className="rounded-lg border border-border px-4 py-2 text-sm"
                title={saved ? 'Remove from wishlist' : 'Add to wishlist'}
              >
                {saved ? '♥ Saved' : '♡ Wishlist'}
              </button>
            </div>
            <div className="delivery-preview">
              <TruckIcon />
              <div>
                <strong>A little happiness, delivered.</strong>
                {deliveryOptions.map((d) => (
                  <p key={d.type}>
                    {d.label}{' '}
                    <span>
                      {d.price === 0
                        ? 'Free'
                        : formatPrice(d.price)}{' '}
                      · {d.daysLabel}
                    </span>
                  </p>
                ))}
                <Link className="text-link" to="/shipping">
                  Delivery details <ArrowRightIcon />
                </Link>
              </div>
            </div>
          </div>
        </div>
      </Reveal>
      {together.length > 0 && (
        <section className="shop-section" aria-label="Frequently bought together">
          <div className="section-heading">
            <h2>Frequently bought together</h2>
          </div>
          <div className="product-grid">
            {together.map((p: any) => (
              <ProductCard product={p} key={p.id} />
            ))}
          </div>
        </section>
      )}
      <Reviews productId={adapted.id} />
      {related.length > 0 && (
        <section className="shop-section" aria-label="Related products">
          <div className="section-heading">
            <h2>You may also like</h2>
          </div>
          <div className="product-grid">
            {related.map((p: any) => (
              <ProductCard product={p} key={p.id} />
            ))}
          </div>
        </section>
      )}
    </div>
  )
}
