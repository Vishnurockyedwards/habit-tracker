import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/database.dart';
import '../data/date_key.dart';
import '../data/providers.dart';
import '../data/tweaks.dart';
import '../logic/xp.dart';
import '../theme/tokens.dart';
import '../widgets/habit_actions_sheet.dart';
import '../widgets/habit_icon.dart';
import '../widgets/sprout/mini_heat_strip.dart';

class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitAsync = ref.watch(habitByIdProvider(habitId));
    final completionsAsync = ref.watch(habitCompletionsProvider(habitId));
    final streaksAsync = ref.watch(allStreaksProvider);
    final accent = ref.watch(accentPaletteProvider);

    return Scaffold(
      backgroundColor: SP.cream,
      body: SafeArea(
        child: habitAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (habit) {
            if (habit == null) {
              return const Center(child: Text('Habit not found'));
            }
            final completions = completionsAsync.asData?.value ?? const [];
            final streaks =
                streaksAsync.asData?.value ?? const <Streak>[];
            Streak? streak;
            for (final s in streaks) {
              if (s.habitId == habitId) {
                streak = s;
                break;
              }
            }
            final todayComplete = completions
                .any((c) => c.date == todayYmd());

            return _DetailBody(
              habit: habit,
              completions: completions,
              streak: streak,
              accent: accent,
              todayComplete: todayComplete,
              onEdit: () => context.push('/edit/${habit.id}'),
              onMore: () => showHabitActionsSheet(
                context,
                ref: ref,
                habit: habit,
              ),
              onToggle: () async {
                final db = ref.read(databaseProvider);
                await db.toggleCompletion(
                  habitId: habit.id,
                  date: todayYmd(),
                  value: habit.targetValue,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.habit,
    required this.completions,
    required this.streak,
    required this.accent,
    required this.todayComplete,
    required this.onEdit,
    required this.onMore,
    required this.onToggle,
  });

  final Habit habit;
  final List<HabitCompletion> completions;
  final Streak? streak;
  final AccentPalette accent;
  final bool todayComplete;
  final VoidCallback onEdit;
  final VoidCallback onMore;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final last30 = _countLast30Days(completions);
    final ratePct = ((last30 / 30) * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        _TopBar(accent: accent, onBack: () => _safePop(context),
            onEdit: onEdit, onMore: onMore),
        const SizedBox(height: 10),
        _HeroCard(habit: habit, accent: accent),
        const SizedBox(height: 16),
        _StatRow(
          accent: accent,
          current: streak?.currentStreak ?? 0,
          best: streak?.longestStreak ?? 0,
          ratePct: ratePct,
        ),
        const SizedBox(height: 16),
        if (habit.freezesRemaining > 0)
          _ShieldRow(count: habit.freezesRemaining, accent: accent),
        if (habit.freezesRemaining > 0) const SizedBox(height: 16),
        _HeatStripSection(
          completions: completions,
          target: habit.targetValue,
          accent: accent,
          last30: last30,
        ),
        const SizedBox(height: 20),
        _NotesSection(habit: habit, accent: accent),
        const SizedBox(height: 20),
        _PrimaryCta(
          done: todayComplete,
          accent: accent,
          onTap: onToggle,
        ),
      ],
    );
  }

  void _safePop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/today');
    }
  }

  int _countLast30Days(List<HabitCompletion> completions) {
    final today = DateTime.now();
    final cutoff = DateTime(today.year, today.month, today.day - 29);
    return completions.where((c) {
      final d = parseYmd(c.date);
      return !d.isBefore(cutoff);
    }).length;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.accent,
    required this.onBack,
    required this.onEdit,
    required this.onMore,
  });

  final AccentPalette accent;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Back'),
          style: TextButton.styleFrom(
            foregroundColor: SP.cocoaSoft,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
        ),
        Row(
          children: [
            TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                foregroundColor: accent.deep,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text(
                'Edit',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: onMore,
              icon: const Icon(Icons.more_vert, size: 20),
              color: SP.cocoaSoft,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.habit, required this.accent});

  final Habit habit;
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.soft, SP.creamSoft],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SP.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.main, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              emojiFor(habit.icon),
              style: const TextStyle(fontSize: 34),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subLine(habit),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: SP.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subLine(Habit habit) {
    final parts = <String>[];
    if (habit.targetValue > 1) {
      final val = habit.targetValue == habit.targetValue.roundToDouble()
          ? habit.targetValue.toInt().toString()
          : habit.targetValue.toString();
      parts.add(habit.unit == null ? val : '$val ${habit.unit}');
    }
    parts.add(_frequencyLabel(habit));
    parts.add('+${XpMath.perCompletion} xp');
    return parts.join(' · ');
  }

  String _frequencyLabel(Habit habit) {
    switch (habit.frequencyType) {
      case 'x_per_week':
        return 'weekly';
      case 'custom':
        return 'custom days';
      case 'daily':
      default:
        return 'daily';
    }
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.accent,
    required this.current,
    required this.best,
    required this.ratePct,
  });

  final AccentPalette accent;
  final int current;
  final int best;
  final int ratePct;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Current',
            value: '$current',
            suffix: 'days',
            accent: accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: 'Best',
            value: '$best',
            suffix: 'days',
            accent: accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: 'Rate',
            value: '$ratePct%',
            suffix: 'this month',
            accent: accent,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.suffix,
    required this.accent,
  });

  final String label;
  final String value;
  final String suffix;
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SP.creamSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SP.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: SP.muted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: accent.deep,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            suffix,
            style: const TextStyle(fontSize: 10, color: SP.cocoaSoft),
          ),
        ],
      ),
    );
  }
}

class _ShieldRow extends StatelessWidget {
  const _ShieldRow({required this.count, required this.accent});

  final int count;
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.shield, color: accent.deep, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: accent.deep,
                ),
                children: [
                  TextSpan(
                    text: count == 1 ? '1 shield' : '$count shields',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' · covers a missed day'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatStripSection extends StatelessWidget {
  const _HeatStripSection({
    required this.completions,
    required this.target,
    required this.accent,
    required this.last30,
  });

  final List<HabitCompletion> completions;
  final double target;
  final AccentPalette accent;
  final int last30;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Last 30 days',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$last30 / 30',
              style: const TextStyle(
                fontSize: 11,
                color: SP.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SP.creamSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SP.hairline),
          ),
          child: MiniHeatStrip(
            completions: completions,
            target: target,
            accent: accent,
          ),
        ),
      ],
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.habit, required this.accent});

  final Habit habit;
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Notes',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SP.creamSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SP.hairline),
          ),
          child: const Text(
            'No notes yet.',
            style: TextStyle(
              fontSize: 12,
              color: SP.muted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notes are coming in the next update.'),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SP.muted, width: 1.5),
            ),
            alignment: Alignment.center,
            child: const Text(
              '+ Add note',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SP.muted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.done,
    required this.accent,
    required this.onTap,
  });

  final bool done;
  final AccentPalette accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: done
            ? null
            : [
                BoxShadow(
                  color: accent.deep,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: done ? SP.creamDeep : accent.main,
          foregroundColor: done ? SP.cocoaSoft : SP.onAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        child: Text(
          done
              ? '✓ Completed today'
              : 'Mark done  ·  earn +${XpMath.perCompletion} xp',
        ),
      ),
    );
  }
}
