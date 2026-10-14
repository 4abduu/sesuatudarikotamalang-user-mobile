class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String blurb;
  final String iconName;
  final String imagePath;

  const CategoryModel({
    required this.id,
    required this.name,
    this.slug = '',
    this.blurb = '',
    this.iconName = '',
    this.imagePath = '',
  });

  factory CategoryModel.fromJson(Map<String, dynamic> j) {
    return CategoryModel(
      id: j['id'] ?? '',
      name: j['name'] ?? '',
      slug: j['slug'] ?? '',
      blurb: j['blurb'] ?? '',
      iconName: j['iconName'] ?? '',
      imagePath: j['imagePath'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'blurb': blurb,
    'iconName': iconName,
    'imagePath': imagePath,
  };
}
