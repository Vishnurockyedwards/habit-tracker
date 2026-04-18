import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/habit_templates.dart';
import '../data/providers.dart';
import '../data/tweaks.dart';
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
    final accent = ref.watch(accentPaletteProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: [
        Text.rich(
          TextSpan(
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 26,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.4,
              color: SP.cocoa,
              height: 1.1,
            ),
            children: [
              const TextSpan(text: 'Plant your first '),
              TextSpan(
                text: 'habit',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: accent.deep,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tap the habits you want to start with. Edit or add more anytime.',
          style: TextStyle(
            fontSize: 14,
            color: SP.cocoaSoft,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < kHabitTemplates.length; i++) ...[
          _TemplateTile(
            template: kHabitTemplates[i],
            selected: _selected.contains(i),
            accent: accent,
            onToggle: () => setState(() {
              if (_selected.contains(i)) {
                _selected.remove(i);
              } else {
                _selected.add(i);
              }
            }),
          ),
          if (i < kHabitTemplates.length - 1) const SizedBox(height: 6),
        ],
        const SizedBox(height: 20),
        _PrimaryCta(
          accent: accent,
          busy: _saving,
          enabled: _selected.isNotEmpty,
          label: _selected.isEmpty
              ? 'Pick at least one'
              : 'Add ${_selected.length} habit${_selected.length == 1 ? '' : 's'} 🌱',
          onPressed: _selected.isEmpty || _saving ? null : _addSelected,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _saving ? null : () => context.go('/create'),
            style: TextButton.styleFrom(foregroundColor: accent.deep),
            child: const Text('Or create your own'),
          ),
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
      SnackBar(content: Text('Planted ${ids.length} 🌱')),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.selected,
    required this.accent,
    required this.onToggle,
  });

  final HabitTemplate template;
  final bool selected;
  final AccentPalette accent;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.soft : SP.creamSoft,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent.main : SP.hairline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SP.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  emojiFor(template.icon),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SP.cocoa,
                      ),
                    ),
                    if (template.blurb != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        template.blurb!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: SP.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? accent.main : Colors.white,
                  border: Border.all(
                    color: selected ? accent.main : SP.mutedSoft,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: selected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.accent,
    required this.busy,
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final AccentPalette accent;
  final bool busy;
  final bool enabled;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled && !busy
            ? [BoxShadow(color: accent.deep, offset: const Offset(0, 4))]
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? accent.main : SP.mutedSoft,
          foregroundColor: SP.onAccent,
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
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: SP.onAccent,
                ),
              )
            : Text(label),
      ),
    );
  }
}
