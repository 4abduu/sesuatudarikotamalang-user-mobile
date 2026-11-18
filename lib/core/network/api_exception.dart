class ApiException implements Exception {
  final int status;
  final String message;
  final String? code;
  final Map<String, dynamic>? data;

  ApiException(this.status, this.message, [this.code, this.data]);

  String? get requestId => data?['requestId'] as String?;

  List<int> get rejectedIndexes {
    final list = data?['rejectedIndexes'];
    if (list is List) return list.map((e) => (e as num).toInt()).toList();
    return const [];
  }

  @override
  String toString() => message;
}
