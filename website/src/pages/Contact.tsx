import { Placeholder } from '../components/Placeholder'
import { Reveal } from '../components/Reveal'
import { ClockIcon, MailIcon, MapPinIcon, PhoneIcon, ReceiptIcon, ShieldCheckIcon } from '../components/Icons'

const contactCards = [
  {
    icon: MailIcon,
    title: 'Support email',
    body: <Placeholder label="support email" example="support@snapprint.in" />,
  },
  {
    icon: PhoneIcon,
    title: 'Support phone',
    body: <Placeholder label="support phone number" />,
  },
  {
    icon: MailIcon,
    title: 'Privacy email',
    body: <a href="mailto:privacy@snapprint.in" className="text-[var(--color-accent)] hover:underline">privacy@snapprint.in</a>,
  },
  {
    icon: ClockIcon,
    title: 'Support hours',
    body: <Placeholder label="support hours" example="Mon-Sat, 10am-7pm IST" />,
  },
]

const businessDetails = [
  { label: 'Business / legal entity name', value: <Placeholder label="legal entity name" example="SnapPrint Private Limited" /> },
  { label: 'Registered address', value: <Placeholder label="registered / physical address" /> },
  { label: 'GSTIN', value: <Placeholder label="GSTIN, if applicable" /> },
  { label: 'Website', value: <a href="https://snapprint.in" className="text-[var(--color-accent)] hover:underline">snapprint.in</a> },
]

export function Contact() {
  return (
    <div>
      <section className="ambient-glow border-b border-[var(--color-border)] px-6 py-14 sm:py-20">
        <div className="mx-auto max-w-6xl">
          <span className="text-xs font-semibold tracking-[0.2em] text-[var(--color-accent)] uppercase">
            Contact
          </span>
          <div className="mt-4 grid gap-8 lg:grid-cols-[1fr_360px] lg:items-end">
            <div>
              <h1 className="text-4xl font-extrabold tracking-tight sm:text-5xl">Contact Us</h1>
              <p className="mt-4 max-w-2xl leading-7 text-[var(--color-muted)]">
                For product questions, order support, privacy requests, or payment queries, use
                the details below.
              </p>
            </div>
            <div className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] p-5">
              <p className="flex items-center gap-2 text-sm font-semibold text-[var(--color-accent)]">
                <ShieldCheckIcon className="h-4 w-4" />
                Payments secured by Razorpay
              </p>
              <p className="mt-3 text-sm leading-6 text-[var(--color-muted)]">
                SnapPrint does not store card, UPI, or bank account details on its servers.
              </p>
            </div>
          </div>
        </div>
      </section>

      <div className="mx-auto max-w-6xl px-6 py-14 sm:py-18">
        <div className="grid gap-5 md:grid-cols-2 lg:grid-cols-4">
          {contactCards.map((card, index) => (
            <Reveal key={card.title} delay={index * 70}>
              <div className="flex h-full gap-4 rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] p-6">
                <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg bg-[var(--color-accent-soft)] text-[var(--color-accent)]">
                  <card.icon className="h-5 w-5" />
                </span>
                <div>
                  <p className="text-xs font-semibold tracking-wide text-[var(--color-muted-2)] uppercase">
                    {card.title}
                  </p>
                  <p className="mt-2 text-sm leading-6 text-[var(--color-ink)]">{card.body}</p>
                </div>
              </div>
            </Reveal>
          ))}
        </div>

        <Reveal className="mt-10">
          <div className="grid gap-8 rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] p-6 sm:p-8 lg:grid-cols-[0.8fr_1.2fr]">
            <div>
              <p className="flex items-center gap-2 text-sm font-semibold text-[var(--color-accent)]">
                <ReceiptIcon className="h-4 w-4" />
                Business details
              </p>
              <h2 className="mt-3 text-2xl font-extrabold tracking-tight">Registered business information</h2>
              <p className="mt-3 text-sm leading-6 text-[var(--color-muted)]">
                Official registration details for SnapPrint, published here for transparency.
              </p>
            </div>
            <dl className="grid gap-4">
              {businessDetails.map((item) => (
                <div key={item.label} className="border-b border-[var(--color-border)] pb-4 last:border-0 last:pb-0">
                  <dt className="text-xs font-semibold tracking-wide text-[var(--color-muted-2)] uppercase">
                    {item.label}
                  </dt>
                  <dd className="mt-1 text-sm leading-6 text-[var(--color-ink)]">{item.value}</dd>
                </div>
              ))}
            </dl>
          </div>
        </Reveal>

        <Reveal className="mt-10">
          <div className="flex gap-4 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg-soft)] p-6">
            <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg bg-[var(--color-accent-soft)] text-[var(--color-accent)]">
              <MapPinIcon className="h-5 w-5" />
            </span>
            <p className="text-sm leading-6 text-[var(--color-muted)]">
              For order-specific help, sign in to the SnapPrint app and include your order ID
              when contacting support. That keeps product, payment, and delivery context tied to
              the correct order record.
            </p>
          </div>
        </Reveal>
      </div>
    </div>
  )
}
