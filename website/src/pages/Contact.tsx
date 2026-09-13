import { useState } from 'react'
import { Reveal } from '../components/Reveal'
import { BusinessValue } from '../components/BusinessValue'
import { Seo } from '../components/Seo'
import { BUSINESS } from '../config/business'
import { api } from '../services/api'
import { isValidEmail } from '../lib/validation'
import { handleSpotlight } from '../lib/spotlight'
import { useToastOptional } from '../context/Toast'
import { ClockIcon, MailIcon, MapPinIcon, PhoneIcon, ReceiptIcon, ShieldCheckIcon } from '../components/Icons'

export function Contact() {
  const toast = useToastOptional()
  const [form, setForm] = useState({ name: '', email: '', subject: '', message: '' })
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [sending, setSending] = useState(false)
  const [sent, setSent] = useState(false)

  const supportEmail = BUSINESS.supportEmail
  const supportPhone = BUSINESS.supportPhone
  const privacyEmail = BUSINESS.privacyEmail

  const contactCards = [
    {
      icon: MailIcon,
      title: 'Support email',
      body: supportEmail ? (
        <a href={`mailto:${supportEmail}`} className="text-[var(--color-accent)] hover:underline">{supportEmail}</a>
      ) : (
        <BusinessValue field="supportEmail" />
      ),
    },
    {
      icon: PhoneIcon,
      title: 'Support phone',
      body: supportPhone ? (
        <a href={`tel:${supportPhone.replace(/\s/g, '')}`} className="text-[var(--color-accent)] hover:underline">{supportPhone}</a>
      ) : (
        <BusinessValue field="supportPhone" />
      ),
    },
    {
      icon: MailIcon,
      title: 'Privacy email',
      body: privacyEmail ? (
        <a href={`mailto:${privacyEmail}`} className="text-[var(--color-accent)] hover:underline">{privacyEmail}</a>
      ) : (
        <BusinessValue field="privacyEmail" />
      ),
    },
    {
      icon: ClockIcon,
      title: 'Support hours',
      body: <BusinessValue field="supportHours" />,
    },
  ]

  const businessDetails = [
    { label: 'Business / legal entity name', value: <BusinessValue field="legalEntityName" /> },
    { label: 'Registered address', value: <BusinessValue field="registeredAddress" /> },
    { label: 'Support email', value: <BusinessValue field="supportEmail" /> },
    { label: 'Website', value: <a href="https://snapprint.in" className="text-[var(--color-accent)] hover:underline">snapprint.in</a> },
  ]

  return (
    <div>
      <Seo
        title="Contact Us | SnapPrint"
        description="Contact SnapPrint support for product, order and payment help."
        path="/contact"
      />
      <section className="ambient-glow border-b border-[var(--color-border)] px-6 py-16 sm:py-24">
        <div className="mx-auto max-w-6xl">
          <span className="text-xs font-semibold tracking-[0.2em] text-[var(--color-accent)] uppercase">
            Contact
          </span>
          <div className="mt-4 grid gap-8 lg:grid-cols-[1fr_360px] lg:items-end">
            <div>
              <h1 className="font-display text-4xl font-semibold tracking-normal text-balance sm:text-6xl">Contact Us</h1>
              <p className="mt-4 max-w-2xl leading-7 text-[var(--color-muted)]">
                For product questions, order support, privacy requests, or payment queries, use
                the details below.
              </p>
            </div>
            <div className="rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] p-5">
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

      <div className="mx-auto max-w-6xl px-6 py-16 sm:py-24">
        <div className="grid gap-5 md:grid-cols-2 lg:grid-cols-4">
          {contactCards.map((card, index) => (
            <Reveal key={card.title} delay={index * 70}>
              <div
                onMouseMove={handleSpotlight}
                className="spotlight flex h-full gap-4 overflow-hidden rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] p-6 transition-all duration-500 ease-[cubic-bezier(0.16,1,0.3,1)] hover:-translate-y-1 hover:border-[var(--color-accent)]/50"
              >
                <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-[var(--color-accent-soft)] text-[var(--color-accent)]">
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
          <div className="grid gap-8 rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] p-6 transition-colors duration-300 hover:border-[var(--color-border-strong)] sm:p-8 lg:grid-cols-[0.8fr_1.2fr]">
            <div>
              <p className="flex items-center gap-2 text-sm font-semibold text-[var(--color-accent)]">
                <ReceiptIcon className="h-4 w-4" />
                Business details
              </p>
              <h2 className="font-display mt-3 text-2xl font-semibold tracking-normal">Registered business information</h2>
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
          <div className="grid gap-8 rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] p-6 transition-colors duration-300 hover:border-[var(--color-accent)]/40 sm:p-8 lg:grid-cols-[0.8fr_1.2fr]">
            <div>
              <p className="flex items-center gap-2 text-sm font-semibold text-[var(--color-accent)]">
                <MailIcon className="h-4 w-4" />
                Send us a message
              </p>
              <h2 className="font-display mt-3 text-2xl font-semibold tracking-normal">We reply within 1 business day</h2>
              <p className="mt-3 text-sm leading-6 text-[var(--color-muted)]">
                Product questions, order support, privacy requests, or payment
                queries — include your order ID for order-specific help.
              </p>
            </div>
            {sent ? (
              <div role="status" className="rounded-xl border border-green-200 bg-green-50 p-6 text-sm leading-6 text-green-800">
                <strong>Message received.</strong> Our support team will get back
                to you at the email you provided.
              </div>
            ) : (
              <form
                onSubmit={async (e) => {
                  e.preventDefault()
                  const next: Record<string, string> = {}
                  if (form.name.trim().length < 2) next.name = 'Please tell us your name'
                  if (!isValidEmail(form.email)) next.email = 'Enter a valid email address'
                  if (form.subject.trim().length < 4) next.subject = 'Please add a subject'
                  if (form.message.trim().length < 10) next.message = 'Please describe your request (10+ characters)'
                  setErrors(next)
                  if (Object.keys(next).length > 0) return
                  setSending(true)
                  try {
                    await api.submitContact({
                      name: form.name.trim(),
                      email: form.email.trim(),
                      subject: form.subject.trim(),
                      message: form.message.trim(),
                    })
                    setSent(true)
                  } catch (err: any) {
                    toast?.notifyError(err?.message || 'Could not send your message. Please try again.')
                  } finally {
                    setSending(false)
                  }
                }}
                className="grid gap-4"
                noValidate
              >
                <div className="grid gap-4 sm:grid-cols-2">
                  <div>
                    <label htmlFor="contact-name" className="text-xs font-semibold tracking-wide text-[var(--color-muted-2)] uppercase">Name</label>
                    <input
                      id="contact-name" name="name" autoComplete="name"
                      value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })}
                      className="mt-1 w-full rounded border border-[var(--color-border)] bg-[var(--color-bg)] p-3 text-sm outline-none focus:border-[var(--color-accent)]"
                    />
                    {errors.name && <p role="alert" className="mt-1 text-xs text-red-600">{errors.name}</p>}
                  </div>
                  <div>
                    <label htmlFor="contact-email" className="text-xs font-semibold tracking-wide text-[var(--color-muted-2)] uppercase">Email</label>
                    <input
                      id="contact-email" name="email" type="email" autoComplete="email"
                      value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })}
                      className="mt-1 w-full rounded border border-[var(--color-border)] bg-[var(--color-bg)] p-3 text-sm outline-none focus:border-[var(--color-accent)]"
                    />
                    {errors.email && <p role="alert" className="mt-1 text-xs text-red-600">{errors.email}</p>}
                  </div>
                </div>
                <div>
                  <label htmlFor="contact-subject" className="text-xs font-semibold tracking-wide text-[var(--color-muted-2)] uppercase">Subject</label>
                  <input
                    id="contact-subject" name="subject"
                    value={form.subject} onChange={(e) => setForm({ ...form, subject: e.target.value })}
                    placeholder="e.g. Help with order #A1B2C3D4"
                    className="mt-1 w-full rounded border border-[var(--color-border)] bg-[var(--color-bg)] p-3 text-sm outline-none focus:border-[var(--color-accent)]"
                  />
                  {errors.subject && <p role="alert" className="mt-1 text-xs text-red-600">{errors.subject}</p>}
                </div>
                <div>
                  <label htmlFor="contact-message" className="text-xs font-semibold tracking-wide text-[var(--color-muted-2)] uppercase">Message</label>
                  <textarea
                    id="contact-message" name="message" rows={5}
                    value={form.message} onChange={(e) => setForm({ ...form, message: e.target.value })}
                    className="mt-1 w-full rounded border border-[var(--color-border)] bg-[var(--color-bg)] p-3 text-sm outline-none focus:border-[var(--color-accent)]"
                  />
                  {errors.message && <p role="alert" className="mt-1 text-xs text-red-600">{errors.message}</p>}
                </div>
                <button type="submit" disabled={sending} className="shop-button justify-center sm:w-auto">
                  {sending ? 'Sending…' : 'Send message'}
                </button>
              </form>
            )}
          </div>
        </Reveal>

        <Reveal className="mt-10">
          <div className="flex gap-4 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-soft)] p-6 transition-colors duration-300 hover:border-[var(--color-accent)]/40">
            <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-[var(--color-accent-soft)] text-[var(--color-accent)]">
              <MapPinIcon className="h-5 w-5" />
            </span>
            <p className="text-sm leading-6 text-[var(--color-muted)]">
              For order-specific help, sign in to your SnapPrint account and include your order ID
              when contacting support. That keeps product, payment, and delivery context tied to
              the correct order record.
            </p>
          </div>
        </Reveal>
      </div>
    </div>
  )
}
