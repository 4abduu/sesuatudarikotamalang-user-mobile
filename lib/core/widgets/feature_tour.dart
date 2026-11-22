import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FeatureTourStep {
  final GlobalKey target;
  final String title;
  final String description;

  const FeatureTourStep({required this.target, required this.title, required this.description});
}

Future<void> showFeatureTour(BuildContext context, List<FeatureTourStep> steps) async {
  if (steps.isEmpty) return;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _FeatureTourOverlay(
      steps: steps,
      onFinished: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
}

class _FeatureTourOverlay extends StatefulWidget {
  final List<FeatureTourStep> steps;
  final VoidCallback onFinished;

  const _FeatureTourOverlay({required this.steps, required this.onFinished});

  @override
  State<_FeatureTourOverlay> createState() => _FeatureTourOverlayState();
}

class _FeatureTourOverlayState extends State<_FeatureTourOverlay> {
  int _index = 0;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _locateTarget();
  }

  void _locateTarget() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderObject = widget.steps[_index].target.currentContext?.findRenderObject();
      if (renderObject is RenderBox && renderObject.hasSize) {
        final origin = renderObject.localToGlobal(Offset.zero);
        setState(() => _targetRect = origin & renderObject.size);
      }
    });
  }

  void _next() {
    if (_index == widget.steps.length - 1) {
      widget.onFinished();
      return;
    }
    setState(() {
      _index++;
      _targetRect = null;
    });
    _locateTarget();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final rect = _targetRect ?? Rect.fromLTWH(media.width / 2 - 32, media.height / 2 - 32, 64, 64);
    final double tooltipWidth = (media.width - 32).clamp(240.0, 340.0).toDouble();
    final double left = (rect.center.dx - tooltipWidth / 2).clamp(16.0, media.width - tooltipWidth - 16.0).toDouble();
    final below = rect.bottom + 16 < media.height - 190;
    final double top = (below ? rect.bottom + 16 : (rect.top - 190).clamp(16.0, media.height - 174.0)).toDouble();
    final step = widget.steps[_index];

    return Material(
      type: MaterialType.transparency,
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _TourShadePainter(rect))),
        Positioned(
          left: left,
          top: top,
          width: tooltipWidth,
          child: Material(
            color: AppColors.surface,
            elevation: 10,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Expanded(child: Text(step.title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.foreground))),
                  Text('${_index + 1}/${widget.steps.length}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ]),
                const SizedBox(height: 8),
                Text(step.description, style: const TextStyle(fontSize: 13, color: AppColors.foreground, height: 1.35)),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: _next, child: Text(_index == widget.steps.length - 1 ? 'Selesai' : 'Lanjut')),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _TourShadePainter extends CustomPainter {
  final Rect target;

  const _TourShadePainter(this.target);

  @override
  void paint(Canvas canvas, Size size) {
    final shade = Paint()..color = Colors.black.withValues(alpha: 0.68);
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, shade);
    final clear = Paint()..blendMode = BlendMode.clear;
    canvas.drawRRect(RRect.fromRectAndRadius(target.inflate(8), const Radius.circular(14)), clear);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TourShadePainter oldDelegate) => oldDelegate.target != target;
}
