bool isMidtransReturnUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('order_id=') ||
        lower.contains('status_code=') ||
        lower.contains('/finish') ||
        lower.contains('/completed') ||
        lower.contains('/unfinish') ||
        lower.contains('/cancel') ||
        lower.contains('/error');
  }

