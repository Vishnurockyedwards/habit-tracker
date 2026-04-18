import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// InkWell button wrapped in a dashed border. Used for "+ Add a habit"
/// and "+ Add note".
class DashedBorderButton extends StatelessWidget {
  const DashedBorderButton({
    super.key,
    required this.label,
    required this.onTap,
    this.verticalPadding = 14,
    this.color = SP.muted,
    this.radius = 16,
  });

  final String label;
  final VoidCallback onTap;
  final double verticalPadding;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: color, radius: radius),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics().toList();
    const dash = 6.0;
    const gap = 4.0;
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
