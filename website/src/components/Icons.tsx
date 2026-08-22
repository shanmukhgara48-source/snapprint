// Hand-crafted, dependency-free stroke icons (24x24, currentColor) to keep the bundle light.
interface IconProps {
  className?: string
}

const base = {
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 1.75,
  strokeLinecap: 'round' as const,
  strokeLinejoin: 'round' as const,
}

export function MenuIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <path d="M4 7h16M4 12h16M4 17h16" />
    </svg>
  )
}

export function XIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <path d="M6 6l12 12M18 6L6 18" />
    </svg>
  )
}

export function TruckIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <path d="M3 7h11v9H3z" />
      <path d="M14 10h4l3 3v3h-7z" />
      <circle cx="7.5" cy="18" r="1.6" />
      <circle cx="17.5" cy="18" r="1.6" />
    </svg>
  )
}

export function ShieldCheckIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <path d="M12 3l7 3v6c0 4.4-3 7.6-7 9-4-1.4-7-4.6-7-9V6l7-3z" />
      <path d="M9 12.2l2 2 4-4.2" />
    </svg>
  )
}

export function CameraIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <path d="M4 8h3l1.6-2.4h6.8L17 8h3a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z" />
      <circle cx="12" cy="13.5" r="3.4" />
    </svg>
  )
}

export function BookOpenIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <path d="M12 6.5c-1.7-1.2-4.4-1.8-7-1.4v13.3c2.6-.4 5.3.2 7 1.4V6.5z" />
      <path d="M12 6.5c1.7-1.2 4.4-1.8 7-1.4v13.3c-2.6-.4-5.3.2-7 1.4V6.5z" />
    </svg>
  )
}

export function FrameIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <rect x="4" y="4" width="16" height="16" rx="1.5" />
      <rect x="7" y="7" width="10" height="10" rx="0.8" />
      <path d="M9.2 14.8l2.3-2.5 1.8 1.8 1.5-1.6 2.2 2.3" />
      <circle cx="10" cy="10" r="0.8" />
    </svg>
  )
}

export function GiftIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <path d="M4 11h16v9H4z" />
      <path d="M3.5 7h17v4h-17zM12 7v13" />
      <path d="M12 7S9.2 3.5 7 4.5C5.2 5.3 6.4 8 12 7zM12 7s2.8-3.5 5-2.5C18.8 5.3 17.6 8 12 7z" />
    </svg>
  )
}

export function UploadIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <path d="M12 16V4M8 8l4-4 4 4" />
      <path d="M4 16v3a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-3" />
    </svg>
  )
}

export function MapPinIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <path d="M20 10.5c0 5.5-8 11-8 11s-8-5.5-8-11a8 8 0 1 1 16 0z" />
      <circle cx="12" cy="10.5" r="2.6" />
    </svg>
  )
}

export function MailIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <rect x="3" y="5" width="18" height="14" rx="2" />
      <path d="M3.5 6.5l8.5 6 8.5-6" />
    </svg>
  )
}

export function PhoneIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <path d="M5 4h3.2l1.4 4.2-2 1.6a12 12 0 0 0 5.6 5.6l1.6-2 4.2 1.4V18a2 2 0 0 1-2 2C10.5 20 4 13.5 4 6a2 2 0 0 1 1-2z" />
    </svg>
  )
}

export function ClockIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <circle cx="12" cy="12" r="8.5" />
      <path d="M12 7.5V12l3 2" />
    </svg>
  )
}

export function SearchIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <circle cx="10.8" cy="10.8" r="6.8" />
      <path d="M16 16l4 4" />
    </svg>
  )
}

export function CheckIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <path d="M5 12.5l4.5 4.5L19 7" />
    </svg>
  )
}

export function ArrowRightIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <path d="M5 12h14M13 6l6 6-6 6" />
    </svg>
  )
}

export function PackageIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <path d="M12 3l8 4.5v9L12 21l-8-4.5v-9L12 3z" />
      <path d="M4.5 7.5L12 12l7.5-4.5M12 12v9" />
    </svg>
  )
}

export function ReceiptIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <path d="M6 3h12v18l-2-1.2-2 1.2-2-1.2-2 1.2-2-1.2L6 21V3z" />
      <path d="M9 8h6M9 12h6M9 16h3" />
    </svg>
  )
}

export function SparkleIcon({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg {...base} className={className} aria-hidden="true">
      <path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8L12 3z" />
    </svg>
  )
}
