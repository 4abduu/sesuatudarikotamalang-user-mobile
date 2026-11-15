import 'dart:ui' show Color;

/// Marketplace (olshop) yang didukung. `name` dipakai sebagai id di API dan nama berkas logo.
enum OlshopPlatform { shopee, tokopedia, tiktokshop }

/// Mode per marketplace pada sebuah produk:
/// tidak = tidak dijual di sana, toko = pakai link toko dari admin, khusus = link khusus produk.
enum OlshopMode { tidak, toko, khusus }

extension OlshopPlatformX on OlshopPlatform {
  String get id => name;

  String get label => switch (this) {
        OlshopPlatform.shopee => 'Shopee',
        OlshopPlatform.tokopedia => 'Tokopedia',
        OlshopPlatform.tiktokshop => 'TikTok Shop',
      };

  String get initial => switch (this) {
        OlshopPlatform.shopee => 'S',
        OlshopPlatform.tokopedia => 'T',
        OlshopPlatform.tiktokshop => 'TT',
      };

  /// Warna khas marketplace (border tombol dan lencana cadangan).
  Color get color => switch (this) {
        OlshopPlatform.shopee => const Color(0xFFEE4D2D),
        OlshopPlatform.tokopedia => const Color(0xFF03AC0E),
        OlshopPlatform.tiktokshop => const Color(0xFF111111),
      };

  /// Berkas logo: taruh PNG di assets/images/olshop/<id>.png (mis. shopee.png).
  String get assetPath => 'assets/images/olshop/$id.png';
}

OlshopPlatform? olshopPlatformFromId(String? v) {
  for (final p in OlshopPlatform.values) {
    if (p.id == v) return p;
  }
  return null;
}

OlshopMode olshopModeFromId(String? v) {
  for (final m in OlshopMode.values) {
    if (m.name == v) return m;
  }
  return OlshopMode.tidak;
}

/// Link siap tampil yang dihitung backend (`olshopLinks` pada respons produk).
class OlshopLink {
  final OlshopPlatform platform;
  final String url;

  /// true bila ini link halaman toko (produk tidak punya link khusus) -> tampilkan peringatan.
  final bool isStoreFallback;

  const OlshopLink({required this.platform, required this.url, required this.isStoreFallback});

  static OlshopLink? fromJson(Map<String, dynamic> j) {
    final platform = olshopPlatformFromId(j['platform']?.toString());
    final url = j['url']?.toString() ?? '';
    if (platform == null || url.isEmpty) return null;
    return OlshopLink(platform: platform, url: url, isStoreFallback: j['isStoreFallback'] == true);
  }
}

/// Pengaturan mentah satu marketplace pada sebuah produk (dipakai form kreator).
class OlshopSetting {
  final OlshopMode mode;
  final String url;
  const OlshopSetting({this.mode = OlshopMode.tidak, this.url = ''});
}

bool olshopSettingsEqual(Map<OlshopPlatform, OlshopSetting> a, Map<OlshopPlatform, OlshopSetting> b) {
  for (final p in OlshopPlatform.values) {
    final x = a[p] ?? const OlshopSetting();
    final y = b[p] ?? const OlshopSetting();
    if (x.mode != y.mode) return false;
    if (x.mode == OlshopMode.khusus && x.url.trim() != y.url.trim()) return false;
  }
  return true;
}

/// Bentuk body request: { shopee: {mode, url?}, tokopedia: {...}, tiktokshop: {...} }
Map<String, dynamic> olshopPayload(Map<OlshopPlatform, OlshopSetting> value) {
  final out = <String, dynamic>{};
  for (final p in OlshopPlatform.values) {
    final s = value[p] ?? const OlshopSetting();
    out[p.id] = s.mode == OlshopMode.khusus
        ? {'mode': 'khusus', 'url': s.url.trim()}
        : {'mode': s.mode.name};
  }
  return out;
}
