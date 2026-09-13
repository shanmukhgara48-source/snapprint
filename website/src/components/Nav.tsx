import { useEffect, useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { LogoMark } from './Logo'
import { ArrowRightIcon, MenuIcon, XIcon, PackageIcon } from './Icons'
import { usePrintPlan } from '../context/PrintPlan'
import { useWishlist } from '../context/Wishlist'
import { getAuthToken, clearAuthToken, api } from '../services/api'
import { firebaseSignOut } from '../lib/firebase'
import { GravityField } from './antiGravity/GravityField'

const links = [
  { to: '/products?category=photo-prints', label: 'Photo prints' },
  { to: '/products?category=photo-books', label: 'Photo books' },
  { to: '/products?category=frames-wall-decor', label: 'Frames & canvas' },
  { to: '/products?occasion=gift', label: 'Gifts' },
]

export function Nav() {
  const [open, setOpen] = useState(false)
  const location = useLocation()
  const { items } = usePrintPlan()
  const { count: wishlistCount } = useWishlist()
  const [authenticated, setAuthenticated] = useState(false)
  const navigate = useNavigate()

  useEffect(() => {
    const token = getAuthToken()
    if (token) {
      api.getOrders()
        .then(() => setAuthenticated(true))
        .catch(() => setAuthenticated(false))
    } else {
      setAuthenticated(false)
    }
  }, [location.pathname])

  useEffect(() => setOpen(false), [location])

  async function handleLogout() {
    clearAuthToken()
    try {
      await firebaseSignOut()
    } catch {
      /* non-fatal */
    }
    setAuthenticated(false)
    navigate('/auth')
  }

  return (
    <>
      <a className="skip-link" href="#main">
        Skip to content
      </a>
      <div className="announcement">
        Good memories deserve more than a camera roll.{' '}
        <Link to="/shipping">
          Free delivery · 5–7 business days <ArrowRightIcon />
        </Link>
      </div>
      <header className="shop-header">
        <nav className="shop-nav wrap" aria-label="Main navigation">
          <GravityField pullIntensity={10}>
            <Link to="/" className="brand">
              <LogoMark className="h-8 w-8" />
              <span>
                snap<span>print</span>
              </span>
            </Link>
          </GravityField>
          <div className="desktop-links">
            {links.map((link) => (
              <GravityField key={link.to} pullIntensity={8} className="inline-block">
                <Link to={link.to}>
                  {link.label}
                </Link>
              </GravityField>
            ))}
            <GravityField pullIntensity={10} className="inline-block ml-4">
              <Link to="/products" className="guide-link">
                Shop collection <span>✧</span>
              </Link>
            </GravityField>
          </div>
          <div className="nav-actions">
            <GravityField pullIntensity={12}>
              <Link
                to="/wishlist"
                className="plan-link block"
                aria-label={`Wishlist with ${wishlistCount} items`}
              >
                <span aria-hidden="true">♡</span>
                <span>Wishlist</span>
                {wishlistCount > 0 && <b>{wishlistCount}</b>}
              </Link>
            </GravityField>
            <GravityField pullIntensity={12}>
              <Link
                to="/card"
                className="plan-link block"
                aria-label={`Cart with ${items.length} items`}
              >
                <PackageIcon />
                <span>Cart</span>
                {items.length > 0 && <b>{items.length}</b>}
              </Link>
            </GravityField>
            {authenticated ? (
              <GravityField pullIntensity={12}>
                <div className="flex items-center gap-2">
                  <Link to="/orders" className="text-sm text-accent hover:underline">
                    Orders
                  </Link>
                  <Link to="/account" className="text-sm text-muted hover:text-ink transition-colors">
                    Account
                  </Link>
                  <button
                    onClick={handleLogout}
                    className="text-sm text-muted hover:text-ink transition-colors"
                  >
                    Logout
                  </button>
                </div>
              </GravityField>
            ) : (
              <GravityField pullIntensity={12}>
                <Link to="/auth" className="shop-button text-sm py-2 px-4">
                  Sign In
                </Link>
              </GravityField>
            )}
            <GravityField pullIntensity={12}>
              <button
                className="icon-button menu-toggle"
                aria-label={open ? 'Close menu' : 'Open menu'}
                aria-expanded={open}
                aria-controls="mobile-menu"
                onClick={() => setOpen(!open)}
              >
                {open ? <XIcon /> : <MenuIcon />}
              </button>
            </GravityField>
          </div>
        </nav>
        {open && (
          <div id="mobile-menu" className="mobile-menu">
            {links.map((link) => (
              <Link key={link.to} to={link.to}>
                {link.label}
                <ArrowRightIcon />
              </Link>
            ))}
            <Link to="/products?category=photo-prints">Explore prints</Link>
            <Link to="/pricing">Pricing & delivery</Link>
            <Link to="/contact">Contact us</Link>
            {authenticated ? (
              <>
                <Link to="/orders">My Orders</Link>
                <Link to="/account">Account</Link>
                <button onClick={handleLogout}>Logout</button>
              </>
            ) : (
              <Link to="/auth">Sign In</Link>
            )}
          </div>
        )}
      </header>
    </>
  )
}
