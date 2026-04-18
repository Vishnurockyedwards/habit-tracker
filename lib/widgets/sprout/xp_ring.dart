import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// 72x72 circular XP ring — creamDeep track, accent-main progress stroke.
/// [progress] is 0..1 within the current level. Stroke animates smoothly.
class XpRing extends StatelessWidget {
  const XpRing({
    super.key,
    required this.progress,
    required this.level,
    required this.accent,
    this.size = 72,
  });

  final double progress;
  final int level;
  final AccentPalette accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: clamped, end: clamped),
            duration: const Duration(milliseconds: 800),
            curve: const Cubic(0.2, 0.8, 0.2, 1),
            builder: (context, value, _) => CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(progress: value, accent: accent),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'LV',
                style: TextStyle(
                  fontSize: 9,
                  color: SP.muted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '$level',
                style: const TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: SP.cocoa,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final AccentPalette accent;

  _RingPainter({required this.progress, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 72) * 28;
    final strokeWidth = (size.width / 72) * 6;

    final track = Paint()
      ..color = SP.creamDeep
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;
    final arc = Paint()
      ..color = accent.main
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.accent != accent;
}
