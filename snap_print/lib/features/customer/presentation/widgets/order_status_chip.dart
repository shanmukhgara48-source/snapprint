import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});
  final String status;

  static Color _bgColor(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return AppColors.warningLight;
      case 'confirmed':
        return const Color(0xFFE3F2FD);
      case 'processing':
        return const Color(0xFFF3E5F5);
      case 'shipped':
        return const Color(0xFFE0F7FA);
      case 'out_for_delivery':
        return AppColors.successLight;
      case 'delivered':
        return AppColors.successLight;
      case 'failed':
        return AppColors.errorLight;
      default:
        return AppColors.accentLight;
    }
  }

  static Color _textColor(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.info;
      case 'processing':
        return const Color(0xFF7B1FA2);
      case 'shipped':
        return const Color(0xFF0097A7);
      case 'out_for_delivery':
        return AppColors.success;
      case 'delivered':
        return AppColors.primary;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  static String _label(String s) {
    switch (s.toLowerCase()) {
      case 'out_for_delivery':
        return 'Out for Delivery';
      default:
        return s[0].toUpperCase() + s.substring(1).toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _textColor(status),
        ),
      ),
    );
  }
}
