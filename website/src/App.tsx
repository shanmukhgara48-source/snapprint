import { Suspense, lazy, useEffect, useState } from 'react'
import {
  BrowserRouter,
  Link,
  Route,
  Routes,
  useLocation,
  useNavigationType,
  Navigate,
  useParams,
} from 'react-router-dom'
import { Nav } from './components/Nav'
import { Footer } from './components/Footer'
import { PrintPlanProvider } from './context/PrintPlan'
import { WishlistProvider } from './context/Wishlist'
import { ToastProvider } from './context/Toast'
import { ErrorBoundary } from './components/ErrorBoundary'
import { AntiGravityCanvas } from './components/antiGravity/AntiGravityCanvas'
import { CursorAura } from './components/antiGravity/CursorAura'
import { api, getAuthToken } from './services/api'
import { getProductionConfigWarnings, getWpBasename, IS_WP_EMBED } from './config/env'

// Route-level code splitting: each page loads on demand.
const Home = lazy(() =>
  import('./pages/Home').then((m) => ({ default: m.Home })),
)
const Products = lazy(() =>
  import('./pages/Products').then((m) => ({ default: m.Products })),
)
const Pricing = lazy(() =>
  import('./pages/Pricing').then((m) => ({ default: m.Pricing })),
)
const Contact = lazy(() =>
  import('./pages/Contact').then((m) => ({ default: m.Contact })),
)
const Terms = lazy(() =>
  import('./pages/Terms').then((m) => ({ default: m.Terms })),
)
const Privacy = lazy(() =>
  import('./pages/Privacy').then((m) => ({ default: m.Privacy })),
)
const Shipping = lazy(() =>
  import('./pages/Shipping').then((m) => ({ default: m.Shipping })),
)
const Refund = lazy(() =>
  import('./pages/Refund').then((m) => ({ default: m.Refund })),
)
const Auth = lazy(() => import('./pages/Auth').then((m) => ({ default: m.Auth })))
const Account = lazy(() =>
  import('./pages/Account').then((m) => ({ default: m.Account })),
)
const Orders = lazy(() =>
  import('./pages/Orders').then((m) => ({ default: m.Orders })),
)
const PrintPlan = lazy(() =>
  import('./pages/PrintPlan').then((m) => ({ default: m.PrintPlan })),
)
const Checkout = lazy(() =>
  import('./pages/Checkout').then((m) => ({ default: m.Checkout })),
)
const Payment = lazy(() =>
  import('./pages/Payment').then((m) => ({ default: m.Payment })),
)
const Success = lazy(() =>
  import('./pages/Success').then((m) => ({ default: m.Success })),
)
const ProductDetail = lazy(() =>
  import('./pages/ProductDetail').then((m) => ({ default: m.ProductDetail })),
)
const Wishlist = lazy(() =>
  import('./pages/Wishlist').then((m) => ({ default: m.Wishlist })),
)

function ScrollToTop() {
  const { pathname, search } = useLocation()
  const navigationType = useNavigationType()
  useEffect(() => {
    if (IS_WP_EMBED) return // WordPress/SEO plugin owns the document head
    if (navigationType !== 'REPLACE') {
      try {
        window.scrollTo({ top: 0, behavior: 'instant' as ScrollBehavior })
      } catch {
        // Older browsers (e.g. Safari < 18) reject the 'instant' enum —
        // fall back instead of throwing on every navigation.
        window.scrollTo(0, 0)
      }
    }
    if (pathname === '/') {
      document.title = 'SnapPrint — Photo Prints, Albums, Frames & Gifts'
    }
  }, [pathname, search, navigationType])
  return null
}

function PageFallback() {
  return (
    <div className="wrap py-12 text-center">
      <p className="text-muted" role="status">
        Loading…
      </p>
    </div>
  )
}

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const [checking, setChecking] = useState(true)
  const [authenticated, setAuthenticated] = useState(false)

  useEffect(() => {
    const token = getAuthToken()
    if (!token) {
      setAuthenticated(false)
      setChecking(false)
      return
    }
    let cancelled = false
    api
      .getOrders()
      .then(() => {
        if (!cancelled) {
          setAuthenticated(true)
          setChecking(false)
        }
      })
      .catch(() => {
        if (!cancelled) {
          setAuthenticated(false)
          setChecking(false)
        }
      })
    return () => {
      cancelled = true
    }
  }, [])

  if (checking) {
    return (
      <div className="wrap py-12 text-center">
        <p className="text-muted" role="status">
          Verifying session...
        </p>
      </div>
    )
  }

  if (!authenticated) {
    return <Navigate to="/auth" replace />
  }

  return <>{children}</>
}

function ProductionWarnings() {
  const [warnings] = useState(getProductionConfigWarnings)
  if (warnings.length === 0) return null
  return (
    <div className="border-b border-amber-200 bg-amber-50 px-4 py-2 text-center text-xs text-amber-800">
      {warnings.join(' ')}
    </div>
  )
}

export default function App() {
  return (
    <BrowserRouter basename={getWpBasename()}>
      <PrintPlanProvider>
        <WishlistProvider>
          <ToastProvider>
          <ErrorBoundary>
            <ScrollToTop />
            <AntiGravityCanvas />
            <CursorAura />
            <div className="flex min-h-screen flex-col">
              <ProductionWarnings />
              <Nav />
              <main id="main" tabIndex={-1} className="flex-1">
                <Suspense fallback={<PageFallback />}>
                  <Routes>
                    <Route path="/" element={<Home />} />
                    <Route path="/products/:id" element={<ProductDetail />} />
                    <Route path="/card" element={<PrintPlan />} />
                    <Route
                      path="/plan"
                      element={<Navigate to="/card" replace />}
                    />
                    <Route path="/checkout" element={<Checkout />} />
                    <Route path="/payment" element={<Payment />} />
                    <Route path="/success" element={<Success />} />
                    <Route path="/products" element={<Products />} />
                    <Route path="/products-services" element={<Products />} />
                    <Route path="/wishlist" element={<Wishlist />} />
                    <Route path="/pricing" element={<Pricing />} />
                    <Route path="/contact" element={<Contact />} />
                    <Route path="/terms" element={<Terms />} />
                    <Route
                      path="/terms-and-conditions"
                      element={<Terms />}
                    />
                    <Route path="/privacy" element={<Privacy />} />
                    <Route path="/privacy-policy" element={<Privacy />} />
                    <Route path="/shipping" element={<Shipping />} />
                    <Route path="/shipping-policy" element={<Shipping />} />
                    <Route path="/refund" element={<Refund />} />
                    <Route
                      path="/cancellation-refund-policy"
                      element={<Refund />}
                    />
                    <Route path="/auth" element={<Auth />} />
                    <Route
                      path="/account"
                      element={
                        <ProtectedRoute>
                          <Account />
                        </ProtectedRoute>
                      }
                    />
                    <Route
                      path="/orders"
                      element={
                        <ProtectedRoute>
                          <Orders />
                        </ProtectedRoute>
                      }
                    />
                    <Route
                      path="/orders/:id"
                      element={
                        <ProtectedRoute>
                          <OrdersDetail />
                        </ProtectedRoute>
                      }
                    />
                    <Route path="*" element={<Home />} />
                  </Routes>
                </Suspense>
              </main>
              <Footer />
            </div>
          </ErrorBoundary>
          </ToastProvider>
        </WishlistProvider>
      </PrintPlanProvider>
    </BrowserRouter>
  )
}

function OrdersDetail() {
  const { id } = useParams()
  const [order, setOrder] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let cancelled = false
    async function fetch() {
      try {
        const data = await api.getOrder(id!)
        if (!cancelled) setOrder(data)
      } catch (err: any) {
        if (!cancelled) setError(err.message || 'Failed to load order')
      } finally {
        if (!cancelled) setLoading(false)
      }
    }
    fetch()
    return () => {
      cancelled = true
    }
  }, [id])

  if (loading)
    return (
      <div className="wrap py-12 text-center">
        <p className="text-muted" role="status">
          Loading order...
        </p>
      </div>
    )
  if (error || !order)
    return (
      <div className="wrap py-12 text-center">
        <p className="text-red-600" role="alert">
          {error || 'Order not found'}
        </p>
        <Link to="/orders" className="text-accent mt-4 inline-block underline">
          ← Back to orders
        </Link>
      </div>
    )

  return (
    <div className="wrap mx-auto max-w-3xl py-12">
      <h1 className="hero-title mb-4">
        Order #{order.id?.slice(0, 8).toUpperCase()}
      </h1>
      <div className="glass rounded-xl border border-border p-6">
        <p>
          Status:{' '}
          <span className="font-semibold capitalize">{order.status}</span>
        </p>
        <p>Total: ₹{order.total_price?.toLocaleString('en-IN')}</p>
        <p>Date: {new Date(order.created_at).toLocaleDateString('en-IN')}</p>
        {order.delivery_address && <p>Address: {order.delivery_address}</p>}
        {order.estimated_delivery && (
          <p>
            Est. delivery:{' '}
            {new Date(order.estimated_delivery).toLocaleDateString('en-IN')}
          </p>
        )}
        <h2 className="font-display mt-4 mb-2">Items</h2>
        {order.items?.map((item: any, i: number) => (
          <div key={i} className="border-t border-border pt-3">
            <p className="font-semibold">
              {item.product_name || item.product?.name}
            </p>
            <p>
              Qty: {item.quantity} × {item.selected_size}
            </p>
            <p>₹{item.unit_price?.toLocaleString('en-IN')} each</p>
          </div>
        ))}
        {order.tracking_events?.length > 0 && (
          <>
            <h2 className="font-display mt-4 mb-2">Tracking</h2>
            {order.tracking_events.map((t: any, i: number) => (
              <p key={i} className="text-muted text-sm">
                {t.status} — {new Date(t.timestamp).toLocaleString('en-IN')}
              </p>
            ))}
          </>
        )}
        <Link
          to="/orders"
          className="text-accent mt-4 inline-block underline"
        >
          ← Back to orders
        </Link>
      </div>
    </div>
  )
}
