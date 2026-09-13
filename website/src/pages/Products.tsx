import { useState, useEffect, useCallback } from 'react'
import { useSearchParams, Link } from 'react-router-dom'
import { api } from '../services/api'
import { categories, catalogProducts } from '../data/products'
import {
  categoryStories,
  curatedIds,
  moments,
  type ShoppingMoment,
} from '../data/shopping'
import { toCatalogProduct } from '../lib/products'
import { SearchSuggest } from '../components/SearchSuggest'
import { ProductCard } from '../components/ProductCard'
import { Seo } from '../components/Seo'
import { ArrowRightIcon, SearchIcon, SparkleIcon } from '../components/Icons'
import type { CatalogProduct } from '../data/products'

export function Products() {
  const [params, setParams] = useSearchParams()
  const [products, setProducts] = useState<CatalogProduct[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [usingFallback, setUsingFallback] = useState(false)
  const categoryId = params.get('category') ?? undefined
  const category = categories.find((c) => c.id === categoryId)
  const selectedOccasionId = params.get('occasion') ?? null
  const occasion: ShoppingMoment | undefined = selectedOccasionId
    ? moments.find((moment) => moment.id === selectedOccasionId)
    : undefined
  const query = params.get('q') ?? ''
  const sort = params.get('sort') ?? 'recommended'
  const budget = params.get('budget') ?? 'all'
  const guide = params.get('guide') === '1' && !category && !occasion

  const fetchProducts = useCallback(async () => {
    try {
      setLoading(true)
      setError('')
      setUsingFallback(false)
      // Primary: real backend catalogue (authoritative names/prices).
      const data = await api.getProducts(category?.name ?? categoryId)
      const adapted = (data.items || []).map(toCatalogProduct)
      if (adapted.length > 0) {
        setProducts(adapted)
        // Star aggregates in one batched call (no N+1).
        try {
          const ratings = await api.getBatchRatings(adapted.map((p) => p.id))
          setProducts(
            adapted.map((p) => ({
              ...p,
              avg_rating: ratings[p.id]?.avg ?? 0,
              review_count: ratings[p.id]?.count ?? 0,
            })),
          )
        } catch {
          /* ratings are decorative — catalogue still renders */
        }
      } else {
        // Backend reachable but empty for this filter — show empty state,
        // not the static catalogue (avoids advertising unavailable items).
        setProducts([])
      }
    } catch {
      // Backend unreachable: fall back to the bundled catalogue for
      // browsing only. Checkout/payment always re-validates server-side,
      // so fallback prices can never become an order total.
      const fallback = category
        ? catalogProducts.filter((p) => p.categoryId === category.id)
        : catalogProducts
      setProducts(fallback)
      setUsingFallback(true)
      setError('')
    } finally {
      setLoading(false)
    }
  }, [categoryId, category?.name])

  useEffect(() => {
    fetchProducts()
  }, [fetchProducts])

  function clearFilters() {
    setParams({}, { replace: true })
  }
  function change(key: string, value: string) {
    setParams(
      (prev) => {
        const next = new URLSearchParams(prev)
        if (value && value !== 'all') next.set(key, value)
        else next.delete(key)
        return next
      },
      { replace: true },
    )
  }

  const visible = products
    .filter(
      (p) =>
        (!query.trim() ||
          [p.name, p.summary, p.finish, p.minimum, ...p.sizes]
            .join(' ')
            .toLowerCase()
            .includes(query.trim().toLowerCase())) &&
        (budget !== '500' || (p.basePrice > 0 && p.basePrice <= 500)),
    )
    .sort((a: CatalogProduct, b: CatalogProduct) =>
      sort === 'low'
        ? (a.basePrice || Infinity) - (b.basePrice || Infinity)
        : sort === 'high'
          ? (b.basePrice || -1) - (a.basePrice || -1)
          : (curatedIds.includes(b.id) ? 1 : 0) -
            (curatedIds.includes(a.id) ? 1 : 0),
    )

  return (
    <div className="collection-page wrap">
      <Seo
        title={
          category
            ? `${category.name} | SnapPrint`
            : 'Find your favourite print | SnapPrint'
        }
        description="Browse SnapPrint photo prints, albums, frames, wall decor and personalised gifts."
        path="/products"
      />
      <div className="breadcrumbs">
        <Link to="/">Home</Link>
        <span>/</span>
        <span>The collection</span>
      </div>
      <div className="collection-intro">
        <p className="eyebrow">MAKE SOMETHING ONLY YOU COULD MAKE</p>
        <h1>
          {occasion
            ? occasion.label
            : category && categoryStories[category.id]
              ? categoryStories[category.id].title
              : 'A memory. A thousand possibilities.'}
        </h1>
        <p>
          {occasion
            ? occasion.description
            : category && categoryStories[category.id]
              ? categoryStories[category.id].description
              : 'For your walls, your shelves, and your favourite people. Find a little something that feels like you.'}
        </p>
      </div>
      {usingFallback && (
        <p role="status" className="field-note" style={{ marginBottom: 12 }}>
          Showing the offline catalogue — prices are estimates and will be
          confirmed from the server at checkout.
        </p>
      )}
      {guide ? (
        <section className="shopping-guide" aria-label="Find your print">
          <div>
            <SparkleIcon />
            <p className="eyebrow">YOUR LITTLE PRINT GUIDE</p>
            <h2>What do you have in mind?</h2>
            <p>Start with the feeling. We'll help narrow things down.</p>
          </div>
          <div className="guide-choices">
            {moments.map((moment) => (
              <button
                key={moment.id}
                aria-pressed={selectedOccasionId === moment.id}
                className={selectedOccasionId === moment.id ? 'selected' : ''}
                onClick={() => {
                  setParams((prev) => {
                    const next = new URLSearchParams(prev)
                    next.delete('guide')
                    next.set('occasion', moment.id)
                    return next
                  }, { replace: true })
                }}
              >
                {moment.short}
                <span>{moment.description}</span>
                <ArrowRightIcon />
              </button>
            ))}
          </div>
          <div className="guide-budget">
            <span>A little something, or a bigger gesture?</span>
            <button
              className={budget === 'all' ? 'selected' : ''}
              aria-pressed={budget === 'all'}
              onClick={() => change('budget', 'all')}
            >
              Any budget
            </button>
            <button
              className={budget === '500' ? 'selected' : ''}
              aria-pressed={budget === '500'}
              onClick={() => change('budget', '500')}
            >
              Starting at ₹500 or less
            </button>
          </div>
        </section>
      ) : (
        <Link className="collection-helper" to="/products">
          <SparkleIcon />
          <span>
            Not sure where to start? <strong>Find your perfect print</strong>
          </span>
          <ArrowRightIcon />
        </Link>
      )}
      <div className="collection-controls">
        <div className="filter-chips" aria-label="Product categories">
          <button
            className={!category ? 'selected' : ''}
            aria-pressed={!category}
            onClick={() => change('category', 'all')}
          >
            All products
          </button>
          {categories.map((c) => (
            <button
              className={category?.id === c.id ? 'selected' : ''}
              aria-pressed={category?.id === c.id}
              key={c.id}
              onClick={() => change('category', c.id)}
            >
              {c.name}
            </button>
          ))}
        </div>
        <div className="search-sort">
          <label className="product-search" style={{ position: 'relative' }}>
            <SearchIcon />
            <input
              aria-label="Search products, sizes and finishes"
              placeholder="Try 'retro', 'canvas', or '6x4'"
              value={query}
              onChange={(e) => change('q', e.target.value)}
            />
            <SearchSuggest query={query} onPick={() => {}} />
          </label>
          <label className="sort-label">
            Sort by{' '}
            <select
              value={sort}
              onChange={(e) => change('sort', e.target.value)}
            >
              <option value="recommended">Recommended</option>
              <option value="low">Price: low to high</option>
              <option value="high">Price: high to low</option>
            </select>
          </label>
        </div>
      </div>
      <div className="results-heading">
        <p role="status">
          {visible.length} {visible.length === 1 ? 'way' : 'ways'} to make it
          yours{occasion ? ` · ${occasion.short}` : ''}
        </p>
        {(occasion || query || category || budget !== 'all') && (
          <button className="text-link" onClick={clearFilters}>
            Clear filters ×
          </button>
        )}
      </div>
      <div className="product-grid">
        {loading ? (
          <p role="status">Loading products...</p>
        ) : error ? (
          <div className="empty-state">
            <h2>Something went wrong</h2>
            <p>{error}</p>
            <button className="shop-button" onClick={fetchProducts}>
              Try again <ArrowRightIcon />
            </button>
          </div>
        ) : visible.length === 0 ? (
          <div className="empty-state">
            <h2>No matches just yet.</h2>
            <p>Try another size, a broader search, or a different budget.</p>
            <button className="shop-button" onClick={clearFilters}>
              Show me all products <ArrowRightIcon />
            </button>
          </div>
        ) : (
          visible.map((p) => <ProductCard product={p} key={p.id} />)
        )}
      </div>
      <p className="visual-note">
        Illustrative product previews. Starting prices vary with size, finish
        and quantity; final totals are confirmed at checkout.{' '}
        <Link to="/pricing">See full pricing</Link>.
      </p>
    </div>
  )
}
