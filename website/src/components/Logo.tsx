interface LogoMarkProps {
  className?: string
}

/** Aperture-inspired monogram — the brand mark used in the nav, footer, and favicon. */
export function LogoMark({ className = 'h-9 w-9' }: LogoMarkProps) {
  return (
    <svg
      viewBox="0 0 48 48"
      className={className}
      fill="none"
      aria-hidden="true"
    >
      <defs>
        <linearGradient
          id="spPrintGlow"
          x1="6"
          y1="6"
          x2="42"
          y2="42"
          gradientUnits="userSpaceOnUse"
        >
          <stop offset="0" stopColor="#4f3adf" />
          <stop offset="1" stopColor="#d4af37" />
        </linearGradient>
      </defs>
      <rect
        x="4"
        y="4"
        width="40"
        height="40"
        rx="13"
        fill="#0b0c12"
        stroke="url(#spPrintGlow)"
        strokeWidth="1.4"
      />
      <rect
        x="10"
        y="10"
        width="28"
        height="28"
        rx="10"
        fill="#12131c"
        stroke="#2f3340"
        strokeWidth="1"
      />
      <path
        d="M15 14h18l-9 10m0 0-5 6m5-6 5 6"
        stroke="url(#spPrintGlow)"
        strokeWidth="2.2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M17.2 30.8c1.5-2.7 4.2-4.5 7.4-4.5 3.1 0 5.8 1.8 7.4 4.5"
        stroke="#d4af37"
        strokeOpacity="0.85"
        strokeWidth="2"
        strokeLinecap="round"
      />
      <circle cx="24" cy="23" r="2.8" fill="#d4af37" />
    </svg>
  )
}
