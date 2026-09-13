/**
 * Central business / legal content for customer-facing pages.
 *
 * REQUIRES OWNER CONTENT — every empty value below blocks production launch.
 * Fill these with REAL, verified information before launch. Do NOT invent
 * legal details: leave a field empty rather than guessing, and the UI will
 * render a neutral "details pending" notice instead of a fabricated fact.
 *
 * Tracked in MVP_LAUNCH_BLOCKERS.md under "Business Information".
 */
export type BusinessField =
  | 'legalEntityName'
  | 'registeredAddress'
  | 'supportEmail'
  | 'privacyEmail'
  | 'supportPhone'
  | 'supportHours'
  | 'jurisdiction'
  | 'policyLastUpdated'
  | 'cancellationWindow'
  | 'claimWindow'
  | 'refundTimeline'

export const BUSINESS: Record<BusinessField, string> = {
  /** Registered legal entity, e.g. "SnapPrint Private Limited". */
  legalEntityName: '',
  /** Registered office address (full postal address). */
  registeredAddress: '',
  /** Customer support email (monitored inbox). */
  supportEmail: '',
  /** Privacy/GDPR contact email. */
  privacyEmail: '',
  /** Customer support phone in E.164, e.g. "+911234567890". */
  supportPhone: '',
  /** Support hours line, e.g. "Mon–Sat, 10am–7pm IST". */
  supportHours: '',
  /** City/state of legal jurisdiction, e.g. "Bengaluru, Karnataka". */
  jurisdiction: '',
  /** Last-reviewed date for policy pages, e.g. "1 September 2026". */
  policyLastUpdated: '',
  /** Order cancellation window, e.g. "within 1 hour of order placement". */
  cancellationWindow: '',
  /** Damage/claim reporting window, e.g. "within 7 days of delivery". */
  claimWindow: '',
  /** Refund processing timeline, e.g. "5–7 business days after approval". */
  refundTimeline: '',
}

/** True only when every legal/business field has a real value. */
export function isBusinessInfoComplete(): boolean {
  return Object.values(BUSINESS).every((v) => v.trim().length > 0)
}

/** Fields still missing real values (for the launch-blockers report). */
export function missingBusinessFields(): BusinessField[] {
  return (Object.keys(BUSINESS) as BusinessField[]).filter(
    (k) => !BUSINESS[k].trim(),
  )
}
