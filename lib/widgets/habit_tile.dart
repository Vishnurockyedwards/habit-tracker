import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../theme/tokens.dart';
import 'habit_icon.dart';

class HabitTile extends StatefulWidget {
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
  State<HabitTile> createState() => _HabitTileState();
}

class _HabitTileState extends State<HabitTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceScale;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 60),
    ]).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    _bounceController.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habit = widget.habit;
    final habitColor = colorFromHex(habit.color);
    final currentStreak = widget.streak?.currentStreak ?? 0;
    final completed = widget.completed;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: AnimatedContainer(
        duration: AppDurations.normal,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: completed
              ? habitColor.withValues(alpha: 0.10)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(AppRadius.cardRadius),
          border: Border(
            left: BorderSide(
              color: completed ? habitColor : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: const BorderRadius.all(AppRadius.cardRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _handleTap,
            onLongPress: widget.onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  AnimatedOpacity(
                    duration: AppDurations.normal,
                    opacity: completed ? 0.7 : 1,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: habitColor.withValues(alpha: 0.15),
                      child: Icon(iconFor(habit.icon), color: habitColor),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: AppDurations.normal,
                      opacity: completed ? 0.65 : 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              decoration: completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: theme.colorScheme.onSurfaceVariant,
                            ),
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
                  ),
                  ScaleTransition(
                    scale: _bounceScale,
                    child: AnimatedSwitcher(
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
                            ? habitColor
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ],
              ),
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
