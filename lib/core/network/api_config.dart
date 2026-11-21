class ApiConfig {
  /// Production API by default; override for local development with:
  /// --dart-define=API_BASE_URL=http://10.0.2.2:4000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.sesuatudarikotamalang.my.id',
  );

  static const String apiPrefix = '/api';

  static String get fullBaseUrl => '$baseUrl$apiPrefix';
}

