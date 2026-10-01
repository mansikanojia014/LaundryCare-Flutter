import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  bool _isLoading = false;
  bool _isAuthenticated = false;

  Map<String, dynamic>? _user;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;

  String? get userRole {
    final role = _user?['role'];
    return role?.toString();
  }

  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      final token = await _storage.read(key: 'jwt_token');

      if (token == null || token.isEmpty) {
        _isAuthenticated = false;
        return;
      }

      final response = await _authService.getCurrentUser();

      if (response['success'] == true) {
        _user = response['user'];
        _isAuthenticated = true;
      } else {
        await logout();
      }
    } catch (_) {
      await logout();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    String? role,
    bool rememberLogin = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
        role: role,
        rememberLogin: rememberLogin,
      );

      if (response['success'] != true) {
        _errorMessage =
            response['message']?.toString() ??
            'Login failed';
        return false;
      }

      final token = response['token']?.toString();

      if (token == null || token.isEmpty) {
        _errorMessage = 'Authentication token was not received';
        return false;
      }

      await _storage.delete(key: 'jwt_token');
      if (rememberLogin) {
        await _storage.write(
          key: 'jwt_token',
          value: token,
        );
      }

      _user = response['user'];
      _isAuthenticated = true;

      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      );

      if (response['success'] != true) {
        _errorMessage =
            response['message']?.toString() ??
            'Registration failed';
        return false;
      }

      final token = response['token']?.toString();

      if (token != null && token.isNotEmpty) {
        await _storage.write(
          key: 'jwt_token',
          value: token,
        );

        _user = response['user'];
        _isAuthenticated = true;
      }

      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');

    _user = null;
    _isAuthenticated = false;
    _errorMessage = null;

    notifyListeners();
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
