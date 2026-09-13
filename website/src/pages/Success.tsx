import { useState, useEffect, useRef } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { usePrintPlan } from '../context/PrintPlan'
import { api, getAuthToken } from '../services/api'
import { formatPrice } from '../data/products'
import { ArrowRightIcon } from '../components/Icons'
import { Reveal } from '../components/Reveal'
import { Seo } from '../components/Seo'
import { AntiGravityWrap } from '../components/antiGravity/AntiGravityWrap'

interface OrderDetail {
  id: string
  total_price: number
  status: string
  created_at: string
  item_count: number
  delivery_address: string | null
  estimated_delivery: string | null
  tracking_events: Array<{ status: string; timestamp: string }>
}

/**
 * Success is reachable ONLY with a real backend order id (?order=<id>).
 * The order is re-fetched from the backend (ownership enforced server-side:
 * GET /orders/{id} is scoped to the authenticated customer). There are no
 * generated or fallback order numbers anywhere in this flow.
 */
export function Success() {
  const { clearCart } = usePrintPlan()
  const navigate = useNavigate()
  const [params] = useSearchParams()
  const [order, setOrder] = useState<OrderDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const clearedRef = useRef(false)
  const orderRef = params.get('order')

  useEffect(() => {
    async function fetchOrder() {
      if (!orderRef) {
        // No real order reference — this page proves nothing. Send the
        // customer somewhere useful instead of inventing a number.
        navigate('/orders', { replace: true })
        return
      }
      if (!getAuthToken()) {
        navigate('/auth', { replace: true })
        return
      }
      try {
        const data = await api.getOrder(orderRef)
        setOrder(data)
        if (!clearedRef.current) {
          clearedRef.current = true
          clearCart()
        }
      } catch (err: any) {
        const status = err?.status as number | undefined
        if (status === 404) {
          setError(
            'We could not find that order on your account. It may belong to a different sign-in.',
          )
        } else {
          setError(
            err?.message || 'Could not load your order. Please try again.',
          )
        }
      } finally {
        setLoading(false)
      }
    }
    fetchOrder()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [orderRef])

  if (loading) {
    return (
      <div className="wrap flex min-h-[60vh] flex-col items-center justify-center py-20 text-center">
        <p className="text-muted" role="status">
          Confirming your order…
        </p>
      </div>
    )
  }

  if (error || !order) {
    return (
      <div className="wrap flex min-h-[60vh] flex-col items-center justify-center py-20 text-center">
        <h1 className="hero-title mb-4">Order status unclear</h1>
        <p className="text-muted mb-8 max-w-lg">{error}</p>
        <div className="flex gap-4">
          <Link to="/orders" className="shop-button inline-flex">
            View My Orders <ArrowRightIcon />
          </Link>
          <Link to="/products" className="text-link self-center">
            Continue Shopping
          </Link>
        </div>
      </div>
    )
  }

  return (
    <div className="wrap flex min-h-[60vh] flex-col items-center justify-center py-20 text-center">
      <Seo
        title="Order confirmed | SnapPrint"
        description="Your SnapPrint order has been confirmed."
        path="/success"
        noindex
      />
      <Reveal>
        <AntiGravityWrap intensity={5} scaleOnHover={1.05}>
          <div className="mx-auto mb-8 flex h-20 w-20 items-center justify-center rounded-full bg-green-100 text-green-600 shadow-sm">
            <svg
              width="40"
              height="40"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.5"
              strokeLinecap="round"
              strokeLinejoin="round"
              aria-hidden="true"
            >
              <polyline points="20 6 9 17 4 12"></polyline>
            </svg>
          </div>
        </AntiGravityWrap>

        <h1 className="hero-title mb-4">Payment Successful!</h1>
        <p className="text-muted mx-auto mb-8 max-w-lg text-xl">
          Thank you for your order. Your memories are being prepared.
        </p>

        <div className="glass bg-surface mx-auto mb-10 max-w-sm rounded-lg border border-border p-6 text-left">
          <p className="text-muted mb-1 text-sm">Order Reference</p>
          <p className="font-display text-2xl font-bold">
            #{order.id.slice(0, 8).toUpperCase()}
          </p>
          <hr className="my-4 border-border" />
          <dl className="space-y-2 text-sm">
            <div className="flex justify-between">
              <dt className="text-muted">Status</dt>
              <dd className="font-semibold capitalize">{order.status}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-muted">Total paid</dt>
              <dd className="font-semibold">
                {formatPrice(order.total_price)}
              </dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-muted">Items</dt>
              <dd>{order.item_count}</dd>
            </div>
            {order.delivery_address && (
              <div>
                <dt className="text-muted">Delivering to</dt>
                <dd>{order.delivery_address}</dd>
              </div>
            )}
            {order.estimated_delivery && (
              <div className="flex justify-between">
                <dt className="text-muted">Estimated delivery</dt>
                <dd>
                  {new Date(order.estimated_delivery).toLocaleDateString(
                    'en-IN',
                  )}
                </dd>
              </div>
            )}
          </dl>
          <hr className="my-4 border-border" />
          <p className="text-muted text-sm">
            A confirmation email will be sent shortly.
          </p>
        </div>

        <div className="flex flex-wrap items-center justify-center gap-4">
          <Link
            to={`/orders/${order.id}`}
            className="shop-button inline-flex"
          >
            View Order <ArrowRightIcon />
          </Link>
          <Link to="/products" className="text-link">
            Continue Shopping
          </Link>
        </div>
        <div className="mt-4">
          <Link
            to="/orders"
            className="text-muted text-sm transition-colors hover:text-ink"
          >
            Track your order →
          </Link>
        </div>
      </Reveal>
    </div>
  )
}
