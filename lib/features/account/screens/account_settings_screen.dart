import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/utils/password_validator.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/password_criteria_checklist.dart';
import '../../../shared/app_scaffold.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AppScaffold(
      title: 'Pengaturan',
      body: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Profil', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        _ProfileSection(),
        const SizedBox(height: 24),
        Text('Ganti Email (OTP)', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        _ChangeEmailOtpSection(),
        const SizedBox(height: 24),
        Text('Ganti Password', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        _ChangePasswordSection(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async { await auth.logout(); if (context.mounted) context.go('/'); },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.destructive,
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.destructive),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: const StadiumBorder(),
              textStyle: GoogleFonts.baloo2(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            child: const Text('Keluar'),
          ),
        ),
      ])),
    );
  }
}

/* ------------------------------------------------------------------ */
/* Style helpers (visual only) — sesuai 27-makunpengaturan.tsx         */
/* ------------------------------------------------------------------ */

/// SectionCard: surface, radius 20, border 1, shadow soft, padding 16.
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );
  }
}

/// Field: label 13 medium di atas input (mb 4), input padding 12, hint muted.
Widget _labeledField(String label, Widget field) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 4),
        field,
      ],
    );

InputDecoration _fieldDecoration([String? hint]) => InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMuted,
      contentPadding: const EdgeInsets.all(12),
    );

class _ProfileSection extends StatefulWidget {
  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  late final TextEditingController _name;
  String? _avatarPath;

  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _name = TextEditingController(text: auth.user?.name ?? '');
    _avatarPath = auth.user?.avatarUrl;
  }

  @override
  void dispose() { _name.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      setState(() => _isUploadingAvatar = true);
      try {
        final res = await ApiClient.uploadMultipart(
          path: '/upload/single',
          fileField: 'image',
          filePath: xfile.path,
        );
        final url = res['url'] as String?;
        if (url != null && url.isNotEmpty) {
          if (mounted) {
            setState(() => _avatarPath = url);
            await context.read<AuthProvider>().updateProfile(avatarUrl: url);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengunggah foto profil: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploadingAvatar = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      if (_avatarPath!.startsWith('http')) {
        imageProvider = NetworkImage(_avatarPath!);
      } else {
        imageProvider = FileImage(File(_avatarPath!));
      }
    }

    return _SectionCard(child: Column(children: [
      GestureDetector(
        onTap: _isUploadingAvatar ? null : _pickImage,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.person_outline, color: AppColors.onPrimary, size: 32)
                  : null,
            ),
            if (_isUploadingAvatar)
              const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
      const SizedBox(height: 4),
      TextButton(
        onPressed: _isUploadingAvatar ? null : _pickImage,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        child: const Text('Ganti foto profil'),
      ),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: _labeledField('Nama', TextField(controller: _name, style: AppTextStyles.body, decoration: _fieldDecoration()))),
      const SizedBox(height: 12),
      PrimaryButton(
        label: 'Simpan Nama',
        verticalPadding: 10,
        fontSize: 13,
        showShadow: false,
        onPressed: () {
          context.read<AuthProvider>().updateProfile(name: _name.text);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama disimpan')));
        },
      ),
    ]));
  }
}

class _ChangeEmailOtpSection extends StatefulWidget {
  @override
  State<_ChangeEmailOtpSection> createState() => _ChangeEmailOtpSectionState();
}

class _ChangeEmailOtpSectionState extends State<_ChangeEmailOtpSection> {
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _otpFocus = FocusNode(); // hanya untuk tampilan kotak OTP
  bool _otpSent = false;
  bool _isLoading = false;
  late String _oldEmail;

  @override
  void initState() {
    super.initState();
    _oldEmail = context.read<AuthProvider>().user?.email ?? '';
    _email.text = '';
  }

  @override
  void dispose() { _email.dispose(); _otp.dispose(); _otpFocus.dispose(); super.dispose(); }

  Future<void> _sendOtp() async {
    final newEmail = _email.text.trim();
    if (newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi email baru terlebih dahulu')));
      return;
    }
    if (newEmail.toLowerCase() == _oldEmail.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email baru harus berbeda dari email saat ini')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().requestChangeEmail(newEmail);
      if (mounted) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kode verifikasi telah dikirim ke $_oldEmail')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verify() async {
    final code = _otp.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan kode OTP')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().verifyChangeEmail(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email berhasil diganti!')));
        setState(() {
          _otpSent = false;
          _email.clear();
          _otp.clear();
          _oldEmail = context.read<AuthProvider>().user?.email ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.moss.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.moss),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppTextStyles.caption.copyWith(color: AppColors.moss),
                children: [
                  const TextSpan(text: 'Email sekarang: '),
                  TextSpan(text: _oldEmail, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      _labeledField(
        'Email baru',
        TextField(
          controller: _email,
          enabled: !_otpSent && !_isLoading,
          keyboardType: TextInputType.emailAddress,
          style: AppTextStyles.body,
          decoration: _fieldDecoration('email-baru@email.com'),
        ),
      ),
      if (!_otpSent) ...[
        const SizedBox(height: 6),
        Text('Kode OTP akan dikirim ke email lama kamu untuk verifikasi.', style: AppTextStyles.caption.copyWith(fontSize: 11)),
      ],
      if (_otpSent) ...[
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.mail_outline, size: 28, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        Center(child: Text('Verifikasi Email', style: AppTextStyles.h3)),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Masukkan 6 digit kode yang kami kirim ke $_oldEmail (email lamamu)',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        _OtpBoxes(controller: _otp, focusNode: _otpFocus, enabled: !_isLoading),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Verifikasi',
          loading: _isLoading,
          verticalPadding: 12,
          fontSize: 13,
          showShadow: false,
          onPressed: _isLoading ? null : _verify,
        ),
      ] else ...[
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Kirim Kode',
          loading: _isLoading,
          verticalPadding: 10,
          fontSize: 13,
          showShadow: false,
          onPressed: _isLoading ? null : _sendOtp,
        ),
      ],
    ]));
  }
}

/// 6 kotak OTP (tampilan saja). Input tetap lewat satu [TextEditingController]
/// yang sama dengan sebelumnya; TextField transparan menangkap ketikan.
class _OtpBoxes extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  const _OtpBoxes({required this.controller, required this.focusNode, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([controller, focusNode]),
            builder: (_, __) {
              final text = controller.text;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final focused = focusNode.hasFocus && i == (text.length < 6 ? text.length : 5);
                  return Container(
                    width: 44,
                    height: 44,
                    margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: focused ? AppColors.primary : AppColors.border),
                      boxShadow: focused
                          ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), spreadRadius: 2)]
                          : null,
                    ),
                    child: Text(
                      i < text.length ? text[i] : '',
                      style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
                    ),
                  );
                }),
              );
            },
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                keyboardType: TextInputType.number,
                maxLength: 6,
                showCursor: false,
                enableInteractiveSelection: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordSection extends StatefulWidget {
  @override
  State<_ChangePasswordSection> createState() => _ChangePasswordSectionState();
}

class _ChangePasswordSectionState extends State<_ChangePasswordSection> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() { _old.dispose(); _new.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _save() async {
    final v = validatePassword(_new.text);
    if (!v.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password belum memenuhi kriteria')));
      return;
    }
    if (_new.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi password tidak sama')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().changePasswordApi(
        oldPassword: _old.text,
        newPassword: _new.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah')));
        _old.clear();
        _new.clear();
        _confirm.clear();
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(child: Column(children: [
      _labeledField('Password lama', TextField(controller: _old, obscureText: true, enabled: !_isLoading, style: AppTextStyles.body, decoration: _fieldDecoration('••••••••'))),
      const SizedBox(height: 12),
      _labeledField('Password baru', TextField(controller: _new, obscureText: true, enabled: !_isLoading, onChanged: (_) => setState(() {}), style: AppTextStyles.body, decoration: _fieldDecoration('••••••••'))),
      const SizedBox(height: 12),
      Align(alignment: Alignment.centerLeft, child: PasswordCriteriaChecklist(password: _new.text)),
      const SizedBox(height: 12),
      _labeledField('Konfirmasi password', TextField(controller: _confirm, obscureText: true, enabled: !_isLoading, style: AppTextStyles.body, decoration: _fieldDecoration('••••••••'))),
      const SizedBox(height: 12),
      PrimaryButton(
        label: 'Simpan Password Baru',
        loading: _isLoading,
        verticalPadding: 10,
        fontSize: 13,
        showShadow: false,
        onPressed: _isLoading ? null : _save,
      ),
    ]));
  }
}
