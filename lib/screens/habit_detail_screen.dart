import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/date_key.dart';
import '../data/providers.dart';
import '../theme/tokens.dart';
import '../widgets/habit_heatmap.dart';
import '../widgets/habit_icon.dart';

class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitAsync = ref.watch(habitByIdProvider(habitId));
    final completionsAsync = ref.watch(habitCompletionsProvider(habitId));
    final streaksAsync = ref.watch(allStreaksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          habitAsync.asData?.value?.name ?? 'Habit',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: habitAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (habit) {
          if (habit == null) {
            return const Center(child: Text('Habit not found'));
          }
          final completions = completionsAsync.asData?.value ?? const [];
          final streaks = streaksAsync.asData?.value ?? const <Streak>[];
          Streak? streak;
          for (final s in streaks) {
            if (s.habitId == habitId) {
              streak = s;
              break;
            }
          }

          return _DetailBody(
            habit: habit,
            completions: completions,
            streak: streak,
          );
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.habit,
    required this.completions,
    required this.streak,
  });

  final Habit habit;
  final List<HabitCompletion> completions;
  final Streak? streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitColor = colorFromHex(habit.color);
    final intensity = _intensityMap(completions, habit.targetValue);
    final last30 = _last30DayCompletions(completions);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        _HeaderCard(habit: habit, habitColor: habitColor),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Current',
                value: '${streak?.currentStreak ?? 0}',
                suffix: 'days',
                icon: Icons.local_fire_department,
                iconColor: AppColors.streakFlame,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatTile(
                label: 'Longest',
                value: '${streak?.longestStreak ?? 0}',
                suffix: 'days',
                icon: Icons.emoji_events,
                iconColor: habitColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Total',
                value: '${streak?.totalCompletions ?? completions.length}',
                suffix: 'completions',
                icon: Icons.check_circle,
                iconColor: AppColors.completionSuccess,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatTile(
                label: 'Last 30 days',
                value: '$last30',
                suffix: '/ 30',
                icon: Icons.calendar_month,
                iconColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Activity',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HabitHeatmap(
                  intensityByDate: intensity,
                  color: habitColor,
                ),
                const SizedBox(height: AppSpacing.sm),
                HeatmapLegend(color: habitColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (streak?.lastCompletedDate != null)
          Text(
            'Last done: ${_formatDate(streak!.lastCompletedDate!)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Map<String, double> _intensityMap(
    List<HabitCompletion> completions,
    double target,
  ) {
    final map = <String, double>{};
    for (final c in completions) {
      final v = target <= 0 ? 1.0 : (c.value / target).clamp(0.2, 1.0);
      map[c.date] = v;
    }
    return map;
  }

  int _last30DayCompletions(List<HabitCompletion> completions) {
    final today = DateTime.now();
    final cutoff = DateTime(today.year, today.month, today.day - 29);
    return completions
        .where((c) {
          final d = parseYmd(c.date);
          return !d.isBefore(cutoff);
        })
        .length;
  }

  String _formatDate(String ymdValue) {
    return DateFormat('MMM d, y').format(parseYmd(ymdValue));
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.habit, required this.habitColor});
  final Habit habit;
  final Color habitColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: habitColor.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: habitColor.withValues(alpha: 0.25),
              child: Icon(iconFor(habit.icon), color: habitColor, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.name, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    _frequencyLabel(habit),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _frequencyLabel(Habit habit) {
    switch (habit.frequencyType) {
      case 'x_per_week':
        final match = RegExp(r'"timesPerWeek":(\d+)')
            .firstMatch(habit.frequencyCfg ?? '');
        final n = match == null ? '?' : match.group(1)!;
        return '$n× per week';
      case 'custom':
        return 'Custom days';
      case 'daily':
      default:
        return 'Every day';
    }
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final String suffix;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  suffix,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
