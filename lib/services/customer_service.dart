import '../config/api_config.dart';
import 'api_service.dart';

class CustomerService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _api.get(ApiConfig.profile);
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    final response = await _api.patch(
      ApiConfig.profile,
      body: {
        'fullName': fullName.trim(),
        'phone': phone?.trim(),
      },
    );

    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    final response = await _api.delete(ApiConfig.profile);
    return Map<String, dynamic>.from(response);
  }
}
