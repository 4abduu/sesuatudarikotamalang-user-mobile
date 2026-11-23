import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/app_version.dart';
import '../../../features/catalog/viewmodel/app_config_view_model.dart';

class AppUpdateScreen extends StatelessWidget {
  const AppUpdateScreen({
    super.key,
    required this.config,
  });

  final AppConfigViewModel config;

  Future<void> _contactDeveloper(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: config.supportEmail,
      queryParameters: {
        'subject': 'Bantuan update aplikasi Sesuatu DariKota Malang',
        'body': 'Versi aplikasi: ${AppVersion.current}',
      },
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kirim email ke ${config.supportEmail}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.system_update_alt_rounded, size: 72),
                  const SizedBox(height: 20),
                  const Text(
                    'Aplikasi perlu diperbarui',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    config.updateMessage ??
                        'Versi aplikasi ini belum kompatibel dengan server terbaru. Silakan gunakan versi terbaru atau hubungi developer.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Versi saat ini: ${AppVersion.current}',
                    textAlign: TextAlign.center,
                  ),
                  if (config.minimumVersion != null)
                    Text('Minimum versi: ${config.minimumVersion}'),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _contactDeveloper(context),
                    icon: const Icon(Icons.email_outlined),
                    label: Text('Hubungi developer (${config.supportEmail})'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: config.fetchSettings,
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
