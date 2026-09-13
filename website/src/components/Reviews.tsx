import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { api, getAuthToken } from '../services/api'
import { Stars } from './Stars'
import { useToastOptional } from '../context/Toast'

interface Review {
  id: string
  rating: number
  title: string
  body: string
  reviewer: string
  verified_purchase: boolean
  helpful_count: number
  voted: boolean
  seller_response: string | null
  created_at: string
}

/**
 * Amazon-style ratings block: summary histogram + review list with helpful
 * votes + write-a-review for signed-in customers.
 */
export function Reviews({ productId }: { productId: string }) {
  const toast = useToastOptional()
  const [summary, setSummary] = useState<{ avg_rating: number; review_count: number; histogram: Record<string, number> } | null>(null)
  const [reviews, setReviews] = useState<Review[]>([])
  const [sort, setSort] = useState<'helpful' | 'recent'>('helpful')
  const [loading, setLoading] = useState(true)
  const [rating, setRating] = useState(5)
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [formError, setFormError] = useState('')
  const authed = Boolean(getAuthToken())

  useEffect(() => {
    let cancelled = false
    async function load() {
      setLoading(true)
      try {
        const [s, r] = await Promise.all([
          api.getReviewSummary(productId),
          api.getReviews(productId, sort),
        ])
        if (!cancelled) {
          setSummary(s)
          setReviews(r)
        }
      } catch {
        if (!cancelled) {
          setSummary(null)
          setReviews([])
        }
      } finally {
        if (!cancelled) setLoading(false)
      }
    }
    load()
    return () => {
      cancelled = true
    }
  }, [productId, sort])

  async function vote(id: string) {
    if (!authed) {
      toast?.notifyError('Please sign in to mark reviews helpful.')
      return
    }
    try {
      const res = await api.voteHelpful(id)
      setReviews((prev) =>
        prev.map((r) => (r.id === id ? { ...r, helpful_count: res.helpful_count, voted: res.voted } : r)),
      )
    } catch (err: any) {
      toast?.notifyError(err.message || 'Could not register your vote.')
    }
  }

  async function submit(e: React.FormEvent) {
    e.preventDefault()
    setFormError('')
    if (!title.trim() && !body.trim()) {
      setFormError('Please add a headline or a few words about the print.')
      return
    }
    setSubmitting(true)
    try {
      await api.createReview(productId, { rating, title: title.trim(), body: body.trim() })
      const [s, r] = await Promise.all([
        api.getReviewSummary(productId),
        api.getReviews(productId, sort),
      ])
      setSummary(s)
      setReviews(r)
      setTitle('')
      setBody('')
      toast?.notifySuccess('Thanks! Your review is live.')
    } catch (err: any) {
      setFormError(err.message || 'Could not post your review.')
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) {
    return <p className="text-muted text-sm" role="status">Loading reviews…</p>
  }

  const total = summary?.review_count ?? reviews.length
  const maxBin = Math.max(1, ...Object.values(summary?.histogram ?? { 5: 1 }))

  return (
    <section aria-label="Customer reviews" className="mt-10">
      <h2 className="font-display text-2xl mb-4">Ratings & reviews</h2>
      <div className="grid gap-8 md:grid-cols-12">
        <div className="md:col-span-4">
          <div className="flex items-end gap-2">
            <span className="font-display text-5xl">{summary ? summary.avg_rating.toFixed(1) : '—'}</span>
            <span className="text-muted mb-1.5 text-sm">out of 5</span>
          </div>
          <Stars value={summary?.avg_rating ?? 0} size={18} className="mt-1" />
          <p className="text-muted mt-1 text-sm">{total} global rating{total === 1 ? '' : 's'}</p>
          {summary && (
            <div className="mt-3 space-y-1">
              {[5, 4, 3, 2, 1].map((star) => (
                <div key={star} className="flex items-center gap-2 text-xs">
                  <span className="text-accent w-10 shrink-0">{star} star</span>
                  <div className="h-2 flex-1 overflow-hidden rounded bg-border">
                    <div
                      className="h-full bg-amber-500"
                      style={{ width: `${((summary.histogram[String(star)] ?? 0) / maxBin) * 100}%` }}
                    />
                  </div>
                  <span className="text-muted w-6 text-right">{summary.histogram[String(star)] ?? 0}</span>
                </div>
              ))}
            </div>
          )}
          <div className="mt-6 rounded-xl border border-border p-4">
            <h3 className="font-semibold">Review this product</h3>
            {!authed ? (
              <p className="text-muted mt-1 text-sm">
                <Link to="/auth" className="text-link">Sign in</Link> to share your thoughts.
              </p>
            ) : (
              <form onSubmit={submit} className="mt-2 space-y-2">
                <div className="flex items-center gap-1" role="radiogroup" aria-label="Your rating">
                  {[1, 2, 3, 4, 5].map((s) => (
                    <button
                      key={s}
                      type="button"
                      role="radio"
                      aria-checked={rating === s}
                      aria-label={`${s} star${s === 1 ? '' : 's'}`}
                      onClick={() => setRating(s)}
                      className="p-0.5"
                    >
                      <span className={s <= rating ? 'text-amber-500' : 'text-neutral-400'}>
                        <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                          <path d="M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.4 6.1 20.5l1.2-6.5L2.5 9.4l6.6-.9z" />
                        </svg>
                      </span>
                    </button>
                  ))}
                </div>
                <input
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="Headline"
                  maxLength={120}
                  className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm"
                />
                <textarea
                  value={body}
                  onChange={(e) => setBody(e.target.value)}
                  placeholder="What did you like? How was the print quality?"
                  maxLength={2000}
                  rows={3}
                  className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm"
                />
                {formError && <p role="alert" className="text-sm text-red-600">{formError}</p>}
                <button type="submit" disabled={submitting} className="shop-button w-full justify-center py-2 text-sm">
                  {submitting ? 'Posting…' : 'Submit review'}
                </button>
              </form>
            )}
          </div>
        </div>
        <div className="md:col-span-8">
          <div className="mb-3 flex items-center gap-2 text-sm">
            <span className="text-muted">Top reviews</span>
            <select
              value={sort}
              onChange={(e) => setSort(e.target.value as 'helpful' | 'recent')}
              aria-label="Sort reviews"
              className="rounded-lg border border-border bg-surface px-2 py-1 text-sm"
            >
              <option value="helpful">Most helpful</option>
              <option value="recent">Most recent</option>
            </select>
          </div>
          {reviews.length === 0 ? (
            <p className="text-muted text-sm">No reviews yet — be the first to review this print.</p>
          ) : (
            <div className="space-y-5">
              {reviews.map((r) => (
                <article key={r.id} className="border-b border-border pb-5">
                  <div className="flex items-center gap-2">
                    <span className="flex h-8 w-8 items-center justify-center rounded-full bg-surface text-sm font-bold text-accent">
                      {r.reviewer.slice(0, 1).toUpperCase()}
                    </span>
                    <span className="text-sm font-medium">{r.reviewer}</span>
                  </div>
                  <div className="mt-1 flex items-center gap-2">
                    <Stars value={r.rating} />
                    <span className="text-sm font-semibold">{r.title || `${r.rating} stars`}</span>
                  </div>
                  <p className="text-muted text-xs">
                    Reviewed on {new Date(r.created_at).toLocaleDateString('en-IN')}
                    {r.verified_purchase && <span className="ml-2 font-semibold text-green-700">Verified Purchase</span>}
                  </p>
                  {r.body && <p className="mt-1.5 text-sm">{r.body}</p>}
                  {r.seller_response && (
                    <p className="mt-2 rounded-lg bg-surface p-2.5 text-xs">
                      <span className="font-semibold">Response from SnapPrint: </span>
                      {r.seller_response}
                    </p>
                  )}
                  <button
                    onClick={() => vote(r.id)}
                    className={`mt-2 rounded-lg border px-3 py-1 text-xs ${r.voted ? 'border-accent text-accent' : 'border-border text-muted hover:text-ink'}`}
                  >
                    Helpful{r.helpful_count > 0 ? ` (${r.helpful_count})` : ''}
                  </button>
                </article>
              ))}
            </div>
          )}
        </div>
      </div>
    </section>
  )
}
