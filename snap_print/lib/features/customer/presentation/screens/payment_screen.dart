import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../providers/cart_provider.dart';
import '../providers/orders_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({
    super.key,
    required this.amount,
    required this.razorpayOrderId,
    required this.addressId,
    required this.deliveryType,
    required this.couponCode,
  });

  final double amount;
  final String razorpayOrderId;
  final String addressId;
  final String deliveryType;
  final String? couponCode;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;
  _PaymentCredentials? _successfulPayment;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _openRazorpay() {
    final user = ref.read(authProvider).valueOrNull;
    // Prefill phone so Razorpay skips the "Contact details" step
    final phone = user?.phone.replaceFirst('+91', '') ?? '9876543210';
    // The key is intentionally provided only at build time. Do not add a
    // fallback here; it risks shipping a test key inside production builds.
    // Test keys are fine in debug/profile builds (local dev, QA) — only
    // release builds must be rejected if they still carry a test key.
    const razorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID');
    final misconfigured =
        razorpayKeyId.isEmpty ||
        (kReleaseMode && razorpayKeyId.startsWith('rzp_test_'));
    if (misconfigured) {
      showErrorSnackbar(
        context,
        'Payment is not configured for this build. Please contact support.',
      );
      return;
    }

    setState(() => _isProcessing = true);
    final options = {
      'key': razorpayKeyId,
      'amount': (widget.amount * 100).toInt(),
      'order_id': widget.razorpayOrderId,
      'name': 'SnapPrint',
      'description': 'Photo products order',
      'prefill': {'contact': phone, 'email': 'customer@snapprint.in'},
      'theme': {'color': '#0B0B0B'},
    };
    try {
      _razorpay.open(options);
    } catch (_) {
      setState(() => _isProcessing = false);
      showErrorSnackbar(context, 'Could not open payment. Please try again.');
    }
  }

  void _handleSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    // Guard against incomplete Razorpay response
    if (response.paymentId == null || response.signature == null) {
      setState(() => _isProcessing = false);
      showErrorSnackbar(
        context,
        'Payment response incomplete. Please contact support.',
      );
      return;
    }
    _successfulPayment = _PaymentCredentials(
      paymentId: response.paymentId!,
      orderId: response.orderId ?? widget.razorpayOrderId,
      signature: response.signature!,
    );
    await _finalizeOrder();
  }

  Future<void> _finalizeOrder() async {
    final payment = _successfulPayment;
    if (payment == null) return;
    if (mounted) setState(() => _isProcessing = true);
    try {
      final ds = ref.read(customerDataSourceProvider);
      final cart = ref.read(cartProvider);

      // Step 1: Verify Razorpay signature
      await ds.verifyPayment({
        'razorpay_payment_id': payment.paymentId,
        'razorpay_order_id': payment.orderId,
        'razorpay_signature': payment.signature,
      });

      // Step 2: Create the actual order in our database
      final order = await ds.placeOrder({
        'items': cart.items
            .map(
              (item) => {
                'product_id': item.productId,
                'qty': item.quantity,
                'size': item.selectedSize,
                'image_url': item.customizationImageUrl,
                'price': item.unitPrice,
              },
            )
            .toList(),
        'address_id': widget.addressId,
        'delivery_type': widget.deliveryType,
        if (widget.couponCode != null) 'coupon_code': widget.couponCode,
        'razorpay_payment_id': payment.paymentId,
        'razorpay_order_id': payment.orderId,
        'razorpay_signature': payment.signature,
      });

      ref.read(cartProvider.notifier).clearCart();
      ref.invalidate(myOrdersProvider);

      if (mounted) {
        context.go(AppRoutes.orderConfirmationPath(order.id));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        showErrorSnackbar(
          context,
          'Payment received. Tap Complete order to finish securely.',
        );
      }
    }
  }

  void _handleError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    showErrorSnackbar(context, response.message ?? AppStrings.paymentFailed);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.payment)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),

            // Payment summary
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Secure Payment',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You will be charged',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₹${widget.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Secure checkout',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Supported payment methods
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: const [
                _PaymentBadge(label: 'UPI'),
                _PaymentBadge(label: 'Cards'),
                _PaymentBadge(label: 'Net Banking'),
                _PaymentBadge(label: 'Wallets'),
              ],
            ),
            const SizedBox(height: 24),

            CustomButton(
              label: _isProcessing
                  ? 'Processing...'
                  : _successfulPayment != null
                  ? 'Complete order'
                  : AppStrings.payNow,
              isLoading: _isProcessing,
              icon: Icons.payment_rounded,
              onPressed: _isProcessing
                  ? null
                  : _successfulPayment != null
                  ? _finalizeOrder
                  : _openRazorpay,
            ),
            const SizedBox(height: 12),
            Text(
              'Secured by Razorpay',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PaymentCredentials {
  const _PaymentCredentials({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });

  final String paymentId;
  final String orderId;
  final String signature;
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
