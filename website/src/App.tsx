import { BrowserRouter, Route, Routes } from 'react-router-dom'
import { Nav } from './components/Nav'
import { Footer } from './components/Footer'
import { Home } from './pages/Home'
import { Products } from './pages/Products'
import { Pricing } from './pages/Pricing'
import { Contact } from './pages/Contact'
import { Terms } from './pages/Terms'
import { Privacy } from './pages/Privacy'
import { Shipping } from './pages/Shipping'
import { Refund } from './pages/Refund'

export default function App() {
  return (
    <BrowserRouter>
      <div className="flex min-h-screen flex-col">
        <Nav />
        <main className="flex-1">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/products" element={<Products />} />
            <Route path="/products-services" element={<Products />} />
            <Route path="/pricing" element={<Pricing />} />
            <Route path="/contact" element={<Contact />} />
            <Route path="/terms" element={<Terms />} />
            <Route path="/terms-and-conditions" element={<Terms />} />
            <Route path="/privacy" element={<Privacy />} />
            <Route path="/privacy-policy" element={<Privacy />} />
            <Route path="/shipping" element={<Shipping />} />
            <Route path="/shipping-policy" element={<Shipping />} />
            <Route path="/refund" element={<Refund />} />
            <Route path="/cancellation-refund-policy" element={<Refund />} />
            <Route path="*" element={<Home />} />
          </Routes>
        </main>
        <Footer />
      </div>
    </BrowserRouter>
  )
}
