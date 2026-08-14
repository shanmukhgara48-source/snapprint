import { PolicyLayout } from '../components/PolicyLayout'
import { Placeholder } from '../components/Placeholder'

export function Refund() {
  return (
    <PolicyLayout
      title="Cancellation and Refund Policy"
      lastUpdated={<Placeholder label="publish date" example="1 August 2026" />}
      intro="SnapPrint products are custom-printed from customer-provided photos. This policy explains when orders can be cancelled and how refunds are handled."
      sections={[
        {
          heading: '1. Custom-Printed Products',
          body: (
            <p>
              SnapPrint products are made to order using photos and selections submitted by the
              customer. Because the product is customised, cancellation and refund eligibility
              may be limited after production begins.
            </p>
          ),
        },
        {
          heading: '2. Order Cancellations',
          body: (
            <p>
              Orders may be cancelled within{' '}
              <Placeholder label="customer cancellation window" example="1 hour of order placement" />{' '}
              if production has not started. Once a product enters production, cancellation may
              no longer be available for that item.
            </p>
          ),
        },
        {
          heading: '3. Refund Eligibility',
          body: (
            <p>
              Refund requests may be considered if an eligible order is cancelled before
              production starts, if the product arrives damaged or defective, if the wrong product
              or size is delivered, or if an order cannot be fulfilled. Final eligibility should
              be assessed against the order record and supporting evidence.
            </p>
          ),
        },
        {
          heading: '4. Non-Refundable Cases',
          body: (
            <p>
              Refunds may not be available for issues caused by the uploaded photo, customer
              cropping or layout choices, low-resolution source images, spelling or text entered
              by the customer, or a change of mind after production has started.
            </p>
          ),
        },
        {
          heading: '5. How to Raise a Request',
          body: (
            <p>
              Contact <Placeholder label="support email" example="support@snapprint.in" /> within{' '}
              <Placeholder label="claim window" example="7 days of delivery" /> with your order
              ID, issue description, and photos of any damaged, defective, or incorrect product.
            </p>
          ),
        },
        {
          heading: '6. Refund Processing',
          body: (
            <p>
              Approved refunds are returned to the original payment method through Razorpay within{' '}
              <Placeholder label="refund processing timeline" example="5-7 business days after approval" />.
              Bank or payment-provider processing time may vary.
            </p>
          ),
        },
      ]}
    />
  )
}
