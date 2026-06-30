import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../../domain/entities/address_entity.dart';

class AddressNotifier extends AsyncNotifier<List<AddressEntity>> {
  @override
  Future<List<AddressEntity>> build() async {
    return ref.read(customerDataSourceProvider).getAddresses();
  }

  Future<void> addAddress(Map<String, dynamic> data) async {
    final ds = ref.read(customerDataSourceProvider);
    await ds.createAddress(data);
    ref.invalidateSelf();
  }

  Future<void> updateAddress(String id, Map<String, dynamic> data) async {
    final ds = ref.read(customerDataSourceProvider);
    await ds.updateAddress(id, data);
    ref.invalidateSelf();
  }

  Future<void> deleteAddress(String id) async {
    final ds = ref.read(customerDataSourceProvider);
    await ds.deleteAddress(id);
    ref.invalidateSelf();
  }

  Future<void> setDefault(String id) async {
    final ds = ref.read(customerDataSourceProvider);
    await ds.setDefaultAddress(id);
    ref.invalidateSelf();
  }
}

final addressProvider =
    AsyncNotifierProvider<AddressNotifier, List<AddressEntity>>(
  AddressNotifier.new,
);

final selectedAddressProvider = StateProvider<AddressEntity?>((ref) {
  final addressAsync = ref.watch(addressProvider);
  return addressAsync.maybeWhen(
    data: (addresses) =>
        addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull,
    orElse: () => null,
  );
});
