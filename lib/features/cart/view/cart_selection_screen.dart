import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/app_scaffold.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/cart_item_model.dart';
import '../viewmodel/cart_view_model.dart';
import '../../product_detail/view/widgets/cart_options_sheet.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override State<CartScreen> createState() => _CartScreenState();
}
class _CartScreenState extends State<CartScreen> {
  final selected = <String>{};
  bool busy = false;
  String? editingQuantityId;
  final quantityController = TextEditingController();

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }
  @override void initState() { super.initState(); Future.microtask(() { if (mounted) context.read<CartViewModel>().refresh(); }); }
  Future<void> change(Future<void> Function() action) async {
    setState(() => busy = true);
    try { await action(); } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Gagal memperbarui keranjang.')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> editVariant(CartItemModel item) async {
    final vm = context.read<CartViewModel>();
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CartOptionsSheet(
        repository: vm.repository,
        productId: item.productId,
        editingItem: item,
        initialSelection: item.options.map<String?>((value) => value).toList(),
      ),
    );
    if (changed == true && mounted) {
      final wasSelected = selected.contains(item.id);
      await vm.refresh();
      if (wasSelected && mounted && !vm.items.any((candidate) => candidate.id == item.id)) {
        final replacement = vm.items.where((candidate) => candidate.productId == item.productId && candidate.status == 'ok').firstOrNull;
        if (replacement != null) selected.add(replacement.id);
      }
      if (mounted) setState(() {});
    }
  }
  void startQuantityEdit(CartItemModel item) {
    setState(() {
      editingQuantityId = item.id;
      quantityController.text = '${item.quantity}';
      quantityController.selection = TextSelection(baseOffset: 0, extentOffset: quantityController.text.length);
    });
  }
  Future<void> saveQuantity(CartItemModel item) async {
    final value = int.tryParse(quantityController.text.trim());
    if (value == null || value < 1 || value > item.maxQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jumlah melebihi stok yang tersedia.')));
      return;
    }
    await change(() => context.read<CartViewModel>().updateQuantity(item, value));
    if (mounted) setState(() => editingQuantityId = null);
  }
  Future<void> adjustQuantity(CartItemModel item, int delta) async {
    final current = editingQuantityId == item.id
        ? (int.tryParse(quantityController.text.trim()) ?? item.quantity)
        : item.quantity;
    final next = current + delta;
    if (next < 1 || next > item.maxQuantity) return;
    if (editingQuantityId == item.id) {
      quantityController.text = '$next';
      quantityController.selection = TextSelection.collapsed(offset: quantityController.text.length);
      await saveQuantity(item);
    } else {
      await change(() => context.read<CartViewModel>().updateQuantity(item, next));
    }
  }
  @override Widget build(BuildContext context) {
    final vm = context.watch<CartViewModel>();
    final available = vm.items.where((item) => item.status == 'ok').toList();
    final chosen = available.where((item) => selected.contains(item.id)).toList();
    final subtotal = chosen.fold<int>(0, (sum, item) => sum + item.lineTotal);
    return AppScaffold(title: 'Keranjang', showBottomNav: false, body: Column(children: [
      Expanded(child: RefreshIndicator(onRefresh: vm.refresh, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
        if (vm.loading) const LinearProgressIndicator(),
        if (vm.error != null) Text(vm.error!),
        if (vm.items.isEmpty && !vm.loading) const Text('Keranjang masih kosong.'),
        if (vm.items.isNotEmpty) CheckboxListTile(controlAffinity: ListTileControlAffinity.leading, title: const Text('Pilih semua'), value: available.isNotEmpty && chosen.length == available.length, onChanged: busy ? null : (value) => setState(() { selected.clear(); if (value == true) selected.addAll(available.map((item) => item.id)); })),
        for (final item in vm.items) Padding(padding: const EdgeInsets.only(bottom: 12), child: Slidable(key: ValueKey(item.id),
          endActionPane: ActionPane(motion: const ScrollMotion(), extentRatio: .25, children: [SlidableAction(onPressed: busy ? null : (_) => change(() => vm.remove(item.id)), backgroundColor: AppColors.destructive, foregroundColor: AppColors.onPrimary, icon: Icons.delete_outline, label: 'Hapus', borderRadius: BorderRadius.circular(20))]),
          child: Card(margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Checkbox(value: selected.contains(item.id) && item.status == 'ok', onChanged: busy || item.status != 'ok' ? null : (value) => setState(() { if (value == true) { selected.add(item.id); } else { selected.remove(item.id); } })),
              ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 64, height: 64, child: item.image == null ? const Icon(Icons.image_outlined) : Image.network(item.image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                InkWell(
                  onTap: busy || item.status != 'ok' ? null : () => editVariant(item),
                  child: Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(child: Text(item.variantLabel, style: const TextStyle(decoration: TextDecoration.underline))),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 17),
                  ]))),
                Text(formatRupiah(item.unitPrice)),
                if (item.status != 'ok') const Text('Stok atau produk tidak tersedia', style: TextStyle(color: Colors.red)),
              ])),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              IconButton(visualDensity: VisualDensity.compact, onPressed: busy || item.quantity <= 1 ? null : () => adjustQuantity(item, -1), icon: const Icon(Icons.remove)),
              if (editingQuantityId == item.id)
                SizedBox(
                  width: 34,
                  child: TextField(
                    controller: quantityController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => saveQuantity(item),
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4), border: UnderlineInputBorder()),
                  ),
                )
              else
                InkWell(onTap: busy || item.status != 'ok' ? null : () => startQuantityEdit(item), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text('${item.quantity}', style: const TextStyle(decoration: TextDecoration.underline)))),
              IconButton(visualDensity: VisualDensity.compact, onPressed: busy || item.quantity >= item.maxQuantity || item.status != 'ok' ? null : () => adjustQuantity(item, 1), icon: const Icon(Icons.add)),
            ]),
          ]))),
        )),
      ]))),
      SafeArea(top: false, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: const Border(top: BorderSide(color: Colors.black12))), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Subtotal (${chosen.length} item): ${formatRupiah(subtotal)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 10),
        FilledButton(onPressed: busy || vm.loading || chosen.isEmpty ? null : () async {
          await context.push(Uri(path: '/reservasi/keranjang', queryParameters: {'item': chosen.map((item) => item.id).toList()}).toString());
          if (mounted) await vm.refresh();
        }, child: Text('Checkout (${chosen.length})')),
      ]))),
    ]));
  }
}
