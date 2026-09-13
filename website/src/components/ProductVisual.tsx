import type { SyntheticEvent } from 'react'
import { categoryStories, photoUrl } from '../data/shopping'
import { formatRatio } from '../lib/printOptions'
import { appAsset } from '../lib/assets'
import type { CatalogProduct } from '../data/products'

const FALLBACK_IMAGE = appAsset('images/memories-still-life.jpg')

function imageFallback(event: SyntheticEvent<HTMLImageElement>) {
  const image = event.currentTarget
  if (!image.src.endsWith('/images/memories-still-life.jpg'))
    image.src = FALLBACK_IMAGE
}

export function ProductVisual({
  product,
  categoryId,
  photo,
  className = '',
  fit = 'cover',
  size,
}: {
  product?: CatalogProduct
  categoryId?: string
  photo?: string
  className?: string
  fit?: 'cover' | 'contain'
  size?: string
}) {
  const category =
    categoryStories[product?.categoryId ?? categoryId ?? 'photo-prints']
  const type = product?.id.includes('canvas') ? 'canvas' : category.type
  const classic =
    product?.categoryId === 'photo-prints' &&
    product.id !== 'retro-polaroid-prints'
  const ratio = formatRatio(size ?? product?.sizes[0] ?? '')
  const proportional =
    ratio && ['frame', 'canvas', 'prints'].includes(type)
      ? {
          width: `${ratio >= 1 ? 72 : 65 * ratio}%`,
          height: `${ratio >= 1 ? 72 / ratio : 65}%`,
        }
      : undefined
  // Only use shaped mockups for the products they represent. Other gift formats retain their own image.
  const genericGift =
    product?.categoryId === 'personalized-gifts' && !product.id.includes('mug')
  const image =
    photo ??
    (product?.categoryId === 'photo-books' &&
    product.id !== 'classic-photo-albums'
      ? product.imageUrl
      : photoUrl(category.image))
  return (
    <div
      className={`product-visual visual-${genericGift ? 'photo' : type} ${classic ? 'classic-print' : ''} ${className}`}
      aria-label={
        product ? `Illustrative preview of ${product.name}` : undefined
      }
    >
      {genericGift ? (
        <img
          src={photo ?? product.imageUrl}
          alt="Product inspiration"
          loading="lazy"
          onError={imageFallback}
        />
      ) : (
        <>
          {type === 'prints' && (
            <>
              <div className="print-behind" />
              <div className="print-behind second" />
            </>
          )}
          <div className="product-object" style={proportional}>
            <img
              src={image}
              alt=""
              loading="lazy"
              onError={imageFallback}
              style={{ objectFit: fit }}
            />
            {type === 'book' && <span>THE GOOD DAYS</span>}
            {type === 'prints' && !classic && (
              <span>a moment worth keeping</span>
            )}
          </div>
        </>
      )}
    </div>
  )
}
