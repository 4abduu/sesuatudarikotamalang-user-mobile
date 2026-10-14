class ApiConfig {
  /// Base URL API Backend:
  /// - Emulator Android: http://10.0.2.2:4000
  /// - Perangkat fisik / Web / Desktop: http://localhost:4000 atau ganti dengan IP LAN laptop backend
  static const String baseUrl = 'http://10.0.2.2:4000';

  static const String apiPrefix = '/api';

  static String get fullBaseUrl => '$baseUrl$apiPrefix';
}
