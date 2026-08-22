import { Link } from 'react-router-dom'
import {
  catalogProducts,
  categories,
  formatPrice,
  formatPriceRange,
  overallPriceRange,
  priceOnRequestCount,
  productCount,
} from '../data/products'
import { deliveryOptions, formatDeliveryPrice } from '../data/delivery'
import { Reveal } from '../components/Reveal'
import { handleSpotlight } from '../lib/spotlight'
import { ClockIcon, ReceiptIcon, ShieldCheckIcon, TruckIcon } from '../components/Icons'

const paymentTrust = [
  {
    icon: ShieldCheckIcon,
    title: 'Secured by Razorpay',
    body: 'Payments are processed by Razorpay. SnapPrint does not store card, UPI, or bank account details.',
  },
  {
    icon: TruckIcon,
    title: 'Delivery shown separately',
    body: `Current delivery options range from ${formatDeliveryPrice(deliveryOptions[0].price)} to ${formatDeliveryPrice(deliveryOptions[2].price)}.`,
  },
  {
    icon: ClockIcon,
    title: 'Final total at checkout',
    body: 'Size, finish, quantity, discounts, and delivery are confirmed in the app before payment.',
  },
]

export function Pricing() {
  return (
    <div>
      <section className="ambient-glow border-b border-[var(--color-border)] px-6 py-16 sm:py-24">
        <div className="mx-auto max-w-6xl">
          <span className="text-xs font-semibold tracking-[0.2em] text-[var(--color-accent)] uppercase">
            Pricing
          </span>
          <div className="mt-4 grid gap-8 lg:grid-cols-[1fr_360px] lg:items-end">
            <div>
              <h1 className="font-display text-4xl font-semibold tracking-normal text-balance sm:text-6xl">
                Transparent product pricing
              </h1>
              <p className="mt-4 max-w-2xl leading-7 text-[var(--color-muted)]">
                Base prices are listed in Indian Rupees and sourced from the backend seed catalog.
                Prices run from {formatPrice(overallPriceRange[0])} to{' '}
                {formatPrice(overallPriceRange[1])}. Shipping and final customisation totals are
                calculated separately at checkout.
              </p>
            </div>
            <div className="rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] p-5">
              <p className="flex items-center gap-2 text-sm font-semibold text-[var(--color-accent)]">
                <ReceiptIcon className="h-4 w-4" />
                Review-ready price list
              </p>
              <p className="mt-3 text-3xl font-extrabold">{productCount}</p>
              <p className="mt-1 text-sm leading-6 text-[var(--color-muted)]">
                products listed. {priceOnRequestCount} products are marked as price on request
                and are quoted individually based on customisation.
              </p>
            </div>
          </div>
        </div>
      </section>

      <div className="mx-auto max-w-6xl px-6 py-16 sm:py-24">
        <div className="grid gap-5 md:grid-cols-2 lg:grid-cols-4">
          {categories.map((category, index) => (
            <Reveal key={category.id} delay={index * 70}>
              <div
                onMouseMove={handleSpotlight}
                className="spotlight h-full overflow-hidden rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] p-6 transition-all duration-500 ease-[cubic-bezier(0.16,1,0.3,1)] hover:-translate-y-1 hover:border-[var(--color-accent)]/50"
              >
                <p className="text-xs font-semibold tracking-wide text-[var(--color-muted-2)] uppercase">
                  {category.products.length} products
                </p>
                <h2 className="font-display mt-2 text-lg font-semibold">{category.name}</h2>
                <p className="mt-3 text-sm leading-6 text-[var(--color-muted)]">{category.description}</p>
                <div className="mt-5 border-t border-[var(--color-border)] pt-5">
                  <p className="text-xs font-semibold tracking-wide text-[var(--color-muted-2)] uppercase">
                    Base price range
                  </p>
                  <p className="mt-1 text-xl font-extrabold text-[var(--color-accent)]">
                    {formatPriceRange(category.priceRange)}
                  </p>
                  {category.hasPriceOnRequest && (
                    <p className="mt-2 text-xs text-[var(--color-muted-2)]">
                      Includes price-on-request items.
                    </p>
                  )}
                </div>
              </div>
            </Reveal>
          ))}
        </div>

        <Reveal className="mt-12">
          <div className="flex flex-wrap items-end justify-between gap-4">
            <div>
              <span className="text-xs font-semibold tracking-[0.2em] text-[var(--color-accent)] uppercase">
                Full price list
              </span>
              <h2 className="font-display mt-2 text-2xl font-semibold tracking-normal sm:text-3xl">
                Product base prices
              </h2>
            </div>
            <p className="max-w-md text-sm leading-6 text-[var(--color-muted)]">
              Base price is the starting price. Exact line-item totals depend on selected
              size, finish, quantity, discounts, and delivery.
            </p>
          </div>
          <div className="mt-6 overflow-x-auto rounded-xl border border-[var(--color-border)]">
            <table className="w-full min-w-[760px] border-collapse text-left text-sm">
              <thead>
                <tr className="sticky top-[64px] border-b border-[var(--color-border)] bg-[var(--color-surface)]/95 text-[var(--color-ink)] backdrop-blur">
                  <th className="py-4 pr-4 pl-5 font-semibold">Product</th>
                  <th className="py-4 pr-4 font-semibold">Category</th>
                  <th className="py-4 pr-4 font-semibold">Representative sizes</th>
                  <th className="py-4 pr-5 text-right font-semibold">Base price</th>
                </tr>
              </thead>
              <tbody>
                {catalogProducts.map((product) => (
                  <tr
                    key={product.id}
                    className="border-b border-[var(--color-border)] bg-[var(--color-bg)]/28 transition-colors last:border-0 hover:bg-[var(--color-accent-soft)]"
                  >
                    <td className="py-4 pr-4 pl-5 font-semibold text-[var(--color-ink)]">{product.name}</td>
                    <td className="py-4 pr-4 text-[var(--color-muted)]">{product.categoryName}</td>
                    <td className="max-w-sm py-4 pr-4 text-[var(--color-muted)]">
                      {product.sizes.slice(0, 3).join(', ')}
                      {product.sizes.length > 3 ? `, +${product.sizes.length - 3} more` : ''}
                    </td>
                    <td className="py-4 pr-5 text-right font-extrabold text-[var(--color-accent)]">
                      {formatPrice(product.basePrice)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Reveal>

        <Reveal className="mt-12">
          <div className="grid gap-5 md:grid-cols-3">
            {paymentTrust.map((item) => (
              <div
                key={item.title}
                onMouseMove={handleSpotlight}
                className="spotlight overflow-hidden rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] p-6 transition-all duration-500 ease-[cubic-bezier(0.16,1,0.3,1)] hover:-translate-y-1 hover:border-[var(--color-accent)]/50"
              >
                <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-[var(--color-accent-soft)] text-[var(--color-accent)]">
                  <item.icon className="h-5 w-5" />
                </span>
                <p className="mt-4 font-bold">{item.title}</p>
                <p className="mt-2 text-sm leading-6 text-[var(--color-muted)]">{item.body}</p>
              </div>
            ))}
          </div>
          <p className="mt-6 text-sm leading-6 text-[var(--color-muted)]">
            See the <Link to="/shipping" className="text-[var(--color-accent)] underline underline-offset-2">Shipping Policy</Link>{' '}
            and <Link to="/refund" className="text-[var(--color-accent)] underline underline-offset-2">Cancellation and Refund Policy</Link>{' '}
            for delivery and refund terms.
          </p>
        </Reveal>
      </div>
    </div>
  )
}
