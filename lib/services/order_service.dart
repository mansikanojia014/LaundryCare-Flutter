import '../config/api_config.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> createOrder({
    required String pickupAddressId,
    required String deliveryAddressId,
    required String pickupDate,
    required String pickupTime,
    required String dropoffDate,
    required String dropoffTime,
    required List<Map<String, dynamic>> items,
    String? discountCode,
    required String paymentMethod,
    String? upiTransactionId,
    String? notes,
  }) async {
    final response = await _api.post(
      ApiConfig.orders,
      body: {
        'pickupAddressId': pickupAddressId,
        'deliveryAddressId': deliveryAddressId,
        'pickupDate': pickupDate,
        'pickupTime': pickupTime,
        'dropoffDate': dropoffDate,
        'dropoffTime': dropoffTime,
        'items': items,
        if (discountCode != null &&
            discountCode.trim().isNotEmpty)
          'discountCode': discountCode.trim(),
        'paymentMethod': paymentMethod,
        if (upiTransactionId != null &&
            upiTransactionId.trim().isNotEmpty)
          'upiTransactionId': upiTransactionId.trim(),
        if (notes != null && notes.trim().isNotEmpty)
          'notes': notes.trim(),
      },
    );

    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMyOrders() async {
    final response = await _api.get(ApiConfig.orders);

    final data = response['orders'];

    if (data is! List) {
      return [];
    }

    return data
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> getOrderDetails(
    String orderId,
  ) async {
    final response = await _api.get(
      '${ApiConfig.orders}/$orderId',
    );

    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> cancelOrder(
    String orderId,
  ) async {
    final response = await _api.patch(
      '${ApiConfig.orders}/$orderId/cancel',
    );

    return Map<String, dynamic>.from(response);
  }
}
