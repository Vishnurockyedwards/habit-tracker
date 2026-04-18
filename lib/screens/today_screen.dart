import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/date_key.dart';
import '../data/providers.dart';
import '../data/tweaks.dart';
import '../logic/xp.dart';
import '../theme/tokens.dart';
import '../widgets/habit_actions_sheet.dart';
import '../widgets/sprout/companion_card.dart';
import '../widgets/sprout/dashed_border_button.dart';
import '../widgets/sprout/habit_row.dart';
import '../widgets/sprout/level_up_overlay.dart';
import '../widgets/sprout/streak_chip.dart';
import '../widgets/sprout/xp_ring.dart';
import '../widgets/template_picker.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(activeHabitsProvider);

    return Scaffold(
      backgroundColor: SP.cream,
      body: SafeArea(
        bottom: false,
        child: habitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading habits: $e')),
          data: (habits) {
            if (habits.isEmpty) return const TemplatePicker();
            return _TodayContent(habits: habits);
          },
        ),
      ),
    );
  }
}

class _TodayContent extends ConsumerStatefulWidget {
  const _TodayContent({required this.habits});

  final List<Habit> habits;

  @override
  ConsumerState<_TodayContent> createState() => _TodayContentState();
}

class _TodayContentState extends ConsumerState<_TodayContent> {
  int? _prevLevel;

  void _maybeShowLevelUp(
    int newLevel,
    CompanionKind companion,
    AccentPalette accent,
  ) {
    final prev = _prevLevel;
    _prevLevel = newLevel;
    // Don't fire on the first settle after load — only on actual crossings.
    if (prev == null || newLevel <= prev) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showLevelUp(
        context,
        level: newLevel,
        companion: companion,
        accent: accent,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final habits = widget.habits;
    final theme = Theme.of(context);
    final tweaks = ref.watch(tweaksProvider);
    final accent = ref.watch(accentPaletteProvider);
    final density = ref.watch(densityProvider);

    final completions =
        ref.watch(todayCompletionsProvider).asData?.value ?? const [];
    final streaks = ref.watch(allStreaksProvider).asData?.value ?? const [];

    final completedIds = {for (final c in completions) c.habitId};
    final completedCount =
        habits.where((h) => completedIds.contains(h.id)).length;
    final total = habits.length;
    final growth = total == 0 ? 0.0 : completedCount / total;

    final bestCurrentStreak = streaks.isEmpty
        ? 0
        : streaks.map((s) => s.currentStreak).fold<int>(0, math.max);

    final totalCompletions =
        streaks.fold<int>(0, (sum, s) => sum + s.totalCompletions);
    final totalXp = XpMath.totalFor(totalCompletions);
    final level = XpMath.levelFor(totalXp);
    final progress = XpMath.progressInLevel(totalXp);
    final xpToday = completedCount * XpMath.perCompletion;

    _maybeShowLevelUp(level, tweaks.companion, accent);

    final now = DateTime.now();
    final dateLabel =
        DateFormat('EEEE · MMM d').format(now).toUpperCase();

    final sorted = [...habits]..sort((a, b) {
      final aDone = completedIds.contains(a.id) ? 1 : 0;
      final bDone = completedIds.contains(b.id) ? 1 : 0;
      if (aDone != bDone) return aDone - bDone; // undone first
      return a.sortOrder.compareTo(b.sortOrder);
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: [
        _Greeting(
          dateLabel: dateLabel,
          timeOfDay: _timeOfDayGreeting(now.hour),
          accent: accent,
          density: density,
          level: level,
          xpProgress: progress,
          streak: bestCurrentStreak,
        ),
        const SizedBox(height: 16),
        CompanionCard(
          companion: tweaks.companion,
          accent: accent,
          growth: growth,
          done: completedCount,
          total: total,
          xpToday: xpToday,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Today',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '$completedCount/$total done',
              style: theme.textTheme.bodySmall?.copyWith(
                color: SP.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < sorted.length; i++) ...[
          SproutHabitRow(
            habit: sorted[i],
            completed: completedIds.contains(sorted[i].id),
            accent: accent,
            density: density,
            onToggle: () => _toggle(ref, sorted[i]),
            onOpen: () => context.push('/habit/${sorted[i].id}'),
            onLongPress: () => showHabitActionsSheet(
              context,
              ref: ref,
              habit: sorted[i],
            ),
          ),
          if (i < sorted.length - 1) SizedBox(height: density.rowGap),
        ],
        const SizedBox(height: 14),
        DashedBorderButton(
          label: '+ Add a habit',
          onTap: () => context.push('/create'),
        ),
      ],
    );
  }

  Future<void> _toggle(WidgetRef ref, Habit habit) async {
    final db = ref.read(databaseProvider);
    await db.toggleCompletion(
      habitId: habit.id,
      date: todayYmd(),
      value: habit.targetValue,
    );
  }

  String _timeOfDayGreeting(int hour) {
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.dateLabel,
    required this.timeOfDay,
    required this.accent,
    required this.density,
    required this.level,
    required this.xpProgress,
    required this.streak,
  });

  final String dateLabel;
  final String timeOfDay;
  final AccentPalette accent;
  final DensityTokens density;
  final int level;
  final double xpProgress;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: SP.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: density.headerSize,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                    letterSpacing: -0.5,
                    color: SP.cocoa,
                  ),
                  children: [
                    const TextSpan(text: 'Good\n'),
                    TextSpan(
                      text: timeOfDay.toLowerCase(),
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: accent.deep,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              if (streak > 0) ...[
                const SizedBox(height: 10),
                StreakChip(streak: streak, accent: accent),
              ],
            ],
          ),
        ),
        XpRing(progress: xpProgress, level: level, accent: accent),
      ],
    );
  }
}

