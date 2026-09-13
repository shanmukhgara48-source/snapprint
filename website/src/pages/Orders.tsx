import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { api } from '../services/api'
import { Reveal } from '../components/Reveal'
import { Seo } from '../components/Seo'
import { PackageIcon, TruckIcon, CheckIcon, XIcon, ClockIcon, ArrowRightIcon } from '../components/Icons'

interface Order {
  id: string
  total_price: number
  status: string
  created_at: string
  item_count: number
  delivery_address: string | null
  estimated_delivery: string | null
  tracking_events: Array<{ status: string; timestamp: string }>
}

interface ReturnInfo {
  id: string
  order_id: string
  reason: string
  status: string
  admin_note: string | null
  created_at: string
}

const RETURNABLE = new Set(['confirmed', 'picked_up', 'out_for_delivery', 'delivered'])

const RETURN_REASONS = [
  { value: 'damaged', label: 'Damaged / defective' },
  { value: 'wrong_item', label: 'Wrong item' },
  { value: 'quality_issue', label: 'Print quality issue' },
  { value: 'late_delivery', label: 'Arrived too late' },
  { value: 'changed_mind', label: 'Changed my mind' },
  { value: 'other', label: 'Other' },
]

export function Orders() {
  const [orders, setOrders] = useState<Order[]>([])
  const [returns, setReturns] = useState<ReturnInfo[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [returnFor, setReturnFor] = useState<string | null>(null)
  const [reason, setReason] = useState('damaged')
  const [details, setDetails] = useState('')
  const [returnMsg, setReturnMsg] = useState('')
  const [returnBusy, setReturnBusy] = useState(false)

  useEffect(() => {
    async function fetchOrders() {
      try {
        const [data, rets] = await Promise.all([
          api.getOrders(),
          api.getMyReturns().catch(() => [] as ReturnInfo[]),
        ])
        setOrders(data)
        setReturns(rets)
      } catch (err: any) {
        setError(err.message || 'Failed to load orders')
      } finally {
        setLoading(false)
      }
    }
    fetchOrders()
  }, [])

  async function submitReturn() {
    if (!returnFor) return
    setReturnBusy(true)
    setReturnMsg('')
    try {
      await api.requestReturn(returnFor, reason, details.trim() || undefined)
      const rets = await api.getMyReturns().catch(() => [] as ReturnInfo[])
      setReturns(rets)
      setReturnFor(null)
      setDetails('')
      setReturnMsg('Return requested — we will update you once it is reviewed.')
    } catch (err: any) {
      setReturnMsg(err.message || 'Could not request the return.')
    } finally {
      setReturnBusy(false)
    }
  }

  function openReturnFor(order: Order): ReturnInfo | undefined {
    return returns.find((r) => r.order_id === order.id && ['requested', 'approved'].includes(r.status))
  }

  function formatDate(iso: string) {
    return new Date(iso).toLocaleDateString('en-IN', {
      day: 'numeric', month: 'short', year: 'numeric',
    })
  }

  function getStatusIcon(status: string) {
    switch (status) {
      case 'confirmed': return <CheckIcon className="h-5 w-5 text-green-600" />
      case 'delivered': return <TruckIcon className="h-5 w-5 text-blue-600" />
      case 'cancelled': return <XIcon className="h-5 w-5 text-red-600" />
      default: return <ClockIcon className="h-5 w-5 text-amber-600" />
    }
  }

  if (loading) {
    return <div className="wrap py-12 text-center"><p className="text-muted">Loading orders...</p></div>
  }

  return (
    <div className="wrap py-12">
      <Seo
        title="My Orders | SnapPrint"
        description="Track your SnapPrint orders."
        path="/orders"
        noindex
      />
      <Reveal>
        <div className="max-w-3xl mx-auto">
          <h1 className="hero-title mb-2">My Orders</h1>
          <p className="text-muted mb-8">Track and manage your SnapPrint orders.</p>

          {error && (
            <div className="bg-red-50 border border-red-200 p-4 rounded-lg mb-6 text-sm text-red-800" role="alert">
              {error}
            </div>
          )}

          {orders.length === 0 ? (
            <div className="empty-state text-center py-16">
              <PackageIcon className="h-16 w-16 text-muted mx-auto mb-4" />
              <h2 className="font-display text-2xl mb-2">No orders yet</h2>
              <p className="text-muted mb-6">When you place your first order, it will appear here.</p>
              <Link to="/products" className="shop-button">
                Start Shopping <ArrowRightIcon />
              </Link>
            </div>
          ) : (
            <>
              {returnMsg && (
                <div className="glass mb-4 rounded-xl border border-border p-4 text-sm" role="status">
                  {returnMsg}
                </div>
              )}
              {returnFor && (
                <div className="glass mb-4 rounded-xl border border-border p-5" role="dialog" aria-label="Request a return">
                  <h2 className="font-display mb-2 text-lg">Request a return</h2>
                  <p className="text-muted mb-3 text-sm">
                    Tell us what went wrong — refunds go back to your original payment method.
                  </p>
                  <label className="mb-2 block text-sm">
                    Reason
                    <select
                      value={reason}
                      onChange={(e) => setReason(e.target.value)}
                      className="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm"
                    >
                      {RETURN_REASONS.map((r) => (
                        <option key={r.value} value={r.value}>{r.label}</option>
                      ))}
                    </select>
                  </label>
                  <label className="mb-3 block text-sm">
                    Details (optional)
                    <textarea
                      value={details}
                      onChange={(e) => setDetails(e.target.value)}
                      maxLength={2000}
                      rows={3}
                      placeholder="e.g. the corner arrived bent"
                      className="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm"
                    />
                  </label>
                  <div className="flex gap-3">
                    <button onClick={submitReturn} disabled={returnBusy} className="shop-button py-2 text-sm">
                      {returnBusy ? 'Submitting…' : 'Submit return request'}
                    </button>
                    <button onClick={() => setReturnFor(null)} className="text-sm text-muted hover:text-ink">
                      Cancel
                    </button>
                  </div>
                </div>
              )}
            <div className="space-y-4">
              {orders.map((order) => (
                <div key={order.id} className="glass p-5 rounded-xl border border-border">
                  <div className="flex items-start justify-between mb-3">
                    <div>
                      <p className="font-semibold text-ink">Order #{order.id.slice(0, 8).toUpperCase()}</p>
                      <p className="text-sm text-muted">{formatDate(order.created_at)}</p>
                    </div>
                    <div className="flex items-center gap-2">
                      {getStatusIcon(order.status)}
                      <span className="text-sm font-semibold capitalize">{order.status}</span>
                    </div>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">{order.item_count} item{order.item_count !== 1 ? 's' : ''}</span>
                    <span className="font-extrabold text-accent">₹{order.total_price.toLocaleString('en-IN')}</span>
                  </div>
                  {order.estimated_delivery && (
                    <p className="text-xs text-muted mt-2">
                      Estimated delivery: {formatDate(order.estimated_delivery)}
                    </p>
                  )}
                  {order.tracking_events && order.tracking_events.length > 0 && (
                    <div className="mt-3 border-t border-border pt-3 space-y-1">
                      {order.tracking_events.slice(-3).map((event, i) => (
                        <p key={i} className="text-xs text-muted">{event.status} — {new Date(event.timestamp).toLocaleString('en-IN')}</p>
                      ))}
                    </div>
                  )}
                  <div className="mt-3">
                    <Link to={`/orders/${order.id}`} className="text-sm text-accent hover:underline">
                      View Order Details →
                    </Link>
                    {(() => {
                      const open = openReturnFor(order)
                      if (open) {
                        return (
                          <p className="mt-1 text-xs text-muted">
                            Return {open.status}
                            {open.status === 'rejected' && open.admin_note ? ` — ${open.admin_note}` : ''}
                          </p>
                        )
                      }
                      const closed = returns.find((r) => r.order_id === order.id)
                      if (closed) {
                        return (
                          <p className="mt-1 text-xs text-muted">
                            Return {closed.status}
                            {closed.admin_note ? ` — ${closed.admin_note}` : ''}
                          </p>
                        )
                      }
                      if (RETURNABLE.has(order.status)) {
                        return (
                          <button
                            onClick={() => { setReturnFor(order.id); setReturnMsg('') }}
                            className="mt-1 block text-sm text-accent hover:underline"
                          >
                            Request return / refund
                          </button>
                        )
                      }
                      return null
                    })()}
                  </div>
                </div>
              ))}
            </div>
            </>
          )}
        </div>
      </Reveal>
    </div>
  )
}
