import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/olshop_logo.dart';
import '../../../../data/models/olshop_model.dart';
import '../../../auth/view/widgets/auth_field.dart';

/// Editor link marketplace untuk form produk kreator.
/// Tiap marketplace punya tiga pilihan: Tidak dijual / Link toko / Link produk.
class OlshopLinksEditor extends StatefulWidget {
  final Map<OlshopPlatform, OlshopSetting> value;
  final ValueChanged<Map<OlshopPlatform, OlshopSetting>> onChanged;

  /// Link toko per marketplace dari pengaturan admin (null = belum diisi).
  final Map<OlshopPlatform, String?> stores;

  /// false bila pengaturan belum berhasil dimuat; opsi "Link toko" tidak dikunci,
  /// backend yang memutuskan.
  final bool storesKnown;
  final Map<OlshopPlatform, String?> errors;
  final bool enabled;

  const OlshopLinksEditor({
    super.key,
    required this.value,
    required this.onChanged,
    required this.stores,
    required this.storesKnown,
    this.errors = const {},
    this.enabled = true,
  });

  @override
  State<OlshopLinksEditor> createState() => _OlshopLinksEditorState();
}

class _OlshopLinksEditorState extends State<OlshopLinksEditor> {
  late final Map<OlshopPlatform, TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = {
      for (final p in OlshopPlatform.values) p: TextEditingController(text: widget.value[p]?.url ?? ''),
    };
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit(OlshopPlatform p, OlshopSetting next) {
    final map = Map<OlshopPlatform, OlshopSetting>.of(widget.value);
    map[p] = next;
    widget.onChanged(map);
  }

  String _modeLabel(OlshopMode m) => switch (m) {
        OlshopMode.tidak => 'Tidak dijual',
        OlshopMode.toko => 'Link toko',
        OlshopMode.khusus => 'Link produk',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Link marketplace (opsional)', style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(
            'Pilih produk ini dijual di marketplace mana. Tombol beli di aplikasi hanya muncul untuk marketplace yang kamu aktifkan.',
            style: AppTextStyles.caption,
          ),
          for (final p in OlshopPlatform.values) ...[
            const SizedBox(height: 16),
            _buildPlatform(p),
          ],
        ],
      ),
    );
  }

  Widget _buildPlatform(OlshopPlatform p) {
    final setting = widget.value[p] ?? const OlshopSetting();
    final storeUrl = widget.stores[p];
    final storeMissing = widget.storesKnown && (storeUrl == null || storeUrl.isEmpty);
    final error = widget.errors[p];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          OlshopLogo(platform: p, size: 22),
          const SizedBox(width: 8),
          Text(p.label, style: AppTextStyles.label),
        ]),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final m in OlshopMode.values)
              ChoiceChip(
                label: Text(_modeLabel(m)),
                selected: setting.mode == m,
                showCheckmark: false,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: setting.mode == m ? AppColors.primary : AppColors.muted,
                ),
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundColor: AppColors.surface,
                side: BorderSide(color: setting.mode == m ? AppColors.primary : AppColors.border),
                onSelected: (!widget.enabled || (m == OlshopMode.toko && storeMissing))
                    ? null
                    : (_) => _emit(p, OlshopSetting(mode: m, url: _ctrls[p]!.text)),
              ),
          ],
        ),
        if (storeMissing)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Opsi "Link toko" belum bisa dipilih karena admin belum mengisi link toko ${p.label}.',
              style: AppTextStyles.caption,
            ),
          ),
        if (setting.mode == OlshopMode.toko && storeUrl != null && storeUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Pembeli akan diarahkan ke halaman toko di ${p.label} dan diberi tahu bahwa produk ini tidak punya link khusus.',
              style: AppTextStyles.caption,
            ),
          ),
        if (setting.mode == OlshopMode.khusus) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _ctrls[p],
            enabled: widget.enabled,
            keyboardType: TextInputType.url,
            autocorrect: false,
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.foreground),
            decoration: authInputDecoration(icon: Icons.link).copyWith(
              hintText: 'https://...',
              errorText: error,
              errorMaxLines: 3,
            ),
            onChanged: (text) => _emit(p, OlshopSetting(mode: OlshopMode.khusus, url: text)),
          ),
          if (error == null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Tempel link produk dari ${p.label}. Hanya link resmi ${p.label} yang diterima.',
                style: AppTextStyles.caption,
              ),
            ),
        ],
      ],
    );
  }
}
