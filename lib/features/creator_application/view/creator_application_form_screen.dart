import '../viewmodel/application_form_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/photo_editor.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../features/auth/viewmodel/auth_view_model.dart';
import '../../../../features/auth/view/widgets/auth_field.dart';
import '../../../../features/catalog/viewmodel/app_config_view_model.dart';
import '../../../../shared/app_scaffold.dart';

class CreatorApplicationFormScreen extends StatefulWidget {
  const CreatorApplicationFormScreen({super.key});
  @override
  State<CreatorApplicationFormScreen> createState() =>
      _CreatorApplicationFormScreenState();
}

class _CreatorApplicationFormScreenState
    extends State<CreatorApplicationFormScreen> {
  final _nama = TextEditingController();
  final _wa = TextEditingController();
  final _brand = TextEditingController();
  final _desc = TextEditingController();
  late final ApplicationFormViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<ApplicationFormViewModel>();
    _nama.text = _vm.applicantName;
    _wa.text = _vm.contact;
    _brand.text = _vm.brandName;
    _desc.text = _vm.description;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final pending = await _vm.loadPendingApplication();
      if (mounted && pending) context.go('/akun/pengajuan');
    });
  }

  @override
  void dispose() {
    _nama.dispose();
    _wa.dispose();
    _brand.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthViewModel>();
    if (!auth.isAuthenticated) {
      _goToLogin();
      return;
    }
    final ok = await _vm.submit();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pengajuan terkirim! Tim kami akan mengkurasi.')),
      );
      context.go('/akun/pengajuan');
    } else if (_vm.actionError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_vm.actionError!)));
    }
  }

  void _goToLogin() {
    context.push('/login?next=${Uri.encodeComponent('/daftar-kreator')}');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ApplicationFormViewModel>();
    final auth = context.watch<AuthViewModel>();
    final isGuest = !auth.isAuthenticated;
    final isNotBuyer = auth.isAuthenticated && !auth.isBuyer;

    if (isNotBuyer) {
      return AppScaffold(
        title: 'Jadi Kreator',
        showBottomNav: false,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 48, color: AppColors.moss),
                const SizedBox(height: 12),
                Text('Akunmu sudah berperan sebagai kreator/admin',
                    style: AppTextStyles.h2, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Buka Dashboard Kreator',
                  onPressed: () => context.go('/dashboard-kreator'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.go('/akun'),
                  child: const Text('Kembali ke Akun'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'Jadi Kreator',
      showBottomNav: false,
      body: Stack(children: [
        Opacity(
          opacity: isGuest ? 0.4 : 1.0,
          child: AbsorbPointer(
            absorbing: isGuest,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daftar Konsinyasi Karyamu', style: AppTextStyles.h1),
                  const SizedBox(height: 4),
                  Text('Konsinyasikan karyamu di toko fisik Kayutangan.',
                      style: AppTextStyles.bodyMuted),
                  const SizedBox(height: 12),
                  AuthField(
                      controller: _nama,
                      onChanged: vm.setApplicantName,
                      label: 'Nama Lengkap',
                      icon: Icons.person_outline),
                  const SizedBox(height: 12),
                  AuthField(
                      controller: _wa,
                      onChanged: vm.setContact,
                      label: 'Nomor WhatsApp',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthField(
                        controller: _brand,
                        label: 'Nama brand (opsional)',
                        icon: Icons.storefront_outlined,
                        onChanged: vm.setBrandName,
                      ),
                      const SizedBox(height: 4),
                      Text('Kosongkan untuk memakai nama akunmu',
                          style: AppTextStyles.caption),
                      if (vm.brandError != null) ...[
                        const SizedBox(height: 4),
                        Text(vm.brandError!,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.destructive)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (ctx) {
                      final cats = ctx.watch<AppConfigViewModel>().categories;
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kategori Utama', style: AppTextStyles.label),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              initialValue: vm.categoryId,
                              isDense: true,
                              isExpanded: true,
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: AppColors.foreground),
                              dropdownColor: AppColors.surface,
                              icon: const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.keyboard_arrow_down,
                                      size: 16, color: AppColors.muted)),
                              decoration: authInputDecoration(
                                  icon: Icons.category_outlined),
                              items: cats
                                  .map((c) => DropdownMenuItem(
                                      value: c.id, child: Text(c.name)))
                                  .toList(),
                              onChanged: vm.setCategoryId,
                            ),
                          ]);
                    },
                  ),
                  const SizedBox(height: 12),
                  AuthField(
                      controller: _desc,
                      onChanged: vm.setDescription,
                      label: 'Deskripsi Produk / Karya',
                      maxLines: 4),
                  const SizedBox(height: 12),
                  PhotoEditor(
                    viewModel: vm.photos,
                    label: 'Foto sampel produk (wajib, min. 1)',
                  ),
                  if (vm.photoError != null) ...[
                    const SizedBox(height: 4),
                    Text(vm.photoError!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.destructive)),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: vm.isSubmitting ? 'Mengirim...' : 'Kirim Pengajuan',
                    onPressed: vm.isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isGuest)
          Positioned.fill(
            child: Container(
              color: AppColors.background.withValues(alpha: 0.3),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock,
                            size: 40, color: AppColors.primary),
                        const SizedBox(height: 12),
                        Text('Masuk untuk melanjutkan',
                            style: AppTextStyles.h3,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text('Kamu perlu masuk untuk mendaftar jadi kreator.',
                            style: AppTextStyles.bodyMuted,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Masuk / Daftar',
                          onPressed: _goToLogin,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
