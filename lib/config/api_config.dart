class ApiConfig {
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String me = '$baseUrl/auth/me';

  static const String passwordResetRequest =
      '$baseUrl/password-reset/request';

  static const String passwordReset =
      '$baseUrl/password-reset/reset';

  static const String profile =
      '$baseUrl/customer/profile';

  static const String addresses =
      '$baseUrl/addresses';

  static const String services =
      '$baseUrl/services';

  static const String clothTypes =
      '$baseUrl/cloth-types';

  static const String discounts =
      '$baseUrl/discounts';

  static const String orders =
      '$baseUrl/orders';

  static const String notifications =
      '$baseUrl/notifications';

  static const String employees =
      '$baseUrl/business/employees';

  static const String businessSettings =
      '$baseUrl/business/settings';

  static const String businessCustomers =
      '$baseUrl/business/customers';

  static const String businessReports =
      '$baseUrl/business/reports';

  static const String businessServices =
      '$baseUrl/business/services';

  static const String businessClothTypes =
      '$baseUrl/business/cloth-types';

  static const String businessDiscounts =
      '$baseUrl/business/discounts';
}





