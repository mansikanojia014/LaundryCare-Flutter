import '../config/api_config.dart';
import 'api_service.dart';

class AddressService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> getAddresses() async {
    final response = await _api.get(ApiConfig.addresses);

    final addresses = response['addresses'];

    if (addresses is! List) {
      return [];
    }

    return addresses
        .map(
          (address) => Map<String, dynamic>.from(address),
        )
        .toList();
  }

  Future<Map<String, dynamic>> createAddress({
    String? label,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    String? landmark,
    bool isDefault = false,
  }) async {
    final response = await _api.post(
      ApiConfig.addresses,
      body: {
        if (label != null && label.trim().isNotEmpty)
          'label': label.trim(),
        'addressLine1': addressLine1.trim(),
        if (addressLine2 != null &&
            addressLine2.trim().isNotEmpty)
          'addressLine2': addressLine2.trim(),
        'city': city.trim(),
        'state': state.trim(),
        'postalCode': postalCode.trim(),
        if (landmark != null &&
            landmark.trim().isNotEmpty)
          'landmark': landmark.trim(),
        'isDefault': isDefault,
      },
    );

    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> updateAddress({
    required String id,
    String? label,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? landmark,
    bool? isDefault,
  }) async {
    final body = <String, dynamic>{
      if (label != null) 'label': label.trim(),
      if (addressLine1 != null)
        'addressLine1': addressLine1.trim(),
      if (addressLine2 != null)
        'addressLine2': addressLine2.trim(),
      if (city != null) 'city': city.trim(),
      if (state != null) 'state': state.trim(),
      if (postalCode != null)
        'postalCode': postalCode.trim(),
      if (landmark != null)
        'landmark': landmark.trim(),
    };

    if (isDefault case final value?) {
      body['isDefault'] = value;
    }

    final response = await _api.patch(
      '${ApiConfig.addresses}/$id',
      body: body,
    );

    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> deleteAddress(
    String id,
  ) async {
    final response = await _api.delete(
      '${ApiConfig.addresses}/$id',
    );

    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> setDefaultAddress(
    String id,
  ) async {
    final response = await _api.patch(
      '${ApiConfig.addresses}/$id/default',
    );

    return Map<String, dynamic>.from(response);
  }
}

