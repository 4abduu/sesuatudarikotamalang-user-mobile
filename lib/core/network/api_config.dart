import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Base URL API Backend:
  /// - Web / Desktop / Localhost: http://localhost:4000
  /// - Emulator Android: http://10.0.2.2:4000
  static String get baseUrl => kIsWeb ? 'http://localhost:4000' : 'http://10.0.2.2:4000';

  static const String apiPrefix = '/api';

  static String get fullBaseUrl => '$baseUrl$apiPrefix';
}

