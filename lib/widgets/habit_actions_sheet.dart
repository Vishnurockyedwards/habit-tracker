import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/database.dart';
import '../data/providers.dart';
import '../notifications/notification_service.dart';
import '../theme/tokens.dart';
import 'habit_icon.dart';

Future<void> showHabitActionsSheet(
  BuildContext context, {
  required WidgetRef ref,
  required Habit habit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => _HabitActionsSheet(habit: habit, ref: ref),
  );
}

class _HabitActionsSheet extends StatelessWidget {
  const _HabitActionsSheet({required this.habit, required this.ref});

  final Habit habit;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = colorFromHex(habit.color);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(iconFor(habit.icon), color: color, size: 18),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    habit.name,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              context.push('/edit/${habit.id}');
            },
          ),
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: const Text('Archive'),
            subtitle: const Text('Hide from Today, keep history'),
            onTap: () async {
              Navigator.pop(context);
              final db = ref.read(databaseProvider);
              await NotificationService.instance.cancelForHabit(habit.id);
              await db.archiveHabit(habit.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Archived "${habit.name}"')),
                );
              }
            },
          ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.error,
            ),
            title: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text('Permanently remove habit and history'),
            onTap: () async {
              Navigator.pop(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text('Delete "${habit.name}"?'),
                  content: const Text(
                    'This permanently removes the habit and all its '
                    'completions. This cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              final db = ref.read(databaseProvider);
              await NotificationService.instance.cancelForHabit(habit.id);
              await db.deleteHabit(habit.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted "${habit.name}"')),
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
