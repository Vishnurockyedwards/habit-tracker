import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class TodayHeroCard extends StatelessWidget {
  const TodayHeroCard({
    super.key,
    required this.completed,
    required this.total,
    required this.bestCurrentStreak,
  });

  final int completed;
  final int total;
  final int bestCurrentStreak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total == 0 ? 0.0 : completed / total;
    final isComplete = total > 0 && completed == total;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          _ProgressRing(
            progress: progress,
            completed: completed,
            total: total,
            accent: theme.colorScheme.primary,
            track: theme.colorScheme.surface.withValues(alpha: 0.45),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _headline(completed, total, isComplete),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _subline(completed, total, isComplete),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer
                        .withValues(alpha: 0.8),
                  ),
                ),
                if (bestCurrentStreak > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _StreakPill(streak: bestCurrentStreak),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _headline(int done, int total, bool complete) {
    if (total == 0) return 'No habits yet';
    if (complete) return 'All done!';
    if (done == 0) return "Let's go";
    return 'Keep going';
  }

  String _subline(int done, int total, bool complete) {
    if (total == 0) return 'Pick a template below to get started.';
    if (complete) return 'Great day. Rest earned.';
    final remaining = total - done;
    return '$remaining more to finish today';
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progress,
    required this.completed,
    required this.total,
    required this.accent,
    required this.track,
  });

  final double progress;
  final int completed;
  final int total;
  final Color accent;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => SizedBox.expand(
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 9,
                backgroundColor: track,
                valueColor: AlwaysStoppedAnimation(accent),
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                total == 0 ? '—' : '$completed',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'of $total',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer
                      .withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 16,
            color: AppColors.streakFlame,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak day best streak',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
