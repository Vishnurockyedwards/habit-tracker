import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/database.dart';
import '../../logic/xp.dart';
import '../../theme/tokens.dart';
import '../habit_icon.dart';

/// Sprout habit row — icon tile + name/sub+xp + checkbox circle.
/// Row tap opens detail; checkbox tap toggles (stopPropagation).
class SproutHabitRow extends StatelessWidget {
  const SproutHabitRow({
    super.key,
    required this.habit,
    required this.completed,
    required this.accent,
    required this.density,
    required this.onToggle,
    this.onOpen,
    this.onLongPress,
  });

  final Habit habit;
  final bool completed;
  final AccentPalette accent;
  final DensityTokens density;
  final VoidCallback onToggle;
  final VoidCallback? onOpen;
  final VoidCallback? onLongPress;

  String _subLine() {
    if (habit.reminderMinutes != null) {
      final h = habit.reminderMinutes! ~/ 60;
      final m = habit.reminderMinutes! % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
    if (habit.targetValue > 1) {
      final val = habit.targetValue == habit.targetValue.roundToDouble()
          ? habit.targetValue.toInt().toString()
          : habit.targetValue.toString();
      final unit = habit.unit;
      return unit == null ? val : '$val $unit';
    }
    return switch (habit.frequencyType) {
      'weekdays' => 'Weekdays',
      'custom' => 'Custom days',
      _ => 'Daily',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = density.iconSize == 36;

    return Semantics(
      label:
          '${habit.name}, ${completed ? 'completed' : 'not done'}, +${XpMath.perCompletion} XP',
      button: true,
      child: Material(
        color: completed ? SP.creamDeep : SP.creamSoft,
        borderRadius: BorderRadius.circular(density.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          onLongPress: onLongPress,
          splashFactory: InkSparkle.splashFactory,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: density.rowPadY,
              horizontal: 18,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: density.iconSize,
                  height: density.iconSize,
                  decoration: BoxDecoration(
                    color: completed ? accent.main : SP.cream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emojiFor(habit.icon),
                    style: TextStyle(fontSize: isCompact ? 18 : 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: theme.textTheme.titleSmall!.copyWith(
                          fontSize: isCompact ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color: SP.cocoa.withValues(
                            alpha: completed ? 0.6 : 1.0,
                          ),
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: SP.muted,
                        ),
                        child: Text(
                          habit.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_subLine()} · +${XpMath.perCompletion} xp',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: SP.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _Checkbox(
                  completed: completed,
                  accent: accent,
                  onToggle: () {
                    HapticFeedback.selectionClick();
                    onToggle();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({
    required this.completed,
    required this.accent,
    required this.onToggle,
  });

  final bool completed;
  final AccentPalette accent;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: completed ? accent.deep : Colors.transparent,
          border: Border.all(
            color: completed ? accent.deep : const Color(0xFFD5C6B1),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: completed
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}
