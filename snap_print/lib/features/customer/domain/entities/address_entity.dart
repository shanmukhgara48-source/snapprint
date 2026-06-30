class AddressEntity {
  const AddressEntity({
    required this.id,
    required this.fullAddress,
    required this.city,
    required this.pincode,
    required this.isDefault,
  });

  final String id;
  final String fullAddress;
  final String city;
  final String pincode;
  final bool isDefault;

  AddressEntity copyWith({bool? isDefault}) => AddressEntity(
        id: id,
        fullAddress: fullAddress,
        city: city,
        pincode: pincode,
        isDefault: isDefault ?? this.isDefault,
      );
}
