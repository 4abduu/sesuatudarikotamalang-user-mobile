/// Tautan satu foto produk ke satu nilai varian (`imageVariants` di API).
class ImageVariantLink {
  final String url;
  final List<Map<String, String>> combination;
  final String legacyOption;
  final String legacyValue;

  const ImageVariantLink({
    required this.url,
    this.combination = const [],
    String option = '',
    String value = '',
  })  : legacyOption = option,
        legacyValue = value;

  /// Compatibility accessors for legacy one-axis links.
  String get option => combination.length == 1 ? combination.first['option'] ?? '' : legacyOption;
  String get value => combination.length == 1 ? combination.first['value'] ?? '' : legacyValue;

  factory ImageVariantLink.fromJson(Map<String, dynamic> j) {
    final raw = j['combination'];
    final combination = raw is List
        ? raw.whereType<Map>().map((e) => {
              'option': (e['option'] ?? '').toString(),
              'value': (e['value'] ?? '').toString(),
            }).where((e) => e['option']!.isNotEmpty && e['value']!.isNotEmpty).toList()
        : <Map<String, String>>[];
    if (combination.isEmpty && j['option'] != null && j['value'] != null) {
      final option = j['option'].toString();
      final value = j['value'].toString();
      if (option.isNotEmpty && value.isNotEmpty) combination.add({'option': option, 'value': value});
    }
    return ImageVariantLink(url: (j['url'] ?? '').toString(), combination: combination);
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'combination': combination,
      };
}
