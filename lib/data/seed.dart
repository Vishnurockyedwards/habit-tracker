import 'database.dart';

/// Seeding is now opt-in via the templates picker on the Today empty state.
/// This helper is a no-op and exists only so older callers keep compiling.
Future<void> seedIfEmpty(AppDatabase db) async {}
