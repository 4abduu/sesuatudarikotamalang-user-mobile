import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/dummy/dummy_categories.dart';
import '../../../data/models/creator_application_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/widgets/auth_gate_bottom_sheet.dart';
import '../../../features/account/providers/applications_provider.dart';
import '../../../shared/app_scaffold.dart';

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

  void _submit() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) { showAuthGateSheet(context, next: '/daftar-kreator', contextLabel: 'mendaftar jadi kreator'); return; }
    if (_nama.text.trim().isEmpty || _brand.text.trim().isEmpty || _desc.text.trim().isEmpty || _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi semua field')));
      return;
    }
    final app = CreatorApplicationModel(
      id: 'app-${DateTime.now().millisecondsSinceEpoch}', userId: auth.user!.id,
      applicantName: _nama.text, contact: _wa.text, email: auth.user!.email,
      brandName: _brand.text, description: _desc.text, category: _category!,
      submittedAt: 'Baru saja', status: ApplicationStatus.pending,
    );
    context.read<ApplicationsProvider>().addApplication(app);
    auth.setApplication(app.id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan terkirim! Tim kami akan mengkurasi.')));
    context.go('/akun/pengajuan');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isGuest = !auth.isAuthenticated;
    final isCreator = auth.isCreator;
    return AppScaffold(
      title: 'Jadi Kreator',
      body: Stack(children: [
        Opacity(opacity: isGuest ? 0.4 : 1.0, child: AbsorbPointer(absorbing: isGuest, child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            const SizedBox(height: 24),
            _Field(controller: _nama, label: 'Nama Lengkap', icon: Icons.person),
            const SizedBox(height: 12),
            _Field(controller: _wa, label: 'Kontak / WhatsApp', icon: Icons.phone),
            const SizedBox(height: 12),
            _Field(controller: _brand, label: 'Nama Brand / Karya', icon: Icons.store),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(initialValue: _category, decoration: const InputDecoration(labelText: 'Kategori Utama', prefixIcon: Icon(Icons.category)),
              items: dummyCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() => _category = v)),
            const SizedBox(height: 12),
            TextField(controller: _desc, maxLines: 4, decoration: const InputDecoration(labelText: 'Deskripsi Produk / Karya', alignLabelWithHint: true)),
            const SizedBox(height: 12),
            _PhotoDropzone(),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Kirim Pengajuan', onPressed: _submit),
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

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  const _Field({required this.controller, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => TextField(controller: controller, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)));
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
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, style: BorderStyle.solid, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface,
          boxShadow: AppShadows.soft,
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
              const Icon(Icons.upload_file, size: 32, color: AppColors.muted),
              const SizedBox(height: 4),
              Text('Klik untuk unggah foto sampel', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.muted)),
              Text('JPG/PNG · visual saja', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.muted)),
            ]),
      ),
    );
  }
}
