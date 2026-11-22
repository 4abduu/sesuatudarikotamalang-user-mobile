import '../../../../core/utils/variant_combinations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/feature_tour.dart';
import '../../../../data/models/variant_option_model.dart';

class VariantBuilder extends StatefulWidget {
  final List<VariantOptionModel> options;
  final Map<String, int> stocks; // key = options.join(' / ')
  final ValueChanged<(List<VariantOptionModel>, Map<String, int>)> onChanged;
  final bool editable;
  const VariantBuilder({super.key, required this.options, required this.stocks, required this.onChanged, this.editable = true});

  @override
  State<VariantBuilder> createState() => _VariantBuilderState();
}

class _VariantBuilderState extends State<VariantBuilder> {
  late List<VariantOptionModel> _opts;
  late Map<String, int> _stocks;
  final _variantTitleKey = GlobalKey();
  final _stockHelpKey = GlobalKey();
  final _stockFieldKey = GlobalKey();
  final _addOptionKey = GlobalKey();

  void _startTour() {
    final hasCombinations = _combos.isNotEmpty;
    showFeatureTour(context, [
      FeatureTourStep(target: _variantTitleKey, title: 'Susun varian dulu', description: 'Buat opsi seperti Ukuran, Warna, atau Motif, lalu isi nilai yang tersedia.'),
      FeatureTourStep(target: _addOptionKey, title: 'Tambah opsi varian', description: 'Tekan + Tambah Opsi, lalu isi nama opsi dan nilainya. Contoh: Ukuran berisi S, M, L.'),
      FeatureTourStep(
        target: hasCombinations ? _stockFieldKey : _stockHelpKey,
        title: hasCombinations ? 'Stok ada di sini' : 'Stok muncul setelah kombinasi dibuat',
        description: hasCombinations
            ? 'Setiap kombinasi dibuat otomatis. Tekan angka stok pada barisnya untuk menambah atau mengurangi stok.'
            : 'Setelah opsi dan nilainya diisi, kombinasi akan muncul di bawah. Di sanalah angka stok bisa ditekan dan diubah.',
      ),
    ]);
  }

  @override
  void initState() {
    super.initState();
    _opts = List.from(widget.options);
    _stocks = Map.from(widget.stocks);
  }

  List<List<String>> get _combos => variantCombinations(_opts);

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cara mengatur varian dan stok'),
        content: const Text(
          'Buat opsi seperti Ukuran dan Warna, lalu isi nilainya. Aplikasi akan membuat semua kombinasi secara otomatis.\n\n'
          'Contoh: S / Merah, M / Merah, S / Hitam. Tekan angka stok pada baris kombinasi untuk mengubah jumlah stoknya.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mengerti'))],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant VariantBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _opts = List.of(widget.options);
    _stocks = Map.of(widget.stocks);
  }

  @override
  Widget build(BuildContext context) {
    // Kartu section TSX: radius 20, surface, border 1px, shadow soft, padding 16.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('Varian & Stok', key: _variantTitleKey, style: AppTextStyles.h3)),
        IconButton(tooltip: 'Lihat panduan varian dan stok', onPressed: _showHelp, icon: const Icon(Icons.help_outline, size: 20, color: AppColors.primary)),
        IconButton(tooltip: 'Mulai tur varian dan stok', onPressed: _startTour, icon: const Icon(Icons.tour_outlined, size: 20, color: AppColors.primary)),
      ]),
      const SizedBox(height: 8),
      Text('Tentukan sumbu varian. Stok dihitung per kombinasi.', style: AppTextStyles.caption),
      const SizedBox(height: 4),
      Text('Tekan angka stok pada baris kombinasi untuk mengubah jumlahnya.', key: _stockHelpKey, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
      if (widget.editable) ...[
        const SizedBox(height: 8),
        Text(
          'Pastikan semua opsi dan nilainya sudah benar sebelum menyimpan. Setelah produk dibuat, struktur varian dikunci; yang dapat diedit hanya stok tiap kombinasi.',
          style: AppTextStyles.caption.copyWith(color: AppColors.foreground),
        ),
      ] else ...[
        const SizedBox(height: 8),
        Text(
          'Struktur varian sudah tersimpan dan dikunci agar pesanan serta riwayat stok tetap konsisten. Stok tiap kombinasi masih dapat diubah.',
          style: AppTextStyles.caption.copyWith(color: AppColors.foreground),
        ),
      ],
      const SizedBox(height: 12),
      ..._opts.asMap().entries.map((e) {
        final i = e.key;
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
          Expanded(flex: 2, child: TextFormField(enabled: widget.editable, initialValue: _opts[i].name, decoration: const InputDecoration(hintText: 'Nama opsi', isDense: true), onChanged: (v) { _opts[i] = VariantOptionModel(name: v, values: _opts[i].values); widget.onChanged((_opts, _stocks)); })),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: TextFormField(enabled: widget.editable, initialValue: _opts[i].values.join(', '), decoration: const InputDecoration(hintText: 'Nilai, pisahkan koma', isDense: true), onChanged: (v) { _opts[i] = VariantOptionModel(name: _opts[i].name, values: v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()); widget.onChanged((_opts, _stocks)); })),
          if (widget.editable) IconButton(iconSize: 16, icon: const Icon(Icons.delete_outline, color: AppColors.primary), onPressed: () { setState(() => _opts.removeAt(i)); widget.onChanged((_opts, _stocks)); }),
        ]));
      }),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          key: _addOptionKey,
          onPressed: widget.editable ? () { setState(() => _opts.add(const VariantOptionModel(name: '', values: []))); widget.onChanged((_opts, _stocks)); } : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            textStyle: GoogleFonts.baloo2(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          child: const Text('+ Tambah Opsi'),
        ),
      ),
      const SizedBox(height: 12),
      if (_combos.isNotEmpty) ...[
        Text('Stok per Kombinasi (${_combos.length} kombinasi)', style: AppTextStyles.label),
        const SizedBox(height: 8),
        // Tabel varian TSX: header surfaceAlt 10px bold, baris surface 11px, border antar baris.
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Container(
                color: AppColors.surfaceAlt,
                child: Row(children: [
                  Expanded(child: Padding(padding: const EdgeInsets.all(8), child: Text('Kombinasi', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.foreground)))),
                  Container(width: 1, height: 32, color: AppColors.border),
                  SizedBox(width: 80, child: Text('Stok', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.foreground))),
                ]),
              ),
              ..._combos.asMap().entries.map((entry) {
                final c = entry.value;
                final key = c.join(' / ');
                return Container(
                  decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(child: Padding(padding: const EdgeInsets.all(8), child: Text(key, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.foreground)))),
                    Container(width: 1, height: 36, color: AppColors.border),
                    SizedBox(width: 80, child: TextFormField(
                      key: entry.key == 0 ? _stockFieldKey : ValueKey(key),
                      initialValue: (_stocks[key] ?? 0).toString(),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                      decoration: InputDecoration(
                        isDense: true, hintText: '0', filled: true, fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      ),
                      onChanged: (v) { _stocks[key] = int.tryParse(v) ?? 0; widget.onChanged((_opts, _stocks)); },
                    )),
                  ]),
                );
              }),
            ]),
          ),
        ),
      ],
    ]),
    );
  }
}
