import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'date_key.dart';
import 'seed.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final databaseSeedProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);
  await seedIfEmpty(db);
});

final activeHabitsProvider = StreamProvider<List<Habit>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchActiveHabits();
});

final todayCompletionsProvider =
    StreamProvider<List<HabitCompletion>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchCompletionsForDate(todayYmd());
});

final allStreaksProvider = StreamProvider<List<Streak>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllStreaks();
});
