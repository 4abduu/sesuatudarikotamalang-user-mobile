import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/upload_api.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/photo_rules.dart';
import '../../../../core/widgets/photo_editor.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../features/account/providers/applications_provider.dart';
import '../../../../data/models/creator_application_model.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/auth/widgets/auth_field.dart';
import '../../../../features/auth/widgets/auth_gate_bottom_sheet.dart';
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
  String? _brandError;
  String? _photoError;
  Set<String> _rejectedKeys = {};
  List<PhotoItem> _photos = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nama.text = auth.user?.name ?? '';
    _wa.text = auth.user?.email ?? '';

    // Bila sudah ada pengajuan pending, langsung arahkan ke layar status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final apps = context.read<ApplicationsProvider>();
      final latest = apps.latestForUser(auth.user?.id ?? '');
      if (latest != null && latest.status == ApplicationStatus.pending) {
        context.go('/pengajuan-kreator');
      }
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
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      showAuthGateSheet(context, next: '/daftar-kreator', contextLabel: 'mendaftar jadi kreator');
      return;
    }
    if (_nama.text.trim().isEmpty || _desc.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi nama lengkap dan deskripsi produk')),
      );
      return;
    }
    if (_photos.isEmpty) {
      setState(() => _photoError = 'Minimal 1 foto sampel produk');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal 1 foto sampel produk')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _brandError = null;
      _photoError = null;
    });

    PhotoSyncResult? sync;
    try {
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
              SnackBar(content: Text('Foto sampel gagal diunggah: ${e.message}')),
            );
          }
        }
        return;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Foto sampel gagal diunggah: $e')),
          );
        }
        return;
      }

      if (!mounted) return;
      final app = await context.read<ApplicationsProvider>().apply(
        applicantName: _nama.text.trim(),
        contact: _wa.text.trim(),
        brandName: _brand.text.trim().isNotEmpty ? _brand.text.trim() : null,
        description: _desc.text.trim(),
        categoryId: _category,
        samplePhotos: sync.images,
        sampleFileUrl: sync.images.isNotEmpty ? sync.images.first : null,
      );

      auth.setApplication(app.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan terkirim! Tim kami akan mengkurasi.')),
        );
        context.go('/akun/pengajuan');
      }
    } on ApiException catch (e) {
      if (sync != null && sync.newlyUploaded.isNotEmpty) {
        await UploadApi.deleteUrls(sync.newlyUploaded);
      }
      if (e.code == 'BRAND_NAME_TAKEN' || e.code == 'BRAND_NAME_INVALID') {
        if (mounted) {
          setState(() => _brandError = e.message);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    } catch (e) {
      if (sync != null && sync.newlyUploaded.isNotEmpty) {
        await UploadApi.deleteUrls(sync.newlyUploaded);
      }
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
                const Icon(Icons.check_circle_outline, size: 48, color: AppColors.moss),
                const SizedBox(height: 12),
                Text('Akunmu sudah berperan sebagai kreator/admin', style: AppTextStyles.h2, textAlign: TextAlign.center),
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
                  Text('Konsinyasikan karyamu di toko fisik Kayutangan.', style: AppTextStyles.bodyMuted),
                  const SizedBox(height: 12),
                  AuthField(controller: _nama, label: 'Nama Lengkap', icon: Icons.person_outline),
                  const SizedBox(height: 12),
                  AuthField(controller: _wa, label: 'Kontak / WhatsApp', icon: Icons.phone_outlined),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthField(
                        controller: _brand,
                        label: 'Nama brand (opsional)',
                        icon: Icons.storefront_outlined,
                        onChanged: (_) {
                          if (_brandError != null) setState(() => _brandError = null);
                        },
                      ),
                      const SizedBox(height: 4),
                      Text('Kosongkan untuk memakai nama akunmu', style: AppTextStyles.caption),
                      if (_brandError != null) ...[
                        const SizedBox(height: 4),
                        Text(_brandError!, style: AppTextStyles.caption.copyWith(color: AppColors.destructive)),
                      ],
                    ],
                  ),
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
                  PhotoEditor(
                    items: _photos,
                    onChanged: (v) => setState(() {
                      _photos = v;
                      if (_photos.isNotEmpty) _photoError = null;
                      _rejectedKeys.removeWhere((k) => !v.any((item) => item.key == k));
                    }),
                    maxPhotos: PhotoRules.maxSamplePhotos,
                    label: 'Foto sampel produk (wajib, min. 1)',
                    rejectedKeys: _rejectedKeys,
                  ),
                  if (_photoError != null) ...[
                    const SizedBox(height: 4),
                    Text(_photoError!, style: AppTextStyles.caption.copyWith(color: AppColors.destructive)),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: _isSubmitting ? 'Mengirim...' : 'Kirim Pengajuan',
                    onPressed: _isSubmitting ? null : _submit,
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
                        const Icon(Icons.lock, size: 40, color: AppColors.primary),
                        const SizedBox(height: 12),
                        Text('Masuk untuk melanjutkan', style: AppTextStyles.h3, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text('Kamu perlu masuk untuk mendaftar jadi kreator.', style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Masuk / Daftar',
                          onPressed: () => showAuthGateSheet(context, next: '/daftar-kreator', contextLabel: 'mendaftar jadi kreator'),
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
