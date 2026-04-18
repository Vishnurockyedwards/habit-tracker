import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/database.dart';
import '../data/providers.dart';
import '../notifications/notification_service.dart';
import '../theme/tokens.dart';
import '../widgets/habit_icon.dart';

enum FrequencyType { daily, xPerWeek, custom }

class CreateHabitScreen extends ConsumerStatefulWidget {
  const CreateHabitScreen({super.key, this.editingId});

  final int? editingId;

  @override
  ConsumerState<CreateHabitScreen> createState() =>
      _CreateHabitScreenState();
}

class _CreateHabitScreenState extends ConsumerState<CreateHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController(text: '1');
  final _unitCtrl = TextEditingController();

  String _icon = habitIconOptions.keys.first;
  Color _color = AppColors.habitPalette.first;
  FrequencyType _frequency = FrequencyType.daily;
  int _timesPerWeek = 3;
  final Set<int> _customDays = {0, 2, 4};
  TimeOfDay? _reminder;
  bool _saving = false;
  bool _loading = false;

  bool get _isEditing => widget.editingId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadHabit();
    }
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
    _icon = habit.icon;
    _color = colorFromHex(habit.color);
    final target = habit.targetValue;
    _targetCtrl.text = target == target.roundToDouble()
        ? target.toInt().toString()
        : target.toString();
    _unitCtrl.text = habit.unit ?? '';
    switch (habit.frequencyType) {
      case 'x_per_week':
        _frequency = FrequencyType.xPerWeek;
        final cfg = habit.frequencyCfg == null
            ? const <String, dynamic>{}
            : jsonDecode(habit.frequencyCfg!) as Map<String, dynamic>;
        _timesPerWeek = (cfg['timesPerWeek'] as num?)?.toInt() ?? 3;
        break;
      case 'custom':
        _frequency = FrequencyType.custom;
        final cfg = habit.frequencyCfg == null
            ? const <String, dynamic>{}
            : jsonDecode(habit.frequencyCfg!) as Map<String, dynamic>;
        final days =
            (cfg['days'] as List?)?.map((e) => (e as num).toInt()) ?? const [];
        _customDays
          ..clear()
          ..addAll(days);
        break;
      default:
        _frequency = FrequencyType.daily;
    }
    final minutes = habit.reminderMinutes;
    _reminder =
        minutes == null ? null : TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit Habit' : 'New Habit')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Habit' : 'New Habit')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Habit name',
                hintText: 'e.g. Drink water',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Give your habit a name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(text: 'Icon'),
            _IconPicker(
              selected: _icon,
              tint: _color,
              onChanged: (i) => setState(() => _icon = i),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(text: 'Color'),
            _ColorPicker(
              selected: _color,
              onChanged: (c) => setState(() => _color = c),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(text: 'Frequency'),
            SegmentedButton<FrequencyType>(
              segments: const [
                ButtonSegment(
                  value: FrequencyType.daily,
                  label: Text('Daily'),
                ),
                ButtonSegment(
                  value: FrequencyType.xPerWeek,
                  label: Text('X / week'),
                ),
                ButtonSegment(
                  value: FrequencyType.custom,
                  label: Text('Custom'),
                ),
              ],
              selected: {_frequency},
              onSelectionChanged: (s) =>
                  setState(() => _frequency = s.first),
            ),
            if (_frequency == FrequencyType.xPerWeek) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Text('Times per week:', style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  IconButton(
                    onPressed: _timesPerWeek > 1
                        ? () => setState(() => _timesPerWeek--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_timesPerWeek', style: theme.textTheme.titleMedium),
                  IconButton(
                    onPressed: _timesPerWeek < 7
                        ? () => setState(() => _timesPerWeek++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
            if (_frequency == FrequencyType.custom) ...[
              const SizedBox(height: AppSpacing.md),
              _WeekdayPicker(
                selected: _customDays,
                onChanged: (day, isOn) => setState(() {
                  if (isOn) {
                    _customDays.add(day);
                  } else {
                    _customDays.remove(day);
                  }
                }),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _targetCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Target',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      final parsed = double.tryParse(v ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a positive number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _unitCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Unit (optional)',
                      hintText: 'glasses, km, min',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(text: 'Reminder'),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(
                  _reminder == null
                      ? 'No reminder'
                      : _reminder!.format(context),
                ),
                trailing: _reminder == null
                    ? const Icon(Icons.chevron_right)
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _reminder = null),
                      ),
                onTap: _pickReminder,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Save habit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminder ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) setState(() => _reminder = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_frequency == FrequencyType.custom && _customDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one day')),
      );
      return;
    }

    setState(() => _saving = true);
    final db = ref.read(databaseProvider);

    final target = double.parse(_targetCtrl.text);
    final unit = _unitCtrl.text.trim();
    final reminderMinutes =
        _reminder == null ? null : _reminder!.hour * 60 + _reminder!.minute;

    String frequencyType;
    String? frequencyCfg;
    switch (_frequency) {
      case FrequencyType.daily:
        frequencyType = 'daily';
        break;
      case FrequencyType.xPerWeek:
        frequencyType = 'x_per_week';
        frequencyCfg = jsonEncode({'timesPerWeek': _timesPerWeek});
        break;
      case FrequencyType.custom:
        frequencyType = 'custom';
        frequencyCfg =
            jsonEncode({'days': _customDays.toList()..sort()});
        break;
    }

    final int habitId;
    if (_isEditing) {
      habitId = widget.editingId!;
      await (db.update(db.habits)..where((h) => h.id.equals(habitId))).write(
        HabitsCompanion(
          name: Value(_nameCtrl.text.trim()),
          icon: Value(_icon),
          color: Value(hexFromColor(_color)),
          frequencyType: Value(frequencyType),
          frequencyCfg: Value(frequencyCfg),
          targetValue: Value(target),
          unit: Value(unit.isEmpty ? null : unit),
          reminderMinutes: Value(reminderMinutes),
        ),
      );
      await db.recomputeStreak(habitId);
    } else {
      habitId = await db.insertHabit(HabitsCompanion.insert(
        name: _nameCtrl.text.trim(),
        icon: Value(_icon),
        color: Value(hexFromColor(_color)),
        frequencyType: Value(frequencyType),
        frequencyCfg: Value(frequencyCfg),
        targetValue: Value(target),
        unit: Value(unit.isEmpty ? null : unit),
        reminderMinutes: Value(reminderMinutes),
      ));
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
    final name = _nameCtrl.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditing ? 'Updated "$name"' : 'Saved "$name"')),
    );
    if (!_isEditing) {
      _resetForm();
      if (mounted) context.go('/today');
    } else if (mounted) {
      context.pop();
    }
  }

  void _resetForm() {
    _nameCtrl.clear();
    _targetCtrl.text = '1';
    _unitCtrl.clear();
    setState(() {
      _icon = habitIconOptions.keys.first;
      _color = AppColors.habitPalette.first;
      _frequency = FrequencyType.daily;
      _timesPerWeek = 3;
      _customDays
        ..clear()
        ..addAll({0, 2, 4});
      _reminder = null;
    });
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({
    required this.selected,
    required this.tint,
    required this.onChanged,
  });

  final String selected;
  final Color tint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final entry in habitIconOptions.entries)
          _PickerChip(
            selected: entry.key == selected,
            onTap: () => onChanged(entry.key),
            child: Icon(
              entry.value,
              color: entry.key == selected
                  ? tint
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onChanged});
  final Color selected;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final color in AppColors.habitPalette)
          GestureDetector(
            onTap: () => onChanged(color),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.toARGB32() == selected.toARGB32()
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({required this.selected, required this.onChanged});

  final Set<int> selected;
  final void Function(int day, bool isOn) onChanged;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          FilterChip(
            label: Text(_labels[i]),
            selected: selected.contains(i),
            onSelected: (v) => onChanged(i, v),
            showCheckmark: false,
          ),
      ],
    );
  }
}

class _PickerChip extends StatelessWidget {
  const _PickerChip({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
