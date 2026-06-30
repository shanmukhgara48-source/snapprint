import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/order_entity.dart';
import '../repositories/customer_repository.dart';
import '../../data/repositories/customer_repository_impl.dart';

class PlaceOrderUseCase {
  PlaceOrderUseCase(this._repository);
  final CustomerRepository _repository;

  Future<OrderEntity> call({
    required List<Map<String, dynamic>> items,
    required String addressId,
    required String deliveryType,
    String? couponCode,
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
  }) {
    final data = <String, dynamic>{
      'items': items,
      'address_id': addressId,
      'delivery_type': deliveryType,
    };
    if (couponCode != null) data['coupon_code'] = couponCode;
    if (razorpayPaymentId != null) data['razorpay_payment_id'] = razorpayPaymentId;
    if (razorpayOrderId != null) data['razorpay_order_id'] = razorpayOrderId;
    if (razorpaySignature != null) data['razorpay_signature'] = razorpaySignature;

    return _repository.placeOrder(data);
  }
}

final placeOrderUseCaseProvider = Provider<PlaceOrderUseCase>((ref) {
  return PlaceOrderUseCase(ref.read(customerRepositoryProvider));
});
