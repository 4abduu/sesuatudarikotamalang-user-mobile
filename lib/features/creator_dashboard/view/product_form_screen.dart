import 'package:flutter/material.dart';
import '../../../core/routing/back_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/photo_editor.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/olshop_model.dart';
import '../../../data/models/variant_option_model.dart';
import '../../auth/view/widgets/auth_field.dart';
import '../../catalog/viewmodel/app_config_view_model.dart';
import '../../../shared/app_scaffold.dart';
import '../viewmodel/product_form_view_model.dart';
import 'widgets/olshop_links_editor.dart';
import 'widgets/variant_builder.dart';

class ProductFormScreen extends StatefulWidget {
  final String productId;
  final String replaceOf;
  const ProductFormScreen(
      {super.key, this.productId = '', this.replaceOf = ''});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _shortDescription = TextEditingController();
  final _price = TextEditingController();
  String? _category;
  bool _limited = false;
  List<VariantOptionModel> _options = [];
  Map<String, int> _stocks = {};
  Map<OlshopPlatform, OlshopSetting> _olshop = {};
  bool _draftApplied = false;

  bool get _isEdit => widget.productId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initialize();
    });
  }

  Future<void> _initialize() async {
    final form = context.read<ProductFormViewModel>();
    await Future.wait([form.init(), context.read<AppConfigViewModel>().init()]);
    if (!mounted ||
        !form.isReady ||
        form.errorMessage != null ||
        _draftApplied) {
      return;
    }
    _draftApplied = true;
    _name.text = form.name;
    _description.text = form.description;
    _shortDescription.text = form.shortDescription;
    final intPrice = int.tryParse(form.price.replaceAll(RegExp(r'\D'), ''));
    _price.text = intPrice != null ? formatRibuan(intPrice) : form.price;
    setState(() {
      _category = form.category;
      _limited = form.limited;
      _options = List.of(form.options);
      _stocks = Map.of(form.stocks);
      _olshop = Map.of(form.olshop);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _shortDescription.dispose();
    _price.dispose();
    super.dispose();
  }

  List<VariantChoice>? _variantChoices() {
    final valid = _options.where(
        (option) => option.name.trim().isNotEmpty && option.values.isNotEmpty);
    return valid.isEmpty
        ? null
        : valid
            .map((option) =>
                VariantChoice(option.name.trim(), List.of(option.values)))
            .toList();
  }

  Future<bool> _confirmDiscard() async {
    final form = context.read<ProductFormViewModel>();
    if (!form.isPhotosDirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Buang perubahan foto?'),
            content:
                const Text('Perubahan foto yang belum disimpan akan hilang.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.destructive),
                child: const Text('Buang'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _save() async {
    final form = context.read<ProductFormViewModel>();
    form
      ..setName(_name.text)
      ..setDescription(_description.text)
      ..setShortDescription(_shortDescription.text)
      ..setPrice(_price.text)
      ..setCategory(_category)
      ..setLimited(_limited)
      ..setVariants(_options, _stocks)
      ..setOlshop(_olshop);
    final saved = await form.submit();
    if (!mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(form.errorMessage ?? 'Gagal menyimpan produk')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(_isEdit
              ? 'Produk diperbarui'
              : 'Produk terkirim dan menunggu persetujuan admin.')),
    );
    context.popOrParent(true);
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<ProductFormViewModel>();
    if (form.isLoading || !form.isReady) {
      return AppScaffold(
        title: _isEdit ? 'Edit Produk' : 'Tambah Produk',
        showBottomNav: false,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (form.errorMessage != null && _isEdit && !_draftApplied) {
      return AppScaffold(
        title: 'Edit Produk',
        showBottomNav: false,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(form.errorMessage!,
                textAlign: TextAlign.center, style: AppTextStyles.bodyMuted),
          ),
        ),
      );
    }
    return PopScope(
      canPop: !form.isPhotosDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _confirmDiscard() && context.mounted) {
          context.popOrParent();
        }
      },
      child: AppScaffold(
        title: _isEdit ? 'Edit Produk' : 'Tambah Produk',
        showBottomNav: false,
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  _isEdit ? 'Perbarui detail produk' : 'Isi detail produk baru',
                  style: AppTextStyles.bodyMuted),
              const SizedBox(height: 16),
              PhotoEditor(
                viewModel: form.photos,
                maxPhotos: 10,
                variantChoices: _variantChoices(),
                label: 'Foto produk (wajib, min. 1)',
                enabled: !form.isSaving,
              ),
              const SizedBox(height: 16),
              AuthField(
                  controller: _name,
                  label: 'Nama Produk',
                  icon: Icons.edit_outlined),
              const SizedBox(height: 16),
              AuthField(
                  controller: _description,
                  label: 'Deskripsi',
                  icon: Icons.description_outlined,
                  maxLines: 4),
              const SizedBox(height: 16),
              AuthField(
                  controller: _shortDescription,
                  label: 'Deskripsi singkat',
                  maxLength: 191,
                  icon: Icons.short_text),
              const SizedBox(height: 16),
              Consumer<AppConfigViewModel>(
                builder: (_, config, __) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kategori', style: AppTextStyles.label),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_category),
                      initialValue: _category,
                      isDense: true,
                      isExpanded: true,
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: AppColors.foreground),
                      dropdownColor: AppColors.surface,
                      icon: const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.keyboard_arrow_down,
                            size: 12, color: AppColors.muted),
                      ),
                      decoration:
                          authInputDecoration(icon: Icons.category_outlined),
                      items: config.categories
                          .map((item) => DropdownMenuItem(
                              value: item.id, child: Text(item.name)))
                          .toList(),
                      onChanged: form.isSaving
                          ? null
                          : (value) => setState(() => _category = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AuthField(
                  controller: _price,
                  label: 'Harga (Rp)',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    ThousandsSeparatorInputFormatter(),
                  ]),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: SwitchListTile(
                  value: _limited,
                  onChanged: form.isSaving
                      ? null
                      : (value) => setState(() => _limited = value),
                  title: const Text('Limited Edition',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Tandai sebagai edisi terbatas',
                      style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  activeThumbColor: AppColors.onPrimary,
                  activeTrackColor: AppColors.primary,
                  inactiveThumbColor: AppColors.onPrimary,
                  inactiveTrackColor: AppColors.border,
                  trackOutlineColor:
                      WidgetStateProperty.all(Colors.transparent),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 16),
              VariantBuilder(
                options: _options,
                stocks: _stocks,
                editable: !_isEdit && !form.isSaving,
                onChanged: (value) {
                  setState(() {
                    _options = value.$1;
                    _stocks = value.$2;
                  });
                  form.setVariants(_options, _stocks);
                },
              ),
              const SizedBox(height: 16),
              Consumer<AppConfigViewModel>(
                builder: (_, config, __) => OlshopLinksEditor(
                  value: _olshop,
                  stores: config.olshopStores,
                  storesKnown: config.settingsOk,
                  errors: form.olshopErrors,
                  enabled: !form.isSaving,
                  onChanged: (value) => setState(() => _olshop = value),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: form.isSaving
                    ? 'Menyimpan...'
                    : (_isEdit ? 'Simpan Perubahan' : 'Tambah Produk'),
                onPressed: form.isSaving ? null : _save,
                icon: const Icon(Icons.check, size: 16),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: form.isSaving
                      ? null
                      : () async {
                          if (await _confirmDiscard() && context.mounted) {
                            context.popOrParent();
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    side:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                    textStyle: GoogleFonts.baloo2(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Batal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
