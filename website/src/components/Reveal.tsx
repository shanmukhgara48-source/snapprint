import type { CSSProperties, ReactNode } from 'react'
import { useReveal } from '../hooks/useReveal'

interface RevealProps {
  children: ReactNode
  delay?: number
  className?: string
}

export function Reveal({ children, delay = 0, className = '' }: RevealProps) {
  const { ref, visible } = useReveal<HTMLDivElement>()
  const style: CSSProperties = delay ? { transitionDelay: `${delay}ms` } : {}

  return (
    <div ref={ref} style={style} className={`reveal ${visible ? 'is-visible' : ''} ${className}`}>
      {children}
    </div>
  )
}
