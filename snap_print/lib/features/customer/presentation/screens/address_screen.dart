import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../providers/address_provider.dart';

class AddressScreen extends ConsumerWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressAsync = ref.watch(addressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addresses)),
      body: addressAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, s) => Center(child: Text('$e')),
        data: (addresses) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...addresses.map(
              (addr) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_outlined,
                        color: AppColors.primary),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${addr.fullAddress}, ${addr.city} - ${addr.pincode}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (addr.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            AppStrings.defaultLabel,
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      final notifier = ref.read(addressProvider.notifier);
                      if (value == 'default') {
                        await notifier.setDefault(addr.id);
                      } else if (value == 'delete') {
                        await notifier.deleteAddress(addr.id);
                      } else if (value == 'edit') {
                        _showAddressForm(context, ref, existing: addr);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'default',
                          child: Text(AppStrings.setDefault)),
                      const PopupMenuItem(
                          value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Text(AppStrings.deleteAddress)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            if (addresses.length < 5)
              CustomButton(
                label: AppStrings.addAddress,
                icon: Icons.add_location_alt_outlined,
                isOutlined: true,
                onPressed: () => _showAddressForm(context, ref),
              )
            else
              Text(
                AppStrings.maxAddressReached,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.error),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddressForm(BuildContext context, WidgetRef ref,
      {dynamic existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddressForm(existing: existing, ref: ref),
    );
  }
}

class _AddressForm extends StatefulWidget {
  const _AddressForm({this.existing, required this.ref});
  final dynamic existing;
  final WidgetRef ref;

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _formKey = GlobalKey<FormState>();
  late final _addressCtrl =
      TextEditingController(text: widget.existing?.fullAddress ?? '');
  late final _cityCtrl =
      TextEditingController(text: widget.existing?.city ?? '');
  late final _pincodeCtrl =
      TextEditingController(text: widget.existing?.pincode ?? '');
  late bool _isDefault = widget.existing?.isDefault ?? false;
  bool _isSaving = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final data = {
      'full_address': _addressCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'pincode': _pincodeCtrl.text.trim(),
      'is_default': _isDefault,
    };
    try {
      final notifier = widget.ref.read(addressProvider.notifier);
      if (widget.existing != null) {
        await notifier.updateAddress(widget.existing!.id, data);
      } else {
        await notifier.addAddress(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) showErrorSnackbar(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing != null
                  ? AppStrings.editAddress
                  : AppStrings.addAddress,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressCtrl,
              decoration:
                  const InputDecoration(labelText: AppStrings.fullAddress),
              maxLines: 2,
              validator: (v) =>
                  v?.isEmpty == true ? AppStrings.addressRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cityCtrl,
              decoration: const InputDecoration(labelText: AppStrings.city),
              validator: (v) =>
                  v?.isEmpty == true ? AppStrings.cityRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pincodeCtrl,
              decoration:
                  const InputDecoration(labelText: AppStrings.pincode),
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v?.isEmpty == true) return AppStrings.pincodeRequired;
                if (v!.length != 6) return AppStrings.invalidPincode;
                return null;
              },
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Checkbox(
                  value: _isDefault,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isDefault = v!),
                ),
                const Text(AppStrings.setDefault),
              ],
            ),
            const SizedBox(height: 8),
            CustomButton(
              label: AppStrings.saveAddress,
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
