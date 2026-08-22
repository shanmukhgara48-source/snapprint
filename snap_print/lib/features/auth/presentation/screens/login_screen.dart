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
  _CountryCode('India', '\u{1F1EE}\u{1F1F3}', '+91'),
  _CountryCode('United States', '\u{1F1FA}\u{1F1F8}', '+1'),
  _CountryCode('United Kingdom', '\u{1F1EC}\u{1F1E7}', '+44'),
  _CountryCode('UAE', '\u{1F1E6}\u{1F1EA}', '+971'),
  _CountryCode('Singapore', '\u{1F1F8}\u{1F1EC}', '+65'),
  _CountryCode('Australia', '\u{1F1E6}\u{1F1FA}', '+61'),
  _CountryCode('Canada', '\u{1F1E8}\u{1F1E6}', '+1'),
];

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  int _tab = 0; // 0 = Login, 1 = Register
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _CountryCode _selectedCountry = _countries.first;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _showPhoneLogin = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  String? _validateEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword() {
    final password = _passwordController.text;
    if (password.isEmpty) return 'Password is required';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Email / Password
  // ---------------------------------------------------------------------------

  Future<void> _signInWithEmail() async {
    final emailError = _validateEmail();
    if (emailError != null) {
      showErrorSnackbar(context, emailError);
      return;
    }
    final passwordError = _validatePassword();
    if (passwordError != null) {
      showErrorSnackbar(context, passwordError);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final isNew = await ref.read(authProvider.notifier).signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (isNew) {
        context.push(AppRoutes.profileSetup, extra: {
          'phone': '',
        });
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, _emailAuthError(e.code));
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_nameController.text.trim().isEmpty) {
      showErrorSnackbar(context, 'Please enter your full name');
      return;
    }
    final emailError = _validateEmail();
    if (emailError != null) {
      showErrorSnackbar(context, emailError);
      return;
    }
    final passwordError = _validatePassword();
    if (passwordError != null) {
      showErrorSnackbar(context, passwordError);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
      if (!mounted) return;
      final authState = ref.read(authProvider);
      authState.whenOrNull(
        error: (e, _) => showErrorSnackbar(context, e.toString()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, _emailAuthError(e.code));
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _emailAuthError(String code) => switch (code) {
        'user-not-found' => 'No account found with this email.',
        'wrong-password' => 'Incorrect password. Try again.',
        'invalid-credential' => 'Invalid email or password.',
        'email-already-in-use' => 'An account already exists with this email.',
        'weak-password' => 'Password is too weak. Use at least 6 characters.',
        'invalid-email' => 'Invalid email address.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'user-disabled' => 'This account has been disabled.',
        _ => 'Authentication failed. Please try again.',
      };

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      if (!mounted) return;
      final authState = ref.read(authProvider);
      authState.whenOrNull(
        error: (e, _) => showErrorSnackbar(context, e.toString()),
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, 'Google sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Phone OTP
  // ---------------------------------------------------------------------------

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
          context, '[${e.code}] ${e.message ?? _phoneAuthError(e.code)}');
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _phoneAuthError(String code) => switch (code) {
        'invalid-phone-number' => 'Invalid phone number. Include country code.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'quota-exceeded' => 'SMS quota exceeded. Try again later.',
        _ => 'Failed to send OTP. Please try again.',
      };

  // ---------------------------------------------------------------------------
  // Forgot Password
  // ---------------------------------------------------------------------------

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showErrorSnackbar(context, 'Enter your email above, then tap "Forgot password?"');
      return;
    }
    final emailError = _validateEmail();
    if (emailError != null) {
      showErrorSnackbar(context, emailError);
      return;
    }
    try {
      await ref.read(authProvider.notifier).sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $email'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, 'Failed to send reset email: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
                GestureDetector(
                  onTap: () => setState(() => _tab = 0),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                      children: [
                        TextSpan(
                          text: 'Login',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      child: _showPhoneLogin
                          ? _buildPhoneFields()
                          : (_tab == 0
                              ? _buildEmailLoginFields()
                              : _buildEmailRegisterFields()),
                    ),
                    const SizedBox(height: 24),
                    _buildCTAButton(),
                    const SizedBox(height: 20),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildGoogleButton(),
                    const SizedBox(height: 12),
                    _buildPhoneToggleButton(),
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
              onTap: () => setState(() {
                _tab = 0;
                _showPhoneLogin = false;
              }),
            ),
          ),
          Expanded(
            child: _SegTab(
              label: 'Register',
              selected: _tab == 1,
              onTap: () => setState(() {
                _tab = 1;
                _showPhoneLogin = false;
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Email login fields
  // ---------------------------------------------------------------------------

  Widget _buildEmailLoginFields() {
    return Column(
      key: const ValueKey('email-login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Email'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _emailController,
          hint: 'email@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Password'),
        const SizedBox(height: 8),
        _buildPasswordField(),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _forgotPassword,
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: const Text('Forgot password?',
                style: TextStyle(fontSize: 12, color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Email register fields
  // ---------------------------------------------------------------------------

  Widget _buildEmailRegisterFields() {
    return Column(
      key: const ValueKey('email-register'),
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
        const _FieldLabel('Email'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _emailController,
          hint: 'email@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Password'),
        const SizedBox(height: 8),
        _buildPasswordField(),
      ],
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Enter your password',
        hintStyle: const TextStyle(
            color: Color(0xFFBBBBBB), fontWeight: FontWeight.w400),
        prefixIcon:
            const Icon(Icons.lock_outline, size: 20, color: Color(0xFF888888)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: const Color(0xFF888888),
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
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

  // ---------------------------------------------------------------------------
  // Phone fields (shown when user taps "Sign in with Phone")
  // ---------------------------------------------------------------------------

  Widget _buildPhoneFields() {
    return Column(
      key: const ValueKey('phone-login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _showPhoneLogin = false),
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            const Text(
              'Sign in with Phone',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_tab == 1) ...[
          const _FieldLabel('Full Name'),
          const SizedBox(height: 8),
          _AuthTextField(
            controller: _nameController,
            hint: 'Your full name',
            icon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
        ],
        const _FieldLabel('Phone Number'),
        const SizedBox(height: 8),
        _buildPhoneRow(),
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

  // ---------------------------------------------------------------------------
  // CTA Button
  // ---------------------------------------------------------------------------

  Widget _buildCTAButton() {
    final String label;
    final VoidCallback? onPressed;

    if (_showPhoneLogin) {
      label = 'Send OTP';
      onPressed = _isLoading ? null : _sendOtp;
    } else if (_tab == 0) {
      label = 'Login';
      onPressed = _isLoading ? null : _signInWithEmail;
    } else {
      label = 'Create Account';
      onPressed = _isLoading ? null : _signUpWithEmail;
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
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
                label,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.3),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Divider + Social buttons
  // ---------------------------------------------------------------------------

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFE0E0E0))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Or continue with',
            style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFE0E0E0))),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isGoogleLoading ? null : _signInWithGoogle,
        icon: _isGoogleLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Image.network(
                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                width: 20,
                height: 20,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.g_mobiledata, size: 24),
              ),
        label: const Text(
          'Continue with Google',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1A1A1A),
          ),
        ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50)),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPhoneToggleButton() {
    if (_showPhoneLogin) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _showPhoneLogin = true),
        icon: const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF1A1A1A)),
        label: const Text(
          'Continue with Phone',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1A1A1A),
          ),
        ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50)),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

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
