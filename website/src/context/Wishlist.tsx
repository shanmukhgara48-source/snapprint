import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from 'react'
import { api, getAuthToken } from '../services/api'

interface WishlistContext {
  ids: Set<string>
  count: number
  has: (productId: string) => boolean
  toggle: (productId: string) => Promise<void>
  refresh: () => Promise<void>
}

const Context = createContext<WishlistContext | null>(null)

/** Amazon "List": server-backed wishlist shared across devices. */
export function WishlistProvider({ children }: { children: ReactNode }) {
  const [ids, setIds] = useState<Set<string>>(new Set())

  const refresh = useCallback(async () => {
    if (!getAuthToken()) {
      setIds(new Set())
      return
    }
    try {
      const res = await api.getWishlistIds()
      setIds(new Set(res.product_ids))
    } catch {
      /* wishlist is non-critical — page still works */
    }
  }, [])

  useEffect(() => {
    refresh()
  }, [refresh])

  const toggle = useCallback(
    async (productId: string) => {
      if (!getAuthToken()) throw new Error('Please sign in to save items to your wishlist.')
      const saved = ids.has(productId)
      // Optimistic update, reconciled by the server response.
      setIds((prev) => {
        const next = new Set(prev)
        if (saved) next.delete(productId)
        else next.add(productId)
        return next
      })
      try {
        if (saved) await api.removeFromWishlist(productId)
        else await api.addToWishlist(productId)
      } catch (err) {
        await refresh()
        throw err
      }
    },
    [ids, refresh],
  )

  const has = useCallback((productId: string) => ids.has(productId), [ids])

  return (
    <Context.Provider value={{ ids, count: ids.size, has, toggle, refresh }}>
      {children}
    </Context.Provider>
  )
}

export function useWishlist() {
  const ctx = useContext(Context)
  if (!ctx) throw new Error('useWishlist must be used inside WishlistProvider')
  return ctx
}
