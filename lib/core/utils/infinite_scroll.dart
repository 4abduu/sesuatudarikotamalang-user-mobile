import 'package:flutter/widgets.dart';

/// Helper listener untuk pagination infinite scroll
void setupInfiniteScroll({
  required ScrollController controller,
  required VoidCallback onLoadMore,
  double threshold = 200.0,
}) {
  controller.addListener(() {
    if (!controller.hasClients) return;
    final maxScroll = controller.position.maxScrollExtent;
    final currentScroll = controller.position.pixels;
    if (maxScroll - currentScroll <= threshold) {
      onLoadMore();
    }
  });
}

