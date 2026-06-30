import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../dashboard/dashboard_screen.dart' show AdminDrawer;

final _deliverySettingsProvider =
    FutureProvider<List<dynamic>>((ref) async {
  final client = ref.read(adminApiClientProvider);
  final response = await client.dio.get('/admin/delivery-settings');
  return response.data as List<dynamic>;
});

class DeliverySettingsScreen extends ConsumerWidget {
  const DeliverySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(_deliverySettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Settings')),
      drawer: const AdminDrawer(),
      body: settingsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AdminTheme.primary)),
        error: (e, s) => Center(child: Text('$e')),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Control delivery pricing and availability',
              style: TextStyle(color: AdminTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ...settings.map((s) {
              final setting = s as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  leading: _typeIcon(setting['type'] as String),
                  title: Text(
                    setting['label'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(setting['days_label'] as String),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActiveChip(
                        isActive: setting['is_active'] as bool,
                        type: setting['type'] as String,
                        ref: ref,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        setting['price'] == 0
                            ? 'FREE'
                            : '₹${(setting['price'] as num).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: setting['price'] == 0
                              ? Colors.green
                              : AdminTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AdminTheme.primary),
                        tooltip: 'Edit',
                        onPressed: () => _showEditDialog(
                          context,
                          ref,
                          setting,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _typeIcon(String type) {
    final iconData = switch (type) {
      'free' => Icons.local_shipping_outlined,
      'standard' => Icons.delivery_dining_rounded,
      'express' => Icons.electric_bolt_rounded,
      _ => Icons.local_shipping_outlined,
    };
    final color = switch (type) {
      'free' => Colors.green,
      'standard' => Colors.blue,
      'express' => Colors.orange,
      _ => AdminTheme.primary,
    };
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(iconData, color: color),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> setting,
  ) {
    showDialog(
      context: context,
      builder: (_) => _EditDeliveryDialog(setting: setting, ref: ref),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({
    required this.isActive,
    required this.type,
    required this.ref,
  });
  final bool isActive;
  final String type;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          final client = ref.read(adminApiClientProvider);
          await client.dio.put(
            '/admin/delivery-settings/$type',
            data: {'is_active': !isActive},
          );
          ref.invalidate(_deliverySettingsProvider);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e'), backgroundColor: Colors.red),
            );
          }
        }
      },
      child: Chip(
        label: Text(
          isActive ? 'Active' : 'Inactive',
          style: TextStyle(
              color: isActive ? Colors.white : AdminTheme.textSecondary,
              fontSize: 12),
        ),
        backgroundColor: isActive ? AdminTheme.primary : Colors.grey.shade200,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _EditDeliveryDialog extends StatefulWidget {
  const _EditDeliveryDialog({required this.setting, required this.ref});
  final Map<String, dynamic> setting;
  final WidgetRef ref;

  @override
  State<_EditDeliveryDialog> createState() => _EditDeliveryDialogState();
}

class _EditDeliveryDialogState extends State<_EditDeliveryDialog> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _daysCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _labelCtrl =
        TextEditingController(text: widget.setting['label'] as String);
    _priceCtrl = TextEditingController(
        text: (widget.setting['price'] as num).toString());
    _daysCtrl =
        TextEditingController(text: widget.setting['days_label'] as String);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _priceCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final client = widget.ref.read(adminApiClientProvider);
      await client.dio.put(
        '/admin/delivery-settings/${widget.setting['type']}',
        data: {
          'label': _labelCtrl.text.trim(),
          'price': price,
          'days_label': _daysCtrl.text.trim(),
        },
      );
      widget.ref.invalidate(_deliverySettingsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text('Edit ${widget.setting['label']}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelCtrl,
            decoration: const InputDecoration(labelText: 'Label'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceCtrl,
            decoration: const InputDecoration(
                labelText: 'Price (₹)', hintText: '0 for free'),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _daysCtrl,
            decoration:
                const InputDecoration(labelText: 'Days label (e.g. 3-4 business days)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

