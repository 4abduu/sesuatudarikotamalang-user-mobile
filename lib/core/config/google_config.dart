/// Konfigurasi Google Sign-In.
///
/// LANGKAH: Ganti nilai di bawah dengan client ID dari Google Cloud Console.
///   - Android: OAuth 2.0 Client ID tipe "Android"
///   - iOS    : OAuth 2.0 Client ID tipe "iOS"
///   - Web    : OAuth 2.0 Client ID tipe "Web application"
///
/// Cara mendapatkannya:
///   1. Buka https://console.cloud.google.com/
///   2. Pilih project → APIs & Services → Credentials
///   3. Buat / salin Client ID sesuai platform
///   4. Isi nilai di bawah, jangan commit file ini ke repo publik
class GoogleConfig {
  /// Web Client ID (digunakan di Flutter Web & sebagai serverClientId di Android/iOS).
  /// Contoh: "1234567890-abc123xyz.apps.googleusercontent.com"
  static const String webClientId = '823022009356-flkshob7sarasbhna69v3na22vhrj56o.apps.googleusercontent.com';
}
