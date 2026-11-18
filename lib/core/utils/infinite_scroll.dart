import 'package:flutter/widgets.dart';

/// Helper listener untuk pagination infinite scroll
void setupInfiniteScroll({
  required ScrollController controller,
  required VoidCallback onLoadMore,
  double threshold = 200.0,
}) {
  var callbackScheduled = false;

  controller.addListener(() {
    if (!controller.hasClients) return;
    final maxScroll = controller.position.maxScrollExtent;
    final currentScroll = controller.position.pixels;
    if (maxScroll - currentScroll > threshold || callbackScheduled) return;

    // A scroll notification can arrive while Flutter is still laying out the
    // sliver. Defer the state change so loadMore() cannot notify listeners
    // while the current widget tree is dirty.
    callbackScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callbackScheduled = false;
      if (!controller.hasClients) return;
      onLoadMore();
    });
  });
}

