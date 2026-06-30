import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Green Palette
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color accent = Color(0xFF81C784);
  static const Color accentLight = Color(0xFFC8E6C9);

  // Background & Surface
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFCDD2);
  static const Color success = Color(0xFF388E3C);
  static const Color successLight = Color(0xFFDCEDC8);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color info = Color(0xFF1976D2);

  // Order Status Colors
  static const Color statusPending = Color(0xFFF57C00);
  static const Color statusConfirmed = Color(0xFF1976D2);
  static const Color statusProcessing = Color(0xFF7B1FA2);
  static const Color statusShipped = Color(0xFF0097A7);
  static const Color statusOutForDelivery = Color(0xFF388E3C);
  static const Color statusDelivered = Color(0xFF2E7D32);
  static const Color statusFailed = Color(0xFFD32F2F);

  // Divider & Border
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFBDBDBD);

  // Shimmer
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}
