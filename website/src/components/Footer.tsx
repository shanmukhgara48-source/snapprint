import { Link } from 'react-router-dom'
import { Placeholder } from './Placeholder'
import { LogoMark } from './Logo'
import { MailIcon, PhoneIcon, ShieldCheckIcon } from './Icons'

const shopLinks = [
  { to: '/products', label: 'Products & Services' },
  { to: '/pricing', label: 'Pricing' },
  { to: '/contact', label: 'Contact Us' },
]

const policyLinks = [
  { to: '/terms', label: 'Terms and Conditions' },
  { to: '/privacy', label: 'Privacy Policy' },
  { to: '/shipping', label: 'Shipping Policy' },
  { to: '/refund', label: 'Cancellation and Refund Policy' },
]

export function Footer() {
  return (
    <footer className="border-t border-[var(--color-border)] bg-[var(--color-bg-soft)]">
      <div className="mx-auto max-w-6xl px-6 py-16 sm:py-20">
        <div className="grid gap-10 sm:grid-cols-2 lg:grid-cols-[1.3fr_0.8fr_1fr_1.1fr]">
          <div>
            <div className="flex items-center gap-2.5">
              <LogoMark className="h-8 w-8" />
              <p className="text-lg font-extrabold text-[var(--color-ink)]">
                Snap<span className="text-[var(--color-accent)]">Print</span>
              </p>
            </div>
            <p className="mt-3 text-sm text-[var(--color-muted)]">Print Your Memories</p>
            <p className="mt-4 text-sm text-[var(--color-muted)]">
              <Placeholder label="Legal entity name" example="SnapPrint Private Limited" />
            </p>
            <p className="mt-2 text-sm text-[var(--color-muted)]">
              <Placeholder label="Registered address" />
            </p>
            <p className="mt-2 text-sm text-[var(--color-muted)]">
              <Placeholder label="GSTIN, if applicable" />
            </p>
          </div>

          <div>
            <p className="text-xs font-semibold tracking-wider text-[var(--color-ink)] uppercase">Shop</p>
            <ul className="mt-4 space-y-2.5 text-sm text-[var(--color-muted)]">
              {shopLinks.map((link) => (
                <li key={link.to}>
                  <Link to={link.to} className="transition-colors hover:text-[var(--color-accent)]">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <p className="text-xs font-semibold tracking-wider text-[var(--color-ink)] uppercase">Policies</p>
            <ul className="mt-4 space-y-2.5 text-sm text-[var(--color-muted)]">
              {policyLinks.map((link) => (
                <li key={link.to}>
                  <Link to={link.to} className="transition-colors hover:text-[var(--color-accent)]">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <p className="text-xs font-semibold tracking-wider text-[var(--color-ink)] uppercase">Contact</p>
            <ul className="mt-4 space-y-3 text-sm text-[var(--color-muted)]">
              <li className="flex items-start gap-2.5">
                <MailIcon className="mt-0.5 h-4 w-4 shrink-0 text-[var(--color-accent)]" />
                <Placeholder label="support email" example="support@snapprint.in" />
              </li>
              <li className="flex items-start gap-2.5">
                <PhoneIcon className="mt-0.5 h-4 w-4 shrink-0 text-[var(--color-accent)]" />
                <Placeholder label="support phone number" />
              </li>
            </ul>
            <p className="mt-4 text-sm text-[var(--color-muted)]">
              Privacy: <a href="mailto:privacy@snapprint.in" className="text-[var(--color-accent)] hover:underline">privacy@snapprint.in</a>
            </p>
          </div>
        </div>

        <div className="mt-12 flex flex-col items-start justify-between gap-4 border-t border-[var(--color-border)] pt-8 text-xs text-[var(--color-muted-2)] sm:flex-row sm:items-center">
          <p>&copy; {new Date().getFullYear()} SnapPrint. All rights reserved.</p>
          <div className="flex items-center gap-2 text-[var(--color-muted)]">
            <ShieldCheckIcon className="h-4 w-4 text-[var(--color-accent)]" />
            <span>Payments secured by Razorpay</span>
          </div>
        </div>
      </div>
    </footer>
  )
}
