import '../../../../core/utils/variant_combinations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
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

  @override
  void initState() {
    super.initState();
    _opts = List.from(widget.options);
    _stocks = Map.from(widget.stocks);
  }

  List<List<String>> get _combos => variantCombinations(_opts);

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
      Text('Varian & Stok', style: AppTextStyles.h3),
      const SizedBox(height: 8),
      Text('Tentukan sumbu varian. Stok dihitung per kombinasi.', style: AppTextStyles.caption),
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
              ..._combos.map((c) {
                final key = c.join(' / ');
                return Container(
                  decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(child: Padding(padding: const EdgeInsets.all(8), child: Text(key, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.foreground)))),
                    Container(width: 1, height: 36, color: AppColors.border),
                    SizedBox(width: 80, child: TextFormField(
                      key: ValueKey(key),
                      initialValue: (_stocks[key] ?? 0).toString(),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                      decoration: const InputDecoration(
                        isDense: true, hintText: '0', filled: false,
                        border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
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
