import { Link } from 'react-router-dom'
import { LogoMark } from './Logo'
import { ShieldCheckIcon } from './Icons'
export function Footer() {
  return (
    <footer className="store-footer">
      <div className="wrap">
        <div className="footer-top">
          <div className="footer-brand">
            <Link to="/" className="brand">
              <LogoMark className="h-8 w-8" />
              <span>
                snap<span>print</span>
              </span>
            </Link>
            <p>
              For the moments
              <br />
              that make you, you.
            </p>
          </div>
          <div>
            <h2>Make something</h2>
            <ul>
              <li>
                <Link to="/products?category=photo-prints">Photo prints</Link>
              </li>
              <li>
                <Link to="/products?category=photo-books">Photo books</Link>
              </li>
              <li>
                <Link to="/products?category=frames-wall-decor">
                  Frames & canvas
                </Link>
              </li>
              <li>
                <Link to="/products?occasion=gift">Personalised gifts</Link>
              </li>
            </ul>
          </div>
          <div>
            <h2>A little guidance</h2>
            <ul>
              <li>
                <Link to="/products">Browse all prints</Link>
              </li>
              <li>
                <Link to="/pricing">Pricing & delivery</Link>
              </li>
              <li>
                <Link to="/card">Your cart</Link>
              </li>
              <li>
                <Link to="/contact">Contact & business details</Link>
              </li>
            </ul>
          </div>
          <div>
            <h2>The details</h2>
            <ul>
              <li>
                <Link to="/shipping">Shipping policy</Link>
              </li>
              <li>
                <Link to="/refund">Returns & cancellations</Link>
              </li>
              <li>
                <Link to="/privacy">Privacy policy</Link>
              </li>
              <li>
                <Link to="/terms">Terms & conditions</Link>
              </li>
              <li>
                <a href="mailto:privacy@snapprint.in">Privacy enquiries</a>
              </li>
            </ul>
          </div>
        </div>
        <div className="footer-bottom">
          <p>© {new Date().getFullYear()} SnapPrint. Made for your memories.</p>
          <span>
            <ShieldCheckIcon /> Payments in the app secured by Razorpay
          </span>
          <p>Made personal. Delivered across India.</p>
        </div>
      </div>
    </footer>
  )
}
