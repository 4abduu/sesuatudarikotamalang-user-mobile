import '../../data/models/variant_option_model.dart';

/// Urutan sumbu dan nilai tetap sama seperti yang diisi kreator.
List<List<String>> variantCombinations(List<VariantOptionModel> options) {
  if (options.isEmpty || options.any((o) => o.name.isEmpty || o.values.isEmpty)) {
    return [];
  }
  var result = <List<String>>[[]];
  for (final option in options) {
    result = [for (final row in result) for (final value in option.values) [...row, value]];
  }
  return result;
}
