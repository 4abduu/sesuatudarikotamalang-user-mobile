import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/upload_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/photo_rules.dart';
import '../../../core/widgets/photo_editor.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/variant_option_model.dart';
import '../../../features/auth/widgets/auth_field.dart';
import '../../../features/catalog/providers/products_provider.dart';
import '../../../shared/app_scaffold.dart';
import '../providers/creator_dashboard_provider.dart';
import '../widgets/variant_builder.dart';

class ProductFormScreen extends StatefulWidget {
  final String productId;
  final String replaceOf;
  const ProductFormScreen({super.key, this.productId = '', this.replaceOf = ''});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _nama = TextEditingController();
  final _deskripsi = TextEditingController();
  final _harga = TextEditingController();
  String? _category;
  bool _limited = false;
  bool _isSaving = false;

  List<PhotoItem> _photos = [];
  List<PhotoItem> _initialPhotos = [];
  Set<String> _rejectedKeys = {};

  List<VariantOptionModel> _opts = [];
  Map<String, int> _stocks = {};

  bool get _isEdit => widget.productId.isNotEmpty;
  bool get _isPhotosDirty => !photoListsEqual(_photos, _initialPhotos);

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

        _initialPhotos = photoItemsFromServer(p.images, p.imageVariants);
        _photos = List.of(_initialPhotos);
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

  List<VariantChoice>? _variantChoices() {
    final validOpts = _opts.where((o) => o.name.trim().isNotEmpty && o.values.isNotEmpty).toList();
    if (validOpts.isEmpty) return null;
    return validOpts.map((o) => VariantChoice(o.name.trim(), List.of(o.values))).toList();
  }

  void _pruneOrphanedVariantLinks(List<VariantOptionModel> newOpts) {
    bool pruned = false;
    final updated = _photos.map((item) {
      if (item.variantOption == null || item.variantValue == null) return item;
      final matchedOpt = newOpts.cast<VariantOptionModel?>().firstWhere(
        (o) => o?.name.trim() == item.variantOption,
        orElse: () => null,
      );
      if (matchedOpt == null || !matchedOpt.values.contains(item.variantValue)) {
        pruned = true;
        return item.withoutVariant();
      }
      return item;
    }).toList();

    if (pruned) {
      setState(() => _photos = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan foto ke varian yang dihapus telah dilepas')),
      );
    }
  }

  Future<bool> _handlePopScope() async {
    if (!_isPhotosDirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buang perubahan foto?'),
        content: const Text('Perubahan foto yang belum disimpan akan hilang.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
    return discard ?? false;
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

    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk harus punya minimal satu foto')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final photoChanged = _isPhotosDirty;
    PhotoSyncResult? sync;
    final dashboard = context.read<CreatorDashboardProvider>();

    try {
      if (!_isEdit || photoChanged) {
        try {
          sync = await syncPhotos(_photos);
        } on ApiException catch (e) {
          if (mounted) {
            if (e.code == 'IMAGE_REJECTED') {
              final newPhotos = _photos.where((p) => p.file != null).toList();
              final rejected = <String>{};
              for (final idx in e.rejectedIndexes) {
                if (idx >= 0 && idx < newPhotos.length) {
                  rejected.add(newPhotos[idx].key);
                }
              }
              setState(() => _rejectedKeys = rejected);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ada foto yang tidak pantas. Hapus foto bertanda merah lalu coba lagi.')),
              );
            } else if (e.code == 'MODERATION_UNAVAILABLE') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pemeriksaan foto sedang tidak tersedia. Coba lagi nanti.')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Foto gagal diunggah: ${e.message}')),
              );
            }
          }
          return;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Foto gagal diunggah: $e')),
            );
          }
          return;
        }
      }

      // Siapkan opsi varian & kombinasi stok
      List<Map<String, dynamic>>? variantOptionsPayload;
      List<Map<String, dynamic>>? variantStocksPayload;

      final validOpts = _opts.where((o) => o.name.trim().isNotEmpty && o.values.isNotEmpty).toList();
      if (validOpts.isNotEmpty) {
        variantOptionsPayload = validOpts.map((o) => {
          'name': o.name.trim(),
          'values': o.values,
        }).toList();

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
          images: photoChanged ? sync!.images : null,
          imageVariants: photoChanged ? sync!.imageVariants : null,
          isLimited: _limited,
        );
      } else {
        await dashboard.createProduct(
          name: _nama.text.trim(),
          categoryId: _category!,
          price: price,
          description: _deskripsi.text.trim(),
          images: sync?.images ?? [],
          imageVariants: sync != null && sync.imageVariants.isNotEmpty ? sync.imageVariants : null,
          isLimited: _limited,
          stock: variantStocksPayload != null && variantStocksPayload.isNotEmpty ? null : 10,
          variantOptions: variantOptionsPayload,
          variantStocks: variantStocksPayload,
          replacesProductId: widget.replaceOf.isEmpty ? null : widget.replaceOf,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Produk "${_nama.text}" diperbarui' : 'Produk terkirim dan menunggu persetujuan admin.')),
        );
        context.pop();
      }
    } on ApiException catch (e) {
      if (sync != null && sync.newlyUploaded.isNotEmpty) {
        await UploadApi.deleteUrls(sync.newlyUploaded);
      }
      if (mounted) {
        if (e.code == 'REPLACEMENT_ALREADY_EXISTS') {
          await dashboard.fetchDashboardData();
        }
        if (!mounted) return;
        final msg = e.code == 'PRODUCT_LOCKED'
            ? (e.message.isNotEmpty ? e.message : 'Produk ini terkunci dan tidak dapat diubah lagi.')
            : (e.message.isNotEmpty ? e.message : 'Gagal menyimpan produk');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (sync != null && sync.newlyUploaded.isNotEmpty) {
        await UploadApi.deleteUrls(sync.newlyUploaded);
      }
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
    return PopScope(
      canPop: !_isPhotosDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _handlePopScope();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: AppScaffold(
        title: _isEdit ? 'Edit Produk' : 'Tambah Produk',
        showBottomNav: false,
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isEdit ? 'Perbarui detail produk' : 'Isi detail produk baru', style: AppTextStyles.bodyMuted),
              const SizedBox(height: 16),
              PhotoEditor(
                items: _photos,
                onChanged: (v) => setState(() {
                  _photos = v;
                  _rejectedKeys.removeWhere((k) => !v.any((item) => item.key == k));
                }),
                maxPhotos: PhotoRules.maxProductPhotos,
                variantChoices: _variantChoices(),
                label: 'Foto produk (wajib, min. 1)',
                dirty: _isPhotosDirty,
                onReset: () => setState(() => _photos = List.of(_initialPhotos)),
                rejectedKeys: _rejectedKeys,
              ),
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
                  _pruneOrphanedVariantLinks(rec.$1);
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
                  onPressed: () async {
                    final shouldPop = await _handlePopScope();
                    if (shouldPop && context.mounted) {
                      context.pop();
                    }
                  },
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
      ),
    );
  }
}
