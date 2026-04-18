import 'package:flutter/material.dart';

import '../../data/date_key.dart';
import '../../data/database.dart';
import '../../theme/tokens.dart';

/// 30-cell horizontal heat strip used on Habit Detail. Three intensities:
/// empty (creamDeep), mid (accent.main 45%), full (accent.main).
class MiniHeatStrip extends StatelessWidget {
  const MiniHeatStrip({
    super.key,
    required this.completions,
    required this.target,
    required this.accent,
  });

  final List<HabitCompletion> completions;
  final double target;
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final byDate = <String, HabitCompletion>{
      for (final c in completions) c.date: c,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 3.0;
        final cellW = (constraints.maxWidth - gap * 29) / 30;
        return Row(
          children: [
            for (var i = 29; i >= 0; i--) ...[
              _Cell(
                width: cellW,
                color: _colorFor(
                  byDate[ymd(today.subtract(Duration(days: i)))],
                  target: target,
                  accent: accent,
                ),
              ),
              if (i > 0) SizedBox(width: gap),
            ],
          ],
        );
      },
    );
  }

  Color _colorFor(
    HabitCompletion? c, {
    required double target,
    required AccentPalette accent,
  }) {
    if (c == null) return SP.creamDeep;
    final safeTarget = target <= 0 ? 1.0 : target;
    final ratio = (c.value / safeTarget).clamp(0.0, 1.0);
    if (ratio < 0.5) {
      return Color.lerp(SP.creamDeep, accent.main, 0.45) ?? accent.main;
    }
    return accent.main;
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
