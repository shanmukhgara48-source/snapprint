import 'package:intl/intl.dart';

class Helpers {
  Helpers._();

  /// Format a rupee amount: ₹1,299
  static String formatPrice(num amount) {
    return '₹${NumberFormat('#,##0', 'en_IN').format(amount)}';
  }

  /// Format a date: 20 Mar 2026
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format a date-time: 20 Mar 2026, 3:45 PM
  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, h:mm a').format(date);
  }

  /// Shorten a UUID to first 8 chars, uppercased: A1B2C3D4
  static String shortId(String id) {
    if (id.length < 8) return id.toUpperCase();
    return id.substring(0, 8).toUpperCase();
  }

  /// Convert snake_case status to Title Case: out_for_delivery → Out For Delivery
  static String formatStatus(String status) {
    return status
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Strip country code from phone for display: +919876543210 → 9876543210
  static String displayPhone(String phone) {
    if (phone.startsWith('+91') && phone.length == 13) {
      return phone.substring(3);
    }
    return phone;
  }

  /// Convert amount to Razorpay paise (integer)
  static int toPaise(double amount) => (amount * 100).round();
}
