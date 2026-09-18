import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../data/dummy/dummy_categories.dart';
import '../../../data/dummy/dummy_products.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/variant_option_model.dart';
import '../../../shared/app_scaffold.dart';
import '../widgets/variant_builder.dart';

/// Full product add/edit form for creators.
///
/// Fields:
///   - Nama produk
///   - Deskripsi (multiline)
///   - Kategori (dropdown, seeded from [dummyCategories])
///   - Harga (number)
///   - Upload foto (via image_picker, single thumbnail preview)
///   - Toggle "Limited Edition"
///   - Variant builder (reusing [VariantBuilder])
///
/// Edit mode: when `?id=<productId>` is provided, the form pre-fills
/// from the matching product in [dummyProducts]. Save shows a SnackBar
/// and pops the screen.
class ProductFormScreen extends StatefulWidget {
  final String productId;
  const ProductFormScreen({super.key, this.productId = ''});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _nama = TextEditingController();
  final _deskripsi = TextEditingController();
  final _harga = TextEditingController();
  String? _category;
  bool _limited = false;
  String? _photoPath;

  List<VariantOptionModel> _opts = [];
  Map<String, int> _stocks = {};

  bool get _isEdit => widget.productId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = dummyProducts.firstWhere(
        (x) => x.id == widget.productId,
        orElse: () => dummyProducts.first,
      );
      _nama.text = p.name;
      _deskripsi.text = p.description;
      _harga.text = p.price.toString();
      _category = p.categoryId;
      _limited = p.badge == BadgeType.limited;
      _opts = List.from(p.variantOptions);
      final stocks = <String, int>{};
      for (final v in p.variants) {
        stocks[v.options.join(' / ')] = v.stock;
      }
      _stocks = stocks;
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _deskripsi.dispose();
    _harga.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xfile != null) setState(() => _photoPath = xfile.path);
  }

  void _save() {
    if (_nama.text.trim().isEmpty ||
        _deskripsi.text.trim().isEmpty ||
        _category == null ||
        _harga.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi nama, deskripsi, kategori, dan harga')),
      );
      return;
    }
    final price = int.tryParse(_harga.text.trim());
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga harus berupa angka positif')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEdit ? 'Produk "${_nama.text}" diperbarui' : 'Produk "${_nama.text}" ditambahkan')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEdit ? 'Edit Produk' : 'Tambah Produk',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEdit ? 'Perbarui detail produk' : 'Isi detail produk baru', style: AppTextStyles.bodyMuted),
            const SizedBox(height: 16),
            _PhotoUploader(path: _photoPath, onPick: _pickPhoto),
            const SizedBox(height: 16),
            TextField(
              controller: _nama,
              decoration: const InputDecoration(labelText: 'Nama Produk', prefixIcon: Icon(Icons.edit_outlined)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deskripsi,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kategori', prefixIcon: Icon(Icons.category_outlined)),
              items: dummyCategories
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _harga,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga (Rp)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SwitchListTile(
                value: _limited,
                onChanged: (v) => setState(() => _limited = v),
                title: const Text('Limited Edition', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Tandai sebagai edisi terbatas', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 20),
            VariantBuilder(
              options: _opts,
              stocks: _stocks,
              onChanged: (rec) {
                setState(() {
                  _opts = rec.$1;
                  _stocks = rec.$2;
                });
              },
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: _isEdit ? 'Simpan Perubahan' : 'Tambah Produk', onPressed: _save, icon: const Icon(Icons.save_outlined, size: 18)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                label: 'Batal',
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, size: 16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PhotoUploader extends StatelessWidget {
  final String? path;
  final VoidCallback onPick;
  const _PhotoUploader({required this.path, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid, width: 2),
          boxShadow: AppShadows.soft,
          image: path != null
              ? DecorationImage(image: FileImage(File(path!)), fit: BoxFit.cover)
              : null,
        ),
        child: path == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.muted),
                const SizedBox(height: 8),
                Text('Unggah foto produk', style: AppTextStyles.label),
                Text('JPG/PNG · rasio 1:1 disarankan', style: AppTextStyles.caption),
              ])
            : null,
      ),
    );
  }
}
