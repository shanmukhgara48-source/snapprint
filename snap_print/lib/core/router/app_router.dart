import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/auth_success_screen.dart';
import '../../features/customer/presentation/screens/customer_home_screen.dart';
import '../../features/customer/presentation/screens/product_list_screen.dart';
import '../../features/customer/presentation/screens/product_detail_screen.dart';
import '../../features/customer/presentation/screens/customization_screen.dart';
import '../../features/customer/presentation/screens/cart_screen.dart';
import '../../features/customer/presentation/screens/address_screen.dart';
import '../../features/customer/presentation/screens/checkout_screen.dart';
import '../../features/customer/presentation/screens/payment_screen.dart';
import '../../features/customer/presentation/screens/order_confirmation_screen.dart';
import '../../features/customer/presentation/screens/order_history_screen.dart';
import '../../features/customer/presentation/screens/profile_screen.dart';
import '../../features/ai_editor/presentation/screens/ai_photo_editor_screen.dart';
import '../../features/delivery/presentation/screens/delivery_home_screen.dart';
import '../../features/delivery/presentation/screens/delivery_order_detail_screen.dart';
import '../../features/delivery/presentation/screens/delivery_proof_screen.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../features/shared/screens/privacy_policy_screen.dart';
import '../../features/shared/widgets/customer_shell.dart';
import '../../features/shared/widgets/delivery_shell.dart';
import '../../features/admin/seed_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const otp = '/otp';
  static const profileSetup = '/profile-setup';
  // keep 'register' as alias so any existing pushes don't break
  static const register = '/profile-setup';
  static const customerHome = '/customer';
  static const productList = '/customer/products/:category';
  static const productDetail = '/customer/product/:id';
  static const customize = '/customer/customize';
  static const aiPhotoEditor = '/customer/ai-photo-editor';
  static const cart = '/customer/cart';
  static const address = '/customer/address';
  static const checkout = '/customer/checkout';
  static const payment = '/customer/payment';
  static const orderConfirmation = '/customer/order-confirmation/:id';
  static const orderHistory = '/customer/orders';
  static const profile = '/customer/profile';
  static const deliveryHome = '/delivery';
  static const deliveryOrderDetail = '/delivery/order/:id';
  static const deliveryProof = '/delivery/proof/:id';
  static const authSuccess = '/auth-success';
  static const seed = '/seed';
  static const privacyPolicy = '/privacy-policy';

  static String productListPath(String category) =>
      '/customer/products/${Uri.encodeComponent(category)}';
  static String productDetailPath(String id) => '/customer/product/$id';
  static String orderConfirmationPath(String id) =>
      '/customer/order-confirmation/$id';
  static String deliveryOrderDetailPath(String id) => '/delivery/order/$id';
  static String deliveryProofPath(String id) => '/delivery/proof/$id';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  // Notify GoRouter whenever auth state changes (including initial build completing)
  ref.listen(authProvider, (prev, next) => authNotifier.notifyListeners());

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;

      return authState.when(
        loading: () => null,
        error: (err, stack) => AppRoutes.login,
        data: (user) {
          final isSplash = location == AppRoutes.splash;
          final isAuthRoute =
              location == AppRoutes.login ||
              location == AppRoutes.otp ||
              location == AppRoutes.profileSetup;

          // Always leave splash once auth state is known
          if (isSplash) {
            if (user == null) return AppRoutes.login;
            return user.role == 'delivery'
                ? AppRoutes.deliveryHome
                : AppRoutes.customerHome;
          }

          if (location == AppRoutes.privacyPolicy) return null;
          if (location == AppRoutes.seed) {
            if (!kDebugMode) return AppRoutes.login;
            return null;
          }

          // Success screen: redirect here after first-time verification
          if (user != null && ref.read(authProvider.notifier).verifiedJustNow) {
            ref.read(authProvider.notifier).acknowledgeVerification();
            return AppRoutes.authSuccess;
          }
          // Let the success screen show without further redirecting
          if (location == AppRoutes.authSuccess) return null;

          if (user == null) return isAuthRoute ? null : AppRoutes.login;

          if (isAuthRoute) {
            return user.role == 'delivery'
                ? AppRoutes.deliveryHome
                : AppRoutes.customerHome;
          }

          if (user.role == 'delivery' && location.startsWith('/customer')) {
            return AppRoutes.deliveryHome;
          }
          if (user.role == 'customer' && location.startsWith('/delivery')) {
            return AppRoutes.customerHome;
          }

          return null;
        },
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OtpScreen(
            phone: extra['phone'] as String,
            verificationId: extra['verificationId'] as String,
            registrationName: extra['registrationName'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.authSuccess,
        builder: (context, state) => const AuthSuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return RegisterScreen(phone: extra['phone'] as String);
        },
      ),

      // Customer shell (bottom nav)
      ShellRoute(
        builder: (context, state, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.customerHome,
            builder: (context, state) => const CustomerHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.cart,
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: AppRoutes.orderHistory,
            builder: (context, state) => const OrderHistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Customer standalone routes
      GoRoute(
        path: AppRoutes.productList,
        builder: (context, state) =>
            ProductListScreen(category: state.pathParameters['category']!),
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.customize,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CustomizationScreen(
            productId: extra['productId'] as String,
            productName: extra['productName'] as String,
            preselectedSize: extra['preselectedSize'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.aiPhotoEditor,
        builder: (context, state) {
          final extra = state.extra as AiPhotoEditorArgs;
          return AiPhotoEditorScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.address,
        builder: (context, state) => const AddressScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.payment,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PaymentScreen(
            amount: extra['amount'] as double,
            razorpayOrderId: extra['razorpayOrderId'] as String,
            addressId: extra['addressId'] as String,
            deliveryType: extra['deliveryType'] as String,
            couponCode: extra['couponCode'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.orderConfirmation,
        builder: (context, state) =>
            OrderConfirmationScreen(orderId: state.pathParameters['id']!),
      ),

      // Delivery shell
      ShellRoute(
        builder: (context, state, child) => DeliveryShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.deliveryHome,
            builder: (context, state) => const DeliveryHomeScreen(),
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),

      // Admin / dev tools — only accessible in debug builds
      if (kDebugMode)
        GoRoute(
          path: AppRoutes.seed,
          builder: (context, state) => const SeedScreen(),
        ),

      // Delivery standalone routes
      GoRoute(
        path: AppRoutes.deliveryOrderDetail,
        builder: (context, state) =>
            DeliveryOrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.deliveryProof,
        builder: (context, state) =>
            DeliveryProofScreen(orderId: state.pathParameters['id']!),
      ),
    ],
  );
});
