import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../providers/delivery_provider.dart';

enum _ProofMode { photo, otp }

class DeliveryProofScreen extends ConsumerStatefulWidget {
  const DeliveryProofScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<DeliveryProofScreen> createState() =>
      _DeliveryProofScreenState();
}

class _DeliveryProofScreenState extends ConsumerState<DeliveryProofScreen> {
  _ProofMode _mode = _ProofMode.photo;
  XFile? _photo;
  final _otpController = TextEditingController();
  bool _isUploading = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) setState(() => _photo = picked);
  }

  Future<void> _submit() async {
    if (_mode == _ProofMode.photo && _photo == null) {
      showErrorSnackbar(context, 'Please take a proof photo');
      return;
    }
    if (_mode == _ProofMode.otp && _otpController.text.length != 6) {
      showErrorSnackbar(context, 'Enter a 6-digit delivery OTP');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? proofUrl;

      if (_mode == _ProofMode.photo) {
        setState(() => _isUploading = true);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('delivery_proofs/${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        final bytes = await _photo!.readAsBytes();
        await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        proofUrl = await storageRef.getDownloadURL();
        setState(() => _isUploading = false);
      } else {
        proofUrl = 'otp:${_otpController.text}';
      }

      await ref.read(deliveryStatusProvider.notifier).updateStatus(
            widget.orderId,
            'delivered',
            proofUrl: proofUrl,
          );

      if (mounted) {
        showSuccessSnackbar(context, 'Order marked as delivered!');
        context.pop();
        context.pop();
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isSubmitting = false;
      });
      if (mounted) showErrorSnackbar(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPin = PinTheme(
      width: 52,
      height: 56,
      textStyle: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.uploadProof)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode toggle
            Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: AppStrings.proofPhoto,
                    icon: Icons.camera_alt_rounded,
                    selected: _mode == _ProofMode.photo,
                    onTap: () => setState(() => _mode = _ProofMode.photo),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModeButton(
                    label: AppStrings.proofOtp,
                    icon: Icons.pin_rounded,
                    selected: _mode == _ProofMode.otp,
                    onTap: () => setState(() => _mode = _ProofMode.otp),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            if (_mode == _ProofMode.photo) ...[
              Text(AppStrings.proofPhoto,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: _isUploading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : _photo != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: FutureBuilder<Uint8List>(
                                future: _photo!.readAsBytes(),
                                builder: (ctx, snap) => snap.hasData
                                    ? Image.memory(snap.data!, fit: BoxFit.cover, width: double.infinity)
                                    : const Center(child: CircularProgressIndicator()),
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_rounded,
                                    size: 48, color: AppColors.primary),
                                SizedBox(height: 8),
                                Text('Tap to capture proof photo',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                ),
              ),
            ] else ...[
              Text(AppStrings.enterDeliveryOtp,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Ask the customer for their delivery OTP',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),
              Center(
                child: Pinput(
                  controller: _otpController,
                  length: 6,
                  autofocus: true,
                  defaultPinTheme: defaultPin,
                  focusedPinTheme: defaultPin.copyDecorationWith(
                    border: Border.all(
                        color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ],

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

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: selected ? Colors.white : AppColors.textSecondary,
                size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
