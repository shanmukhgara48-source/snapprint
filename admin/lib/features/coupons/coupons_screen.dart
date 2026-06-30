import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../dashboard/dashboard_screen.dart' show AdminDrawer;

final _couponsProvider = FutureProvider<List<dynamic>>((ref) async {
  final client = ref.read(adminApiClientProvider);
  final response = await client.dio.get('/admin/coupons');
  return response.data as List<dynamic>;
});

class CouponsScreen extends ConsumerWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(_couponsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Coupons')),
      drawer: const AdminDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCouponForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Coupon'),
        backgroundColor: AdminTheme.primary,
      ),
      body: couponsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AdminTheme.primary)),
        error: (e, s) => Center(child: Text('$e')),
        data: (coupons) => Padding(
          padding: const EdgeInsets.all(16),
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            columns: const [
              DataColumn2(label: Text('Code'), size: ColumnSize.M),
              DataColumn2(label: Text('Type'), size: ColumnSize.S),
              DataColumn2(label: Text('Value'), size: ColumnSize.S),
              DataColumn2(label: Text('Min Order'), size: ColumnSize.S),
              DataColumn2(label: Text('Expires'), size: ColumnSize.M),
              DataColumn2(label: Text('Actions'), size: ColumnSize.S),
            ],
            rows: coupons.map<DataRow>((c) {
              final expiresAt = c['expires_at'] != null
                  ? DateTime.tryParse(c['expires_at'] as String)
                  : null;
              final isPercent = c['discount_type'] == 'percent';
              return DataRow(cells: [
                DataCell(Text(
                  c['code'] as String? ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      fontSize: 13),
                )),
                DataCell(Text(isPercent ? '%' : '₹')),
                DataCell(Text(isPercent
                    ? '${c['value']}%'
                    : '₹${(c['value'] as num?)?.toStringAsFixed(0) ?? '0'}')),
                DataCell(Text(
                    '₹${(c['min_order'] as num?)?.toStringAsFixed(0) ?? '0'}')),
                DataCell(Text(expiresAt != null
                    ? DateFormat('dd MMM yy').format(expiresAt)
                    : 'No expiry')),
                DataCell(IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AdminTheme.error),
                  onPressed: () =>
                      _deleteCoupon(context, ref, c['id'] as String),
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCoupon(
      BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: const Text('Are you sure you want to delete this coupon?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(adminApiClientProvider).dio.delete('/admin/coupons/$id');
      ref.invalidate(_couponsProvider);
    }
  }

  void _showCouponForm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _CouponFormDialog(ref: ref),
    );
  }
}

class _CouponFormDialog extends StatefulWidget {
  const _CouponFormDialog({required this.ref});
  final WidgetRef ref;

  @override
  State<_CouponFormDialog> createState() => _CouponFormDialogState();
}

class _CouponFormDialogState extends State<_CouponFormDialog> {
  final _codeCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _minOrderCtrl = TextEditingController();
  final _expiresCtrl = TextEditingController();
  String _discountType = 'percent';
  bool _isSaving = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    _minOrderCtrl.dispose();
    _expiresCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final data = {
      'code': _codeCtrl.text.toUpperCase().trim(),
      'discount_type': _discountType,
      'value': double.tryParse(_valueCtrl.text) ?? 0,
      'min_order': double.tryParse(_minOrderCtrl.text) ?? 0,
      if (_expiresCtrl.text.isNotEmpty) 'expires_at': _expiresCtrl.text,
    };
    await widget.ref.read(adminApiClientProvider).dio.post('/admin/coupons', data: data);
    widget.ref.invalidate(_couponsProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Coupon'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Code (e.g. SAVE20)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Type: '),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Percent (%)'),
                  selected: _discountType == 'percent',
                  onSelected: (_) => setState(() => _discountType = 'percent'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Flat (₹)'),
                  selected: _discountType == 'flat',
                  onSelected: (_) => setState(() => _discountType = 'flat'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valueCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _discountType == 'percent'
                    ? 'Discount (%)'
                    : 'Discount Amount (₹)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _minOrderCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Minimum Order Amount (₹)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _expiresCtrl,
              decoration: const InputDecoration(
                labelText: 'Expires At (YYYY-MM-DD, optional)',
                hintText: '2026-12-31',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}
