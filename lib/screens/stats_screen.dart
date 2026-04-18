import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/database.dart';
import '../data/date_key.dart';
import '../data/providers.dart';
import '../theme/tokens.dart';
import '../widgets/habit_icon.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(activeHabitsProvider);
    final streaksAsync = ref.watch(allStreaksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading habits: $e')),
        data: (habits) {
          if (habits.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.insights,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No stats yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Create a habit and start checking it off to see streaks here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          final streaks = streaksAsync.asData?.value ?? const <Streak>[];
          final streakById = {for (final s in streaks) s.habitId: s};

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _HabitStatsCard(
                  habit: habit,
                  streak: streakById[habit.id],
                  onTap: () => context.push('/stats/habit/${habit.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HabitStatsCard extends ConsumerWidget {
  const _HabitStatsCard({
    required this.habit,
    required this.streak,
    required this.onTap,
  });

  final Habit habit;
  final Streak? streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = colorFromHex(habit.color);
    final current = streak?.currentStreak ?? 0;
    final longest = streak?.longestStreak ?? 0;
    final total = streak?.totalCompletions ?? 0;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: const BorderRadius.all(AppRadius.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(iconFor(habit.icon), color: color, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      habit.name,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _MiniStat(
                    icon: Icons.local_fire_department,
                    iconColor: AppColors.streakFlame,
                    label: 'Current',
                    value: '$current',
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _MiniStat(
                    icon: Icons.emoji_events,
                    iconColor: color,
                    label: 'Longest',
                    value: '$longest',
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _MiniStat(
                    icon: Icons.check_circle,
                    iconColor: AppColors.completionSuccess,
                    label: 'Total',
                    value: '$total',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _SevenDayStrip(habitId: habit.id, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _SevenDayStrip extends ConsumerWidget {
  const _SevenDayStrip({required this.habitId, required this.color});
  final int habitId;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final completionsAsync = ref.watch(habitCompletionsProvider(habitId));
    final completions = completionsAsync.asData?.value ?? const [];
    final doneDates = {for (final c in completions) c.date};

    final today = DateTime.now();
    final days = <DateTime>[];
    for (var i = 6; i >= 0; i--) {
      days.add(DateTime(today.year, today.month, today.day - i));
    }

    return Row(
      children: [
        for (final d in days) ...[
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: doneDates.contains(ymd(d))
                    ? color
                    : theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          if (d != days.last) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: AppSpacing.xs),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label.toLowerCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
