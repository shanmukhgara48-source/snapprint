import { useEffect, useState } from 'react'
import { NavLink, useLocation } from 'react-router-dom'
import { LogoMark } from './Logo'
import { Button } from './Button'
import { MenuIcon, XIcon } from './Icons'

const links = [
  { to: '/', label: 'Home', end: true },
  { to: '/products', label: 'Products' },
  { to: '/pricing', label: 'Pricing' },
  { to: '/contact', label: 'Contact Us' },
]

export function Nav() {
  const [open, setOpen] = useState(false)
  const [scrolled, setScrolled] = useState(false)
  const location = useLocation()

  useEffect(() => setOpen(false), [location.pathname])

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8)
    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  return (
    <header
      className={`sticky top-0 z-50 border-b transition-colors duration-300 ${
        scrolled
          ? 'border-[var(--color-border)] bg-[var(--color-bg)]/85 backdrop-blur-lg'
          : 'border-transparent bg-transparent'
      }`}
    >
      <nav className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <NavLink to="/" className="flex items-center gap-2.5 text-lg font-extrabold tracking-tight text-[var(--color-ink)]">
          <LogoMark className="h-8 w-8" />
          Snap<span className="text-[var(--color-accent)]">Print</span>
        </NavLink>

        <ul className="hidden items-center gap-8 text-sm font-medium md:flex">
          {links.map((link) => (
            <li key={link.to}>
              <NavLink
                to={link.to}
                end={link.end}
                className={({ isActive }) =>
                  `relative py-1 transition-colors ${
                    isActive ? 'text-[var(--color-accent)]' : 'text-[var(--color-ink)]/85 hover:text-[var(--color-accent)]'
                  }`
                }
              >
                {link.label}
              </NavLink>
            </li>
          ))}
        </ul>

        <div className="hidden md:block">
          <Button to="/products" variant="primary" className="!px-5 !py-2.5 text-xs">
            Browse Catalog
          </Button>
        </div>

        <button
          className="flex h-9 w-9 items-center justify-center rounded-lg border border-[var(--color-border-strong)] text-[var(--color-ink)] md:hidden"
          onClick={() => setOpen((o) => !o)}
          aria-label="Toggle menu"
          aria-expanded={open}
        >
          {open ? <XIcon /> : <MenuIcon />}
        </button>
      </nav>

      {open && (
        <div className="border-t border-[var(--color-border)] bg-[var(--color-bg)] px-6 py-5 md:hidden">
          <ul className="flex flex-col gap-4 text-sm font-medium">
            {links.map((link) => (
              <li key={link.to}>
                <NavLink
                  to={link.to}
                  end={link.end}
                  className={({ isActive }) =>
                    isActive ? 'text-[var(--color-accent)]' : 'text-[var(--color-ink)]/85'
                  }
                >
                  {link.label}
                </NavLink>
              </li>
            ))}
          </ul>
          <Button to="/products" variant="primary" className="mt-5 w-full">
            Browse Catalog
          </Button>
        </div>
      )}
    </header>
  )
}
