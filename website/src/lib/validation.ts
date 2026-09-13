/** Shared India-specific checkout validation (mirrors backend constraints). */

export function normalizeIndianPhone(input: string): string | null {
  const digits = input.replace(/\D/g, '')
  // Accept 10-digit mobile, or 91-prefixed 12-digit form.
  let local = digits
  if (local.length === 12 && local.startsWith('91')) local = local.slice(2)
  if (local.length === 11 && local.startsWith('0')) local = local.slice(1)
  if (!/^[6-9]\d{9}$/.test(local)) return null
  return `+91${local}`
}

export function toE164(input: string): string | null {
  const trimmed = input.trim()
  if (trimmed.startsWith('+')) {
    return /^\+[1-9][0-9]{7,14}$/.test(trimmed) ? trimmed : null
  }
  return normalizeIndianPhone(trimmed)
}

export function isValidPin(pin: string): boolean {
  return /^[1-9][0-9]{5}$/.test(pin.trim())
}

export function isValidEmail(email: string): boolean {
  const v = email.trim()
  if (v.length > 254 || v.length < 5) return false
  return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(v)
}
