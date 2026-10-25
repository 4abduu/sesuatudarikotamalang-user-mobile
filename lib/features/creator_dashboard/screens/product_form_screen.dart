import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/variant_option_model.dart';
import '../../../features/auth/widgets/auth_field.dart';
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
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../features/catalog/providers/products_provider.dart';
import '../providers/creator_dashboard_provider.dart';

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
  bool _isSaving = false;

  List<VariantOptionModel> _opts = [];
  Map<String, int> _stocks = {};

  bool get _isEdit => widget.productId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final dashboard = context.read<CreatorDashboardProvider>();
      final p = dashboard.myProducts.cast<ProductModel?>().firstWhere(
        (x) => x?.id == widget.productId,
        orElse: () => null,
      );
      if (p != null) {
        _nama.text = p.name;
        _deskripsi.text = p.description;
        _harga.text = p.price.toString();
        _category = p.categoryId;
        _limited = p.isLimited;
        _opts = List.from(p.variantOptions);
        final stocks = <String, int>{};
        for (final v in p.variants) {
          stocks[v.options.join(' / ')] = v.stock;
        }
        _stocks = stocks;
      }
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

  Future<void> _save() async {
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

    setState(() => _isSaving = true);
    try {
      final dashboard = context.read<CreatorDashboardProvider>();

      // 1. Unggah foto produk jika ada foto lokal baru yang dipilih
      List<String> imageUrls = [];
      if (_photoPath != null && _photoPath!.isNotEmpty) {
        if (_photoPath!.startsWith('http://') || _photoPath!.startsWith('https://')) {
          imageUrls.add(_photoPath!);
        } else {
          try {
            final uploadRes = await ApiClient.uploadMultipart(
              path: '/upload/single',
              fileField: 'file',
              filePath: _photoPath!,
            );
            if (uploadRes != null && uploadRes['url'] != null) {
              imageUrls.add(uploadRes['url'] as String);
            }
          } catch (uploadErr) {
            // Jika upload gagal, tetap lanjut atau beri info
            debugPrint('Upload gambar gagal: $uploadErr');
          }
        }
      }

      // 2. Siapkan opsi varian & kombinasi stok
      List<Map<String, dynamic>>? variantOptionsPayload;
      List<Map<String, dynamic>>? variantStocksPayload;

      final validOpts = _opts.where((o) => o.name.trim().isNotEmpty && o.values.isNotEmpty).toList();
      if (validOpts.isNotEmpty) {
        variantOptionsPayload = validOpts.map((o) => {
          'name': o.name.trim(),
          'values': o.values,
        }).toList();

        // Buat kombinasi Cartesian dari opsi yang valid
        var combos = [[]];
        for (final o in validOpts) {
          combos = combos.expand((r) => o.values.map((v) => [...r, v])).toList();
        }

        variantStocksPayload = combos.map((c) {
          final comboList = c.cast<String>();
          final key = comboList.join(' / ');
          final stockVal = _stocks[key] ?? 0;
          return {
            'combination': comboList,
            'stock': stockVal,
          };
        }).toList();
      }

      if (_isEdit) {
        await dashboard.updateProduct(
          id: widget.productId,
          name: _nama.text.trim(),
          categoryId: _category,
          description: _deskripsi.text.trim(),
          price: price,
          images: imageUrls.isNotEmpty ? imageUrls : null,
          isLimited: _limited,
        );
      } else {
        await dashboard.createProduct(
          name: _nama.text.trim(),
          categoryId: _category!,
          price: price,
          description: _deskripsi.text.trim(),
          images: imageUrls,
          isLimited: _limited,
          stock: variantStocksPayload != null && variantStocksPayload.isNotEmpty ? null : 10,
          variantOptions: variantOptionsPayload,
          variantStocks: variantStocksPayload,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Produk "${_nama.text}" diperbarui' : 'Produk "${_nama.text}" ditambahkan')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan produk: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEdit ? 'Edit Produk' : 'Tambah Produk',
      showBottomNav: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEdit ? 'Perbarui detail produk' : 'Isi detail produk baru', style: AppTextStyles.bodyMuted),
            const SizedBox(height: 16),
            _PhotoUploader(path: _photoPath, onPick: _pickPhoto),
            const SizedBox(height: 16),
            AuthField(controller: _nama, label: 'Nama Produk', icon: Icons.edit_outlined),
            const SizedBox(height: 16),
            AuthField(controller: _deskripsi, label: 'Deskripsi', icon: Icons.description_outlined, maxLines: 4),
            const SizedBox(height: 16),
            Consumer<ProductsProvider>(
              builder: (context, prodProv, _) {
                final categories = prodProv.categories;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Kategori', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    isDense: true,
                    isExpanded: true,
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.foreground),
                    dropdownColor: AppColors.surface,
                    icon: const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.keyboard_arrow_down, size: 12, color: AppColors.muted)),
                    decoration: authInputDecoration(icon: Icons.category_outlined),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v),
                  ),
                ]);
              },
            ),
            const SizedBox(height: 16),
            AuthField(controller: _harga, label: 'Harga (Rp)', icon: Icons.payments_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                activeThumbColor: AppColors.onPrimary,
                activeTrackColor: AppColors.primary,
                inactiveThumbColor: AppColors.onPrimary,
                inactiveTrackColor: AppColors.border,
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            PrimaryButton(
              label: _isSaving
                  ? 'Menyimpan...'
                  : (_isEdit ? 'Simpan Perubahan' : 'Tambah Produk'),
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.check, size: 16),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  textStyle: GoogleFonts.baloo2(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Batal'),
              ),
            ),
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
                const Icon(Icons.photo_camera_outlined, size: 36, color: AppColors.muted),
                const SizedBox(height: 8),
                Text('Unggah foto produk', style: GoogleFonts.baloo2(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                Text('JPG/PNG · rasio 1:1 disarankan', style: AppTextStyles.caption),
              ])
            : null,
      ),
    );
  }
}
