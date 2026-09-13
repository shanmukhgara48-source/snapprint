import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/orders_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final isGuest = user == null || user.id == 'guest';
    final ordersAsync = isGuest ? null : ref.watch(myOrdersProvider);
    final orders = ordersAsync?.valueOrNull;
    final printsCount = orders?.fold<int>(0, (sum, o) => sum + o.itemCount);
    final deliveredCount = orders?.where((o) => o.status == 'delivered').length;

    if (isGuest) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text(AppStrings.profile)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: _profileCardDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _ProfileAvatar(size: 82),
                  const SizedBox(height: 16),
                  const Text(
                    'Not signed in',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to access your profile and orders',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 26,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              children: [
                const _ProfileAvatar(size: 84, dark: true),
                const SizedBox(height: 14),
                Text(
                  user.displayName ?? user.phone,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _ProfileStat(
                      value: printsCount?.toString() ?? '—',
                      label: 'Prints',
                    ),
                    const SizedBox(width: 10),
                    _ProfileStat(
                      value: orders?.length.toString() ?? '—',
                      label: 'Orders',
                    ),
                    const SizedBox(width: 10),
                    _ProfileStat(
                      value: deliveredCount?.toString() ?? '—',
                      label: 'Delivered',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _MenuItem(
            icon: Icons.location_on_outlined,
            label: 'My Addresses',
            onTap: () => context.push(AppRoutes.address),
          ),
          _MenuItem(
            icon: Icons.receipt_long_outlined,
            label: AppStrings.orderHistory,
            onTap: () => context.push(AppRoutes.orderHistory),
          ),
          _MenuItem(
            icon: Icons.favorite_border_rounded,
            label: 'Wishlist',
            onTap: () => context.push(AppRoutes.wishlist),
          ),
          _MenuItem(
            icon: Icons.local_offer_outlined,
            label: 'My Coupons',
            onTap: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Coming soon!'))),
          ),
          _MenuItem(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            onTap: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Coming soon!'))),
          ),
          _MenuItem(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () => context.push(AppRoutes.privacyPolicy),
          ),
          const SizedBox(height: 8),
          _MenuItem(
            icon: Icons.logout_rounded,
            label: AppStrings.logout,
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () => _confirmLogout(context, ref),
          ),
          _MenuItem(
            icon: Icons.delete_forever_rounded,
            label: 'Delete Account',
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account, all orders, and personal data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(apiClientProvider).delete('/auth/me');
                await ref.read(authProvider.notifier).signOut();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete account: $e')),
                  );
                }
              }
            },
            child: const Text(
              'Delete My Account',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).signOut();
            },
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.size, this.dark = false});
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.12) : AppColors.beige,
        borderRadius: BorderRadius.circular(size / 2.8),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.20)
              : AppColors.divider,
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.52,
        color: dark ? AppColors.accent : AppColors.primary,
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _profileCardDecoration(radius: 22),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 5,
          ),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.accent).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: iconColor ?? AppColors.accent, size: 20),
          ),
          title: Text(
            label,
            style: TextStyle(
              color: textColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textHint,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

BoxDecoration _profileCardDecoration({double radius = 28}) {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.divider),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.045),
        blurRadius: 22,
        offset: const Offset(0, 12),
      ),
    ],
  );
}
