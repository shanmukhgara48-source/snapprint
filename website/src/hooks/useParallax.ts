import { useEffect, useRef, useState } from 'react'

/**
 * Subtle scroll-driven parallax offset for large decorative visuals.
 * No-op (offset stays 0) under prefers-reduced-motion or on small/touch screens,
 * where the extra scroll-linked repaint isn't worth the cost.
 */
export function useParallax<T extends HTMLElement>(strength = 0.1) {
  const ref = useRef<T | null>(null)
  const [offset, setOffset] = useState(0)

  useEffect(() => {
    const node = ref.current
    if (!node) return

    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    const isSmallScreen = window.matchMedia('(max-width: 767px)').matches
    if (reduceMotion || isSmallScreen) return

    let ticking = false
    const update = () => {
      const rect = node.getBoundingClientRect()
      const center = rect.top + rect.height / 2 - window.innerHeight / 2
      setOffset(center * -strength)
      ticking = false
    }
    const onScroll = () => {
      if (!ticking) {
        ticking = true
        requestAnimationFrame(update)
      }
    }

    update()
    window.addEventListener('scroll', onScroll, { passive: true })
    window.addEventListener('resize', onScroll, { passive: true })
    return () => {
      window.removeEventListener('scroll', onScroll)
      window.removeEventListener('resize', onScroll)
    }
  }, [strength])

  return { ref, offset }
}
