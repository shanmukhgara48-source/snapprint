import { useMemo, useState } from 'react'
import {
  catalogProducts,
  categories,
  formatPrice,
  formatPriceRange,
  overallPriceRange,
  productCount,
  trendingProducts,
} from '../data/products'
import type { CatalogProduct } from '../data/products'
import { sameDayDeliveryNote } from '../data/delivery'
import { Reveal } from '../components/Reveal'
import { Button } from '../components/Button'
import { handleSpotlight } from '../lib/spotlight'
import {
  ArrowRightIcon,
  BookOpenIcon,
  CameraIcon,
  FrameIcon,
  GiftIcon,
  PackageIcon,
  SearchIcon,
} from '../components/Icons'

function CategoryIcon({ icon, className = 'h-5 w-5' }: { icon: string; className?: string }) {
  if (icon === 'book') return <BookOpenIcon className={className} />
  if (icon === 'frame') return <FrameIcon className={className} />
  if (icon === 'gift') return <GiftIcon className={className} />
  return <CameraIcon className={className} />
}

function ProductCard({ product }: { product: CatalogProduct }) {
  const visibleSizes = product.sizes.slice(0, 3)
  const remainingSizes = product.sizes.length - visibleSizes.length

  return (
    <article
      onMouseMove={handleSpotlight}
      className="spotlight group flex h-full flex-col overflow-hidden rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] transition-all duration-500 ease-[cubic-bezier(0.16,1,0.3,1)] hover:-translate-y-1.5 hover:border-[var(--color-accent)]/60 hover:shadow-[0_28px_74px_-38px_rgba(212,175,55,0.8)]"
    >
      <div className="image-vignette photo-corner relative aspect-[4/3] bg-black">
        <img
          src={product.imageUrl}
          alt={product.name}
          loading="lazy"
          decoding="async"
          className="h-full w-full object-cover transition-transform duration-700 ease-[cubic-bezier(0.16,1,0.3,1)] group-hover:scale-110"
        />
      </div>
      <div className="flex flex-1 flex-col p-5">
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="text-xs font-semibold tracking-wide text-[var(--color-muted-2)] uppercase">
              {product.categoryName}
            </p>
            <h3 className="font-display mt-1.5 font-semibold leading-snug text-[var(--color-ink)] transition-colors duration-300 group-hover:text-[var(--color-accent)]">
              {product.name}
            </h3>
          </div>
          {product.isTrending && (
            <span className="animate-pulse-soft shrink-0 rounded-full border border-[var(--color-accent)]/40 bg-[var(--color-accent-soft)] px-2 py-1 text-[0.68rem] font-extrabold tracking-wide text-[var(--color-accent)] uppercase">
              Trending
            </span>
          )}
        </div>
        <p className="mt-3 flex-1 text-sm leading-6 text-[var(--color-muted)]">{product.summary}</p>
        <div className="mt-4 flex flex-wrap gap-2">
          {visibleSizes.map((size) => (
            <span
              key={size}
              className="rounded-full border border-[var(--color-border-strong)] px-2.5 py-1 text-xs text-[var(--color-muted)]"
            >
              {size}
            </span>
          ))}
          {remainingSizes > 0 && (
            <span className="rounded-full border border-[var(--color-border-strong)] px-2.5 py-1 text-xs text-[var(--color-muted)]">
              +{remainingSizes} more
            </span>
          )}
        </div>
        <div className="mt-5 flex items-end justify-between gap-3 border-t border-[var(--color-border)] pt-4">
          <div>
            <p className="text-xs font-semibold tracking-wide text-[var(--color-muted-2)] uppercase">Base price</p>
            <p className="mt-1 text-xl font-extrabold text-[var(--color-accent)]">
              {formatPrice(product.basePrice)}
            </p>
          </div>
          <p className="text-right text-xs leading-5 text-[var(--color-muted-2)]">
            {product.minimum || product.quantity || 'Custom order'}
          </p>
        </div>
      </div>
    </article>
  )
}

export function Products() {
  const [activeId, setActiveId] = useState('all')
  const [query, setQuery] = useState('')
  const activeCategory = useMemo(
    () => categories.find((category) => category.id === activeId),
    [activeId],
  )
  const scopedProducts = activeCategory ? activeCategory.products : catalogProducts
  const normalizedQuery = query.trim().toLowerCase()
  const visibleProducts = useMemo(() => {
    if (!normalizedQuery) return scopedProducts
    return scopedProducts.filter((product) => {
      const haystack = [
        product.name,
        product.categoryName,
        product.summary,
        product.minimum,
        product.finish,
        product.sizes.join(' '),
      ]
        .join(' ')
        .toLowerCase()
      return haystack.includes(normalizedQuery)
    })
  }, [normalizedQuery, scopedProducts])
  const categoryTitle = activeCategory?.name ?? 'All products'
  const categoryDescription =
    activeCategory?.description ??
    'Search the complete SnapPrint catalog across prints, albums, frames, wall decor, and personalised gifts.'
  const categoryImage = activeCategory?.imageUrl ?? trendingProducts[0]?.imageUrl ?? categories[0].imageUrl
  const categoryRange = activeCategory?.priceRange ?? overallPriceRange
  const hasPriceOnRequest =
    activeCategory?.hasPriceOnRequest ?? catalogProducts.some((product) => product.basePrice === 0)

  return (
    <div>
      <section className="ambient-glow border-b border-[var(--color-border)] px-6 py-16 sm:py-24">
        <div className="mx-auto max-w-6xl">
          <span className="text-xs font-semibold tracking-[0.2em] text-[var(--color-accent)] uppercase">
            Products and services
          </span>
          <div className="mt-4 grid gap-8 lg:grid-cols-[1fr_360px] lg:items-end">
            <div>
              <h1 className="font-display text-4xl font-semibold tracking-normal text-balance sm:text-6xl">
                The SnapPrint catalog
              </h1>
              <p className="mt-4 max-w-2xl leading-7 text-[var(--color-muted)]">
                Browse our full range of photo prints, photo books, frames, wall decor, and
                personalised gifts by category, then confirm final size, finish, quantity,
                delivery, and total in the SnapPrint app at checkout.
              </p>
            </div>
            <div className="rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] p-5">
              <p className="text-3xl font-extrabold text-[var(--color-accent)]">{productCount}</p>
              <p className="mt-1 text-sm font-semibold text-[var(--color-ink)]">catalog products</p>
              <p className="mt-2 text-sm leading-6 text-[var(--color-muted)]">
                {sameDayDeliveryNote}
              </p>
            </div>
          </div>
        </div>
      </section>

      <div className="sticky top-[64px] z-40 border-b border-[var(--color-border)] bg-[var(--color-bg)]/92 backdrop-blur-lg">
        <div
          className="mx-auto flex max-w-6xl gap-2 overflow-x-auto px-6 py-3"
          role="tablist"
          aria-label="Product categories"
        >
          <button
            type="button"
            role="tab"
            aria-selected={activeId === 'all'}
            onClick={() => setActiveId('all')}
            className={`inline-flex shrink-0 items-center gap-2 rounded-full border px-4 py-2 text-sm font-semibold whitespace-nowrap transition-colors ${
              activeId === 'all'
                ? 'border-[var(--color-accent)] bg-[var(--color-accent-soft)] text-[var(--color-accent)]'
                : 'border-[var(--color-border-strong)] text-[var(--color-muted)] hover:text-[var(--color-ink)]'
            }`}
          >
            <PackageIcon className="h-4 w-4" />
            All products
          </button>
          {categories.map((category) => (
            <button
              key={category.id}
              type="button"
              role="tab"
              aria-selected={activeId === category.id}
              onClick={() => setActiveId(category.id)}
              className={`inline-flex shrink-0 items-center gap-2 rounded-full border px-4 py-2 text-sm font-semibold whitespace-nowrap transition-colors ${
                activeId === category.id
                  ? 'border-[var(--color-accent)] bg-[var(--color-accent-soft)] text-[var(--color-accent)]'
                  : 'border-[var(--color-border-strong)] text-[var(--color-muted)] hover:text-[var(--color-ink)]'
              }`}
            >
              <CategoryIcon icon={category.icon} className="h-4 w-4" />
              {category.name}
            </button>
          ))}
        </div>
      </div>

      <section className="mx-auto max-w-6xl px-6 py-16 sm:py-24">
        <div className="grid gap-8 lg:grid-cols-[320px_1fr]">
          <aside className="lg:sticky lg:top-36 lg:self-start">
            <div className="overflow-hidden rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)]">
              <div className="image-vignette aspect-[5/3]">
                <img
                  src={categoryImage}
                  alt={categoryTitle}
                  loading="eager"
                  decoding="async"
                  className="h-full w-full object-cover"
                />
              </div>
              <div className="p-6">
                <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-[var(--color-accent-soft)] text-[var(--color-accent)]">
                  {activeCategory ? <CategoryIcon icon={activeCategory.icon} /> : <PackageIcon className="h-5 w-5" />}
                </span>
                <h2 className="font-display mt-5 text-2xl font-semibold tracking-normal">{categoryTitle}</h2>
                <p className="mt-3 text-sm leading-6 text-[var(--color-muted)]">{categoryDescription}</p>
                <div className="mt-5 border-t border-[var(--color-border)] pt-5">
                  <p className="text-xs font-semibold tracking-wide text-[var(--color-muted-2)] uppercase">
                    Price range
                  </p>
                  <p className="mt-1 text-xl font-extrabold text-[var(--color-accent)]">
                    {formatPriceRange(categoryRange)}
                  </p>
                  {hasPriceOnRequest && (
                    <p className="mt-2 text-xs text-[var(--color-muted-2)]">
                      Some products are price on request.
                    </p>
                  )}
                </div>
              </div>
            </div>
          </aside>

          <div>
            <div className="flex flex-wrap items-end justify-between gap-4">
              <div>
                <p className="text-xs font-semibold tracking-[0.2em] text-[var(--color-accent)] uppercase">
                  {visibleProducts.length} of {scopedProducts.length} products
                </p>
                <h2 className="font-display mt-2 text-2xl font-semibold tracking-normal sm:text-3xl">
                  {categoryTitle}
                </h2>
              </div>
              <Button to="/pricing" variant="secondary" className="!px-5 !py-2.5">
                Pricing Table
                <ArrowRightIcon className="h-4 w-4" />
              </Button>
            </div>

            <label className="mt-6 flex items-center gap-3 rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] px-4 py-3 text-sm text-[var(--color-muted)] focus-within:border-[var(--color-accent)]">
              <SearchIcon className="h-5 w-5 shrink-0 text-[var(--color-accent)]" />
              <span className="sr-only">Search catalog</span>
              <input
                value={query}
                onChange={(event) => setQuery(event.target.value)}
                placeholder="Search products, sizes, finishes, or occasions"
                className="w-full bg-transparent text-[var(--color-ink)] outline-none placeholder:text-[var(--color-muted-2)]"
              />
            </label>

            <div className="mt-8 grid gap-6 sm:grid-cols-2 xl:grid-cols-3">
              {visibleProducts.map((product, index) => (
                <Reveal key={product.id} delay={index < 9 ? index * 35 : 0}>
                  <ProductCard product={product} />
                </Reveal>
              ))}
            </div>
            {visibleProducts.length === 0 && (
              <div className="mt-8 rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] p-8 text-center">
                <p className="font-display text-2xl font-semibold">No matching products</p>
                <p className="mt-2 text-sm text-[var(--color-muted)]">
                  Try a broader term like album, frame, canvas, mug, poster, or print.
                </p>
              </div>
            )}
          </div>
        </div>
      </section>

      <section className="border-t border-[var(--color-border)] bg-[var(--color-bg-soft)]">
        <div className="mx-auto max-w-6xl px-6 py-16 sm:py-24">
          <div className="grid gap-8 lg:grid-cols-[0.8fr_1.2fr] lg:items-center">
            <Reveal>
              <span className="text-xs font-semibold tracking-[0.2em] text-[var(--color-accent)] uppercase">
                Trending now
              </span>
              <h2 className="font-display mt-3 text-3xl font-semibold tracking-normal sm:text-4xl">
                Popular picks from our catalog
              </h2>
            </Reveal>
            <div className="grid gap-4 sm:grid-cols-2">
              {trendingProducts.slice(0, 6).map((product, index) => (
                <Reveal key={product.id} delay={index * 60}>
                  <div className="group flex gap-4 rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] p-4 transition-all duration-300 ease-[cubic-bezier(0.16,1,0.3,1)] hover:-translate-y-1 hover:border-[var(--color-accent)]/50 hover:shadow-[0_16px_44px_-26px_rgba(212,175,55,0.7)]">
                    <div className="h-18 w-18 shrink-0 overflow-hidden rounded-xl">
                      <img
                        src={product.imageUrl}
                        alt={product.name}
                        loading="lazy"
                        decoding="async"
                        className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-110"
                      />
                    </div>
                    <div>
                      <p className="font-bold leading-snug transition-colors duration-300 group-hover:text-[var(--color-accent)]">
                        {product.name}
                      </p>
                      <p className="mt-1 text-sm text-[var(--color-accent)]">{formatPrice(product.basePrice)}</p>
                      <p className="mt-1 text-xs text-[var(--color-muted-2)]">{product.categoryName}</p>
                    </div>
                  </div>
                </Reveal>
              ))}
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}
