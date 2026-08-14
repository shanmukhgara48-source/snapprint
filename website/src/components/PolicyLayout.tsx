import type { ReactNode } from 'react'

interface PolicySection {
  heading: string
  body: ReactNode
}

interface PolicyLayoutProps {
  title: string
  lastUpdated: ReactNode
  intro?: ReactNode
  sections: PolicySection[]
}

function slugify(text: string) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '')
}

export function PolicyLayout({ title, lastUpdated, intro, sections }: PolicyLayoutProps) {
  return (
    <div>
      <section className="ambient-glow border-b border-[var(--color-border)] px-6 py-16 sm:py-24">
        <div className="mx-auto max-w-6xl">
          <div className="max-w-2xl">
            <span className="text-xs font-semibold tracking-[0.2em] text-[var(--color-accent)] uppercase">Policy</span>
            <h1 className="mt-3 text-3xl font-extrabold tracking-tight text-balance sm:text-6xl">{title}</h1>
            <p className="mt-5 inline-flex items-center rounded-full border border-[var(--color-border-strong)] px-3 py-1 text-xs text-[var(--color-muted)]">
              Last updated: {lastUpdated}
            </p>
            {intro && <p className="mt-6 leading-relaxed text-[var(--color-muted)]">{intro}</p>}
          </div>
        </div>
      </section>

      <div className="mx-auto max-w-6xl px-6 py-16 sm:py-24">
        <div className="grid gap-10 lg:grid-cols-[240px_1fr]">
          <nav className="hidden lg:block">
            <div className="sticky top-24 space-y-2.5 border-l border-[var(--color-border)] pl-5 text-sm">
              {sections.map((section) => (
                <a
                  key={section.heading}
                  href={`#${slugify(section.heading)}`}
                  className="block text-[var(--color-muted)] transition-colors hover:text-[var(--color-accent)]"
                >
                  {section.heading}
                </a>
              ))}
            </div>
          </nav>

          <div className="max-w-3xl space-y-6">
            {sections.map((section) => (
              <section
                key={section.heading}
                id={slugify(section.heading)}
                className="scroll-mt-24 rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] p-6 transition-colors duration-300 hover:border-[var(--color-border-strong)] sm:p-8"
              >
                <h2 className="text-lg font-bold text-[var(--color-ink)]">{section.heading}</h2>
                <div className="mt-3 space-y-3 leading-relaxed text-[var(--color-muted)]">{section.body}</div>
              </section>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
