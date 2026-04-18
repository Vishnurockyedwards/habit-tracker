import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import 'life.dart';

/// Port of `PetCompanion` (cat Moss) from the Sprout prototype.
class PetCompanion extends StatelessWidget {
  const PetCompanion({
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
        painter: _PetPainter(
          growth: growth.clamp(0.0, 1.0),
          accent: accent,
          life: life,
          bloom: bloom,
        ),
      ),
    );
  }
}

class _PetPainter extends CustomPainter {
  final double growth;
  final AccentPalette accent;
  final Life life;
  final bool bloom;

  _PetPainter({
    required this.growth,
    required this.accent,
    required this.life,
    required this.bloom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200.0;
    canvas.scale(scale);

    // Sun glow
    canvas.drawCircle(
      const Offset(100, 60),
      46,
      Paint()..color = SP.gold.withValues(alpha: 0.15),
    );
    // Ground shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(100, 172),
        width: 92,
        height: 10,
      ),
      Paint()..color = SP.cocoa.withValues(alpha: 0.1),
    );

    _paintTail(canvas);
    // Body
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(100, 145),
        width: 80,
        height: 60,
      ),
      Paint()..color = accent.main,
    );
    // Belly
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(100, 155),
        width: 44,
        height: 30,
      ),
      Paint()..color = accent.soft.withValues(alpha: 0.7),
    );

    _paintHead(canvas);

    if (bloom) _paintBloomSparkles(canvas);
  }

  void _paintTail(Canvas canvas) {
    canvas.save();
    canvas.translate(130, 150);
    canvas.rotate(life.swayT * 15 * pi / 180);
    canvas.translate(-130, -150);
    final path = Path()
      ..moveTo(130, 150)
      ..quadraticBezierTo(155, 140, 152, 115);
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.main
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();
  }

  void _paintHead(Canvas canvas) {
    // Head tilt: 0 → -2° via swayT
    canvas.save();
    canvas.translate(100, 110);
    canvas.rotate(-life.swayT * 2 * pi / 180);
    canvas.translate(-100, -110);

    _paintEar(
      canvas,
      pivot: const Offset(82, 95),
      wagDeg: -life.swayT * 3,
      outerPath: [
        const Offset(78, 100),
        const Offset(74, 78),
        const Offset(92, 92),
      ],
      innerPath: [
        const Offset(80, 96),
        const Offset(78, 84),
        const Offset(88, 92),
      ],
    );
    _paintEar(
      canvas,
      pivot: const Offset(118, 95),
      wagDeg: life.swayT * 3,
      outerPath: [
        const Offset(122, 100),
        const Offset(126, 78),
        const Offset(108, 92),
      ],
      innerPath: [
        const Offset(120, 96),
        const Offset(122, 84),
        const Offset(112, 92),
      ],
    );

    // Head circle
    canvas.drawCircle(
      const Offset(100, 110),
      28,
      Paint()..color = accent.main,
    );
    // Cheeks
    final cheek = Paint()..color = accent.glow.withValues(alpha: 0.6);
    canvas.drawCircle(const Offset(82, 118), 5, cheek);
    canvas.drawCircle(const Offset(118, 118), 5, cheek);

    // Eyes
    final eyePaint = Paint()..color = SP.cocoa;
    final eyeRy = life.blink ? 0.4 : 4.0;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(90, 108), width: 6, height: eyeRy * 2),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(110, 108), width: 6, height: eyeRy * 2),
      eyePaint,
    );
    if (!life.blink) {
      final spark = Paint()..color = Colors.white;
      canvas.drawCircle(const Offset(91.5, 106), 1, spark);
      canvas.drawCircle(const Offset(111.5, 106), 1, spark);
    }

    // Nose
    final nose = Path()
      ..moveTo(97, 118)
      ..quadraticBezierTo(100, 121, 103, 118)
      ..close();
    canvas.drawPath(nose, Paint()..color = accent.deep);

    // Mouth
    final mouth = Path();
    if (growth > 0.5) {
      mouth
        ..moveTo(95, 122)
        ..quadraticBezierTo(100, 127, 105, 122);
    } else {
      mouth
        ..moveTo(96, 124)
        ..quadraticBezierTo(100, 125, 104, 124);
    }
    canvas.drawPath(
      mouth,
      Paint()
        ..color = SP.cocoa
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Whiskers
    final whisker = Paint()
      ..color = SP.cocoa.withValues(alpha: 0.5)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(78, 120), const Offset(68, 118), whisker);
    canvas.drawLine(const Offset(78, 122), const Offset(68, 124), whisker);
    canvas.drawLine(const Offset(122, 120), const Offset(132, 118), whisker);
    canvas.drawLine(const Offset(122, 122), const Offset(132, 124), whisker);

    canvas.restore();
  }

  void _paintEar(
    Canvas canvas, {
    required Offset pivot,
    required double wagDeg,
    required List<Offset> outerPath,
    required List<Offset> innerPath,
  }) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(wagDeg * pi / 180);
    canvas.translate(-pivot.dx, -pivot.dy);

    final outer = Path()..moveTo(outerPath[0].dx, outerPath[0].dy);
    for (final p in outerPath.skip(1)) {
      outer.lineTo(p.dx, p.dy);
    }
    outer.close();
    canvas.drawPath(outer, Paint()..color = accent.deep);

    final inner = Path()..moveTo(innerPath[0].dx, innerPath[0].dy);
    for (final p in innerPath.skip(1)) {
      inner.lineTo(p.dx, p.dy);
    }
    inner.close();
    canvas.drawPath(inner, Paint()..color = accent.glow);

    canvas.restore();
  }

  void _paintBloomSparkles(Canvas canvas) {
    // Two pulsing sparkles; derive phase from bobT for a simple animated pulse.
    final pulse1 = (sin(life.bobT * 2 * pi) + 1) / 2; // 0..1
    final pulse2 = (sin(life.bobT * 2 * pi + pi / 2) + 1) / 2;
    canvas.drawCircle(
      const Offset(60, 70),
      3,
      Paint()..color = accent.main.withValues(alpha: 0.8 * pulse1),
    );
    canvas.drawCircle(
      const Offset(145, 80),
      2,
      Paint()..color = accent.main.withValues(alpha: 0.6 * pulse2),
    );
  }

  @override
  bool shouldRepaint(covariant _PetPainter old) =>
      old.growth != growth ||
      old.accent != accent ||
      old.life.blink != life.blink ||
      old.life.swayT != life.swayT ||
      old.life.bobT != life.bobT ||
      old.bloom != bloom;
}
