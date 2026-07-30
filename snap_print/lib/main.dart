import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/firebase/fcm_service.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/domain/entities/user_entity.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSize = 180;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 96 << 20;

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // On debug builds: disable app verification so Play Integrity / SafetyNet
  // failures on emulators don't block phone OTP. Use test phone numbers only.
  if (kDebugMode) {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }

  final container = ProviderContainer();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SnapPrintApp(),
    ),
  );

  var fcmStarted = false;
  late final ProviderSubscription<AsyncValue<UserEntity?>> authSubscription;
  authSubscription = container.listen<AsyncValue<UserEntity?>>(authProvider, (
    _,
    next,
  ) {
    if (fcmStarted || next.valueOrNull == null) return;
    fcmStarted = true;
    authSubscription.close();
    _startFcmAfterLaunchSettles(container);
  }, fireImmediately: true);
}

void _startFcmAfterLaunchSettles(ProviderContainer container) {
  // Initialize FCM after launch/auth settles so notification permission, token
  // lookup, and topic subscription cannot delay or ANR the first experience.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      Future<void>.delayed(const Duration(seconds: 4), () async {
        await container
            .read(fcmServiceProvider)
            .initialize(
              onToken: (token) =>
                  container.read(authProvider.notifier).syncFcmToken(token),
              onNotificationTap: (data) {
                final orderId = data['order_id'] as String?;
                if (orderId != null) {
                  container
                      .read(appRouterProvider)
                      .push(AppRoutes.orderConfirmationPath(orderId));
                }
              },
            );
      }),
    );
  });
}
