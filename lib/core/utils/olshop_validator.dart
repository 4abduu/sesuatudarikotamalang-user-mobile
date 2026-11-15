import '../../data/models/olshop_model.dart';

/// Domain resmi per marketplace. HARUS selaras dengan backend (lib/olshop.ts).
/// Pemeriksaan di sini hanya untuk pesan galat cepat; backend yang menentukan.
const Map<OlshopPlatform, List<String>> _roots = {
  OlshopPlatform.shopee: ['shopee.co.id', 'shp.ee'],
  OlshopPlatform.tokopedia: ['tokopedia.com', 'tokopedia.link'],
  OlshopPlatform.tiktokshop: ['tiktok.com'],
};

/// Mengembalikan pesan galat, atau null bila link lolos pemeriksaan sisi klien.
String? validateOlshopUrl(OlshopPlatform platform, String raw) {
  final value = raw.trim();
  if (value.isEmpty) return 'Link wajib diisi';
  if (value.length > 500) return 'Maksimal 500 karakter';
  if (RegExp(r'\s').hasMatch(value)) return 'Link tidak boleh mengandung spasi';
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return 'Format link salah';
  if (uri.scheme != 'https') return 'Link harus diawali https://';
  if (uri.userInfo.isNotEmpty) return 'Link tidak boleh mengandung nama pengguna/kata sandi';
  if (uri.hasPort) return 'Link tidak boleh memakai port khusus';
  final host = uri.host.toLowerCase();
  if (RegExp(r'^[\d.]+$').hasMatch(host) || host.contains(':')) return 'Link tidak boleh berupa alamat IP';
  if (host.contains('xn--')) return 'Domain tidak dikenali';
  final roots = _roots[platform]!;
  if (!roots.any((r) => host == r || host.endsWith('.$r'))) {
    return 'Domain harus milik ${platform.label} (${roots.join(', ')})';
  }
  return null;
}
