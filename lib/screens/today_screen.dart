import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/date_key.dart';
import '../data/providers.dart';
import '../theme/tokens.dart';
import '../widgets/habit_actions_sheet.dart';
import '../widgets/habit_tile.dart';
import '../widgets/template_picker.dart';
import '../widgets/today_hero_card.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  late final ConfettiController _confetti;
  int? _prevCompleted;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _maybeCelebrate(int completed, int total) {
    if (total == 0) {
      _prevCompleted = completed;
      return;
    }
    final prev = _prevCompleted;
    if (prev != null && prev < total && completed == total) {
      _confetti.play();
    }
    _prevCompleted = completed;
  }

  @override
  Widget build(BuildContext context) {
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
      body: Stack(
        children: [
          habitsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading habits: $e')),
            data: (habits) {
              if (habits.isEmpty) {
                return const TemplatePicker();
              }
              final completions = completionsAsync.asData?.value ?? const [];
              final streaks = streaksAsync.asData?.value ?? const [];
              final completedIds = {for (final c in completions) c.habitId};
              final streakById = {for (final s in streaks) s.habitId: s};

              final completedCount =
                  habits.where((h) => completedIds.contains(h.id)).length;
              final bestCurrentStreak = streaks.isEmpty
                  ? 0
                  : streaks
                      .map((s) => s.currentStreak)
                      .fold<int>(0, math.max);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _maybeCelebrate(completedCount, habits.length);
              });

              final buckets = _bucketByTime(habits);

              return ListView(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.xxl,
                ),
                children: [
                  TodayHeroCard(
                    completed: completedCount,
                    total: habits.length,
                    bestCurrentStreak: bestCurrentStreak,
                  ),
                  for (final entry in buckets.entries)
                    if (entry.value.isNotEmpty) ...[
                      _SectionHeader(label: entry.key),
                      for (final habit in entry.value)
                        HabitTile(
                          habit: habit,
                          streak: streakById[habit.id],
                          completed: completedIds.contains(habit.id),
                          onTap: () => _toggle(ref, habit),
                          onLongPress: () => showHabitActionsSheet(
                            context,
                            ref: ref,
                            habit: habit,
                          ),
                        ),
                    ],
                ],
              );
            },
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirection: math.pi / 2,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 24,
                maxBlastForce: 28,
                minBlastForce: 12,
                gravity: 0.25,
                shouldLoop: false,
                colors: const [
                  Color(0xFF6750A4),
                  Color(0xFF1E88E5),
                  Color(0xFF43A047),
                  Color(0xFFE53935),
                  Color(0xFFFB8C00),
                  Color(0xFF8E24AA),
                ],
              ),
            ),
          ),
        ],
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
