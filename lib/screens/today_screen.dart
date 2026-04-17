import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/date_key.dart';
import '../data/providers.dart';
import '../theme/tokens.dart';
import '../widgets/habit_tile.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(activeHabitsProvider);
    final completionsAsync = ref.watch(todayCompletionsProvider);
    final streaksAsync = ref.watch(allStreaksProvider);

    final subtitle = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.md,
                bottom: AppSpacing.sm,
              ),
              child: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading habits: $e')),
        data: (habits) {
          if (habits.isEmpty) {
            return _EmptyState(
              onCreate: () => context.go('/create'),
            );
          }
          final completions = completionsAsync.asData?.value ?? const [];
          final streaks = streaksAsync.asData?.value ?? const [];
          final completedIds = {for (final c in completions) c.habitId};
          final streakById = {for (final s in streaks) s.habitId: s};

          final buckets = _bucketByTime(habits);

          return ListView(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.xxl,
            ),
            children: [
              for (final entry in buckets.entries)
                if (entry.value.isNotEmpty) ...[
                  _SectionHeader(label: entry.key),
                  for (final habit in entry.value)
                    HabitTile(
                      habit: habit,
                      streak: streakById[habit.id],
                      completed: completedIds.contains(habit.id),
                      onTap: () => _toggle(ref, habit),
                    ),
                ],
            ],
          );
        },
      ),
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

  Map<String, List<Habit>> _bucketByTime(List<Habit> habits) {
    final buckets = <String, List<Habit>>{
      'Morning': [],
      'Afternoon': [],
      'Evening': [],
      'Any time': [],
    };
    for (final h in habits) {
      final m = h.reminderMinutes;
      if (m == null) {
        buckets['Any time']!.add(h);
      } else if (m < 12 * 60) {
        buckets['Morning']!.add(h);
      } else if (m < 17 * 60) {
        buckets['Afternoon']!.add(h);
      } else {
        buckets['Evening']!.add(h);
      }
    }
    return buckets;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.checklist_rtl,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No habits yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create your first habit to start building a streak.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create habit'),
            ),
          ],
        ),
      ),
    );
  }
}
