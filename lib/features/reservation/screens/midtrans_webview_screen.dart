import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class MidtransWebViewScreen extends StatefulWidget {
  final String url;
  final String? orderId;

  const MidtransWebViewScreen({
    super.key,
    required this.url,
    this.orderId,
  });

  @override
  State<MidtransWebViewScreen> createState() => _MidtransWebViewScreenState();
}

class _MidtransWebViewScreenState extends State<MidtransWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initWebView();
    }
  }

  void _initWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _progress = progress;
                if (progress == 100) _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
            _checkRedirect(url);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
            _checkRedirect(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_isCompletedOrCancelUrl(request.url)) {
              if (mounted) context.pop(true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    _controller = controller;
  }

  bool _isCompletedOrCancelUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('order_id=') ||
        lower.contains('status_code=') ||
        lower.contains('/finish') ||
        lower.contains('/completed') ||
        lower.contains('/unfinish') ||
        lower.contains('/cancel') ||
        lower.contains('/error');
  }

  void _checkRedirect(String url) {
    if (_isCompletedOrCancelUrl(url)) {
      if (mounted) context.pop(true);
    }
  }

  Future<void> _openExternalBrowser() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Did pop triggers naturally
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran Midtrans'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(true),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              tooltip: 'Buka di Browser',
              onPressed: _openExternalBrowser,
            ),
          ],
          bottom: _isLoading && !kIsWeb
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3.0),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress / 100.0 : null,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              : null,
        ),
        body: kIsWeb
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.payment, size: 64, color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text('Pembayaran Online Web', style: AppTextStyles.h2),
                      const SizedBox(height: 8),
                      Text(
                        'Di Flutter Web, pembayaran Midtrans diselesaikan lewat tab browser terpisah untuk keamanan transaksi.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMuted,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.launch),
                        label: const Text('Buka Halaman Pembayaran'),
                        onPressed: _openExternalBrowser,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        child: const Text('Selesai / Cek Status Pembayaran'),
                        onPressed: () => context.pop(true),
                      ),
                    ],
                  ),
                ),
              )
            : (_controller != null
                ? WebViewWidget(controller: _controller!)
                : const Center(child: CircularProgressIndicator())),
      ),
    );
  }
}
