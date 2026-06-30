import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _PolicyContent(),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent();

  @override
  Widget build(BuildContext context) {
    const headingStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
    const bodyStyle = TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF444444));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Privacy Policy', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        const Text('Last updated: June 2025', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
        const SizedBox(height: 20),

        const Text('1. Information We Collect', style: headingStyle),
        const SizedBox(height: 8),
        const Text(
          'We collect the following information when you use SnapPrint:\n'
          '• Phone number (for account creation and OTP verification)\n'
          '• Name (optional, for personalisation)\n'
          '• Delivery address (to fulfil your orders)\n'
          '• Photos you upload for printing (processed and stored securely)\n'
          '• Order history (to show you past orders and resolve issues)\n'
          '• Device token (to send you order status notifications)',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        const Text('2. How We Use Your Information', style: headingStyle),
        const SizedBox(height: 8),
        const Text(
          'We use your information to:\n'
          '• Process and deliver your photo print orders\n'
          '• Send order status updates via push notifications\n'
          '• Provide customer support\n'
          '• Improve our app and services\n\n'
          'We do not sell your personal information to third parties.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        const Text('3. Photos You Upload', style: headingStyle),
        const SizedBox(height: 8),
        const Text(
          'Photos you upload are stored securely in Cloudflare R2 and are used '
          'solely to print and deliver your order. Photos are not shared with '
          'any third party other than our printing partner. We retain photos for '
          '30 days after order delivery, after which they are permanently deleted.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        const Text('4. Data Sharing', style: headingStyle),
        const SizedBox(height: 8),
        const Text(
          'We share your information only with:\n'
          '• Our printing and delivery partners (name, address, and photos required to fulfil orders)\n'
          '• Firebase (Google) for authentication and push notifications\n'
          '• Razorpay for payment processing (we do not store card details)\n\n'
          'All partners are bound by data processing agreements.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        const Text('5. Data Retention', style: headingStyle),
        const SizedBox(height: 8),
        const Text(
          'We retain your account data for as long as your account is active. '
          'You can delete your account at any time from the Profile screen. '
          'On deletion, all personal data and order history are permanently removed '
          'within 30 days.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        const Text('6. Your Rights', style: headingStyle),
        const SizedBox(height: 8),
        const Text(
          'You have the right to:\n'
          '• Access the personal data we hold about you\n'
          '• Request correction of inaccurate data\n'
          '• Delete your account and all associated data\n'
          '• Withdraw consent for push notifications at any time\n\n'
          'To exercise these rights, use the in-app controls or contact us at '
          'privacy@snapprint.in',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        const Text('7. Security', style: headingStyle),
        const SizedBox(height: 8),
        const Text(
          'We use industry-standard security measures including HTTPS, Firebase '
          'Authentication, and encrypted storage. We never store payment card '
          'details on our servers.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        const Text('8. Children', style: headingStyle),
        const SizedBox(height: 8),
        const Text(
          'SnapPrint is not directed at children under 13. We do not knowingly '
          'collect personal data from children.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),

        const Text('9. Contact Us', style: headingStyle),
        const SizedBox(height: 8),
        const Text(
          'For privacy questions or to exercise your data rights:\n'
          'Email: privacy@snapprint.in\n'
          'Address: SnapPrint, India',
          style: bodyStyle,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
