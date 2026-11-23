import '../network/api_service.dart';
import '../network/api_config.dart';
import '../network/token_storage.dart';
import '../../data/services/upload_service.dart';
import '../../data/repositories/catalog_repositories.dart';
import '../../data/repositories/upload_repository.dart';
import '../../data/repositories/cart_repository.dart';

class AppDependencies {
  AppDependencies({TokenStorage? tokenStorage, ApiService? api})
      : tokenStorage = tokenStorage ?? SharedPrefsTokenStorage() {
    this.api = api ?? ApiService(baseUrl: ApiConfig.fullBaseUrl, tokenStorage: this.tokenStorage);
    upload = UploadService(this.api);
  }

  final TokenStorage tokenStorage;
  late final ApiService api;
  late final UploadRepository upload;
  late final ProductRepository products = ProductRepository(api);
  late final CartRepository cart = CartRepository(api);
}
