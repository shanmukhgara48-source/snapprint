import type { ReactNode } from 'react'
import { BUSINESS, type BusinessField } from '../config/business'

/**
 * Renders a business/legal value from central config. When the owner has not
 * supplied the value yet, renders a neutral notice (never a fabricated fact,
 * never a red alarming placeholder in production).
 */
export function BusinessValue({
  field,
  fallback,
}: {
  field: BusinessField
  fallback?: ReactNode
}) {
  const value = BUSINESS[field]
  if (value.trim()) return <>{value}</>
  return (
    <span className="text-muted italic">
      {fallback ?? 'Details pending final confirmation — please contact support.'}
    </span>
  )
}
