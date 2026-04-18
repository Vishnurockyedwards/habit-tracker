import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import 'life.dart';

/// Port of `PlantCompanion` from the Sprout prototype.
/// Draws into a 200x200 logical viewBox, scaled to the passed size.
class PlantCompanion extends StatelessWidget {
  const PlantCompanion({
    super.key,
    required this.growth,
    required this.accent,
    required this.life,
    this.bloom = false,
    this.size = 180,
  });

  final double growth;
  final AccentPalette accent;
  final Life life;
  final bool bloom;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PlantPainter(
          growth: growth.clamp(0.0, 1.0),
          accent: accent,
          life: life,
          bloom: bloom,
        ),
      ),
    );
  }
}

class _PlantPainter extends CustomPainter {
  final double growth;
  final AccentPalette accent;
  final Life life;
  final bool bloom;

  _PlantPainter({
    required this.growth,
    required this.accent,
    required this.life,
    required this.bloom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200.0;
    canvas.scale(scale);

    _paintSunGlow(canvas);

    // Swayed group (stem + leaves + flower)
    final swayDeg = life.swayT * 2; // 0..2°
    canvas.save();
    canvas.translate(100, 150);
    canvas.rotate(swayDeg * pi / 180);
    canvas.translate(-100, -150);

    final stemH = 20 + growth * 80;
    _paintStem(canvas, stemH);
    _paintLeaf(
      canvas,
      cx: 86,
      cy: 150 - stemH * 0.45,
      rx: 14,
      ry: 8,
      rotationDeg: -25,
      fill: const Color(0xFF8AA67A),
      opacity: growth > 0.1 ? 1.0 : 0.15,
    );
    _paintLeaf(
      canvas,
      cx: 114,
      cy: 150 - stemH * 0.62,
      rx: 16,
      ry: 9,
      rotationDeg: 25,
      fill: const Color(0xFF8AA67A),
      opacity: growth > 0.35 ? 1.0 : 0.15,
    );
    _paintLeaf(
      canvas,
      cx: 82,
      cy: 150 - stemH * 0.8,
      rx: 14,
      ry: 8,
      rotationDeg: -30,
      fill: const Color(0xFF5F7D52),
      opacity: growth > 0.6 ? 1.0 : 0.15,
    );

    final flowerScale = growth >= 1 ? (bloom ? 1.15 : 1.0) : 0.0;
    if (flowerScale > 0) {
      _paintFlower(canvas, 100, 150 - stemH, flowerScale);
    }

    canvas.restore();

    _paintPot(canvas);
    _paintFace(canvas);
  }

  void _paintSunGlow(Canvas canvas) {
    canvas.drawCircle(
      const Offset(100, 60),
      46,
      Paint()..color = SP.gold.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      const Offset(100, 60),
      28,
      Paint()..color = SP.gold.withValues(alpha: 0.28),
    );
  }

  void _paintStem(Canvas canvas, double stemH) {
    final path = Path()
      ..moveTo(100, 150)
      ..quadraticBezierTo(98, 150 - stemH * 0.6, 100, 150 - stemH);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF5F7D52)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintLeaf(
    Canvas canvas, {
    required double cx,
    required double cy,
    required double rx,
    required double ry,
    required double rotationDeg,
    required Color fill,
    required double opacity,
  }) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotationDeg * pi / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      Paint()..color = fill.withValues(alpha: opacity),
    );
    canvas.restore();
  }

  void _paintFlower(Canvas canvas, double cx, double cy, double scale) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);

    final petal = Paint()..color = accent.main;
    canvas.drawCircle(const Offset(0, -8), 6, petal);
    canvas.drawCircle(const Offset(6, -4), 6, petal);
    canvas.drawCircle(const Offset(-6, -4), 6, petal);
    canvas.drawCircle(const Offset(4, -12), 6, petal);
    canvas.drawCircle(const Offset(-4, -12), 6, petal);
    canvas.drawCircle(const Offset(0, -8), 3, Paint()..color = SP.gold);

    canvas.restore();
  }

  void _paintPot(Canvas canvas) {
    final potBody = Path()
      ..moveTo(68, 150)
      ..lineTo(132, 150)
      ..lineTo(126, 180)
      ..lineTo(74, 180)
      ..close();
    canvas.drawPath(potBody, Paint()..color = accent.main);
    final rim = RRect.fromRectAndRadius(
      const Rect.fromLTWH(64, 146, 72, 10),
      const Radius.circular(2),
    );
    canvas.drawRRect(rim, Paint()..color = accent.deep);
  }

  void _paintFace(Canvas canvas) {
    final eyePaint = Paint()..color = SP.cocoa;
    final eyeRy = life.blink ? 0.3 : 1.8;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(90, 166),
        width: 3.6,
        height: eyeRy * 2,
      ),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(110, 166),
        width: 3.6,
        height: eyeRy * 2,
      ),
      eyePaint,
    );

    final mouth = Path();
    if (growth > 0.5) {
      mouth
        ..moveTo(94, 172)
        ..quadraticBezierTo(100, 177, 106, 172);
    } else {
      mouth
        ..moveTo(94, 173)
        ..quadraticBezierTo(100, 174, 106, 173);
    }
    canvas.drawPath(
      mouth,
      Paint()
        ..color = SP.cocoa
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    final cheek = Paint()..color = accent.glow.withValues(alpha: 0.6);
    canvas.drawCircle(const Offset(82, 170), 3, cheek);
    canvas.drawCircle(const Offset(118, 170), 3, cheek);
  }

  @override
  bool shouldRepaint(covariant _PlantPainter old) =>
      old.growth != growth ||
      old.accent != accent ||
      old.life.blink != life.blink ||
      old.life.swayT != life.swayT ||
      old.bloom != bloom;
}
