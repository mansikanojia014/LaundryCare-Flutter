import '../config/api_config.dart';
import 'api_service.dart';

class ServiceService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> getServices() async {
    final response = await _api.get(ApiConfig.services);

    final data = response['services'];

    if (data is! List) {
      return [];
    }

    return data
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getClothTypes() async {
    final response = await _api.get(ApiConfig.clothTypes);

    final data = response['clothTypes'];

    if (data is! List) {
      return [];
    }

    return data
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getServicesForClothType(
    String clothTypeId,
  ) async {
    final response = await _api.get(
      '${ApiConfig.clothTypes}/$clothTypeId/services',
    );

    final data = response['services'];

    if (data is! List) {
      return [];
    }

    return data
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
