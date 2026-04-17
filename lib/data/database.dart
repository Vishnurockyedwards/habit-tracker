import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get icon => text().withDefault(const Constant('check_circle'))();
  TextColumn get color => text().withDefault(const Constant('#6750A4'))();
  TextColumn get frequencyType =>
      text().withDefault(const Constant('daily'))();
  TextColumn get frequencyCfg => text().nullable()();
  RealColumn get targetValue => real().withDefault(const Constant(1))();
  TextColumn get unit => text().nullable()();
  IntColumn get reminderMinutes => integer().nullable()();
  IntColumn get freezesRemaining => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

class HabitCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer()
      .references(Habits, #id, onDelete: KeyAction.cascade)();
  TextColumn get date => text()();
  RealColumn get value => real().withDefault(const Constant(1))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get loggedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, date},
      ];
}

class Streaks extends Table {
  IntColumn get habitId => integer()
      .references(Habits, #id, onDelete: KeyAction.cascade)();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  TextColumn get lastCompletedDate => text().nullable()();
  IntColumn get totalCompletions =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {habitId};
}

@DriftDatabase(tables: [Habits, HabitCompletions, Streaks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() =>
      driftDatabase(name: 'habit_tracker_db');

  Stream<List<Habit>> watchActiveHabits() {
    return (select(habits)
          ..where((h) => h.archivedAt.isNull())
          ..orderBy([(h) => OrderingTerm(expression: h.sortOrder)]))
        .watch();
  }

  Future<int> insertHabit(HabitsCompanion habit) =>
      into(habits).insert(habit);

  Future<bool> updateHabit(Habit habit) => update(habits).replace(habit);

  Future<void> archiveHabit(int id) =>
      (update(habits)..where((h) => h.id.equals(id))).write(
        HabitsCompanion(archivedAt: Value(DateTime.now())),
      );

  Future<void> deleteHabit(int id) =>
      (delete(habits)..where((h) => h.id.equals(id))).go();

  Stream<List<HabitCompletion>> watchCompletionsForDate(String date) {
    return (select(habitCompletions)..where((c) => c.date.equals(date)))
        .watch();
  }

  Stream<List<HabitCompletion>> watchCompletionsForHabit(int habitId) {
    return (select(habitCompletions)
          ..where((c) => c.habitId.equals(habitId))
          ..orderBy([(c) => OrderingTerm.desc(c.date)]))
        .watch();
  }

  Future<void> toggleCompletion({
    required int habitId,
    required String date,
    double value = 1,
  }) async {
    final existing = await (select(habitCompletions)
          ..where((c) => c.habitId.equals(habitId) & c.date.equals(date)))
        .getSingleOrNull();
    if (existing != null) {
      await (delete(habitCompletions)
            ..where((c) => c.id.equals(existing.id)))
          .go();
    } else {
      await into(habitCompletions).insert(
        HabitCompletionsCompanion.insert(
          habitId: habitId,
          date: date,
          value: Value(value),
        ),
      );
    }
  }

  Future<Streak?> getStreak(int habitId) =>
      (select(streaks)..where((s) => s.habitId.equals(habitId)))
          .getSingleOrNull();

  Future<void> upsertStreak(StreaksCompanion streak) =>
      into(streaks).insertOnConflictUpdate(streak);

  Stream<List<Streak>> watchAllStreaks() => select(streaks).watch();
}
