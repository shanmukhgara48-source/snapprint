import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react'

interface Toast {
  id: number
  message: string
  kind: 'info' | 'success' | 'error'
}

interface ToastContextValue {
  notify: (message: string, kind?: Toast['kind']) => void
  notifyError: (message: string) => void
  notifySuccess: (message: string) => void
}

const ToastContext = createContext<ToastContextValue | null>(null)

export function useToast(): ToastContextValue {
  const ctx = useContext(ToastContext)
  if (!ctx) throw new Error('ToastProvider required')
  return ctx
}

/** Optional hook for components rendered outside the provider. */
export function useToastOptional(): ToastContextValue | null {
  return useContext(ToastContext)
}

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([])
  const idRef = useRef(1)

  const notify = useCallback(
    (message: string, kind: Toast['kind'] = 'info') => {
      const id = idRef.current++
      setToasts((prev) => [...prev.slice(-2), { id, message, kind }])
      setTimeout(() => {
        setToasts((prev) => prev.filter((t) => t.id !== id))
      }, 5000)
    },
    [],
  )

  const value = useMemo<ToastContextValue>(
    () => ({
      notify,
      notifyError: (message: string) => notify(message, 'error'),
      notifySuccess: (message: string) => notify(message, 'success'),
    }),
    [notify],
  )

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div
        aria-live="polite"
        className="fixed bottom-4 left-1/2 z-[100] flex w-full max-w-md -translate-x-1/2 flex-col gap-2 px-4"
      >
        {toasts.map((t) => (
          <div
            key={t.id}
            role={t.kind === 'error' ? 'alert' : 'status'}
            className={`rounded-lg border px-4 py-3 text-sm shadow-lg ${
              t.kind === 'error'
                ? 'border-red-200 bg-red-50 text-red-800'
                : t.kind === 'success'
                  ? 'border-green-200 bg-green-50 text-green-800'
                  : 'border-border bg-surface text-ink'
            }`}
          >
            {t.message}
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  )
}
