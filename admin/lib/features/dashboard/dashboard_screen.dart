import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

final _dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.read(adminApiClientProvider);
  final orders = await client.dio.get('/admin/orders');
  final users = await client.dio.get('/admin/users');
  final allOrders = orders.data as List<dynamic>;
  final allUsers = users.data as List<dynamic>;
  final revenue = allOrders.fold<double>(
    0,
    (sum, o) => sum + ((o['total_price'] as num?)?.toDouble() ?? 0),
  );
  return {
    'total_orders': allOrders.length,
    'total_users': allUsers.length,
    'revenue': revenue,
    'pending': allOrders.where((o) => o['status'] == 'pending').length,
    'delivered': allOrders.where((o) => o['status'] == 'delivered').length,
  };
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Logout', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              await ref.read(adminApiClientProvider).clearToken();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: statsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AdminTheme.primary)),
        error: (e, s) => Center(child: Text('$e')),
        data: (stats) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overview',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(
                      title: 'Total Orders',
                      value: '${stats['total_orders']}',
                      icon: Icons.receipt_long_rounded,
                      color: AdminTheme.primary),
                  _StatCard(
                      title: 'Total Users',
                      value: '${stats['total_users']}',
                      icon: Icons.people_rounded,
                      color: Colors.blue),
                  _StatCard(
                      title: 'Revenue',
                      value: '₹${(stats['revenue'] as double).toStringAsFixed(0)}',
                      icon: Icons.currency_rupee_rounded,
                      color: Colors.purple),
                  _StatCard(
                      title: 'Pending',
                      value: '${stats['pending']}',
                      icon: Icons.pending_rounded,
                      color: Colors.orange),
                  _StatCard(
                      title: 'Delivered',
                      value: '${stats['delivered']}',
                      icon: Icons.check_circle_rounded,
                      color: Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 180,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(value,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: color)),
              const SizedBox(height: 4),
              Text(title,
                  style: const TextStyle(
                      color: AdminTheme.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminDrawer extends StatelessWidget {
  const AdminDrawer();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AdminTheme.primary),
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 36),
                SizedBox(width: 12),
                Text('SnapPrint Admin',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          _DrawerItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              route: '/dashboard',
              selected: location == '/dashboard'),
          _DrawerItem(
              icon: Icons.inventory_2_rounded,
              label: 'Products',
              route: '/products',
              selected: location == '/products'),
          _DrawerItem(
              icon: Icons.receipt_long_rounded,
              label: 'Orders',
              route: '/orders',
              selected: location == '/orders'),
          _DrawerItem(
              icon: Icons.people_rounded,
              label: 'Users',
              route: '/users',
              selected: location == '/users'),
          _DrawerItem(
              icon: Icons.local_offer_rounded,
              label: 'Coupons',
              route: '/coupons',
              selected: location == '/coupons'),
          _DrawerItem(
              icon: Icons.local_shipping_rounded,
              label: 'Delivery Settings',
              route: '/delivery-settings',
              selected: location == '/delivery-settings'),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.selected,
  });
  final IconData icon;
  final String label;
  final String route;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: selected ? AdminTheme.primary : AdminTheme.textSecondary),
      title: Text(label,
          style: TextStyle(
              color: selected ? AdminTheme.primary : null,
              fontWeight: selected ? FontWeight.w700 : null)),
      selected: selected,
      selectedTileColor: const Color(0xFFC8E6C9),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}
