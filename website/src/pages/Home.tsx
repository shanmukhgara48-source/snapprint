import { Link } from 'react-router-dom'
import {
  categories,
  formatPrice,
  formatPriceRange,
  overallPriceRange,
  priceOnRequestCount,
  productCount,
} from '../data/products'
import { deliveryOptions, formatDeliveryPrice } from '../data/delivery'
import { Button } from '../components/Button'
import { Reveal } from '../components/Reveal'
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
  { to: '/shipping', title: 'Shipping policy', body: `${deliveryOptions.length} delivery options, including ${formatDeliveryPrice(deliveryOptions[0].price)} delivery.` },
  { to: '/privacy', title: 'Privacy policy', body: 'Covers photo storage, retention, and how your data is used.' },
  { to: '/refund', title: 'Refund policy', body: 'Cancellation window, claim period, and refund processing timeline.' },
]

function CategoryIcon({ icon, className = 'h-5 w-5' }: { icon: string; className?: string }) {
  if (icon === 'book') return <BookOpenIcon className={className} />
  if (icon === 'frame') return <FrameIcon className={className} />
  if (icon === 'gift') return <GiftIcon className={className} />
  return <CameraIcon className={className} />
}

function HeroGallery() {
  return (
    <div className="relative">
      <div className="image-vignette aspect-[5/4] overflow-hidden rounded-lg border border-white/10 bg-[var(--color-surface)] shadow-2xl sm:aspect-[6/5]">
        <img
          src="/og.jpg"
          alt="SnapPrint printed photos, photo album, framed print, and photo mug"
          loading="eager"
          decoding="async"
          className="h-full w-full object-cover object-[100%_50%]"
        />
        <div className="absolute inset-y-0 left-0 z-10 w-[24%] bg-gradient-to-r from-[#08080a] via-[#08080a]/92 to-transparent" />
        <div className="absolute right-4 bottom-4 left-4 z-20 rounded-lg border border-white/10 bg-black/55 p-4 backdrop-blur">
          <p className="text-sm font-extrabold text-white">Prints, albums, frames and gifts</p>
          <p className="mt-1 text-xs leading-5 text-white/72">
            A premium product surface for the same catalog customers see in SnapPrint.
          </p>
        </div>
      </div>
      <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
        {categories.map((category) => (
          <Link
            key={category.id}
            to="/products"
            className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] p-3 transition-colors hover:border-[var(--color-accent)]/60"
          >
            <p className="text-xs font-semibold text-[var(--color-muted-2)]">{category.name}</p>
            <p className="mt-1 text-sm font-extrabold text-[var(--color-accent)]">
              {formatPriceRange(category.priceRange)}
            </p>
          </Link>
        ))}
      </div>
      <div className="gold-rule mx-auto mt-5 h-px w-3/4" />
    </div>
  )
}

function MobileProductPreview() {
  return (
    <div className="image-vignette mt-8 aspect-[16/10] overflow-hidden rounded-lg border border-white/10 bg-[var(--color-surface)] lg:hidden">
      <img
        src="/og.jpg"
        alt="SnapPrint photo products"
        loading="eager"
        decoding="async"
        className="h-full w-full object-cover object-[100%_50%]"
      />
      <div className="absolute inset-y-0 left-0 z-10 w-[24%] bg-gradient-to-r from-[#08080a] via-[#08080a]/90 to-transparent" />
      <div className="absolute right-3 bottom-3 left-3 z-20 rounded-lg border border-white/10 bg-black/55 p-3 backdrop-blur">
        <p className="text-xs font-extrabold text-white">Prints, albums, frames and gifts</p>
      </div>
    </div>
  )
}

export function Home() {
  return (
    <div>
      <section className="ambient-glow overflow-hidden border-b border-[var(--color-border)]">
        <div className="mx-auto grid max-w-6xl items-center gap-12 px-6 py-16 sm:py-22 lg:grid-cols-[1.02fr_0.98fr] lg:py-28">
          <div>
            <span className="inline-flex items-center gap-2 rounded-full border border-[var(--color-border-strong)] bg-black/20 px-4 py-1.5 text-xs font-semibold tracking-wide text-[var(--color-accent)] uppercase">
              <SparkleIcon className="h-3.5 w-3.5" />
              Premium Indian photo printing
            </span>
            <h1 className="mt-6 max-w-3xl text-5xl leading-[1.03] font-extrabold tracking-tight text-balance sm:text-6xl lg:text-7xl">
              SnapPrint
              <span className="block text-gradient-gold">Print Your Memories.</span>
            </h1>
            <p className="mt-6 max-w-xl text-base leading-8 text-[var(--color-muted)] sm:text-lg">
              Order custom photo prints, photo books, frames, wall decor, and personalised gifts
              from a catalog grounded in the live SnapPrint backend.
            </p>
            <div className="mt-9 flex flex-col gap-3 sm:flex-row sm:items-center">
              <Button to="/products" variant="primary">
                Explore Catalog
                <ArrowRightIcon className="h-4 w-4" />
              </Button>
              <Button to="/pricing" variant="secondary">
                View Pricing
              </Button>
            </div>
            <MobileProductPreview />
            <div className="mt-10 grid gap-3 sm:grid-cols-3">
              {heroStats.map((stat) => (
                <div key={stat.label} className="rounded-lg border border-[var(--color-border)] bg-black/18 p-4">
                  <p className="text-2xl font-extrabold text-[var(--color-ink)]">{stat.value}</p>
                  <p className="mt-1 text-xs font-semibold tracking-wide text-[var(--color-muted-2)] uppercase">
                    {stat.label}
                  </p>
                </div>
              ))}
            </div>
            <div className="mt-8 flex flex-wrap gap-x-6 gap-y-3">
              {trustItems.map((item) => (
                <div key={item.label} className="flex items-center gap-2.5 text-sm text-[var(--color-muted)]">
                  <item.icon className="h-4.5 w-4.5 text-[var(--color-accent)]" />
                  {item.label}
                </div>
              ))}
            </div>
          </div>
          <div className="hidden lg:block">
            <HeroGallery />
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-6 py-16 sm:py-22">
        <Reveal className="max-w-2xl">
          <span className="text-xs font-semibold tracking-[0.2em] text-[var(--color-accent)] uppercase">
            Products and services
          </span>
          <h2 className="mt-3 text-3xl font-extrabold tracking-tight sm:text-4xl">
            A polished catalog for real photo-commerce orders
          </h2>
          <p className="mt-4 leading-7 text-[var(--color-muted)]">
            Browse {productCount} products across {categories.length} categories, priced from{' '}
            {formatPrice(overallPriceRange[0])} to {formatPrice(overallPriceRange[1])}.{' '}
            {priceOnRequestCount} items are clearly marked as price on request where the backend
            has no base price.
          </p>
        </Reveal>

        <div className="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {categories.map((category, index) => (
            <Reveal key={category.id} delay={index * 70}>
              <Link
                to="/products"
                className="group block h-full overflow-hidden rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] transition-all duration-300 hover:-translate-y-1 hover:border-[var(--color-accent)]/60 hover:shadow-[0_22px_60px_-34px_rgba(212,175,55,0.7)]"
              >
                <div className="image-vignette aspect-[5/3]">
                  <img
                    src={category.imageUrl}
                    alt={category.name}
                    loading="lazy"
                    decoding="async"
                    className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
                  />
                </div>
                <div className="p-5">
                  <div className="flex items-center justify-between gap-3">
                    <span className="flex h-10 w-10 items-center justify-center rounded-lg bg-[var(--color-accent-soft)] text-[var(--color-accent)]">
                      <CategoryIcon icon={category.icon} />
                    </span>
                    <span className="text-xs font-semibold text-[var(--color-muted-2)]">
                      {category.products.length} products
                    </span>
                  </div>
                  <h3 className="mt-4 font-bold text-[var(--color-ink)]">{category.name}</h3>
                  <p className="mt-2 text-sm leading-6 text-[var(--color-muted)]">{category.description}</p>
                  <p className="mt-4 text-sm font-extrabold text-[var(--color-accent)]">
                    {formatPriceRange(category.priceRange)}
                  </p>
                </div>
              </Link>
            </Reveal>
          ))}
        </div>
      </section>

      <section className="border-y border-[var(--color-border)] bg-[var(--color-bg-soft)]">
        <div className="mx-auto max-w-6xl px-6 py-16 sm:py-22">
          <Reveal className="max-w-2xl">
            <span className="text-xs font-semibold tracking-[0.2em] text-[var(--color-accent)] uppercase">
              How it works
            </span>
            <h2 className="mt-3 text-3xl font-extrabold tracking-tight sm:text-4xl">
              Simple enough for everyday prints, careful enough for heirlooms
            </h2>
          </Reveal>
          <div className="mt-10 grid gap-5 md:grid-cols-3">
            {steps.map((step, index) => (
              <Reveal key={step.title} delay={index * 80}>
                <div className="h-full rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] p-6">
                  <div className="flex items-center justify-between gap-4">
                    <span className="flex h-11 w-11 items-center justify-center rounded-lg bg-[var(--color-accent-soft)] text-[var(--color-accent)]">
                      <step.icon className="h-5 w-5" />
                    </span>
                    <span className="text-xs font-extrabold tracking-[0.2em] text-white/12">
                      0{index + 1}
                    </span>
                  </div>
                  <h3 className="mt-5 font-bold">{step.title}</h3>
                  <p className="mt-2 text-sm leading-6 text-[var(--color-muted)]">{step.body}</p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-6 py-16 sm:py-22">
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
                className="group flex h-full flex-col rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] p-6 transition-all duration-300 hover:-translate-y-1 hover:border-[var(--color-accent)]/60"
              >
                <h3 className="font-bold">{item.title}</h3>
                <p className="mt-2 flex-1 text-sm leading-6 text-[var(--color-muted)]">{item.body}</p>
                <span className="mt-5 inline-flex items-center gap-2 text-sm font-semibold text-[var(--color-accent)]">
                  Review <ArrowRightIcon className="h-4 w-4" />
                </span>
              </Link>
            </Reveal>
          ))}
        </div>
      </section>
    </div>
  )
}
