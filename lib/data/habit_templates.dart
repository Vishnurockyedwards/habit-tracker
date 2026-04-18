import 'package:drift/drift.dart';

import 'database.dart';

class HabitTemplate {
  const HabitTemplate({
    required this.name,
    required this.icon,
    required this.color,
    required this.frequencyType,
    this.frequencyCfg,
    this.targetValue = 1,
    this.unit,
    this.reminderMinutes,
    this.blurb,
  });

  final String name;
  final String icon;
  final String color;
  final String frequencyType;
  final String? frequencyCfg;
  final double targetValue;
  final String? unit;
  final int? reminderMinutes;
  final String? blurb;
}

const kHabitTemplates = <HabitTemplate>[
  HabitTemplate(
    name: 'Drink water',
    icon: 'water_drop',
    color: '#1E88E5',
    frequencyType: 'daily',
    targetValue: 8,
    unit: 'glasses',
    reminderMinutes: 10 * 60,
    blurb: '8 glasses a day',
  ),
  HabitTemplate(
    name: 'Meditate',
    icon: 'self_improvement',
    color: '#8E24AA',
    frequencyType: 'daily',
    targetValue: 10,
    unit: 'minutes',
    reminderMinutes: 7 * 60,
    blurb: '10 quiet minutes',
  ),
  HabitTemplate(
    name: 'Run',
    icon: 'directions_run',
    color: '#43A047',
    frequencyType: 'x_per_week',
    frequencyCfg: '{"timesPerWeek":3}',
    targetValue: 3,
    unit: 'km',
    reminderMinutes: 18 * 60,
    blurb: '3× per week',
  ),
  HabitTemplate(
    name: 'Read',
    icon: 'menu_book',
    color: '#5E35B1',
    frequencyType: 'daily',
    targetValue: 20,
    unit: 'pages',
    reminderMinutes: 21 * 60,
    blurb: 'Wind down with 20 pages',
  ),
  HabitTemplate(
    name: 'Workout',
    icon: 'fitness_center',
    color: '#E53935',
    frequencyType: 'custom',
    frequencyCfg: '{"days":[0,2,4]}',
    targetValue: 30,
    unit: 'min',
    reminderMinutes: 17 * 60 + 30,
    blurb: 'Mon / Wed / Fri',
  ),
  HabitTemplate(
    name: 'Sleep by 11',
    icon: 'bedtime',
    color: '#00897B',
    frequencyType: 'daily',
    reminderMinutes: 22 * 60 + 30,
    blurb: 'Wind-down reminder at 10:30',
  ),
  HabitTemplate(
    name: 'Code practice',
    icon: 'code',
    color: '#FB8C00',
    frequencyType: 'daily',
    targetValue: 45,
    unit: 'min',
    reminderMinutes: 20 * 60,
    blurb: '45 min of deliberate practice',
  ),
  HabitTemplate(
    name: 'Journal',
    icon: 'brush',
    color: '#6750A4',
    frequencyType: 'daily',
    reminderMinutes: 21 * 60 + 30,
    blurb: 'Three lines before bed',
  ),
];

Future<List<int>> applyTemplates(
  AppDatabase db,
  Iterable<HabitTemplate> templates,
) async {
  final ids = <int>[];
  var sort = (await db.habits.count().getSingle());
  for (final t in templates) {
    final id = await db.insertHabit(
      HabitsCompanion.insert(
        name: t.name,
        icon: Value(t.icon),
        color: Value(t.color),
        frequencyType: Value(t.frequencyType),
        frequencyCfg: Value(t.frequencyCfg),
        targetValue: Value(t.targetValue),
        unit: Value(t.unit),
        reminderMinutes: Value(t.reminderMinutes),
        sortOrder: Value(sort++),
      ),
    );
    await db.upsertStreak(StreaksCompanion.insert(habitId: Value(id)));
    ids.add(id);
  }
  return ids;
}
