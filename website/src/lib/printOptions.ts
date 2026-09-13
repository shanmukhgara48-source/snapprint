import type { CatalogProduct } from '../data/products'

// Descriptive dimensions (e.g. a mug's print area) aren't purchasable variants.
export function productFormats(product: CatalogProduct): string[] {
  return product.sizes.filter((size) => !/^(mug\s|print area\s)/i.test(size))
}

// Never turn an ambiguous minimum quantity into a misleading complete-order price.
export function startingAmount(
  product: CatalogProduct,
  groups = 1,
): number | null {
  if (product.basePrice <= 0) return null
  if (/price per piece/i.test(product.minimum)) {
    const count = Number(product.minimum.match(/^\d+/)?.[0])
    return count > 0 ? product.basePrice * count * groups : null
  }
  if (/^[2-9]\d* pieces|^\d{2,} pieces|^Set of \d+ or/i.test(product.minimum))
    return null
  return product.basePrice * groups
}

// Only a single unambiguous width × height drives the illustrative silhouette.
export function formatRatio(size: string): number | undefined {
  const dimensions = [
    ...size.matchAll(/(\d+(?:\.\d+)?)\s*x\s*(\d+(?:\.\d+)?)/gi),
  ]
  if (
    dimensions.length !== 1 ||
    /\b(?:and|Pro tiers)\b|&/i.test(size) ||
    /\bx\s*\d+\s*pieces|\bx\d+\s*\+/i.test(size)
  )
    return undefined
  const width = Number(dimensions[0][1])
  const height = Number(dimensions[0][2])
  return width > 0 && height > 0
    ? Math.max(0.4, Math.min(2.5, width / height))
    : undefined
}
