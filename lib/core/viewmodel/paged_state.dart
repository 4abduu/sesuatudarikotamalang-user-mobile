class PageResult<T> {
  const PageResult({required this.items, required this.total, required this.totalPages});
  final List<T> items;
  final int total;
  final int totalPages;
}

class PagedState<T> {
  PagedState({this.limit = 10});
  final int limit;
  List<T> items = <T>[];
  int page = 1;
  int total = 0;
  bool hasMore = false;
  bool isLoading = false;
  bool isLoadingMore = false;
  String? error;
  int _requestId = 0;

  int beginFirstPage() {
    page = 1;
    error = null;
    isLoading = true;
    isLoadingMore = false;
    return ++_requestId;
  }

  int beginNextPage() {
    isLoadingMore = true;
    return _requestId;
  }

  bool isStale(int id) => id != _requestId;

  void applyFirstPage(PageResult<T> result) {
    items = List<T>.of(result.items);
    total = result.total;
    hasMore = page < result.totalPages;
  }

  void applyNextPage(PageResult<T> result) {
    page += 1;
    items = [...items, ...result.items];
    total = result.total;
    hasMore = page < result.totalPages;
  }
}
