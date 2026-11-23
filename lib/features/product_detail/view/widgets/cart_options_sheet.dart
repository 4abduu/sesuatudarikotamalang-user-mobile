import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../data/repositories/cart_repository.dart';
import '../../../../data/models/cart_item_model.dart';
import '../../../../core/network/api_exception.dart';
import '../../viewmodel/variant_selection_view_model.dart';
import 'variant_picker.dart';

class PickupSelection {
  const PickupSelection(this.options, this.quantity);
  final List<String?> options;
  final int quantity;
}

class CartOptionsSheet extends StatefulWidget {
  const CartOptionsSheet({super.key, required this.repository, required this.productId, this.pickup = false, this.initialSelection, this.editingItem});
  final bool pickup;
  final List<String?>? initialSelection;
  final CartRepository repository;
  final String productId;
  final CartItemModel? editingItem;
  @override
  State<CartOptionsSheet> createState() => _CartOptionsSheetState();
}

class _CartOptionsSheetState extends State<CartOptionsSheet> {
  VariantSelectionViewModel? selection;
  CartSnapshot? cart;
  int quantity = 1;
  bool loading = true, saving = false;
  String? error;
  @override
  void initState() { super.initState(); load(); }
  @override
  void dispose() { selection?.dispose(); super.dispose(); }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final product = await widget.repository.getProduct(widget.productId);
      final snapshot = widget.pickup ? CartSnapshot([], {}) : await widget.repository.get();
      if (!mounted) return;
      final previous = selection?.selected;
      selection?.dispose();
      selection = VariantSelectionViewModel(product);
      if (previous != null) {
        selection!.restoreSelection(previous);
      } else if (widget.initialSelection != null) {
        selection!.restoreSelection(widget.initialSelection!);
      }
      quantity = widget.editingItem?.quantity ?? 1;
      cart = snapshot;
    } catch (_) {
      error = 'Gagal memuat stok terbaru. Coba lagi.';
    } finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final model = selection;
    return SafeArea(child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .75,
      child: loading ? const Center(child: CircularProgressIndicator())
        : model == null || cart == null ? Center(child: TextButton(onPressed: load, child: Text(error ?? 'Coba lagi')))
        : AnimatedBuilder(animation: model, builder: (context, _) {
          final variant = model.matchedVariant;
          final inCart = cart!.items.where((item) => item.variantId == variant?.id && item.id != widget.editingItem?.id).fold<int>(0, (sum, item) => sum + item.quantity);
          final stock = variant?.effectiveStock ?? 0;
          final limit = max(0, min(stock, 10) - inCart);
          quantity = limit == 0 ? 1 : min(quantity, limit);
          return Padding(padding: const EdgeInsets.all(20), child: Column(children: [
            Row(children: [Expanded(child: Text(model.product.name, style: Theme.of(context).textTheme.titleLarge)), IconButton(onPressed: saving ? null : () => Navigator.pop(context), icon: const Icon(Icons.close))]),
            Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              VariantPicker(product: model.product, provider: model),
              const SizedBox(height: 16),
              Text(variant == null ? 'Pilih semua opsi varian terlebih dahulu.' : 'Stok tersedia: $stock · Di keranjang: $inCart'),
              Text('Maksimal ${widget.pickup ? 'pesanan' : 'tambahan'}: $limit (batas 10 unit per varian)'),
              Row(children: [const Expanded(child: Text('Jumlah')), IconButton(onPressed: !saving && quantity > 1 ? () => setState(() => quantity--) : null, icon: const Icon(Icons.remove)), Text('$quantity'), IconButton(onPressed: !saving && quantity < limit ? () => setState(() => quantity++) : null, icon: const Icon(Icons.add))]),
              if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ]))),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: saving || variant == null || limit == 0 ? null : () async {
                if (widget.pickup) {
                  Navigator.pop(context, PickupSelection(model.selected, quantity));
                  return;
                }
                setState(() { saving = true; error = null; });
                try {
                  final editing = widget.editingItem;
                  if (editing == null) {
                    await widget.repository.add(productId: widget.productId, variantId: variant.id, quantity: quantity);
                  } else if (editing.variantId == variant.id) {
                    await widget.repository.update(editing.id, quantity);
                  } else {
                    // Tambahkan varian baru dahulu. Jika gagal karena stok/batas
                    // keranjang, item lama tetap aman.
                    await widget.repository.add(productId: widget.productId, variantId: variant.id, quantity: quantity);
                    await widget.repository.remove(editing.id);
                  }
                  if (context.mounted) Navigator.pop(context, true);
                } catch (e) {
                  final message = e is ApiException ? e.message : 'Gagal menambahkan ke keranjang.';
                  await load();
                  if (mounted) setState(() => error = message);
                } finally { if (mounted) setState(() => saving = false); }
              },
              child: Text(
                saving
                    ? (widget.editingItem == null ? 'Menambahkan...' : 'Memperbarui...')
                    : widget.pickup
                        ? 'Lanjut ke Pickup'
                        : (widget.editingItem == null ? 'Masukkan ke Keranjang' : 'Perbarui Keranjang'),
              ),
            )),
          ]));
        }),
    ));
  }
}
