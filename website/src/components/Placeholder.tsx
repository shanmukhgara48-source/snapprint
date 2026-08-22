interface PlaceholderProps {
  /** Short label describing what real value will replace this, e.g. "Legal entity name" */
  label: string
  /** Optional fallback text shown alongside the label, e.g. an example format */
  example?: string
}

/**
 * Visually and textually unmistakable marker for business/legal details that
 * are NOT final. Never remove this component's distinct styling when editing
 * copy — it's what makes placeholder content impossible to mistake for real
 * business information before Razorpay (or anyone else) reviews the site.
 */
export function Placeholder({ label, example }: PlaceholderProps) {
  return (
    <span className="box-decoration-clone rounded-md border border-dashed border-[var(--color-coral)]/70 bg-[var(--color-coral)]/10 px-1.5 py-0.5 text-[0.82em] font-semibold leading-relaxed text-[var(--color-coral)]">
      Pending final detail: {label}
      {example ? `, e.g. ${example}` : ''}
    </span>
  )
}
