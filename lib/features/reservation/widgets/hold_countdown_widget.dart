import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

class HoldCountdownWidget extends StatefulWidget {
  final DateTime expiresAt;
  const HoldCountdownWidget({super.key, required this.expiresAt});
  @override
  State<HoldCountdownWidget> createState() => _HoldCountdownWidgetState();
}

class _HoldCountdownWidgetState extends State<HoldCountdownWidget> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.expiresAt.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _remaining = widget.expiresAt.difference(DateTime.now()));
      if (_remaining.isNegative) _timer?.cancel();
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _openWhatsApp() async {
    const text = 'Halo, saya mengalami kendala dengan reservasi yang stoknya sedang di-hold. Bisa dibantu?';
    final uri = Uri.parse('https://wa.me/6281234567890?text=${Uri.encodeComponent(text)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka WhatsApp.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.isNegative) {
      return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.destructive.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [Icon(Icons.error, color: AppColors.destructive), SizedBox(width: 8), Expanded(child: Text('Waktu habis, silakan reservasi ulang.', style: TextStyle(color: AppColors.destructive)))]));
    }
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.mustard.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        const Icon(Icons.hourglass_top, color: AppColors.mustard),
        const SizedBox(height: 8),
        Text('Stok di-hold sampai', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.muted)),
        Text('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}', style: GoogleFonts.baloo2(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.mustard)),
        const SizedBox(height: 4),
        Text('Harap datang sebelum waktu ini.', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.muted)),
        const SizedBox(height: 12),
        InkWell(
          onTap: _openWhatsApp,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_outlined, size: 14, color: AppColors.moss),
                const SizedBox(width: 6),
                Text('Ada kendala? Hubungi kami via WhatsApp', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.moss, decoration: TextDecoration.underline)),
              ],
            ),
          ),
        ),
      ]));
  }
}
