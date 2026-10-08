class CategoryModel {
  final String id;
  final String name;
  final String blurb;
  final String iconName; // lucide icon name
  
  // ===============================================================
  // OPTION GAMBAR FIGMA: Tambahan field imagePath untuk aset gambar.
  // Jika ingin versi awal tanpa imagePath, bisa dikomentari baris ini.
  // ===============================================================
  final String imagePath;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.blurb,
    required this.iconName,
    this.imagePath = '', // default value agar kompatibel dengan versi awal
  });
}
