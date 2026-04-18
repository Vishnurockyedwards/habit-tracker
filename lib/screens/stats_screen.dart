import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/database.dart';
import '../data/date_key.dart';
import '../data/providers.dart';
import '../data/tweaks.dart';
import '../logic/xp.dart';
import '../theme/tokens.dart';
import '../widgets/habit_icon.dart';
import '../widgets/sprout/growth_heatmap.dart';
import '../widgets/sprout/weekly_bars.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

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
            if (habits.isEmpty) return const _EmptyState();
            return _StatsBody(habits: habits);
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart_outlined, size: 48, color: SP.muted),
            const SizedBox(height: AppSpacing.md),
            Text('No stats yet', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            const Text(
              'Create a habit and start checking it off to see your season.',
              textAlign: TextAlign.center,
              style: TextStyle(color: SP.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsBody extends ConsumerWidget {
  const _StatsBody({required this.habits});

  final List<Habit> habits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentPaletteProvider);
    final streaks = ref.watch(allStreaksProvider).asData?.value ?? const [];

    final sinceYmd = ymd(
      DateTime.now().subtract(const Duration(days: 90)),
    );
    final completions = ref
            .watch(completionsSinceProvider(sinceYmd))
            .asData
            ?.value ??
        const [];

    final bestStreak =
        streaks.isEmpty ? 0 : streaks.map((s) => s.currentStreak).fold<int>(0, math.max);
    final longestEver =
        streaks.isEmpty ? 0 : streaks.map((s) => s.longestStreak).fold<int>(0, math.max);

    final totalCompletions =
        streaks.fold<int>(0, (sum, s) => sum + s.totalCompletions);
    final totalXp = totalCompletions * XpMath.perCompletion;
    final level = XpMath.levelFor(totalXp);
    final nextThreshold = XpMath.thresholdForLevel(level);
    final toNext = (nextThreshold - totalXp).clamp(0, nextThreshold);

    final completionPct = _completionPct(
      completions,
      habits.length,
      30,
    );

    final bestDay = _bestWeekday(completions);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        _Header(accent: accent),
        const SizedBox(height: 16),
        _StatGrid(
          accent: accent,
          currentStreak: bestStreak,
          longest: longestEver,
          completionPct: completionPct,
          totalXp: totalXp,
          level: level,
          toNext: toNext,
          bestDay: bestDay,
        ),
        const SizedBox(height: 22),
        Text(
          'Growth history',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SP.creamSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SP.hairline),
          ),
          child: GrowthHeatmap(
            completions: completions,
            activeHabitCount: habits.length,
            accent: accent,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'This week',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${_thisWeekDone(completions)} / ${habits.length * 7} habits',
              style: const TextStyle(
                fontSize: 11,
                color: SP.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
          decoration: BoxDecoration(
            color: SP.creamSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SP.hairline),
          ),
          child: WeeklyBars(
            completions: completions,
            activeHabitCount: habits.length,
            accent: accent,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Top performers',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        _TopPerformers(
          habits: habits,
          streaks: streaks,
          accent: accent,
          onTap: (id) => context.push('/habit/$id'),
        ),
      ],
    );
  }

  double _completionPct(
    List<HabitCompletion> completions,
    int activeHabits,
    int days,
  ) {
    if (activeHabits == 0) return 0;
    final today = DateTime.now();
    final cutoff = DateTime(today.year, today.month, today.day - (days - 1));
    final recent =
        completions.where((c) => !parseYmd(c.date).isBefore(cutoff)).length;
    return (recent / (activeHabits * days)).clamp(0.0, 1.0);
  }

  String _bestWeekday(List<HabitCompletion> completions) {
    if (completions.isEmpty) return '—';
    final counts = List<int>.filled(7, 0);
    for (final c in completions) {
      counts[parseYmd(c.date).weekday - 1]++;
    }
    var bestIdx = 0;
    var bestVal = counts[0];
    for (var i = 1; i < 7; i++) {
      if (counts[i] > bestVal) {
        bestIdx = i;
        bestVal = counts[i];
      }
    }
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[bestIdx];
  }

  int _thisWeekDone(List<HabitCompletion> completions) {
    final today = DateTime.now();
    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    return completions.where((c) {
      final d = parseYmd(c.date);
      return !d.isBefore(monday);
    }).length;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.accent});
  final AccentPalette accent;

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
                'INSIGHTS',
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
                    const TextSpan(text: 'Your '),
                    TextSpan(
                      text: 'season',
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: SP.cream,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: SP.hairline),
          ),
          child: const Text(
            '90 days ∞',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: SP.cocoaSoft,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.accent,
    required this.currentStreak,
    required this.longest,
    required this.completionPct,
    required this.totalXp,
    required this.level,
    required this.toNext,
    required this.bestDay,
  });

  final AccentPalette accent;
  final int currentStreak;
  final int longest;
  final double completionPct;
  final int totalXp;
  final int level;
  final int toNext;
  final String bestDay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Current streak',
                value: '$currentStreak',
                sub: 'days · personal best $longest',
                accent: accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Completion',
                value: '${(completionPct * 100).round()}%',
                sub: 'past 30 days',
                accent: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total XP',
                value: _compact(totalXp),
                sub: 'level $level · $toNext to level ${level + 1}',
                accent: accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Best day',
                value: bestDay,
                sub: 'most completions',
                accent: accent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _compact(int n) {
    if (n >= 1000) {
      final thousands = n / 1000;
      return '${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}k';
    }
    return n.toString();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.accent,
  });

  final String label;
  final String value;
  final String sub;
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: SP.creamSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SP.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: SP.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: accent.deep,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(fontSize: 11, color: SP.cocoaSoft),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TopPerformers extends StatelessWidget {
  const _TopPerformers({
    required this.habits,
    required this.streaks,
    required this.accent,
    required this.onTap,
  });

  final List<Habit> habits;
  final List<Streak> streaks;
  final AccentPalette accent;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final streakById = {for (final s in streaks) s.habitId: s};

    final ranked = <_Ranked>[];
    final today = DateTime.now();
    for (final h in habits) {
      final s = streakById[h.id];
      final daysSinceCreate = math
          .max(1, today.difference(h.createdAt).inDays + 1);
      final rate = ((s?.totalCompletions ?? 0) / daysSinceCreate)
          .clamp(0.0, 1.0);
      ranked.add(_Ranked(
        habit: h,
        pct: (rate * 100).round(),
        streak: s?.currentStreak ?? 0,
      ));
    }
    ranked.sort((a, b) => b.pct.compareTo(a.pct));
    final top = ranked.take(4).toList();

    return Column(
      children: [
        for (var i = 0; i < top.length; i++) ...[
          _LeaderRow(entry: top[i], accent: accent, onTap: () => onTap(top[i].habit.id)),
          if (i < top.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _Ranked {
  final Habit habit;
  final int pct;
  final int streak;
  _Ranked({required this.habit, required this.pct, required this.streak});
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.entry,
    required this.accent,
    required this.onTap,
  });

  final _Ranked entry;
  final AccentPalette accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SP.creamSoft,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SP.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SP.cream,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  emojiFor(entry.habit.icon),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.habit.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: SP.cocoa,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        height: 4,
                        child: Stack(
                          children: [
                            const ColoredBox(color: SP.creamDeep),
                            FractionallySizedBox(
                              widthFactor: entry.pct / 100,
                              child: ColoredBox(color: accent.main),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.pct}%',
                    style: const TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: SP.cocoa,
                    ),
                  ),
                  Text(
                    '🔥 ${entry.streak}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: SP.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
