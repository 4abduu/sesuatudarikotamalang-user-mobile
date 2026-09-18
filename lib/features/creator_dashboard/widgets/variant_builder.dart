import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/variant_option_model.dart';

class VariantBuilder extends StatefulWidget {
  final List<VariantOptionModel> options;
  final Map<String, int> stocks; // key = options.join(' / ')
  final ValueChanged<(List<VariantOptionModel>, Map<String, int>)> onChanged;
  const VariantBuilder({super.key, required this.options, required this.stocks, required this.onChanged});

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

  List<List<String>> get _combos {
    if (_opts.isEmpty || _opts.any((o) => o.name.isEmpty || o.values.isEmpty)) return [];
    var result = [[]];
    for (final o in _opts) {
      result = result.expand((r) => o.values.map((v) => [...r, v])).toList();
    }
    return result.map((c) => c.cast<String>()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Varian & Stok', style: AppTextStyles.h3),
      const SizedBox(height: 8),
      Text('Tentukan sumbu varian. Stok dihitung per kombinasi.', style: AppTextStyles.caption),
      const SizedBox(height: 12),
      ..._opts.asMap().entries.map((e) {
        final i = e.key;
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
          Expanded(flex: 2, child: TextField(decoration: const InputDecoration(hintText: 'Nama opsi', isDense: true), onChanged: (v) { _opts[i] = VariantOptionModel(name: v, values: _opts[i].values); widget.onChanged((_opts, _stocks)); })),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: TextField(decoration: const InputDecoration(hintText: 'Nilai, pisahkan koma', isDense: true), onChanged: (v) { _opts[i] = VariantOptionModel(name: _opts[i].name, values: v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()); widget.onChanged((_opts, _stocks)); })),
          IconButton(icon: const Icon(Icons.delete, color: AppColors.destructive), onPressed: () { setState(() => _opts.removeAt(i)); widget.onChanged((_opts, _stocks)); }),
        ]));
      }),
      OutlinedButton(onPressed: () { setState(() => _opts.add(const VariantOptionModel(name: '', values: []))); widget.onChanged((_opts, _stocks)); }, child: const Text('Tambah Opsi')),
      const SizedBox(height: 12),
      if (_combos.isNotEmpty) ...[
        Text('Stok per Kombinasi (${_combos.length} kombinasi)', style: AppTextStyles.label),
        const SizedBox(height: 8),
        ..._combos.map((c) {
          final key = c.join(' / ');
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
            Expanded(child: Text(key, style: AppTextStyles.body)),
            SizedBox(width: 80, child: TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(isDense: true, hintText: '0'), onChanged: (v) { _stocks[key] = int.tryParse(v) ?? 0; widget.onChanged((_opts, _stocks)); })),
          ]));
        }),
      ],
    ]);
  }
}
