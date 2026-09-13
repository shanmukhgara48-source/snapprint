import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { api, getAuthToken } from '../services/api'
import { toCatalogProduct } from '../lib/products'
import { ProductCard } from '../components/ProductCard'
import { Reveal } from '../components/Reveal'
import { Seo } from '../components/Seo'
import { ArrowRightIcon } from '../components/Icons'
import { useWishlist } from '../context/Wishlist'
import type { CatalogProduct } from '../data/products'

export function Wishlist() {
  const { ids, refresh } = useWishlist()
  const [products, setProducts] = useState<CatalogProduct[]>([])
  const [loading, setLoading] = useState(true)
  const authed = Boolean(getAuthToken())

  useEffect(() => {
    refresh()
  }, [refresh])

  useEffect(() => {
    async function load() {
      if (!authed) {
        setLoading(false)
        return
      }
      try {
        const items = await api.getWishlist()
        const adapted = (items || []).map(toCatalogProduct)
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
          setProducts(adapted)
        }
      } catch {
        setProducts([])
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [authed, ids.size]) // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <div className="wrap py-12">
      <Seo title="My Wishlist | SnapPrint" description="Your saved SnapPrint prints." path="/wishlist" noindex />
      <Reveal>
        <h1 className="hero-title mb-2">My Wishlist</h1>
        <p className="text-muted mb-8">Saved on your account — synced across web and app.</p>
        {!authed ? (
          <p>
            <Link to="/auth" className="text-link">Sign in</Link> to see your wishlist.
          </p>
        ) : loading ? (
          <p role="status">Loading wishlist…</p>
        ) : products.length === 0 ? (
          <div className="empty-state">
            <h2>Nothing saved yet.</h2>
            <p>Tap the heart on any product to keep it here.</p>
            <Link to="/products" className="shop-button">
              Explore the collection <ArrowRightIcon />
            </Link>
          </div>
        ) : (
          <div className="product-grid">
            {products.map((p) => (
              <ProductCard product={p} key={p.id} />
            ))}
          </div>
        )}
      </Reveal>
    </div>
  )
}
