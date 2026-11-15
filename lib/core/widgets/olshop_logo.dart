import 'package:flutter/material.dart';
import '../../data/models/olshop_model.dart';

/// Logo marketplace. Memakai PNG di assets/images/olshop/<id>.png; bila berkas
/// belum ada, tampil lencana huruf berwarna khas marketplace (tidak error).
class OlshopLogo extends StatelessWidget {
  final OlshopPlatform platform;
  final double size;
  const OlshopLogo({super.key, required this.platform, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: Image.asset(
          platform.assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _Fallback(platform: platform, size: size),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final OlshopPlatform platform;
  final double size;
  const _Fallback({required this.platform, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: platform.color,
      child: Text(
        platform.initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * (platform.initial.length > 1 ? 0.36 : 0.5),
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
