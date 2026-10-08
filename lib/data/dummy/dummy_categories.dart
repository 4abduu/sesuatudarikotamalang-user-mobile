import '../models/category_model.dart';

// ===============================================================
// OPTION 1 (UTAMA): Kodingan Awal (Tanpa imagePath / Menggunakan Icon)
// ===============================================================
final List<CategoryModel> dummyCategories = [
  const CategoryModel(
    id: 'postcard',
    name: 'Postcard',
    blurb: 'Kartu pos ilustrasi tangan',
    iconName: 'mail',
    // imagePath: 'assets/images/categories/postcard.png', // Un-comment jika menggunakan gambar
  ),
  const CategoryModel(
    id: 'pin-enamel',
    name: 'Pin Enamel',
    blurb: 'Pin kecil bertema lokal',
    iconName: 'circle-dot',
    // imagePath: 'assets/images/categories/pin_enamel.png',
  ),
  const CategoryModel(
    id: 'apparel',
    name: 'Apparel',
    blurb: 'Kaos & kaos tangan',
    iconName: 'shirt',
    // imagePath: 'assets/images/categories/apparel.png',
  ),
  const CategoryModel(
    id: 'stiker',
    name: 'Stiker',
    blurb: 'Stiker vinyl ornamen',
    iconName: 'sticker',
    // imagePath: 'assets/images/categories/stiker.png',
  ),
  const CategoryModel(
    id: 'kriya-kayu',
    name: 'Kriya Kayu',
    blurb: 'Gantungan & hiasan kayu',
    iconName: 'tree-pine',
    // imagePath: 'assets/images/categories/kriya_kayu.png',
  ),
  const CategoryModel(
    id: 'tote-bag',
    name: 'Tote Bag',
    blurb: 'Tas kanvas hasil sablon',
    iconName: 'shopping-bag',
    // imagePath: 'assets/images/categories/tote_bag.png',
  ),
  const CategoryModel(
    id: 'keramik',
    name: 'Keramik',
    blurb: 'Mug & pinjtan tanah liat',
    iconName: 'coffee',
    // imagePath: 'assets/images/categories/keramik.png',
  ),
  const CategoryModel(
    id: 'zine',
    name: 'Zine',
    blurb: 'Buku kecil cerita kota',
    iconName: 'book-open',
    // imagePath: 'assets/images/categories/zine.png',
  ),
];
