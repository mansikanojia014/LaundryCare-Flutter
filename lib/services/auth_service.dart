import '../config/api_config.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? role,
    bool rememberLogin = false,
  }) async {
    final response = await _api.post(
      ApiConfig.login,
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': ?role,
        'rememberLogin': rememberLogin,
      },
    );

    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await _api.post(
      ApiConfig.register,
      body: {
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'phone': ?phone?.trim(),
      },
    );

    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _api.get(ApiConfig.me);

    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    final response = await _api.post(
      ApiConfig.passwordResetRequest,
      body: {
        'email': email.trim().toLowerCase(),
      },
    );

    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
  }) async {
    final response = await _api.post(
      ApiConfig.passwordReset,
      body: {
        'token': token,
        'password': password,
      },
    );

    return Map<String, dynamic>.from(response);
  }
}
