import type { ReactNode } from 'react'
import { Link } from 'react-router-dom'

type Variant = 'primary' | 'secondary' | 'ghost'

interface ButtonProps {
  variant?: Variant
  children: ReactNode
  className?: string
  to?: string
  href?: string
  onClick?: () => void
  type?: 'button' | 'submit'
}

const base =
  'inline-flex items-center justify-center gap-2 rounded-full px-7 py-3.5 text-sm font-semibold tracking-wide transition-all duration-300 ease-[cubic-bezier(0.16,1,0.3,1)] active:scale-[0.97] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-accent)]'

const variants: Record<Variant, string> = {
  primary:
    'shine bg-gradient-to-r from-[var(--color-accent-2)] to-[var(--color-accent)] text-[#0c0c0e] shadow-[0_10px_30px_-10px_rgba(212,175,55,0.6)] hover:-translate-y-0.5 hover:shadow-[0_18px_46px_-10px_rgba(212,175,55,0.8)]',
  secondary:
    'border border-[var(--color-border-strong)] text-[var(--color-ink)] hover:-translate-y-0.5 hover:border-[var(--color-accent)] hover:text-[var(--color-accent)]',
  ghost: 'text-[var(--color-muted)] hover:text-[var(--color-accent)]',
}

export function Button({
  variant = 'primary',
  children,
  className = '',
  to,
  href,
  onClick,
  type,
}: ButtonProps) {
  const cls = `${base} ${variants[variant]} ${className}`

  if (to) {
    return (
      <Link to={to} className={cls}>
        {children}
      </Link>
    )
  }

  if (href) {
    const external = href.startsWith('http')
    return (
      <a href={href} className={cls} target={external ? '_blank' : undefined} rel={external ? 'noopener noreferrer' : undefined}>
        {children}
      </a>
    )
  }

  return (
    <button type={type ?? 'button'} className={cls} onClick={onClick}>
      {children}
    </button>
  )
}
