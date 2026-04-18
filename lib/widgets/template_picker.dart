import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/habit_templates.dart';
import '../data/providers.dart';
import '../notifications/notification_service.dart';
import '../theme/tokens.dart';
import 'habit_icon.dart';

class TemplatePicker extends ConsumerStatefulWidget {
  const TemplatePicker({super.key});

  @override
  ConsumerState<TemplatePicker> createState() => _TemplatePickerState();
}

class _TemplatePickerState extends ConsumerState<TemplatePicker> {
  final Set<int> _selected = {0, 1};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          'Start with a quick pick',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tap the habits you want to build. You can edit or add more later.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < kHabitTemplates.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _TemplateTile(
              template: kHabitTemplates[i],
              selected: _selected.contains(i),
              onToggle: () => setState(() {
                if (_selected.contains(i)) {
                  _selected.remove(i);
                } else {
                  _selected.add(i);
                }
              }),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: _selected.isEmpty || _saving ? null : _addSelected,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: Text(
            _selected.isEmpty
                ? 'Pick at least one'
                : 'Add ${_selected.length} habit${_selected.length == 1 ? '' : 's'}',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: _saving ? null : () => context.go('/create'),
          child: const Text('Or create your own'),
        ),
      ],
    );
  }

  Future<void> _addSelected() async {
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final chosen = [
      for (var i = 0; i < kHabitTemplates.length; i++)
        if (_selected.contains(i)) kHabitTemplates[i],
    ];
    final ids = await applyTemplates(db, chosen);
    // Any template with a reminder wants notifications.
    if (chosen.any((t) => t.reminderMinutes != null)) {
      await NotificationService.instance.requestPermissions();
    }
    for (final id in ids) {
      final saved = await db.getHabit(id);
      if (saved != null) {
        await NotificationService.instance.scheduleForHabit(saved);
      }
      await db.recomputeStreak(id);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${ids.length} habits')),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.selected,
    required this.onToggle,
  });

  final HabitTemplate template;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = colorFromHex(template.color);
    return Material(
      color: selected
          ? color.withValues(alpha: 0.12)
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: const BorderRadius.all(AppRadius.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.18),
                child: Icon(iconFor(template.icon), color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.name, style: theme.textTheme.titleMedium),
                    if (template.blurb != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        template.blurb!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: selected ? color : theme.colorScheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
