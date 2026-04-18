import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/database.dart';
import '../data/providers.dart';
import '../data/tweaks.dart';
import '../notifications/notification_service.dart';
import '../theme/tokens.dart';
import '../widgets/habit_icon.dart';

/// 16 Sprout emoji options for habit icons.
const _habitEmojis = <String>[
  '💧', '💊', '🧘', '📖', '🏃', '🍎', '😴', '📝',
  '🥗', '🏋️', '💻', '🎨', '🌸', '🎤', '🧹', '🎵',
];

enum _FrequencyChoice { daily, weekdays, custom }

enum _Difficulty { easy, medium, hard }

int _xpFor(_Difficulty d) => switch (d) {
      _Difficulty.easy => 10,
      _Difficulty.medium => 20,
      _Difficulty.hard => 30,
    };

class CreateHabitScreen extends ConsumerStatefulWidget {
  const CreateHabitScreen({super.key, this.editingId});

  final int? editingId;

  @override
  ConsumerState<CreateHabitScreen> createState() =>
      _CreateHabitScreenState();
}

class _CreateHabitScreenState extends ConsumerState<CreateHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: '');

  String _emoji = _habitEmojis.first;
  _FrequencyChoice _frequency = _FrequencyChoice.daily;
  _Difficulty _difficulty = _Difficulty.easy;
  final Set<int> _customDays = {0, 2, 4};
  TimeOfDay? _reminder = const TimeOfDay(hour: 8, minute: 0);
  bool _remindEnabled = true;
  bool _saving = false;
  bool _loading = false;

  bool get _isEditing => widget.editingId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadHabit();
  }

  Future<void> _loadHabit() async {
    setState(() => _loading = true);
    final db = ref.read(databaseProvider);
    final habit = await db.getHabit(widget.editingId!);
    if (!mounted || habit == null) {
      setState(() => _loading = false);
      return;
    }
    _nameCtrl.text = habit.name;
    _emoji = _canonicalEmoji(habit.icon);
    switch (habit.frequencyType) {
      case 'custom':
        final cfg = habit.frequencyCfg == null
            ? const <String, dynamic>{}
            : jsonDecode(habit.frequencyCfg!) as Map<String, dynamic>;
        final days = (cfg['days'] as List?)
                ?.map((e) => (e as num).toInt())
                .toSet() ??
            <int>{};
        if (days.containsAll({0, 1, 2, 3, 4}) && days.length == 5) {
          _frequency = _FrequencyChoice.weekdays;
        } else {
          _frequency = _FrequencyChoice.custom;
          _customDays
            ..clear()
            ..addAll(days);
        }
        break;
      case 'daily':
        _frequency = _FrequencyChoice.daily;
        break;
      default:
        // legacy x_per_week: default to daily; user picks again.
        _frequency = _FrequencyChoice.daily;
    }
    final minutes = habit.reminderMinutes;
    if (minutes == null) {
      _remindEnabled = false;
    } else {
      _remindEnabled = true;
      _reminder =
          TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    }
    setState(() => _loading = false);
  }

  String _canonicalEmoji(String stored) {
    final mapped = emojiFor(stored);
    // Prefer the exact stored emoji if it's already in our palette.
    if (_habitEmojis.contains(stored)) return stored;
    if (_habitEmojis.contains(mapped)) return mapped;
    return _habitEmojis.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(accentPaletteProvider);

    if (_loading) {
      return Scaffold(
        backgroundColor: SP.cream,
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      backgroundColor: SP.cream,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              _TopBar(
                isEditing: _isEditing,
                onClose: () => _safePop(context),
              ),
              const SizedBox(height: 14),
              _PreviewCard(
                emoji: _emoji,
                name: _nameCtrl.text.isEmpty
                    ? 'Name your habit'
                    : _nameCtrl.text,
                frequency: _frequency,
                xp: _xpFor(_difficulty),
                accent: accent,
              ),
              const SizedBox(height: 18),

              _Label('Name'),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                autofocus: !_isEditing,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'e.g. Stretch',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: SP.hairline),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Give your habit a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              _Label('Icon'),
              _EmojiGrid(
                selected: _emoji,
                accent: accent,
                onTap: (e) => setState(() => _emoji = e),
              ),
              const SizedBox(height: 14),

              _Label('How often'),
              _ChipRow(
                children: [
                  for (final f in _FrequencyChoice.values)
                    _Chip(
                      label: _frequencyLabel(f),
                      active: _frequency == f,
                      accent: accent,
                      onTap: () => setState(() => _frequency = f),
                    ),
                ],
              ),
              if (_frequency == _FrequencyChoice.custom) ...[
                const SizedBox(height: 10),
                _WeekdayPicker(
                  selected: _customDays,
                  accent: accent,
                  onToggle: (day, isOn) => setState(() {
                    if (isOn) {
                      _customDays.add(day);
                    } else {
                      _customDays.remove(day);
                    }
                  }),
                ),
              ],
              const SizedBox(height: 14),

              _Label('Difficulty · affects XP'),
              _ChipRow(
                children: [
                  for (final d in _Difficulty.values)
                    _Chip(
                      label: '${d.name} · +${_xpFor(d)}',
                      active: _difficulty == d,
                      accent: accent,
                      onTap: () => setState(() => _difficulty = d),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              _Label('Reminder'),
              _ReminderRow(
                enabled: _remindEnabled,
                time: _reminder,
                accent: accent,
                onToggle: (v) => setState(() => _remindEnabled = v),
                onPickTime: _pickReminder,
              ),
              const SizedBox(height: 22),

              _PrimaryCta(
                label: _isEditing ? 'Save changes' : 'Plant this habit 🌱',
                accent: accent,
                onPressed: _saving ? null : _save,
                busy: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _frequencyLabel(_FrequencyChoice f) => switch (f) {
        _FrequencyChoice.daily => 'daily',
        _FrequencyChoice.weekdays => 'weekdays',
        _FrequencyChoice.custom => 'custom',
      };

  Future<void> _pickReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminder ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) setState(() => _reminder = picked);
  }

  void _safePop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/today');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_frequency == _FrequencyChoice.custom && _customDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one day')),
      );
      return;
    }

    setState(() => _saving = true);
    final db = ref.read(databaseProvider);

    final reminderMinutes = _remindEnabled && _reminder != null
        ? _reminder!.hour * 60 + _reminder!.minute
        : null;

    final (frequencyType, frequencyCfg) = _encodeFrequency();

    final int habitId;
    if (_isEditing) {
      habitId = widget.editingId!;
      await (db.update(db.habits)..where((h) => h.id.equals(habitId))).write(
        HabitsCompanion(
          name: Value(_nameCtrl.text.trim()),
          icon: Value(_emoji),
          color: Value(hexFromColor(_paletteColor())),
          frequencyType: Value(frequencyType),
          frequencyCfg: Value(frequencyCfg),
          reminderMinutes: Value(reminderMinutes),
        ),
      );
      await db.recomputeStreak(habitId);
    } else {
      habitId = await db.insertHabit(
        HabitsCompanion.insert(
          name: _nameCtrl.text.trim(),
          icon: Value(_emoji),
          color: Value(hexFromColor(_paletteColor())),
          frequencyType: Value(frequencyType),
          frequencyCfg: Value(frequencyCfg),
          reminderMinutes: Value(reminderMinutes),
        ),
      );
      await db.upsertStreak(StreaksCompanion.insert(habitId: Value(habitId)));
    }

    if (reminderMinutes != null) {
      await NotificationService.instance.requestPermissions();
    }
    final saved = await db.getHabit(habitId);
    if (saved != null) {
      await NotificationService.instance.scheduleForHabit(saved);
    }

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditing ? 'Updated' : 'Planted 🌱')),
    );
    if (_isEditing) {
      context.pop();
    } else {
      context.go('/today');
    }
  }

  (String, String?) _encodeFrequency() {
    switch (_frequency) {
      case _FrequencyChoice.daily:
        return ('daily', null);
      case _FrequencyChoice.weekdays:
        return (
          'custom',
          jsonEncode({'days': [0, 1, 2, 3, 4]}),
        );
      case _FrequencyChoice.custom:
        return (
          'custom',
          jsonEncode({'days': _customDays.toList()..sort()}),
        );
    }
  }

  Color _paletteColor() {
    final accent = accentPalettes[ref.read(tweaksProvider).accent]!;
    return accent.main;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.isEditing, required this.onClose});

  final bool isEditing;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: onClose,
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Close'),
          style: TextButton.styleFrom(
            foregroundColor: SP.cocoaSoft,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
        ),
        Text(
          isEditing ? 'Edit habit' : 'New habit',
          style: const TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: SP.cocoa,
          ),
        ),
        const SizedBox(width: 64),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.emoji,
    required this.name,
    required this.frequency,
    required this.xp,
    required this.accent,
  });

  final String emoji;
  final String name;
  final _FrequencyChoice frequency;
  final int xp;
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.soft, SP.creamSoft],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SP.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.main, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: SP.cocoa,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${switch (frequency) {
                    _FrequencyChoice.daily => 'daily',
                    _FrequencyChoice.weekdays => 'weekdays',
                    _FrequencyChoice.custom => 'custom',
                  }} · +$xp xp',
                  style: const TextStyle(
                    fontSize: 11,
                    color: SP.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: SP.muted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String selected;
  final AccentPalette accent;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SP.creamSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SP.hairline),
      ),
      child: GridView.count(
        crossAxisCount: 8,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final e in _habitEmojis)
            GestureDetector(
              onTap: () => onTap(e),
              child: Container(
                decoration: BoxDecoration(
                  color: selected == e ? accent.soft : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected == e ? accent.main : SP.hairline,
                    width: selected == e ? 1.5 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(e, style: const TextStyle(fontSize: 18)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 6, runSpacing: 6, children: children);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool active;
  final AccentPalette accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? accent.soft : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active ? accent.main : const Color(0x1F2D1F16),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? accent.deep : SP.cocoaSoft,
          ),
        ),
      ),
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({
    required this.selected,
    required this.accent,
    required this.onToggle,
  });

  final Set<int> selected;
  final AccentPalette accent;
  final void Function(int day, bool isOn) onToggle;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          GestureDetector(
            onTap: () => onToggle(i, !selected.contains(i)),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected.contains(i) ? accent.main : SP.creamSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected.contains(i) ? accent.main : SP.hairline,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _labels[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected.contains(i) ? SP.onAccent : SP.cocoaSoft,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.enabled,
    required this.time,
    required this.accent,
    required this.onToggle,
    required this.onPickTime,
  });

  final bool enabled;
  final TimeOfDay? time;
  final AccentPalette accent;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SP.creamSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SP.hairline),
      ),
      child: Row(
        children: [
          Switch(
            value: enabled,
            onChanged: onToggle,
            activeThumbColor: Colors.white,
            activeTrackColor: accent.main,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: SP.mutedSoft,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              enabled && time != null
                  ? 'Ping me at ${time!.format(context)}'
                  : 'No reminder',
              style: const TextStyle(
                fontSize: 13,
                color: SP.cocoa,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (enabled)
            TextButton(
              onPressed: onPickTime,
              style: TextButton.styleFrom(
                foregroundColor: accent.deep,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: SP.hairline),
                ),
              ),
              child: Text(
                time?.format(context) ?? '—',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.accent,
    required this.onPressed,
    required this.busy,
  });

  final String label;
  final AccentPalette accent;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed == null
            ? null
            : [BoxShadow(color: accent.deep, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent.main,
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
                height: 20,
                width: 20,
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
