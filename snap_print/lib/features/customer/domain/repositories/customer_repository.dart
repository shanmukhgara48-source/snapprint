import '../entities/address_entity.dart';
import '../entities/order_entity.dart';
import '../entities/product_entity.dart';

abstract class CustomerRepository {
  Future<List<ProductEntity>> getProducts({String? category, int page, int limit});
  Future<ProductEntity> getProductById(String id);

  Future<Map<String, dynamic>> validateCoupon(String code, double subtotal);

  Future<List<AddressEntity>> getAddresses();
  Future<AddressEntity> createAddress(Map<String, dynamic> data);
  Future<AddressEntity> updateAddress(String id, Map<String, dynamic> data);
  Future<void> deleteAddress(String id);
  Future<void> setDefaultAddress(String id);

  Future<Map<String, dynamic>> createRazorpayOrder(double amount);
  Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> data);

  Future<OrderEntity> placeOrder(Map<String, dynamic> data);
  Future<List<OrderEntity>> getMyOrders();
  Future<OrderEntity> getOrderById(String id);
}
