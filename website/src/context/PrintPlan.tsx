import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react'
import type { CatalogProduct } from '../data/products'

export interface PlanItem {
  key: string
  productId: string
  size: string
  units: number
  /** Persistent media URL returned by POST /upload/image (sent to backend). */
  imageUrl?: string
  /** Local object URL for instant preview only — never sent to the server. */
  previewUrl?: string
  /** Display snapshot (catalog or backend-adapted product). */
  product?: CatalogProduct
}

export interface CheckoutData {
  email: string
  firstName: string
  lastName: string
  address: string
  city: string
  state: string
  pin: string
  phone: string
  /** Backend address id created at checkout (authoritative for payment). */
  addressId?: string
  /** Coupon code applied at checkout (validated server-side). */
  couponCode?: string
  deliveryType?: string
  /** Gift wrap for the whole order (fee is server-authoritative). */
  giftWrap?: boolean
  /** Optional gift message (max 500 chars, stored with the order). */
  giftMessage?: string
}

interface PlanContext {
  items: PlanItem[]
  add: (item: Omit<PlanItem, 'key'>) => void
  remove: (key: string) => void
  update: (key: string, units: number) => void
  setItemImage: (key: string, imageUrl: string, previewUrl?: string) => void
  clearCart: () => void
  storageAvailable: boolean
  checkoutData: CheckoutData | null
  setCheckoutData: (data: CheckoutData) => void
}

const Context = createContext<PlanContext | null>(null)
const storageKey = 'snapprint-plan-v1'

function isValidItem(item: any): item is PlanItem {
  if (!item || typeof item !== 'object') return false
  if (typeof item.productId !== 'string' || !item.productId) return false
  if (typeof item.size !== 'string' || !item.size) return false
  if (typeof item.key !== 'string') return false
  if (!Number.isInteger(item.units) || item.units <= 0 || item.units > 20) {
    return false
  }
  // Key must match product+size (+image when the photo differs per item so
  // two copies of the same product with different photos stay distinct).
  const base = `${item.productId}:${item.size}`
  if (item.key !== base && item.key !== `${base}:${item.imageUrl || ''}`) {
    return false
  }
  if (
    item.imageUrl !== undefined &&
    (typeof item.imageUrl !== 'string' || item.imageUrl.length > 2048)
  ) {
    return false
  }
  return true
}

function readPlan(): PlanItem[] {
  try {
    const value: unknown = JSON.parse(
      localStorage.getItem(storageKey) ?? '[]',
    )
    if (!Array.isArray(value)) return []
    return value
      .filter(isValidItem)
      .map(({ previewUrl: _preview, product, ...rest }) => ({
        ...rest,
        // Never persist blob: URLs across reloads; re-upload after refresh.
        previewUrl: undefined,
        product,
      }))
      .slice(0, 100)
  } catch {
    return []
  }
}

export function PrintPlanProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<PlanItem[]>(readPlan)
  const [storageAvailable, setStorageAvailable] = useState(true)
  const [checkoutData, setCheckoutData] = useState<CheckoutData | null>(null)

  useEffect(() => {
    try {
      // Persist everything except transient blob: preview URLs.
      const serialisable = items.map(
        ({ previewUrl: _preview, ...rest }) => rest,
      )
      localStorage.setItem(storageKey, JSON.stringify(serialisable))
    } catch {
      setStorageAvailable(false)
    }
  }, [items])

  // Revoke blob: preview URLs when items leave the cart.
  useEffect(() => {
    return () => {
      for (const item of items) {
        if (item.previewUrl?.startsWith('blob:')) {
          try {
            URL.revokeObjectURL(item.previewUrl)
          } catch {
            /* ignore */
          }
        }
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <Context.Provider
      value={{
        items,
        storageAvailable,
        checkoutData,
        setCheckoutData,
        clearCart: () => setItems([]),
        add: (item) =>
          setItems((prev) => {
            const key = item.imageUrl
              ? `${item.productId}:${item.size}:${item.imageUrl}`
              : `${item.productId}:${item.size}`
            const existing = prev.find((p) => p.key === key)
            if (existing) {
              return prev.map((p) =>
                p.key === key
                  ? { ...p, units: Math.min(20, p.units + item.units) }
                  : p,
              )
            }
            return [...prev, { ...item, key }]
          }),
        remove: (key) =>
          setItems((prev) => {
            const gone = prev.find((p) => p.key === key)
            if (gone?.previewUrl?.startsWith('blob:')) {
              try {
                URL.revokeObjectURL(gone.previewUrl)
              } catch {
                /* ignore */
              }
            }
            return prev.filter((p) => p.key !== key)
          }),
        update: (key, units) =>
          setItems((prev) =>
            prev.map((p) =>
              p.key === key
                ? { ...p, units: Math.max(1, Math.min(20, units)) }
                : p,
            ),
          ),
        setItemImage: (key, imageUrl, previewUrl) =>
          setItems((prev) =>
            prev.map((p) =>
              p.key === key ? { ...p, imageUrl, previewUrl } : p,
            ),
          ),
      }}
    >
      {children}
    </Context.Provider>
  )
}

export function usePrintPlan() {
  const context = useContext(Context)
  if (!context) throw new Error('PrintPlanProvider required')
  return context
}
