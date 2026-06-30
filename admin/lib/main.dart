import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/api_client.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/products/products_screen.dart';
import 'features/users/users_screen.dart';
import 'features/coupons/coupons_screen.dart';
import 'features/delivery_settings/delivery_settings_screen.dart';

void main() {
  runApp(const ProviderScope(child: AdminApp()));
}

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final token =
          await ref.read(adminApiClientProvider).getToken();
      final isLogin = state.matchedLocation == '/login';
      if (token == null && !isLogin) return '/login';
      if (token != null && isLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const AdminLoginScreen()),
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/products', builder: (context, state) => const ProductsScreen()),
      GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
      GoRoute(path: '/users', builder: (context, state) => const UsersScreen()),
      GoRoute(path: '/coupons', builder: (context, state) => const CouponsScreen()),
      GoRoute(path: '/delivery-settings', builder: (context, state) => const DeliverySettingsScreen()),
    ],
  );
});

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SnapPrint Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.light,
      routerConfig: ref.watch(_routerProvider),
    );
  }
}
