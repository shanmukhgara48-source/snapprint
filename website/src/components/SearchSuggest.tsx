import { useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import { api } from '../services/api'

interface Suggestion {
  id: string
  name: string
  category: string
  base_price: number
  image: string | null
}

/** Amazon-style autocomplete dropdown wired to GET /products/suggest. */
export function SearchSuggest({
  query,
  onPick,
}: {
  query: string
  onPick: () => void
}) {
  const [items, setItems] = useState<Suggestion[]>([])
  const [open, setOpen] = useState(false)
  const timer = useRef<number | undefined>(undefined)

  useEffect(() => {
    window.clearTimeout(timer.current)
    if (query.trim().length < 2) {
      setItems([])
      setOpen(false)
      return
    }
    timer.current = window.setTimeout(async () => {
      try {
        const res = await api.suggestProducts(query.trim())
        setItems(res)
        setOpen(true)
      } catch {
        setItems([])
        setOpen(false)
      }
    }, 220)
    return () => window.clearTimeout(timer.current)
  }, [query])

  if (!open || items.length === 0) return null

  return (
    <div
      className="absolute left-0 right-0 top-full z-30 mt-1 overflow-hidden rounded-xl border border-border bg-surface shadow-xl"
      role="listbox"
      aria-label="Product suggestions"
    >
      {items.map((s) => (
        <Link
          key={s.id}
          to={`/products/${s.id}`}
          role="option"
          aria-selected="false"
          onClick={() => {
            setOpen(false)
            onPick()
          }}
          className="flex items-center gap-3 px-3 py-2 hover:bg-border/40"
        >
          {s.image ? (
            <img src={s.image} alt="" className="h-9 w-9 rounded object-cover" loading="lazy" />
          ) : (
            <span className="h-9 w-9 rounded bg-border" />
          )}
          <span className="min-w-0 flex-1">
            <span className="block truncate text-sm font-medium">{s.name}</span>
            <span className="text-muted block text-xs">in {s.category}</span>
          </span>
        </Link>
      ))}
    </div>
  )
}
