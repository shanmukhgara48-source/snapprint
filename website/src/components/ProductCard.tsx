import { Link } from 'react-router-dom'
import { formatPrice, type CatalogProduct } from '../data/products'
import { productFormats } from '../lib/printOptions'
import { isOutOfStock, saleInfo, stockLabel } from '../lib/products'
import { productStory } from '../data/shopping'
import { ProductVisual } from './ProductVisual'
import { Stars } from './Stars'
import { ArrowRightIcon } from './Icons'
import { AntiGravityWrap } from './antiGravity/AntiGravityWrap'
import { useWishlist } from '../context/Wishlist'
import { useToastOptional } from '../context/Toast'

export function ProductCard({ product }: { product: CatalogProduct }) {
  const out = isOutOfStock(product)
  const stock = stockLabel(product)
  const sale = saleInfo(product.basePrice, product.compare_at_price)
  const wishlist = useWishlist()
  const toast = useToastOptional()
  const saved = wishlist.has(product.id)

  async function toggleHeart(e: React.MouseEvent) {
    e.preventDefault()
    e.stopPropagation()
    try {
      await wishlist.toggle(product.id)
    } catch (err: any) {
      toast?.notifyError(err.message || 'Could not update your wishlist.')
    }
  }

  return (
    <AntiGravityWrap intensity={12} scaleOnHover={1.03} className="h-full">
      <Link to={`/products/${product.id}`} className="shop-card h-full block">
        <div className="card-image">
          <ProductVisual product={product} />
          <div className="absolute left-2 top-2 z-10 flex flex-col items-start gap-1">
            {product.is_bestseller && (
              <span className="product-badge" style={{ position: 'static', background: '#ea7c28', color: '#fff' }}>
                Bestseller
              </span>
            )}
            {product.isTrending && (
              <span className="product-badge" style={{ position: 'static' }}>Popular pick</span>
            )}
            {sale && (
              <span className="product-badge" style={{ position: 'static', background: '#cc0c39', color: '#fff' }}>
                {sale.percentOff}% off
              </span>
            )}
            {stock && (
              <span
                className="product-badge"
                style={{
                  position: 'static',
                  background: out ? '#fee2e2' : '#fef3c7',
                  color: out ? '#991b1b' : '#92400e',
                }}
              >
                {stock}
              </span>
            )}
          </div>
          <button
            onClick={toggleHeart}
            aria-label={saved ? 'Remove from wishlist' : 'Add to wishlist'}
            aria-pressed={saved}
            className="absolute right-2 top-2 z-10 flex h-8 w-8 items-center justify-center rounded-full bg-white/90 shadow hover:scale-110"
          >
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill={saved ? '#e0245e' : 'none'}
              stroke={saved ? '#e0245e' : '#555'}
              strokeWidth="2"
              aria-hidden="true"
            >
              <path d="M12 21s-7.5-4.9-9.7-9.2C.7 8.6 2.6 5 6.1 5c2 0 3.4 1.1 4.2 2.3l1.7 2 1.7-2c.8-1.2 2.2-2.3 4.2-2.3 3.5 0 5.4 3.6 3.8 6.8C19.5 16.1 12 21 12 21z" />
            </svg>
          </button>
          <span className="card-customize">
            {out ? 'View anyway' : 'Make it yours'} <ArrowRightIcon />
          </span>
        </div>
        <div className="card-info">
          <p className="card-meta">
            {product.categoryName} ·{' '}
            {productFormats(product).length > 1
              ? `${productFormats(product).length} size options`
              : 'Personalise it'}
          </p>
          <h3>{product.name}</h3>
          {(product.review_count ?? 0) > 0 && (
            <span className="mt-1 flex items-center gap-1.5">
              <Stars value={product.avg_rating ?? 0} size={13} />
              <span className="text-xs text-muted">{product.review_count}</span>
            </span>
          )}
          <p className="card-story">{productStory(product)}</p>
          <div className="card-price">
            <strong>
              {product.basePrice > 0 && <small>From </small>}
              {formatPrice(product.basePrice)}
              {sale && (
                <small className="ml-2 text-muted line-through">
                  M.R.P. {formatPrice(sale.mrp)}
                </small>
              )}
            </strong>
            <span>{product.minimum}</span>
          </div>
        </div>
      </Link>
    </AntiGravityWrap>
  )
}
