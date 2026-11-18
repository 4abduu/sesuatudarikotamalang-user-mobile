import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/config/google_config.dart';
import '../../core/network/api_exception.dart';

class GoogleAuthService {
  Future<String> signIn() async {
    if (GoogleConfig.webClientId.isEmpty || GoogleConfig.webClientId.startsWith('GANTI')) {
      throw ApiException(0, 'Google Client ID belum diisi. Silakan masukkan Client ID di lib/core/config/google_config.dart.');
    }
    final googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? GoogleConfig.webClientId : null,
      serverClientId: kIsWeb ? null : GoogleConfig.webClientId,
      scopes: ['email', 'profile'],
    );
    await googleSignIn.signOut();
    final account = await googleSignIn.signIn();
    if (account == null) throw ApiException(0, 'Login Google dibatalkan');
    final idToken = (await account.authentication).idToken;
    if (idToken == null) throw ApiException(0, 'Gagal mendapatkan token Google. Pastikan Web Client ID sudah dikonfigurasi.');
    return idToken;
  }
}
