import 'package:flutter/material.dart';

import '../../data/date_key.dart';
import '../../data/database.dart';
import '../../theme/tokens.dart';

/// 7-day vertical bars — one bar per weekday (M..S). Today's bar uses a
/// 135° stripe pattern in accent.main / accent.deep.
class WeeklyBars extends StatelessWidget {
  const WeeklyBars({
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
    // Build last 7 days in Monday..Sunday order for the current ISO week.
    final mondayOffset = today.weekday - 1;
    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: mondayOffset));
    final days = <_DayStats>[];
    final expected = activeHabitCount == 0 ? 1 : activeHabitCount;

    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayYmdStr = todayYmd();

    for (var i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final key = ymd(date);
      final count = completions.where((c) => c.date == key).length;
      days.add(_DayStats(
        label: labels[i],
        count: count,
        total: expected,
        pct: (count / expected).clamp(0.0, 1.0),
        isToday: key == todayYmdStr,
      ));
    }

    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in days) ...[
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${d.count}/${d.total}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: SP.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 90,
                    width: double.infinity,
                    child: _Bar(
                      pct: d.pct,
                      accent: accent,
                      striped: d.isToday,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    d.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: d.isToday ? accent.deep : SP.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (d != days.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _DayStats {
  final String label;
  final int count;
  final int total;
  final double pct;
  final bool isToday;
  _DayStats({
    required this.label,
    required this.count,
    required this.total,
    required this.pct,
    required this.isToday,
  });
}

class _Bar extends StatelessWidget {
  const _Bar({required this.pct, required this.accent, required this.striped});
  final double pct;
  final AccentPalette accent;
  final bool striped;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        color: SP.creamDeep,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: pct, end: pct),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, _) => FractionallySizedBox(
              heightFactor: value,
              widthFactor: 1,
              child: striped
                  ? CustomPaint(
                      painter: _StripePainter(
                        base: accent.main,
                        stripe: accent.deep,
                      ),
                    )
                  : ColoredBox(color: accent.main),
            ),
          ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  final Color base;
  final Color stripe;
  _StripePainter({required this.base, required this.stripe});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final paint = Paint()
      ..color = stripe
      ..strokeWidth = 4;
    final span = size.width + size.height;
    for (double d = -size.height; d < span; d += 8) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StripePainter old) =>
      old.base != base || old.stripe != stripe;
}
