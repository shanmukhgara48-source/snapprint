import type { CatalogProduct } from '../data/products'
import { appAsset } from './assets'

/** Backend ProductOut shape (see backend/app/schemas/product.py). */
export interface BackendProduct {
  id: string
  name: string
  category: string
  category_id?: string | null
  base_price: number
  sizes: Array<{ label: string; price: number } | string | any>
  images?: string[] | null
  description?: string | null
  material?: string | null
  dimensions?: string | null
  options_summary?: string | null
  delivery_info?: string | null
  price_note?: string | null
  minimum?: string | null
  quantity?: string | null
  finish?: string | null
  sort_order?: number
  stock_quantity?: number
  tracks_inventory?: boolean
  sku?: string | null
  compare_at_price?: number | null
  is_bestseller?: boolean
  is_featured?: boolean
  is_trending?: boolean
  is_orderable?: boolean
  is_active?: boolean
}

export interface ProductRating {
  avg: number
  count: number
}

function slugify(value: string): string {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '')
}

function sizeLabel(size: BackendProduct['sizes'][number]): string | null {
  if (typeof size === 'string') return size
  if (size && typeof size === 'object' && typeof size.label === 'string') {
    return size.label
  }
  return null
}

/**
 * Adapt a backend product to the frontend catalog shape so existing UI
 * components keep working. Authoritative pricing always comes from the
 * server quote — this adapter is display-only.
 */
export function toCatalogProduct(p: BackendProduct): CatalogProduct {
  const sizes = (p.sizes || [])
    .map(sizeLabel)
    .filter((s): s is string => Boolean(s))
  return {
    id: p.id,
    name: p.name,
    categoryId: p.category_id || slugify(p.category || 'photo-prints'),
    categoryName: p.category || 'Photo Prints',
    basePrice: Number(p.base_price ?? 0),
    sizes: sizes.length > 0 ? sizes : ['Standard'],
    summary: p.description || p.options_summary || '',
    minimum: (p as any).minimum || 'Minimum order: 1',
    quantity: (p as any).quantity || 'Sets / copies',
    finish: p.material || (p as any).finish || '',
    delivery: p.delivery_info || '',
    isFeatured: Boolean(p.is_featured),
    isTrending: Boolean(p.is_trending),
    imageUrl:
      (p.images && p.images[0]) || appAsset('images/memories-still-life.jpg'),
    // Preserve live inventory so the UI can reflect the shared stock level
    // (e.g. 10 → 9 after a mobile-app purchase).
    stock_quantity:
      typeof p.stock_quantity === 'number' ? p.stock_quantity : undefined,
    tracks_inventory: Boolean(p.tracks_inventory),
    is_orderable: p.is_orderable !== false,
    sku: p.sku ?? null,
    compare_at_price:
      typeof p.compare_at_price === 'number' ? p.compare_at_price : undefined,
    is_bestseller: Boolean(p.is_bestseller),
  }
}

/** Shared-stock helpers — backend stock_quantity is the single source of truth. */
export function isOutOfStock(p: {
  stock_quantity?: number
  tracks_inventory?: boolean
  is_orderable?: boolean
}): boolean {
  if (p.is_orderable === false) return true
  return Boolean(p.tracks_inventory) && (p.stock_quantity ?? 1) <= 0
}

export function stockLabel(p: {
  stock_quantity?: number
  tracks_inventory?: boolean
}): string | null {
  if (!p.tracks_inventory || typeof p.stock_quantity !== 'number') return null
  if (p.stock_quantity <= 0) return 'Out of stock'
  if (p.stock_quantity <= 5) return `Only ${p.stock_quantity} left`
  return `${p.stock_quantity} in stock`
}

/** Amazon-style deal: strike-through MRP + % off (display-only; checkout uses server prices). */
export function saleInfo(
  basePrice: number,
  compareAt?: number,
): { mrp: number; percentOff: number } | null {
  if (typeof compareAt !== 'number' || compareAt <= basePrice || basePrice <= 0) return null
  return { mrp: compareAt, percentOff: Math.round(((compareAt - basePrice) / compareAt) * 100) }
}

/** Authoritative unit price for a size (display fallback; NOT order truth). */
export function backendSizePrice(
  p: BackendProduct,
  size: string,
): number | null {
  for (const s of p.sizes || []) {
    if (typeof s === 'object' && s && (s as any).label === size) {
      const price = Number((s as any).price)
      return Number.isFinite(price) && price > 0 ? price : null
    }
  }
  const base = Number(p.base_price ?? 0)
  return base > 0 ? base : null
}
