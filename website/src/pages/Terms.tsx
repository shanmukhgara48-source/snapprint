import { Link } from 'react-router-dom'
import { PolicyLayout } from '../components/PolicyLayout'
import { Placeholder } from '../components/Placeholder'

export function Terms() {
  return (
    <PolicyLayout
      title="Terms and Conditions"
      lastUpdated={<Placeholder label="publish date" example="1 August 2026" />}
      intro="These Terms and Conditions govern your use of the SnapPrint website and app, and any order you place with us."
      sections={[
        {
          heading: '1. About SnapPrint',
          body: (
            <p>
              SnapPrint is a photo-printing and personalised products service operated by{' '}
              <Placeholder label="legal entity name" example="SnapPrint Private Limited" />. In
              these Terms, "SnapPrint", "we", "us", and "our" refer to that business entity.
            </p>
          ),
        },
        {
          heading: '2. Use of the Website and App',
          body: (
            <p>
              By accessing the SnapPrint website, using the SnapPrint app, browsing products, or
              placing an order, you agree to these Terms. If you do not agree, please do not use
              the service or place an order.
            </p>
          ),
        },
        {
          heading: '3. Products and Custom Orders',
          body: (
            <p>
              SnapPrint offers custom photo products including photo prints, photo books, frames,
              wall decor, and personalised gifts. Products are made using photos, text, and other
              content submitted by the customer, so each order is customised to the submitted
              order details.
            </p>
          ),
        },
        {
          heading: '4. Customer Content',
          body: (
            <p>
              You retain ownership of photos and content you upload. By submitting content, you
              confirm that you have the right to use it for printing and grant SnapPrint a limited
              permission to use it only to create, process, fulfil, deliver, and support your
              order.
            </p>
          ),
        },
        {
          heading: '5. Pricing and Payments',
          body: (
            <p>
              Product base prices are listed in Indian Rupees. The final payable amount may vary
              based on size, finish, quantity, discount, delivery option, and checkout selections.
              Payments are processed through Razorpay. SnapPrint does not store card, UPI, or
              bank account details on its servers.
            </p>
          ),
        },
        {
          heading: '6. Shipping and Delivery',
          body: (
            <p>
              Delivery timelines and charges depend on the selected delivery option and delivery
              location. Please review the{' '}
              <Link to="/shipping" className="text-[var(--color-accent)] underline underline-offset-2">
                Shipping Policy
              </Link>{' '}
              before placing an order.
            </p>
          ),
        },
        {
          heading: '7. Cancellation and Refunds',
          body: (
            <p>
              Because SnapPrint products are custom-printed, cancellation and refund eligibility
              may be limited once production begins. Please review the{' '}
              <Link to="/refund" className="text-[var(--color-accent)] underline underline-offset-2">
                Cancellation and Refund Policy
              </Link>{' '}
              for the applicable conditions and timelines.
            </p>
          ),
        },
        {
          heading: '8. Prohibited Content',
          body: (
            <p>
              You must not upload content that is unlawful, abusive, infringing, or that you do
              not have permission to print. SnapPrint may refuse or cancel orders involving
              prohibited content or suspected misuse.
            </p>
          ),
        },
        {
          heading: '9. Limitation of Liability',
          body: (
            <p>
              To the extent permitted by applicable law, SnapPrint's liability for an order is
              limited to the amount paid for that order. Nothing in these Terms limits rights
              that cannot be excluded under applicable consumer protection law.
            </p>
          ),
        },
        {
          heading: '10. Governing Law',
          body: (
            <p>
              These Terms are governed by the laws of India. Courts at{' '}
              <Placeholder label="city / jurisdiction" example="Bengaluru, Karnataka" /> will
              have jurisdiction, subject to applicable law.
            </p>
          ),
        },
        {
          heading: '11. Contact',
          body: (
            <p>
              For questions about these Terms, contact{' '}
              <Placeholder label="support email" example="support@snapprint.in" /> or write to{' '}
              <Placeholder label="registered business address" />.
            </p>
          ),
        },
      ]}
    />
  )
}
