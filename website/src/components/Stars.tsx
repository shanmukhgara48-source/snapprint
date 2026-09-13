export function Stars({
  value,
  size = 14,
  className = '',
}: {
  value: number
  size?: number
  className?: string
}) {
  const full = Math.round(value)
  return (
    <span
      className={`inline-flex items-center gap-0.5 ${className}`}
      role="img"
      aria-label={`Rated ${value} out of 5 stars`}
    >
      {[1, 2, 3, 4, 5].map((i) => (
        <svg
          key={i}
          width={size}
          height={size}
          viewBox="0 0 24 24"
          fill={i <= full ? 'currentColor' : 'none'}
          stroke="currentColor"
          strokeWidth="1.8"
          className={i <= full ? 'text-amber-500' : 'text-neutral-400'}
          aria-hidden="true"
        >
          <path d="M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.4 6.1 20.5l1.2-6.5L2.5 9.4l6.6-.9z" />
        </svg>
      ))}
    </span>
  )
}
