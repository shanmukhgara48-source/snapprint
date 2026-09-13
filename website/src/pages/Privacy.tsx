import { PolicyLayout } from '../components/PolicyLayout'
import { BusinessValue } from '../components/BusinessValue'
import { Seo } from '../components/Seo'

export function Privacy() {
  return (
    <>
    <Seo
      title="Privacy Policy | SnapPrint"
      description="How SnapPrint collects, uses and protects your information."
      path="/privacy"
    />
    <PolicyLayout
      title="Privacy Policy"
      lastUpdated={<BusinessValue field="policyLastUpdated" fallback="Last reviewed: pending owner confirmation" />}
      intro="This Privacy Policy explains what information SnapPrint collects, how it is used, and the choices you have. It applies to the SnapPrint website and app."
      sections={[
        {
          heading: '1. Information We Collect',
          body: (
            <p>
              We collect the following information when you use SnapPrint: phone number for
              account creation and OTP verification; optional name for personalisation; delivery
              address to fulfil orders; photos you upload for printing; order history to show
              past orders and resolve issues; and device token to send order status
              notifications.
            </p>
          ),
        },
        {
          heading: '2. How We Use Your Information',
          body: (
            <p>
              We use your information to process and deliver photo print orders, send order
              status updates through push notifications, provide customer support, and improve
              our app and services. We do not sell your personal information to third parties.
            </p>
          ),
        },
        {
          heading: '3. Photos You Upload',
          body: (
            <p>
              Photos you upload are stored securely in Cloudflare R2 and are used solely to print
              and deliver your order. Photos are not shared with any third party other than our
              printing partner. We retain photos for 30 days after order delivery, after which
              they are permanently deleted.
            </p>
          ),
        },
        {
          heading: '4. Data Sharing',
          body: (
            <p>
              We share information only with our printing and delivery partners for order
              fulfilment; Firebase (Google) for authentication and push notifications; and
              Razorpay for payment processing. We do not store card details. All partners are
              bound by data processing agreements.
            </p>
          ),
        },
        {
          heading: '5. Data Retention',
          body: (
            <p>
              We retain account data for as long as your account is active. You can delete your
              account at any time from the Account page (My Account → Danger zone) after signing
              in. On deletion, personal identifiers are removed and paid order records are
              anonymised within 30 days. Orders that are still active must be completed or
              cancelled first.
            </p>
          ),
        },
        {
          heading: '6. Your Rights',
          body: (
            <p>
              You have the right to access the personal data we hold about you, request
              correction of inaccurate data, delete your account and associated data, and
              withdraw consent for push notifications at any time. To exercise these rights, use
              the in-app controls or contact us at{' '}
              <BusinessValue field="privacyEmail" />.
            </p>
          ),
        },
        {
          heading: '7. Security',
          body: (
            <p>
              We use industry-standard security measures including HTTPS, Firebase
              Authentication, and encrypted storage. We never store payment card details on our
              servers.
            </p>
          ),
        },
        {
          heading: '8. Children',
          body: (
            <p>
              SnapPrint is not directed at children under 13. We do not knowingly collect
              personal data from children.
            </p>
          ),
        },
        {
          heading: '9. Contact Us',
          body: (
            <p>
              For privacy questions or to exercise your data rights, email{' '}
              <BusinessValue field="privacyEmail" />{' '}
              or write to <BusinessValue field="registeredAddress" />.
            </p>
          ),
        },
      ]}
    />
    </>
  )
}
