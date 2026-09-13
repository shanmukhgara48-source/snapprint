import { deliveryOptions, formatDeliveryPrice, sameDayDeliveryNote } from '../data/delivery'
import { PolicyLayout } from '../components/PolicyLayout'
import { BusinessValue } from '../components/BusinessValue'
import { Seo } from '../components/Seo'

export function Shipping() {
  return (
    <>
    <Seo
      title="Shipping Policy | SnapPrint"
      description="SnapPrint delivery options, timelines and charges."
      path="/shipping"
    />
    <PolicyLayout
      title="Shipping Policy"
      lastUpdated={<BusinessValue field="policyLastUpdated" fallback="Last reviewed: pending owner confirmation" />}
      intro="This policy explains delivery options, timelines, and charges for SnapPrint orders."
      sections={[
        {
          heading: '1. Delivery Options',
          body: (
            <div>
              <div className="grid gap-3">
                {deliveryOptions.map((option) => (
                  <div
                    key={option.type}
                    className="grid gap-3 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg)]/35 p-4 transition-colors duration-300 hover:border-[var(--color-accent)]/40 sm:grid-cols-[1fr_1fr_auto] sm:items-center"
                  >
                    <div>
                      <p className="text-xs font-semibold tracking-wide text-[var(--color-muted-2)] uppercase">
                        Delivery option
                      </p>
                      <p className="mt-1 font-semibold text-[var(--color-ink)]">{option.label}</p>
                    </div>
                    <div>
                      <p className="text-xs font-semibold tracking-wide text-[var(--color-muted-2)] uppercase">
                        Estimated time
                      </p>
                      <p className="mt-1">{option.daysLabel}</p>
                    </div>
                    <div>
                      <p className="text-xs font-semibold tracking-wide text-[var(--color-muted-2)] uppercase">
                        Charge
                      </p>
                      <p className="mt-1 font-extrabold text-[var(--color-accent)]">
                        {formatDeliveryPrice(option.price)}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
              <p className="mt-4 text-sm leading-6">{sameDayDeliveryNote}</p>
            </div>
          ),
        },
        {
          heading: '2. Delivery Coverage',
          body: (
            <p>
              SnapPrint supports nationwide delivery for standard orders. Same-day delivery is
              listed for select products in Bengaluru, Hyderabad, NCR, and Chennai subject to the
              order cut-off noted above.
            </p>
          ),
        },
        {
          heading: '3. Order Processing',
          body: (
            <p>
              Products enter production after payment confirmation and order validation. Custom
              products, photo books, bulk products, and price-on-request products may require
              additional coordination before dispatch.
            </p>
          ),
        },
        {
          heading: '4. Tracking',
          body: (
            <p>
              Customers can track status in the SnapPrint app as the order moves through
              processing, printed, out for delivery, and delivered stages. Push notifications may
              be sent for order status updates.
            </p>
          ),
        },
        {
          heading: '5. Delivery Issues',
          body: (
            <p>
              If a shipment is delayed, damaged, incorrectly delivered, or not delivered, contact{' '}
              <BusinessValue field="supportEmail" /> with the
              order ID and relevant photos or details so the issue can be investigated.
            </p>
          ),
        },
      ]}
    />
    </>
  )
}
