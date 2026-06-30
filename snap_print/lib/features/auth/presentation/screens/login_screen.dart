import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';

const _kYellow = Color(0xFFF5FF2D);
const _kBg = Color(0xFFF5F5F5);

class _CountryCode {
  const _CountryCode(this.name, this.flag, this.dialCode);
  final String name;
  final String flag;
  final String dialCode;
}

const _countries = [
  _CountryCode('India', '🇮🇳', '+91'),
  _CountryCode('United States', '🇺🇸', '+1'),
  _CountryCode('United Kingdom', '🇬🇧', '+44'),
  _CountryCode('UAE', '🇦🇪', '+971'),
  _CountryCode('Singapore', '🇸🇬', '+65'),
  _CountryCode('Australia', '🇦🇺', '+61'),
  _CountryCode('Canada', '🇨🇦', '+1'),
];

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  int _tab = 0;
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  _CountryCode _selectedCountry = _countries.first;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String get _fullPhone =>
      '${_selectedCountry.dialCode}${_phoneController.text.trim()}';

  String? _validatePhone() {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) return 'Phone number is required';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 12) return 'Enter a valid phone number';
    return null;
  }

  Future<void> _sendOtp() async {
    if (_tab == 1 && _nameController.text.trim().isEmpty) {
      showErrorSnackbar(context, 'Please enter your full name');
      return;
    }
    final phoneError = _validatePhone();
    if (phoneError != null) {
      showErrorSnackbar(context, phoneError);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final verificationId =
          await ref.read(authProvider.notifier).sendOtp(_fullPhone);
      if (!mounted) return;
      if (verificationId == 'auto-verified') return;
      context.push(AppRoutes.otp, extra: {
        'phone': _fullPhone,
        'verificationId': verificationId,
        if (_tab == 1) 'registrationName': _nameController.text.trim(),
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showErrorSnackbar(
          context, '[${e.code}] ${e.message ?? _firebaseError(e.code)}');
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _firebaseError(String code) => switch (code) {
        'invalid-phone-number' => 'Invalid phone number. Include country code.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'quota-exceeded' => 'SMS quota exceeded. Try again later.',
        _ => 'Failed to send OTP. Please try again.',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Logo + tagline
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.photo_camera_rounded,
                          size: 38, color: Colors.white),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'SnapPrint',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Print Your Memories',
                      style:
                          TextStyle(fontSize: 13, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Heading
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _tab == 0
                      ? 'Step Into the\nFuture of Printing'
                      : 'Create an\nAccount',
                  key: ValueKey(_tab),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (_tab == 1)
                const Text(
                  'Already have an account? ',
                  style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                ),
              const SizedBox(height: 20),

              // Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSegmentedControl(),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      child: _tab == 0
                          ? _buildLoginFields()
                          : _buildRegisterFields(),
                    ),
                    const SizedBox(height: 24),
                    _buildCTAButton(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'By continuing, you agree to our Terms & Privacy Policy',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                ),
              ),
              const SizedBox(height: 16),
              if (kDebugMode)
                Center(
                  child: GestureDetector(
                    onLongPress: () => _showDevLogin(context),
                    child: const Text('v1.0.0-debug',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFFCCCCCC))),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(50),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _SegTab(
              label: 'Login',
              selected: _tab == 0,
              onTap: () => setState(() => _tab = 0),
            ),
          ),
          Expanded(
            child: _SegTab(
              label: 'Register',
              selected: _tab == 1,
              onTap: () => setState(() => _tab = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginFields() {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Phone Number'),
        const SizedBox(height: 8),
        _buildPhoneRow(),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                activeColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Remember Me',
                style:
                    TextStyle(fontSize: 13, color: Color(0xFF555555))),
            const Spacer(),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, minimumSize: Size.zero),
              child: const Text('Need help?',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.primary)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterFields() {
    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Full Name'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _nameController,
          hint: 'Your full name',
          icon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Phone Number'),
        const SizedBox(height: 8),
        _buildPhoneRow(),
        const SizedBox(height: 16),
        const _FieldLabel('Email (optional)'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _emailController,
          hint: 'email@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildPhoneRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: _showCountryPicker,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_selectedCountry.flag,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                Text(
                  _selectedCountry.dialCode,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_drop_down,
                    size: 16, color: Color(0xFF888888)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AuthTextField(
            controller: _phoneController,
            hint: '9876543210',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            onSubmitted: (_) => _sendOtp(),
          ),
        ),
      ],
    );
  }

  Widget _buildCTAButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _sendOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kYellow,
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50)),
          disabledBackgroundColor: _kYellow.withValues(alpha: 0.6),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Color(0xFF1A1A1A)),
              )
            : Text(
                _tab == 0 ? 'Send OTP' : 'Create Account',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.3),
              ),
      ),
    );
  }

  void _showDevLogin(BuildContext context) {
    final phoneCtrl = TextEditingController(text: '+919876543210');
    final nameCtrl = TextEditingController(text: 'QA Tester');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dev Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneCtrl.text.trim();
              final name = nameCtrl.text.trim();
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).devLogin(phone, name);
              if (!mounted) return;
              this.context.go(AppRoutes.customerHome);
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Select Country',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          ..._countries.map(
            (c) => ListTile(
              leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
              title: Text(c.name),
              trailing: Text(c.dialCode,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              selected: c.dialCode == _selectedCountry.dialCode &&
                  c.name == _selectedCountry.name,
              onTap: () {
                setState(() => _selectedCountry = c);
                Navigator.pop(ctx);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SegTab extends StatelessWidget {
  const _SegTab(
      {required this.label,
      required this.selected,
      required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight:
                  selected ? FontWeight.w800 : FontWeight.w500,
              fontSize: 14,
              color: selected
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFF888888),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF555555)),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: Color(0xFFBBBBBB), fontWeight: FontWeight.w400),
        prefixIcon:
            Icon(icon, size: 20, color: const Color(0xFF888888)),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
