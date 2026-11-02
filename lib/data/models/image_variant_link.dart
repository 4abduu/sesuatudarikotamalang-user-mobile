/// Tautan satu foto produk ke satu nilai varian (`imageVariants` di API).
class ImageVariantLink {
  final String url;
  final String option;
  final String value;

  const ImageVariantLink({required this.url, required this.option, required this.value});

  factory ImageVariantLink.fromJson(Map<String, dynamic> j) => ImageVariantLink(
        url: (j['url'] ?? '').toString(),
        option: (j['option'] ?? '').toString(),
        value: (j['value'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {'url': url, 'option': option, 'value': value};
}
