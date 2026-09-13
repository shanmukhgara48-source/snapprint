import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { categories, formatPrice } from '../data/products'
import { curatedProducts, moments, photoUrl } from '../data/shopping'
import { api } from '../services/api'
import { toCatalogProduct } from '../lib/products'
import type { CatalogProduct } from '../data/products'
import { ProductVisual } from '../components/ProductVisual'
import { ProductCard } from '../components/ProductCard'
import {
  ArrowRightIcon,
  UploadIcon,
  TruckIcon,
  ShieldCheckIcon,
  SparkleIcon,
  GiftIcon,
} from '../components/Icons'
import { Reveal } from '../components/Reveal'
import { Seo } from '../components/Seo'
import { appAsset } from '../lib/assets'
import { AntiGravityWrap } from '../components/antiGravity/AntiGravityWrap'

export function Home() {
  // Curated picks: real backend products first, static catalogue fallback.
  const [curated, setCurated] = useState<CatalogProduct[]>(curatedProducts)
  useEffect(() => {
    let cancelled = false
    async function load() {
      try {
        const [featured, trending] = await Promise.all([
          api.getProducts(undefined, 1).catch(() => null),
          api.getProducts(undefined, 1).catch(() => null),
        ])
        const items = [
          ...((featured as any)?.items ?? []),
          ...((trending as any)?.items ?? []),
        ]
        if (!cancelled && items.length > 0) {
          const seen = new Set<string>()
          const adapted = items
            .map(toCatalogProduct)
            .filter((p) => (seen.has(p.id) ? false : (seen.add(p.id), true)))
            .slice(0, 4)
          if (adapted.length > 0) setCurated(adapted)
        }
      } catch {
        /* static fallback stays */
      }
    }
    load()
    return () => {
      cancelled = true
    }
  }, [])

  return (
    <div className="storefront">
      <Seo
        title="SnapPrint — Photo Prints, Albums, Frames & Gifts"
        description="SnapPrint turns phone photos into premium prints, albums, frames, wall decor, and personalised gifts with clear pricing, secure Razorpay checkout, and delivery across India."
        path="/"
        jsonLd={{
          '@context': 'https://schema.org',
          '@type': 'Organization',
          name: 'SnapPrint',
          url: 'https://snapprint.in/',
          logo: 'https://snapprint.in/favicon.svg',
          sameAs: [],
        }}
      />
      <section className="home-hero wrap">
        <Reveal delay={100} className="hero-copy">
          <p className="eyebrow">
            <span /> MADE FROM YOUR MEMORIES
          </p>
          <h1>
            Some moments
            <br />
            deserve to be
            <br />
            <em>held onto.</em>
          </h1>
          <p className="hero-description">
            The big days. The little things. The beautifully ordinary.
            <br className="desktop-break" /> Turn your favourite photos into
            something real.
          </p>
          <div className="hero-actions">
            <Link className="shop-button" to="/products/classic-photo-prints">
              <UploadIcon /> Start with your photos <ArrowRightIcon />
            </Link>
            <Link className="text-link" to="/products">
              Explore the collection <ArrowRightIcon />
            </Link>
          </div>
          <p className="hero-footnote">
            Yours to create. Yours to keep. Or theirs to treasure.
          </p>
        </Reveal>
        <Reveal delay={300} className="hero-art">
          <AntiGravityWrap intensity={8} scaleOnHover={1.01}>
            <img
              src={appAsset('images/memories-still-life.jpg')}
              alt="A sunlit arrangement of personal photo prints, a memory book, and a framed seaside moment"
              fetchPriority="high"
            />
            <span className="hero-stamp">
              off your phone.
              <br />
              <em>into your life.</em>
              <SparkleIcon />
            </span>
            <Link
              className="hero-product-tag"
              to="/products/retro-polaroid-prints"
            >
              <span className="tag-symbol">↗</span>
              <span>
                A little nostalgia, printed.
                <small>Discover retro prints · from ₹478</small>
              </span>
              <ArrowRightIcon />
            </Link>
            <span className="image-caption">
              A little inspiration. Your photos make it yours.
            </span>
          </AntiGravityWrap>
        </Reveal>
      </section>
      <div className="promise-strip">
        <div className="wrap">
          <span>
            <SparkleIcon /> Made personal, by you
          </span>
          <span>
            <TruckIcon /> Delivery across India
          </span>
          <span>
            <ShieldCheckIcon /> Secure Razorpay checkout
          </span>
          <Link to="/pricing">
            Clear prices. Happy surprises. <ArrowRightIcon />
          </Link>
        </div>
      </div>
      <section className="shop-section wrap">
        <div className="section-heading">
          <div>
            <p className="eyebrow">FROM CAMERA ROLL TO REAL LIFE</p>
            <h2>What will you make?</h2>
          </div>
          <Link className="text-link" to="/products">
            Shop all products <ArrowRightIcon />
          </Link>
        </div>
        <div className="category-grid">
          {categories.map((category, index) => (
            <Link
              className="category-card"
              to={`/products?category=${category.id}`}
              key={category.id}
            >
              <ProductVisual categoryId={category.id} />
              <div>
                <h3>
                  {
                    [
                      'Photo prints',
                      'Photo books',
                      'Frames & canvas',
                      'Personalised gifts',
                    ][index]
                  }
                  <ArrowRightIcon />
                </h3>
                <p>
                  {
                    [
                      'Small prints. Endless possibilities.',
                      'Your stories, page by page.',
                      'Make yourself at home.',
                      'A little more “you” in every gift.',
                    ][index]
                  }
                </p>
                <span>From {formatPrice(category.priceRange[0])}</span>
              </div>
            </Link>
          ))}
        </div>
        <p className="visual-note">
          Product visuals are illustrative. Explore each product for available
          formats and finishes.
        </p>
      </section>
      <section className="finder-band wrap">
        <div className="finder-spark">✳</div>
        <div>
          <p className="eyebrow">A LITTLE HELP GETTING STARTED</p>
          <h2>
            A camera roll full of memories.
            <br />
            Not sure what to make?
          </h2>
        </div>
        <Link className="shop-button light-button" to="/products">
          Browse top picks first <ArrowRightIcon />
        </Link>
        <span className="finder-note">
          A few simple choices. Something very you.
        </span>
      </section>
      <section className="shop-section wrap">
        <div className="section-heading">
          <div>
            <p className="eyebrow">GOOD PLACES TO START</p>
            <h2>Small things. Lasting feelings.</h2>
          </div>
          <Link className="text-link" to="/products">
            Find your favourite <ArrowRightIcon />
          </Link>
        </div>
        <div className="product-grid">
          {curated.map((p) => (
            <ProductCard product={p} key={p.id} />
          ))}
        </div>
      </section>
      <section className="occasion-section">
        <div className="wrap shop-section">
          <div className="section-heading">
            <div>
              <p className="eyebrow">THERE’S A MEMORY FOR THAT</p>
              <h2>Shop the feeling.</h2>
            </div>
            <p>
              Big milestones or no occasion at all.
              <br />
              Start with what matters to you.
            </p>
          </div>
          <div className="occasion-grid">
            {moments.map((moment) => (
              <Link
                to={`/products?occasion=${moment.id}`}
                className="occasion-card"
                key={moment.id}
              >
                <img
                  src={photoUrl(moment.image)}
                  alt={
                    moment.short === 'Travel'
                      ? 'A lakeside holiday surrounded by mountains'
                      : moment.short === 'Gifting'
                        ? 'A little new arrival held close'
                        : moment.short === 'Everyday'
                          ? 'A beautiful view from a day worth remembering'
                          : 'A wedding celebration under the lights'
                  }
                  loading="lazy"
                />
                <div>
                  <span>{moment.short}</span>
                  <h3>{moment.label}</h3>
                  <p>{moment.description}</p>
                </div>
                <span className="occasion-arrow">
                  <ArrowRightIcon />
                </span>
              </Link>
            ))}
          </div>
        </div>
      </section>
      <section className="story-section wrap">
        <div className="story-photo">
          <ProductVisual categoryId="photo-prints" />
          <span className="handwritten">remember this?</span>
        </div>
        <div className="story-copy">
          <p className="eyebrow">LESS SCROLLING. MORE SMILING.</p>
          <h2>
            Your photos weren’t
            <br />
            meant to stay
            <br />
            <em>on your phone.</em>
          </h2>
          <p>
            A photo on the fridge. A story on the coffee table. A favourite face
            waiting on your desk. Make a little space for the moments that make
            you, you.
          </p>
          <Link className="text-link" to="/products?occasion=everyday">
            Bring a memory home <ArrowRightIcon />
          </Link>
        </div>
      </section>
      <section className="how-section wrap">
        <div className="section-heading">
          <div>
            <p className="eyebrow">HAPPY MEMORIES. SIMPLE STEPS.</p>
            <h2>A little you. A little us. A lot to love.</h2>
          </div>
        </div>
        <div className="steps-grid">
          {[
            {
              icon: UploadIcon,
              title: 'Pick your happy moments',
              body: 'Choose a product and try a photo in your private, on-device preview.',
            },
            {
              icon: SparkleIcon,
              title: 'Make it feel like you',
              body: 'Explore formats, choose a size, and save your favourites to your card.',
            },
            {
              icon: GiftIcon,
              title: 'Make it real in the app',
              body: 'Upload your originals, finish customising, and confirm delivery before you pay.',
            },
          ].map((step, i) => (
            <div key={step.title}>
              <span className="step-number">0{i + 1}</span>
              <step.icon />
              <h3>{step.title}</h3>
              <p>{step.body}</p>
            </div>
          ))}
        </div>
      </section>
      <section className="last-call">
        <p className="eyebrow">
          YOUR NEXT FAVOURITE THING IS ALREADY IN YOUR CAMERA ROLL
        </p>
        <h2>
          Let’s make something <em>meaningful.</em>
        </h2>
        <Link to="/products" className="shop-button">
          Find your first print <ArrowRightIcon />
        </Link>
      </section>
    </div>
  )
}
