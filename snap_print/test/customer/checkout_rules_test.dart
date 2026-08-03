import 'package:flutter_test/flutter_test.dart';
import 'package:snap_print/features/customer/domain/checkout_rules.dart';

void main() {
  test('free orders bypass online payment while payable orders require it', () {
    expect(requiresOnlinePayment(0), isFalse);
    expect(requiresOnlinePayment(0.001), isFalse);
    expect(requiresOnlinePayment(0.01), isTrue);
    expect(requiresOnlinePayment(499), isTrue);
  });
}
