import 'package:drift/drift.dart';

import 'database.dart';
import 'date_key.dart';

Future<void> seedIfEmpty(AppDatabase db) async {
  final count = await db.habits.count().getSingle();
  if (count > 0) return;

  final now = DateTime.now();

  await db.batch((batch) {
    batch.insertAll(db.habits, [
      HabitsCompanion.insert(
        name: 'Drink water',
        icon: const Value('water_drop'),
        color: const Value('#1E88E5'),
        frequencyType: const Value('daily'),
        targetValue: const Value(8),
        unit: const Value('glasses'),
        reminderMinutes: const Value(10 * 60),
        sortOrder: const Value(0),
      ),
      HabitsCompanion.insert(
        name: 'Meditate',
        icon: const Value('self_improvement'),
        color: const Value('#8E24AA'),
        frequencyType: const Value('daily'),
        targetValue: const Value(10),
        unit: const Value('minutes'),
        reminderMinutes: const Value(7 * 60),
        sortOrder: const Value(1),
      ),
      HabitsCompanion.insert(
        name: 'Run',
        icon: const Value('directions_run'),
        color: const Value('#43A047'),
        frequencyType: const Value('x_per_week'),
        frequencyCfg: const Value('{"timesPerWeek":3}'),
        targetValue: const Value(3),
        unit: const Value('km'),
        reminderMinutes: const Value(18 * 60),
        sortOrder: const Value(2),
      ),
    ]);
  });

  final inserted = await db.select(db.habits).get();
  await db.batch((batch) {
    for (final h in inserted) {
      batch.insert(
        db.streaks,
        StreaksCompanion.insert(
          habitId: Value(h.id),
        ),
      );
    }
  });

  final waterId = inserted.firstWhere((h) => h.name == 'Drink water').id;
  final meditateId = inserted.firstWhere((h) => h.name == 'Meditate').id;

  await db.batch((batch) {
    batch.insertAll(db.habitCompletions, [
      HabitCompletionsCompanion.insert(
        habitId: waterId,
        date: ymd(now.subtract(const Duration(days: 1))),
        value: const Value(8),
      ),
      HabitCompletionsCompanion.insert(
        habitId: waterId,
        date: ymd(now.subtract(const Duration(days: 2))),
        value: const Value(6),
      ),
      HabitCompletionsCompanion.insert(
        habitId: meditateId,
        date: ymd(now.subtract(const Duration(days: 1))),
        value: const Value(10),
      ),
    ]);
  });
}
