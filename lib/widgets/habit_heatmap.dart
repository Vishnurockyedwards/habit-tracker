import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/date_key.dart';
import '../theme/tokens.dart';

/// GitHub-style heatmap: 7 rows (Mon..Sun) × N columns (weeks).
/// `intensityByDate` maps `yyyy-MM-dd` → 0..1. Missing dates render as empty.
class HabitHeatmap extends StatelessWidget {
  const HabitHeatmap({
    super.key,
    required this.intensityByDate,
    required this.color,
    this.weeks = 26,
    this.endDate,
  });

  final Map<String, double> intensityByDate;
  final Color color;
  final int weeks;
  final DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = endDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Align last column to current week (Mon start).
    final currentWeekStart =
        DateTime(today.year, today.month, today.day - (today.weekday - 1));
    final firstWeekStart = DateTime(
      currentWeekStart.year,
      currentWeekStart.month,
      currentWeekStart.day - 7 * (weeks - 1),
    );

    final emptyColor = theme.colorScheme.surfaceContainerHighest;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: 10,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 3.0;
        const rowLabelWidth = 18.0;
        final available = constraints.maxWidth - rowLabelWidth;
        final cell = ((available - gap * (weeks - 1)) / weeks)
            .clamp(6.0, 18.0)
            .toDouble();

        final monthLabels = _monthLabels(firstWeekStart, weeks);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month label row
            Padding(
              padding: const EdgeInsets.only(left: rowLabelWidth),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    for (var w = 0; w < weeks; w++) ...[
                      SizedBox(
                        width: cell,
                        child: Text(
                          monthLabels[w] ?? '',
                          style: labelStyle,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          softWrap: false,
                        ),
                      ),
                      if (w < weeks - 1) const SizedBox(width: gap),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Grid with day-of-week labels on the left
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: rowLabelWidth,
                  child: Column(
                    children: [
                      for (var d = 0; d < 7; d++) ...[
                        SizedBox(
                          height: cell,
                          child: Text(
                            (d == 0 || d == 2 || d == 4)
                                ? const ['M', '', 'W', '', 'F', '', ''][d]
                                : '',
                            style: labelStyle,
                          ),
                        ),
                        if (d < 6) const SizedBox(height: gap),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      for (var w = 0; w < weeks; w++) ...[
                        _WeekColumn(
                          weekStart: DateTime(
                            firstWeekStart.year,
                            firstWeekStart.month,
                            firstWeekStart.day + 7 * w,
                          ),
                          today: today,
                          cell: cell,
                          gap: gap,
                          intensityByDate: intensityByDate,
                          baseColor: color,
                          emptyColor: emptyColor,
                        ),
                        if (w < weeks - 1) const SizedBox(width: gap),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static Map<int, String> _monthLabels(DateTime firstWeekStart, int weeks) {
    final labels = <int, String>{};
    int? lastMonth;
    for (var w = 0; w < weeks; w++) {
      final weekStart = DateTime(
        firstWeekStart.year,
        firstWeekStart.month,
        firstWeekStart.day + 7 * w,
      );
      if (weekStart.month != lastMonth) {
        labels[w] = DateFormat.MMM().format(weekStart);
        lastMonth = weekStart.month;
      }
    }
    return labels;
  }
}

class _WeekColumn extends StatelessWidget {
  const _WeekColumn({
    required this.weekStart,
    required this.today,
    required this.cell,
    required this.gap,
    required this.intensityByDate,
    required this.baseColor,
    required this.emptyColor,
  });

  final DateTime weekStart;
  final DateTime today;
  final double cell;
  final double gap;
  final Map<String, double> intensityByDate;
  final Color baseColor;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var d = 0; d < 7; d++) ...[
          _Cell(
            date: DateTime(weekStart.year, weekStart.month, weekStart.day + d),
            today: today,
            size: cell,
            intensityByDate: intensityByDate,
            baseColor: baseColor,
            emptyColor: emptyColor,
          ),
          if (d < 6) SizedBox(height: gap),
        ],
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.date,
    required this.today,
    required this.size,
    required this.intensityByDate,
    required this.baseColor,
    required this.emptyColor,
  });

  final DateTime date;
  final DateTime today;
  final double size;
  final Map<String, double> intensityByDate;
  final Color baseColor;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    if (date.isAfter(today)) {
      return SizedBox(width: size, height: size);
    }
    final key = ymd(date);
    final intensity = (intensityByDate[key] ?? 0).clamp(0.0, 1.0);
    final isToday = ymd(today) == key;
    final color = intensity <= 0
        ? emptyColor
        : Color.lerp(emptyColor, baseColor, 0.35 + 0.65 * intensity)!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: isToday
            ? Border.all(
                color: Theme.of(context).colorScheme.onSurface,
                width: 1,
              )
            : null,
      ),
    );
  }
}

class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = theme.colorScheme.surfaceContainerHighest;
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final levels = <double>[0, 0.33, 0.66, 1];
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Less', style: style),
        const SizedBox(width: AppSpacing.xs),
        for (final v in levels) ...[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: v <= 0 ? empty : Color.lerp(empty, color, 0.35 + 0.65 * v),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 2),
        ],
        const SizedBox(width: AppSpacing.xs),
        Text('More', style: style),
      ],
    );
  }
}
