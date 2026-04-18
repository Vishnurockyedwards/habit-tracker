import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/date_key.dart';
import '../data/providers.dart';
import '../data/tweaks.dart';
import '../theme/tokens.dart';
import '../widgets/companion/companion.dart';
import '../widgets/habit_icon.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tweaks = ref.watch(tweaksProvider);
    final accent = ref.watch(accentPaletteProvider);
    final habits =
        ref.watch(activeHabitsProvider).asData?.value ?? const <Habit>[];

    final monthStart = DateTime(_month.year, _month.month);
    final monthEnd = DateTime(_month.year, _month.month + 1, 0);
    final firstCellOffset = monthStart.weekday % 7; // Sun=0, Mon=1...

    final sinceYmd = ymd(monthStart.subtract(Duration(days: firstCellOffset)));
    final completions =
        ref.watch(completionsSinceProvider(sinceYmd)).asData?.value ??
            const <HabitCompletion>[];

    final totalCells = _totalCells(firstCellOffset, monthEnd.day);
    final cells = <_DayCell>[];
    for (var i = 0; i < totalCells; i++) {
      final date = monthStart
          .subtract(Duration(days: firstCellOffset))
          .add(Duration(days: i));
      final inMonth = date.month == monthStart.month;
      final done = completions.where((c) => c.date == ymd(date)).length;
      cells.add(_DayCell(
        date: date,
        inMonth: inMonth,
        done: done,
        total: habits.length,
      ));
    }

    final selectedDone =
        completions.where((c) => c.date == ymd(_selected)).length;
    final selectedTotal = habits.length;
    final selectedCompletedIds = {
      for (final c in completions)
        if (c.date == ymd(_selected)) c.habitId,
    };

    return Scaffold(
      backgroundColor: SP.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            _Header(
              month: _month,
              accent: accent,
              onPrev: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1),
              ),
              onNext: () => setState(
                () => _month = DateTime(_month.year, _month.month + 1),
              ),
            ),
            const SizedBox(height: 14),
            const _DowHeader(),
            const SizedBox(height: 6),
            _MonthGrid(
              cells: cells,
              selected: _selected,
              accent: accent,
              onSelect: (d) => setState(() => _selected = d),
            ),
            const SizedBox(height: 20),
            _SummaryCard(
              selected: _selected,
              done: selectedDone,
              total: selectedTotal,
              companion: tweaks.companion,
              accent: accent,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _SelectedDayHabits(
              habits: habits,
              completedIds: selectedCompletedIds,
              accent: accent,
            ),
          ],
        ),
      ),
    );
  }

  int _totalCells(int offset, int daysInMonth) {
    final used = offset + daysInMonth;
    return ((used + 6) ~/ 7) * 7;
  }
}

class _DayCell {
  final DateTime date;
  final bool inMonth;
  final int done;
  final int total;
  _DayCell({
    required this.date,
    required this.inMonth,
    required this.done,
    required this.total,
  });
}

class _Header extends StatelessWidget {
  const _Header({
    required this.month,
    required this.accent,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final AccentPalette accent;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CALENDAR',
                style: TextStyle(
                  fontSize: 11,
                  color: SP.muted,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.4,
                    color: SP.cocoa,
                  ),
                  children: [
                    TextSpan(text: DateFormat.MMMM().format(month)),
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: '${month.year}',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: accent.deep,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _ArrowButton(icon: Icons.chevron_left, onTap: onPrev),
        const SizedBox(width: 6),
        _ArrowButton(icon: Icons.chevron_right, onTap: onNext),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: SP.cream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SP.hairline),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: SP.cocoaSoft),
      ),
    );
  }
}

class _DowHeader extends StatelessWidget {
  const _DowHeader();

  @override
  Widget build(BuildContext context) {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: [
        for (final l in labels)
          Expanded(
            child: Center(
              child: Text(
                l,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: SP.muted,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.cells,
    required this.selected,
    required this.accent,
    required this.onSelect,
  });

  final List<_DayCell> cells;
  final DateTime selected;
  final AccentPalette accent;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayKey = ymd(today);
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: cells.length,
      itemBuilder: (context, i) {
        final c = cells[i];
        final isToday = ymd(c.date) == todayKey;
        final isSelected = ymd(c.date) == ymd(selected);
        return _MonthCell(
          cell: c,
          isToday: isToday,
          isSelected: isSelected,
          accent: accent,
          onTap: c.inMonth ? () => onSelect(c.date) : null,
        );
      },
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.cell,
    required this.isToday,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final _DayCell cell;
  final bool isToday;
  final bool isSelected;
  final AccentPalette accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final allDone = cell.total > 0 && cell.done >= cell.total;
    final bg = isSelected
        ? accent.soft
        : isToday
            ? SP.cream
            : Colors.transparent;
    final borderColor = isSelected
        ? accent.main
        : isToday
            ? accent.main
            : Colors.transparent;
    final textColor = isSelected ? accent.deep : SP.cocoa;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: cell.inMonth ? 1 : 0.35,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${cell.date.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    if (cell.total > 0) ...[
                      const SizedBox(height: 3),
                      _Dots(done: cell.done, total: cell.total, accent: accent),
                    ],
                  ],
                ),
              ),
              if (allDone)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: SP.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.done,
    required this.total,
    required this.accent,
  });

  final int done;
  final int total;
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    final shown = math.min(6, total);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < shown; i++) ...[
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: i < done ? accent.main : SP.mutedSoft,
              shape: BoxShape.circle,
            ),
          ),
          if (i < shown - 1) const SizedBox(width: 2),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.selected,
    required this.done,
    required this.total,
    required this.companion,
    required this.accent,
    required this.theme,
  });

  final DateTime selected;
  final int done;
  final int total;
  final CompanionKind companion;
  final AccentPalette accent;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SP.creamSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SP.hairline),
      ),
      child: Row(
        children: [
          Transform.translate(
            offset: const Offset(-14, 0),
            child: Companion(
              kind: companion,
              growth: pct,
              accent: accent,
              bloom: pct >= 1,
              size: 96,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(selected),
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    color: SP.cocoa,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$done of $total habits · ${(pct * 100).round()}% bloomed',
                  style: const TextStyle(fontSize: 12, color: SP.muted),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: 5,
                    child: Stack(
                      children: [
                        const ColoredBox(color: SP.creamDeep),
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: ColoredBox(color: accent.main),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedDayHabits extends StatelessWidget {
  const _SelectedDayHabits({
    required this.habits,
    required this.completedIds,
    required this.accent,
  });

  final List<Habit> habits;
  final Set<int> completedIds;
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (var i = 0; i < habits.length; i++) ...[
          _DayHabitRow(
            habit: habits[i],
            done: completedIds.contains(habits[i].id),
            accent: accent,
          ),
          if (i < habits.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _DayHabitRow extends StatelessWidget {
  const _DayHabitRow({
    required this.habit,
    required this.done,
    required this.accent,
  });

  final Habit habit;
  final bool done;
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: done ? SP.creamDeep : SP.creamSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SP.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done ? accent.main : SP.cream,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              emojiFor(habit.icon),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              habit.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SP.cocoa.withValues(alpha: done ? 0.6 : 1),
                decoration: done ? TextDecoration.lineThrough : null,
                decorationColor: SP.muted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            done ? '✓' : '—',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: done ? accent.deep : SP.mutedSoft,
            ),
          ),
        ],
      ),
    );
  }
}
