import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/auth/widgets/auth_field.dart';
import '../../../../features/auth/widgets/auth_gate_bottom_sheet.dart';
import '../../../../features/account/providers/applications_provider.dart';
import '../../../../features/catalog/providers/products_provider.dart';
import '../../../../shared/app_scaffold.dart';

class CreatorApplicationFormScreen extends StatefulWidget {
  const CreatorApplicationFormScreen({super.key});
  @override
  State<CreatorApplicationFormScreen> createState() => _CreatorApplicationFormScreenState();
}

class _CreatorApplicationFormScreenState extends State<CreatorApplicationFormScreen> {
  final _nama = TextEditingController();
  final _wa = TextEditingController();
  final _brand = TextEditingController();
  final _desc = TextEditingController();
  String? _category;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nama.text = auth.user?.name ?? '';
    _wa.text = auth.user?.email ?? '';
  }

  @override
  void dispose() { _nama.dispose(); _wa.dispose(); _brand.dispose(); _desc.dispose(); super.dispose(); }

  bool _isSubmitting = false;

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      showAuthGateSheet(context, next: '/daftar-kreator', contextLabel: 'mendaftar jadi kreator');
      return;
    }
    if (_nama.text.trim().isEmpty || _brand.text.trim().isEmpty || _desc.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi semua field')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final app = await context.read<ApplicationsProvider>().apply(
        applicantName: _nama.text.trim(),
        contact: _wa.text.trim(),
        brandName: _brand.text.trim(),
        description: _desc.text.trim(),
        categoryId: _category,
      );
      auth.setApplication(app.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan terkirim! Tim kami akan mengkurasi.')));
        context.go('/akun/pengajuan');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim pengajuan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isGuest = !auth.isAuthenticated;
    final isCreator = auth.isCreator;
    return AppScaffold(
      title: 'Jadi Kreator',
      showBottomNav: false,
      body: Stack(children: [
        Opacity(opacity: isGuest ? 0.4 : 1.0, child: AbsorbPointer(absorbing: isGuest, child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (isCreator) ...[
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              const Icon(Icons.check_circle, size: 48, color: AppColors.moss),
              const SizedBox(height: 8),
              Text('Kamu Sudah Menjadi Kreator', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              PrimaryButton(label: 'Buka Dashboard Kreator', onPressed: () => context.push('/dashboard-kreator')),
            ]))),
          ] else ...[
            Text('Daftar Konsinyasi Karyamu', style: AppTextStyles.h1),
            const SizedBox(height: 4),
            Text('Konsinyasikan karyamu di toko fisik Kayutangan.', style: AppTextStyles.bodyMuted),
            const SizedBox(height: 12),
            AuthField(controller: _nama, label: 'Nama Lengkap', icon: Icons.person_outline),
            const SizedBox(height: 12),
            AuthField(controller: _wa, label: 'Kontak / WhatsApp', icon: Icons.phone_outlined),
            const SizedBox(height: 12),
            AuthField(controller: _brand, label: 'Nama Brand / Karya', icon: Icons.storefront_outlined),
            const SizedBox(height: 12),
            Builder(
              builder: (ctx) {
                final cats = ctx.watch<ProductsProvider>().categories;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Kategori Utama', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    isDense: true,
                    isExpanded: true,
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.foreground),
                    dropdownColor: AppColors.surface,
                    icon: const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.muted)),
                    decoration: authInputDecoration(icon: Icons.category_outlined),
                    items: cats
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v),
                  ),
                ]);
              },
            ),
            const SizedBox(height: 12),
            AuthField(controller: _desc, label: 'Deskripsi Produk / Karya', maxLines: 4),
            const SizedBox(height: 12),
            _PhotoDropzone(),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isSubmitting ? 'Mengirim...' : 'Kirim Pengajuan',
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ])))),
        if (isGuest) Positioned.fill(child: Container(color: AppColors.background.withValues(alpha: 0.3), child: Center(child: Card(margin: const EdgeInsets.all(32), child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Text('Masuk untuk melanjutkan', style: AppTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Kamu perlu masuk untuk mendaftar jadi kreator.', style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Masuk / Daftar', onPressed: () => showAuthGateSheet(context, next: '/daftar-kreator', contextLabel: 'mendaftar jadi kreator')),
        ])))))),
      ]),
    );
  }
}

class _PhotoDropzone extends StatefulWidget {
  @override
  State<_PhotoDropzone> createState() => _PhotoDropzoneState();
}

class _PhotoDropzoneState extends State<_PhotoDropzone> {
  String? _photoPath;

  Future<void> _pick() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xfile != null) setState(() => _photoPath = xfile.path);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photoPath != null;
    return GestureDetector(
      onTap: _pick,
      child: CustomPaint(
        // Border putus-putus 2px (border-dashed TSX), tanpa shadow.
        foregroundPainter: const _DashedBorderPainter(color: AppColors.border, radius: 12, strokeWidth: 2),
        child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface,
          image: hasPhoto ? DecorationImage(image: FileImage(File(_photoPath!)), fit: BoxFit.cover) : null,
        ),
        child: hasPhoto
          ? Stack(children: [
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _photoPath = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.destructive, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 16, color: AppColors.onPrimary),
                  ),
                ),
              ),
            ])
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.upload_outlined, size: 32, color: AppColors.muted),
              const SizedBox(height: 4),
              Text('Klik untuk unggah foto sampel', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.muted)),
              Text('JPG/PNG · visual saja', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.muted)),
            ]),
      ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  const _DashedBorderPainter({required this.color, required this.radius, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rect = Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    const dash = 6.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color || old.radius != radius || old.strokeWidth != strokeWidth;
}
