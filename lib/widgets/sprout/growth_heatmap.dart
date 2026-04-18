import 'package:flutter/material.dart';

import '../../data/date_key.dart';
import '../../data/database.dart';
import '../../theme/tokens.dart';

/// 13w × 7d aggregate heatmap — one cell per day of the last 91 days,
/// 5 intensity bins computed as (completions that day) / (active habits).
class GrowthHeatmap extends StatelessWidget {
  const GrowthHeatmap({
    super.key,
    required this.completions,
    required this.activeHabitCount,
    required this.accent,
  });

  final List<HabitCompletion> completions;
  final int activeHabitCount;
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final countsByDate = <String, int>{};
    for (final c in completions) {
      countsByDate[c.date] = (countsByDate[c.date] ?? 0) + 1;
    }
    final expected = activeHabitCount == 0 ? 1 : activeHabitCount;

    final shades = [
      SP.creamDeep,
      Color.lerp(SP.creamDeep, accent.main, 0.25)!,
      Color.lerp(SP.creamDeep, accent.main, 0.50)!,
      Color.lerp(SP.creamDeep, accent.main, 0.75)!,
      accent.main,
    ];

    final days = <int>[];
    for (var i = 90; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final done = countsByDate[ymd(d)] ?? 0;
      final ratio = done / expected;
      final level = ratio == 0
          ? 0
          : ratio < 0.25
              ? 1
              : ratio < 0.5
                  ? 2
                  : ratio < 0.75
                      ? 3
                      : 4;
      days.add(level);
    }

    final cells = <List<int>>[];
    for (var w = 0; w < 13; w++) {
      final col = <int>[];
      for (var d = 0; d < 7; d++) {
        final idx = w * 7 + d;
        if (idx < days.length) col.add(days[idx]);
      }
      cells.add(col);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final col in cells)
              Column(
                children: [
                  for (var i = 0; i < col.length; i++) ...[
                    _Cell(color: shades[col[i]]),
                    if (i < col.length - 1) const SizedBox(height: 4),
                  ],
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              'Less',
              style: TextStyle(
                fontSize: 11,
                color: SP.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            for (final s in shades) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: s,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
            ],
            const SizedBox(width: 4),
            const Text(
              'More',
              style: TextStyle(
                fontSize: 11,
                color: SP.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0x082D1F16),
          width: 1,
        ),
      ),
    );
  }
}
