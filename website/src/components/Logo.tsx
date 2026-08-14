interface LogoMarkProps {
  className?: string
}

/** Aperture-inspired monogram — the brand mark used in the nav, footer, and favicon. */
export function LogoMark({ className = 'h-9 w-9' }: LogoMarkProps) {
  return (
    <svg viewBox="0 0 40 40" className={className} fill="none" aria-hidden="true">
      <rect x="1" y="1" width="38" height="38" rx="11" fill="#0a0a0c" stroke="#d4af37" strokeWidth="1.4" />
      <circle cx="20" cy="20" r="10.5" stroke="#d4af37" strokeWidth="1.4" />
      <circle cx="20" cy="20" r="3.6" fill="#d4af37" />
      <path
        d="M20 6.8V10M20 30v3.2M33.2 20H30M10 20H6.8"
        stroke="#d4af37"
        strokeWidth="1.4"
        strokeLinecap="round"
      />
    </svg>
  )
}
