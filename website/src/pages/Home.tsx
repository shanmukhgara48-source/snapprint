import { Link } from 'react-router-dom'
import {
  categories,
  formatPrice,
  formatPriceRange,
  overallPriceRange,
  priceOnRequestCount,
  productCount,
} from '../data/products'
import type { CatalogCategory } from '../data/products'
import { deliveryOptions, formatDeliveryPrice } from '../data/delivery'
import { Button } from '../components/Button'
import { Reveal } from '../components/Reveal'
import { useParallax } from '../hooks/useParallax'
import {
  ArrowRightIcon,
  BookOpenIcon,
  CameraIcon,
  FrameIcon,
  GiftIcon,
  PackageIcon,
  ReceiptIcon,
  ShieldCheckIcon,
  SparkleIcon,
  TruckIcon,
  UploadIcon,
} from '../components/Icons'

const heroStats = [
  { value: productCount.toString(), label: 'products in catalog' },
  { value: categories.length.toString(), label: 'real categories' },
  { value: `${formatPrice(overallPriceRange[0])}+`, label: 'catalog pricing' },
]

const trustItems = [
  { icon: ShieldCheckIcon, label: 'Razorpay checkout' },
  { icon: TruckIcon, label: 'Delivery options from ₹0' },
  { icon: ReceiptIcon, label: 'Policies and pricing published' },
]

const steps = [
  {
    icon: UploadIcon,
    title: 'Upload your photos',
    body: 'Choose memories from your device and place a custom print order in the SnapPrint app.',
  },
  {
    icon: SparkleIcon,
    title: 'Pick product and finish',
    body: 'Select sizes, paper or product finish, quantity, and delivery option before checkout.',
  },
  {
    icon: PackageIcon,
    title: 'Track print to doorstep',
    body: 'Order status moves through processing, printed, out for delivery, and delivered in the app.',
  },
]

const reviewLinks = [
  { to: '/pricing', title: 'Transparent pricing', body: `${productCount} products with clearly listed base prices.` },
  { to: '/shipping', title: 'Shipping policy', body: `${deliveryOptions.length} delivery tiers, including ${formatDeliveryPrice(deliveryOptions[0].price)} delivery, with timelines shown in business days.` },
  { to: '/privacy', title: 'Privacy policy', body: 'Covers photo storage, retention, and how your data is used.' },
  { to: '/refund', title: 'Refund policy', body: 'Cancellation window, claim period, and refund processing timeline.' },
]

function CategoryIcon({ icon, className = 'h-5 w-5' }: { icon: string; className?: string }) {
  if (icon === 'book') return <BookOpenIcon className={className} />
  if (icon === 'frame') return <FrameIcon className={className} />
  if (icon === 'gift') return <GiftIcon className={className} />
  return <CameraIcon className={className} />
}

function Hero() {
  const { ref: parallaxRef, offset } = useParallax<HTMLDivElement>(0.08)

  return (
    <section className="relative isolate overflow-hidden border-b border-[var(--color-border)]">
      <div
        ref={parallaxRef}
        className="absolute inset-0 -z-20"
        style={{ transform: `translate3d(0, ${offset}px, 0) scale(1.12)` }}
      >
        <img
          src="/og.jpg"
          alt=""
          aria-hidden="true"
          loading="eager"
          decoding="async"
          className="h-full w-full object-cover object-[100%_45%] opacity-35"
        />
      </div>
      <div className="cinematic-scrim -z-10" />

      <div className="mx-auto flex min-h-[80vh] max-w-4xl flex-col items-center justify-center px-6 py-24 text-center sm:min-h-[88vh]">
        <span
          className="hero-enter animate-float inline-flex items-center gap-2 rounded-full border border-[var(--color-border-strong)] bg-black/30 px-4 py-1.5 text-xs font-semibold tracking-wide text-[var(--color-accent)] uppercase backdrop-blur"
          style={{ animationDelay: '0ms' }}
        >
          <SparkleIcon className="h-3.5 w-3.5" />
          Premium Indian photo printing
        </span>
        <h1
          className="hero-enter hero-title mt-7 font-extrabold text-balance"
          style={{ animationDelay: '110ms' }}
        >
          Print Your
          <span className="block text-gradient-gold">Memories.</span>
        </h1>
        <p
          className="hero-enter mt-7 max-w-xl text-base leading-8 text-[var(--color-muted)] sm:text-lg"
          style={{ animationDelay: '220ms' }}
        >
          Custom photo prints, photo books, frames, wall decor, and personalised gifts —
          crafted from your favourite moments and delivered across India.
        </p>
        <div
          className="hero-enter mt-10 flex flex-col gap-3 sm:flex-row sm:items-center"
          style={{ animationDelay: '320ms' }}
        >
          <Button to="/products" variant="primary">
            Explore Catalog
            <ArrowRightIcon className="h-4 w-4" />
          </Button>
          <Button to="/pricing" variant="secondary">
            View Pricing
          </Button>
        </div>
        <div
          className="hero-enter mt-9 flex flex-wrap items-center justify-center gap-x-6 gap-y-2 text-xs text-[var(--color-muted)] sm:text-sm"
          style={{ animationDelay: '400ms' }}
        >
          {trustItems.map((item) => (
            <span key={item.label} className="inline-flex items-center gap-2">
              <item.icon className="h-4 w-4 text-[var(--color-accent)]" />
              {item.label}
            </span>
          ))}
        </div>
      </div>

      <div
        className="hero-enter relative border-t border-white/10 bg-black/25 backdrop-blur"
        style={{ animationDelay: '480ms' }}
      >
        <div className="mx-auto grid max-w-5xl grid-cols-1 divide-y divide-white/10 sm:grid-cols-3 sm:divide-x sm:divide-y-0">
          {heroStats.map((stat) => (
            <div key={stat.label} className="px-6 py-5 text-center">
              <p className="text-2xl font-extrabold text-[var(--color-ink)]">{stat.value}</p>
              <p className="mt-1 text-xs font-semibold tracking-wide text-[var(--color-muted-2)] uppercase">
                {stat.label}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

function CategoryStory({ category, index }: { category: CatalogCategory; index: number }) {
  const reversed = index % 2 === 1

  return (
    <Reveal>
      <div className="grid items-center gap-10 lg:grid-cols-2 lg:gap-16">
        <div
          className={`image-vignette group aspect-[4/3] overflow-hidden rounded-2xl border border-[var(--color-border)] shadow-[0_40px_100px_-50px_rgba(0,0,0,0.9)] ${
            reversed ? 'lg:order-2' : ''
          }`}
        >
          <img
            src={category.imageUrl}
            alt={category.name}
            loading="lazy"
            decoding="async"
            className="h-full w-full object-cover transition-transform duration-[1200ms] ease-[cubic-bezier(0.16,1,0.3,1)] group-hover:scale-105"
          />
        </div>
        <div className={reversed ? 'lg:order-1' : ''}>
          <div className="flex items-center gap-3">
            <span className="numeral-ghost text-6xl sm:text-7xl">0{index + 1}</span>
            <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-[var(--color-accent-soft)] text-[var(--color-accent)]">
              <CategoryIcon icon={category.icon} />
            </span>
          </div>
          <h3 className="mt-5 text-3xl font-extrabold tracking-tight sm:text-4xl">{category.name}</h3>
          <p className="mt-4 max-w-md leading-7 text-[var(--color-muted)]">{category.description}</p>
          <p className="mt-6 text-2xl font-extrabold text-[var(--color-accent)]">
            {formatPriceRange(category.priceRange)}
          </p>
          <Link
            to="/products"
            className="group/link mt-6 inline-flex items-center gap-2 text-sm font-semibold text-[var(--color-ink)] transition-colors hover:text-[var(--color-accent)]"
          >
            Browse {category.name}
            <ArrowRightIcon className="h-4 w-4 transition-transform duration-300 group-hover/link:translate-x-1" />
          </Link>
        </div>
      </div>
    </Reveal>
  )
}

export function Home() {
  return (
    <div>
      <Hero />

      <section className="mx-auto max-w-6xl px-6 py-20 sm:py-28">
        <Reveal className="max-w-2xl">
          <span className="text-xs font-semibold tracking-[0.2em] text-[var(--color-accent)] uppercase">
            Products and services
          </span>
          <h2 className="mt-3 text-3xl font-extrabold tracking-tight sm:text-4xl">
            Every product, made to feel personal
          </h2>
          <p className="mt-4 leading-7 text-[var(--color-muted)]">
            {productCount} products across {categories.length} categories, priced from{' '}
            {formatPrice(overallPriceRange[0])} to {formatPrice(overallPriceRange[1])}.{' '}
            {priceOnRequestCount} items are marked price on request.
          </p>
        </Reveal>

        <div className="mt-16 space-y-20 sm:space-y-28">
          {categories.map((category, index) => (
            <CategoryStory key={category.id} category={category} index={index} />
          ))}
        </div>
      </section>

      <section className="border-y border-[var(--color-border)] bg-[var(--color-bg-soft)]">
        <div className="mx-auto max-w-6xl px-6 py-20 sm:py-28">
          <Reveal className="max-w-2xl">
            <span className="text-xs font-semibold tracking-[0.2em] text-[var(--color-accent)] uppercase">
              How it works
            </span>
            <h2 className="mt-3 text-3xl font-extrabold tracking-tight sm:text-4xl">
              Simple enough for everyday prints, careful enough for heirlooms
            </h2>
          </Reveal>
          <div className="mt-14 grid gap-10 sm:grid-cols-3 sm:gap-8">
            {steps.map((step, index) => (
              <Reveal key={step.title} delay={index * 90}>
                <div className="group">
                  <span className="numeral-ghost text-5xl">0{index + 1}</span>
                  <div className="mt-4 flex h-11 w-11 items-center justify-center rounded-xl bg-[var(--color-accent-soft)] text-[var(--color-accent)] transition-transform duration-500 group-hover:scale-110">
                    <step.icon className="h-5 w-5" />
                  </div>
                  <h3 className="mt-5 text-lg font-bold">{step.title}</h3>
                  <p className="mt-2 leading-6 text-[var(--color-muted)]">{step.body}</p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-6 py-20 sm:py-28">
        <Reveal className="max-w-2xl">
          <span className="text-xs font-semibold tracking-[0.2em] text-[var(--color-accent)] uppercase">
            Why customers trust SnapPrint
          </span>
          <h2 className="mt-3 text-3xl font-extrabold tracking-tight sm:text-4xl">
            Everything you need before you order
          </h2>
          <p className="mt-4 leading-7 text-[var(--color-muted)]">
            Pricing, policies, contact information, delivery details, and payment handling are
            all published up front, so there are no surprises at checkout.
          </p>
        </Reveal>

        <div className="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {reviewLinks.map((item, index) => (
            <Reveal key={item.to} delay={index * 70}>
              <Link
                to={item.to}
                className="group flex h-full flex-col rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] p-6 transition-all duration-500 ease-[cubic-bezier(0.16,1,0.3,1)] hover:-translate-y-1.5 hover:border-[var(--color-accent)]/60 hover:shadow-[0_22px_60px_-34px_rgba(212,175,55,0.6)]"
              >
                <h3 className="font-bold transition-colors duration-300 group-hover:text-[var(--color-accent)]">
                  {item.title}
                </h3>
                <p className="mt-2 flex-1 text-sm leading-6 text-[var(--color-muted)]">{item.body}</p>
                <span className="mt-5 inline-flex items-center gap-2 text-sm font-semibold text-[var(--color-accent)]">
                  Review
                  <ArrowRightIcon className="h-4 w-4 transition-transform duration-300 group-hover:translate-x-1" />
                </span>
              </Link>
            </Reveal>
          ))}
        </div>
      </section>
    </div>
  )
}
