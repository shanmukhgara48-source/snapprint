import '../../domain/entities/address_entity.dart';

class AddressModel extends AddressEntity {
  const AddressModel({
    required super.id,
    required super.fullAddress,
    required super.city,
    required super.pincode,
    required super.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id'].toString(),
        fullAddress: json['full_address'] as String,
        city: json['city'] as String,
        pincode: json['pincode'] as String,
        isDefault: json['is_default'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'full_address': fullAddress,
        'city': city,
        'pincode': pincode,
        'is_default': isDefault,
      };
}
