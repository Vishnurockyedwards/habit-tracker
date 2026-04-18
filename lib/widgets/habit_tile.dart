import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../theme/tokens.dart';
import 'habit_icon.dart';

class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.completed,
    this.streak,
    this.onTap,
    this.onLongPress,
  });

  final Habit habit;
  final Streak? streak;
  final bool completed;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitColor = colorFromHex(habit.color);
    final currentStreak = streak?.currentStreak ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(AppRadius.cardRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap?.call();
          },
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: habitColor.withValues(alpha: 0.15),
                  child: Icon(iconFor(habit.icon), color: habitColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (habit.targetValue > 1) ...[
                            Text(
                              _targetLabel(habit),
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          if (currentStreak > 0) ...[
                            const Icon(
                              Icons.local_fire_department,
                              size: 14,
                              color: AppColors.streakFlame,
                            ),
                            Text(
                              '$currentStreak',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.streakFlame,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (habit.freezesRemaining > 0) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Icon(
                              Icons.shield,
                              size: 13,
                              color: habitColor,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${habit.freezesRemaining}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: habitColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: AppDurations.fast,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    completed
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    key: ValueKey(completed),
                    size: 32,
                    color: completed
                        ? AppColors.completionSuccess
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _targetLabel(Habit habit) {
    final value = habit.targetValue == habit.targetValue.roundToDouble()
        ? habit.targetValue.toInt().toString()
        : habit.targetValue.toString();
    final unit = habit.unit;
    return unit == null ? value : '$value $unit';
  }
}
