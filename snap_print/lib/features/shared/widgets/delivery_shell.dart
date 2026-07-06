import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../providers/realtime_sync_provider.dart';

class DeliveryShell extends ConsumerWidget {
  const DeliveryShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the WebSocket sync alive while the delivery UI is on screen.
    ref.watch(realtimeSyncProvider);
    return Scaffold(
      body: child,
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: AppColors.primary),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.delivery_dining_rounded,
                        size: 44, color: Colors.white),
                    SizedBox(height: 8),
                    Text('Delivery Partner',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              ListTile(
                leading:
                    const Icon(Icons.logout_rounded, color: AppColors.error),
                title: const Text('Logout',
                    style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) {
                    showSuccessSnackbar(context, 'Logged out successfully');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
