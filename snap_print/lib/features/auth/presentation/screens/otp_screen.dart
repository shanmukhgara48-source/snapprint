import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';

const _kYellow = Color(0xFFF5FF2D);
const _kBg = Color(0xFFF5F5F5);

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String verificationId;
  final String? registrationName;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.verificationId,
    this.registrationName,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  late String _verificationId;
  bool _isVerifying = false;
  bool _isResending = false;
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otpController.text.length < 6) {
      showErrorSnackbar(context, 'Enter the complete 6-digit OTP');
      return;
    }
    setState(() => _isVerifying = true);
    try {
      final isNewUser = await ref.read(authProvider.notifier).verifyOtp(
            verificationId: _verificationId,
            smsCode: _otpController.text.trim(),
          );
      if (!mounted) return;

      if (isNewUser && widget.registrationName != null) {
        // Register tab flow: auto-create profile, then success
        await ref.read(authProvider.notifier).completeProfile(
              phone: widget.phone,
              displayName: widget.registrationName!,
              role: 'customer',
            );
        // Router handles redirect to authSuccess via verifiedJustNow flag
        return;
      }

      if (isNewUser) {
        // Login tab flow for a new user: go to profile setup
        if (mounted) {
          context.pushReplacement(
            AppRoutes.profileSetup,
            extra: {'phone': widget.phone},
          );
        }
        return;
      }

      // Existing user: router handles redirect to authSuccess
      final authState = ref.read(authProvider);
      authState.whenOrNull(
        error: (e, _) => showErrorSnackbar(context, e.toString()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, _firebaseError(e.code));
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, 'Verification failed: $e');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_secondsLeft > 0 || _isResending) return;
    setState(() => _isResending = true);
    _otpController.clear();
    try {
      final newVerificationId =
          await ref.read(authProvider.notifier).sendOtp(widget.phone);
      if (!mounted) return;
      if (newVerificationId != 'auto-verified') {
        setState(() => _verificationId = newVerificationId);
        _startTimer();
        showSuccessSnackbar(context, 'OTP resent to ${widget.phone}');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, _firebaseError(e.code));
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, 'Could not resend OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  String _firebaseError(String code) => switch (code) {
        'invalid-verification-code' =>
          'Invalid OTP. Please check and try again.',
        'session-expired' => 'OTP expired. Please request a new one.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        'operation-not-allowed' =>
          'Phone sign-in temporarily unavailable.',
        'invalid-phone-number' => 'Invalid phone number format.',
        _ => 'Verification failed. Please try again.',
      };

  @override
  Widget build(BuildContext context) {
    final focusedTheme = PinTheme(
      width: 52,
      height: 58,
      textStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A)),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final defaultTheme = PinTheme(
      width: 52,
      height: 58,
      textStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A)),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final submittedTheme = PinTheme(
      width: 52,
      height: 58,
      textStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A)),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFF4),
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(14),
      ),
    );

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // App bar row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: Color(0xFF1A1A1A)),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'OTP Verification',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    const Text(
                      'Enter the\nVerification Code',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF888888)),
                        children: [
                          const TextSpan(
                              text:
                                  'We sent a 6-digit code to\n'),
                          TextSpan(
                            text: widget.phone,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // OTP boxes
                    Center(
                      child: Pinput(
                        controller: _otpController,
                        length: 6,
                        autofocus: true,
                        defaultPinTheme: defaultTheme,
                        focusedPinTheme: focusedTheme,
                        submittedPinTheme: submittedTheme,
                        onCompleted: (_) => _verify(),
                        separatorBuilder: (i) =>
                            const SizedBox(width: 8),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kYellow,
                          foregroundColor: const Color(0xFF1A1A1A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)),
                          disabledBackgroundColor:
                              _kYellow.withValues(alpha: 0.6),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF1A1A1A)),
                              )
                            : const Text(
                                'Verify OTP',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    letterSpacing: 0.3),
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Resend
                    Center(
                      child: _secondsLeft > 0
                          ? RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF888888)),
                                children: [
                                  const TextSpan(
                                      text: 'Resend OTP in '),
                                  TextSpan(
                                    text:
                                        '0:${_secondsLeft.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : TextButton(
                              onPressed:
                                  _isResending ? null : _resendOtp,
                              child: _isResending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Resend OTP',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
