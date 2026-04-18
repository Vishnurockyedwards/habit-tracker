import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import 'life.dart';

/// Port of `SproutCreatureCompanion` (Pip) from the Sprout prototype.
class CreatureCompanion extends StatelessWidget {
  const CreatureCompanion({
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
        painter: _CreaturePainter(
          growth: growth.clamp(0.0, 1.0),
          accent: accent,
          life: life,
          bloom: bloom,
        ),
      ),
    );
  }
}

class _CreaturePainter extends CustomPainter {
  final double growth;
  final AccentPalette accent;
  final Life life;
  final bool bloom;

  _CreaturePainter({
    required this.growth,
    required this.accent,
    required this.life,
    required this.bloom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200.0;
    canvas.scale(scale);

    // Sun glow + ground shadow (outside bob group)
    canvas.drawCircle(
      const Offset(100, 60),
      46,
      Paint()..color = SP.gold.withValues(alpha: 0.18),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(100, 172),
        width: 88,
        height: 10,
      ),
      Paint()..color = SP.cocoa.withValues(alpha: 0.1),
    );

    // Bob: translateY = -sin(bobT * pi) * 4
    final bobY = -sin(life.bobT * pi) * 4;
    canvas.save();
    canvas.translate(0, bobY);

    _paintLeafHair(canvas);
    _paintBody(canvas);
    _paintArms(canvas);
    _paintFace(canvas);
    if (growth >= 1) _paintCrown(canvas);

    canvas.restore();

    if (bloom) _paintBloomGlyphs(canvas);
  }

  void _paintLeafHair(Canvas canvas) {
    canvas.save();
    canvas.translate(100, 88);
    canvas.rotate(-life.swayT * 3 * pi / 180);
    canvas.translate(-100, -88);

    final leftLeaf = Path()
      ..moveTo(100, 92)
      ..quadraticBezierTo(86, 72, 94, 58)
      ..quadraticBezierTo(104, 70, 100, 92)
      ..close();
    canvas.drawPath(leftLeaf, Paint()..color = const Color(0xFF7A9568));

    final rightLeaf = Path()
      ..moveTo(100, 92)
      ..quadraticBezierTo(114, 72, 106, 58)
      ..quadraticBezierTo(96, 70, 100, 92)
      ..close();
    canvas.drawPath(rightLeaf, Paint()..color = const Color(0xFF8AA67A));

    final stem = Path()
      ..moveTo(100, 88)
      ..quadraticBezierTo(100, 70, 100, 60);
    canvas.drawPath(
      stem,
      Paint()
        ..color = const Color(0xFF5F7D52)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    canvas.restore();
  }

  void _paintBody(Canvas canvas) {
    final body = Path()
      ..moveTo(100, 90)
      ..cubicTo(72, 90, 62, 118, 70, 145)
      ..cubicTo(76, 165, 124, 165, 130, 145)
      ..cubicTo(138, 118, 128, 90, 100, 90)
      ..close();
    canvas.drawPath(body, Paint()..color = accent.main);

    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(100, 148),
        width: 36,
        height: 20,
      ),
      Paint()..color = accent.soft.withValues(alpha: 0.5),
    );
  }

  void _paintArms(Canvas canvas) {
    _paintArm(canvas, const Offset(68, 130), -15);
    _paintArm(canvas, const Offset(132, 130), 15);
  }

  void _paintArm(Canvas canvas, Offset center, double rotationDeg) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationDeg * pi / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 12, height: 20),
      Paint()..color = accent.deep,
    );
    canvas.restore();
  }

  void _paintFace(Canvas canvas) {
    // Cheeks
    final cheek = Paint()..color = accent.glow.withValues(alpha: 0.7);
    canvas.drawCircle(const Offset(80, 130), 5, cheek);
    canvas.drawCircle(const Offset(120, 130), 5, cheek);

    // Eyes
    final eyePaint = Paint()..color = SP.cocoa;
    final eyeRy = life.blink ? 0.5 : 5.0;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(88, 120), width: 8, height: eyeRy * 2),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(112, 120), width: 8, height: eyeRy * 2),
      eyePaint,
    );
    if (!life.blink) {
      final spark = Paint()..color = Colors.white;
      canvas.drawCircle(const Offset(89.5, 118), 1.2, spark);
      canvas.drawCircle(const Offset(113.5, 118), 1.2, spark);
    }

    // Mouth
    final mouth = Path();
    if (growth > 0.5) {
      mouth
        ..moveTo(92, 136)
        ..quadraticBezierTo(100, 144, 108, 136);
    } else {
      mouth
        ..moveTo(94, 138)
        ..quadraticBezierTo(100, 140, 106, 138);
    }
    canvas.drawPath(
      mouth,
      Paint()
        ..color = SP.cocoa
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintCrown(Canvas canvas) {
    canvas.save();
    canvas.translate(100, 58);
    final petal = Paint()..color = accent.deep;
    canvas.drawCircle(Offset.zero, 4, petal);
    canvas.drawCircle(const Offset(5, 3), 4, petal);
    canvas.drawCircle(const Offset(-5, 3), 4, petal);
    canvas.drawCircle(const Offset(0, -5), 4, petal);
    canvas.drawCircle(Offset.zero, 2, Paint()..color = SP.gold);
    canvas.restore();
  }

  void _paintBloomGlyphs(Canvas canvas) {
    final pulse1 = (sin(life.bobT * 2 * pi) + 1) / 2; // 0..1
    final pulse2 = (sin(life.bobT * 2 * pi + pi / 2) + 1) / 2;
    _paintStar(canvas, const Offset(54, 78), 14, pulse1);
    _paintStar(canvas, const Offset(146, 90), 10, pulse2);
  }

  void _paintStar(Canvas canvas, Offset pos, double fontSize, double alpha) {
    final tp = TextPainter(
      text: TextSpan(
        text: '✦',
        style: TextStyle(
          fontSize: fontSize,
          color: accent.main.withValues(alpha: alpha),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _CreaturePainter old) =>
      old.growth != growth ||
      old.accent != accent ||
      old.life.blink != life.blink ||
      old.life.swayT != life.swayT ||
      old.life.bobT != life.bobT ||
      old.bloom != bloom;
}
