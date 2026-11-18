import '../network/api_service.dart';
import '../network/api_config.dart';
import '../network/token_storage.dart';
import '../../data/services/upload_service.dart';

class AppDependencies {
  AppDependencies({TokenStorage? tokenStorage, ApiService? api})
      : tokenStorage = tokenStorage ?? SharedPrefsTokenStorage(),
        api = api ?? ApiService(baseUrl: ApiConfig.fullBaseUrl, tokenStorage: tokenStorage ?? SharedPrefsTokenStorage()) {
    upload = UploadService(this.api);
  }

  final TokenStorage tokenStorage;
  final ApiService api;
  late final UploadService upload;
}
