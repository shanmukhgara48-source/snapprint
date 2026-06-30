import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../dashboard/dashboard_screen.dart' show AdminDrawer;

final _ordersProvider = FutureProvider<List<dynamic>>((ref) async {
  final client = ref.read(adminApiClientProvider);
  final response = await client.dio.get('/admin/orders');
  return response.data as List<dynamic>;
});

final _deliveryPartnersProvider = FutureProvider<List<dynamic>>((ref) async {
  final client = ref.read(adminApiClientProvider);
  final response = await client.dio.get('/admin/delivery-partners');
  return response.data as List<dynamic>;
});

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(_ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      drawer: const AdminDrawer(),
      body: ordersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AdminTheme.primary)),
        error: (e, s) => Center(child: Text('$e')),
        data: (orders) => Padding(
          padding: const EdgeInsets.all(16),
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            columns: const [
              DataColumn2(label: Text('Order ID'), size: ColumnSize.M),
              DataColumn2(label: Text('Customer'), size: ColumnSize.M),
              DataColumn2(label: Text('Status'), size: ColumnSize.M),
              DataColumn2(label: Text('Total'), size: ColumnSize.S),
              DataColumn2(label: Text('Date'), size: ColumnSize.M),
              DataColumn2(label: Text('Assign'), size: ColumnSize.M),
            ],
            rows: orders.map<DataRow>((o) {
              final createdAt = o['created_at'] != null
                  ? DateTime.tryParse(o['created_at'] as String)
                  : null;
              return DataRow(cells: [
                DataCell(Text(
                    (o['id'] as String? ?? '').substring(0, 8).toUpperCase())),
                DataCell(Text(o['customer_phone'] as String? ?? '—')),
                DataCell(_StatusBadge(status: o['status'] as String? ?? '')),
                DataCell(Text(
                    '₹${(o['total_price'] as num?)?.toStringAsFixed(0) ?? '0'}')),
                DataCell(Text(createdAt != null
                    ? DateFormat('dd MMM yy').format(createdAt)
                    : '—')),
                DataCell(
                  o['delivery_partner_id'] == null
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.primary,
                            minimumSize: const Size(80, 32),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () => _assignDelivery(
                              context, ref, o['id'] as String),
                          child: const Text('Assign'),
                        )
                      : const Text('Assigned',
                          style: TextStyle(
                              color: AdminTheme.primary,
                              fontWeight: FontWeight.w600)),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _assignDelivery(
      BuildContext context, WidgetRef ref, String orderId) async {
    final partners = ref.read(_deliveryPartnersProvider).valueOrNull ?? [];
    if (partners.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No delivery partners available')),
      );
      return;
    }

    String? selectedId;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Delivery Partner'),
        content: DropdownButtonFormField<String>(
          decoration:
              const InputDecoration(labelText: 'Select Partner'),
          items: partners
              .map<DropdownMenuItem<String>>(
                (p) => DropdownMenuItem(
                  value: p['id'] as String,
                  child: Text(p['phone'] as String? ?? p['id'] as String),
                ),
              )
              .toList(),
          onChanged: (v) => selectedId = v,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (selectedId != null) {
                await ref.read(adminApiClientProvider).dio.post(
                  '/admin/orders/$orderId/assign',
                  data: {'delivery_partner_id': selectedId},
                );
                ref.invalidate(_ordersProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  Color get _color {
    switch (status) {
      case 'delivered':
        return AdminTheme.primary;
      case 'out_for_delivery':
        return Colors.green;
      case 'failed':
        return AdminTheme.error;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style:
            TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
