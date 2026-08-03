import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../data/datasources/delivery_remote_datasource.dart';
import '../providers/delivery_provider.dart';

class DeliveryProofScreen extends ConsumerStatefulWidget {
  const DeliveryProofScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<DeliveryProofScreen> createState() =>
      _DeliveryProofScreenState();
}

class _DeliveryProofScreenState extends ConsumerState<DeliveryProofScreen> {
  XFile? _photo;
  bool _isUploading = false;
  bool _isSubmitting = false;

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
      maxWidth: 2400,
    );
    if (picked != null && mounted) setState(() => _photo = picked);
  }

  Future<void> _submit() async {
    if (_photo == null) {
      showErrorSnackbar(context, 'Please take a proof photo');
      return;
    }

    setState(() {
      _isUploading = true;
      _isSubmitting = true;
    });
    try {
      final proofUrl = await ref
          .read(deliveryDataSourceProvider)
          .uploadProof(widget.orderId, _photo!.path);
      if (mounted) setState(() => _isUploading = false);

      await ref
          .read(deliveryStatusProvider.notifier)
          .updateStatus(widget.orderId, 'delivered', proofUrl: proofUrl);

      if (mounted) {
        showSuccessSnackbar(context, 'Order marked as delivered!');
        context.pop();
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _isSubmitting = false;
        });
        showErrorSnackbar(context, '$error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.uploadProof)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.proofPhoto,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Capture the delivered package at the customer address.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _isSubmitting ? null : _pickPhoto,
              child: Container(
                width: double.infinity,
                height: 260,
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: _isUploading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _photo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: FutureBuilder<Uint8List>(
                          future: _photo!.readAsBytes(),
                          builder: (context, snapshot) => snapshot.hasData
                              ? Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                )
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap to capture proof photo',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const Spacer(),
            CustomButton(
              label: AppStrings.submitProof,
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
