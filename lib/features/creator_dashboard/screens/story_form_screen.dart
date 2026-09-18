import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../data/dummy/dummy_products.dart';
import '../../../shared/app_scaffold.dart';

/// Form to add/edit the "Behind the Design" story for a product.
///
/// Fields:
///   - Judul cerita
///   - Isi cerita (multiline)
///   - Upload foto proses (image_picker, multiple; thumbnails shown)
///
/// Edit mode: when `?productId=<id>` matches a product with an
/// existing story, pre-fill the title and body. Save → SnackBar + pop.
class StoryFormScreen extends StatefulWidget {
  final String productId;
  const StoryFormScreen({super.key, this.productId = ''});

  @override
  State<StoryFormScreen> createState() => _StoryFormScreenState();
}

class _StoryFormScreenState extends State<StoryFormScreen> {
  final _judul = TextEditingController();
  final _isi = TextEditingController();
  final List<String> _photos = [];
  String _productName = '';
  bool get _isEdit => _judul.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.productId.isNotEmpty) {
      final p = dummyProducts.firstWhere(
        (x) => x.id == widget.productId,
        orElse: () => dummyProducts.first,
      );
      _productName = p.name;
      if (p.hasStory) {
        _judul.text = p.story!.title;
        _isi.text = p.story!.body;
      }
    }
  }

  @override
  void dispose() {
    _judul.dispose();
    _isi.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 80);
    if (files.isNotEmpty) {
      setState(() => _photos.addAll(files.map((f) => f.path)));
    }
  }

  void _save() {
    if (_judul.text.trim().isEmpty || _isi.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan isi cerita wajib diisi')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEdit ? 'Cerita "${_judul.text}" diperbarui' : 'Cerita "${_judul.text}" ditambahkan')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEdit ? 'Edit Cerita' : 'Tambah Cerita',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_productName.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.moss.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.moss),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Untuk produk: $_productName', style: AppTextStyles.caption)),
                ]),
              ),
              const SizedBox(height: 16),
            ],
            Text('Judul Cerita', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextField(
              controller: _judul,
              decoration: const InputDecoration(hintText: 'cth: Jendela yang Nggak Pernah Ketutup'),
            ),
            const SizedBox(height: 16),
            Text('Isi Cerita', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextField(
              controller: _isi,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Ceritakan inspirasi di balik karya ini...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Text('Foto Proses Pembuatan', style: AppTextStyles.label),
            const SizedBox(height: 6),
            Text('Unggah beberapa foto proses (opsional)', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            _PhotoGallery(photos: _photos, onPick: _pickPhoto, onRemove: (i) => setState(() => _photos.removeAt(i))),
            const SizedBox(height: 24),
            PrimaryButton(label: _isEdit ? 'Simpan Perubahan' : 'Tambah Cerita', onPressed: _save, icon: const Icon(Icons.save_outlined, size: 18)),
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

class _PhotoGallery extends StatelessWidget {
  final List<String> photos;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;
  const _PhotoGallery({required this.photos, required this.onPick, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...photos.asMap().entries.map((e) {
          return Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(image: FileImage(File(e.value)), fit: BoxFit.cover),
                  boxShadow: AppShadows.soft,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => onRemove(e.key),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: AppColors.destructive, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 14, color: AppColors.onPrimary),
                  ),
                ),
              ),
            ],
          );
        }),
        GestureDetector(
          onTap: onPick,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, style: BorderStyle.solid, width: 1.5),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, size: 24, color: AppColors.muted),
                SizedBox(height: 4),
                Text('Tambah', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
