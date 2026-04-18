import 'dart:convert';

import '../data/date_key.dart';

/// Rules for awarding streak shields (freezes). Freezes act as a tolerance
/// buffer — the engine already tolerates up to `freezesRemaining` missed
/// required days per streak; this policy decides when to grant new shields.
class FreezePolicy {
  const FreezePolicy._();

  /// Grant one shield for every fresh N-day milestone in the current streak.
  static const int awardEvery = 7;

  /// Maximum shields a single habit can hold at once.
  static const int maxFreezes = 3;

  /// How many milestones were newly crossed going from [prevStreak] to
  /// [newStreak]. Negative or unchanged progress returns 0.
  static int milestonesCrossed({
    required int prevStreak,
    required int newStreak,
  }) {
    if (newStreak <= prevStreak) return 0;
    return (newStreak ~/ awardEvery) - (prevStreak ~/ awardEvery);
  }

  static int cap(int freezes) => freezes.clamp(0, maxFreezes);
}

class StreakResult {
  final int currentStreak;
  final int longestStreak;
  final String? lastCompletedDate;
  final int totalCompletions;
  final int freezesConsumed;

  const StreakResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCompletedDate,
    required this.totalCompletions,
    this.freezesConsumed = 0,
  });

  @override
  String toString() =>
      'StreakResult(current: $currentStreak, longest: $longestStreak, '
      'last: $lastCompletedDate, total: $totalCompletions, '
      'freezesConsumed: $freezesConsumed)';
}

class StreakEngine {
  const StreakEngine._();

  static StreakResult compute({
    required String frequencyType,
    String? frequencyCfg,
    required Set<String> completedDates,
    required DateTime asOf,
    int freezes = 0,
  }) {
    final today = DateTime(asOf.year, asOf.month, asOf.day);
    final last = _lastCompleted(completedDates);
    final total = completedDates.length;

    switch (frequencyType) {
      case 'x_per_week':
        final cfg = _decode(frequencyCfg);
        final target = (cfg['timesPerWeek'] as num?)?.toInt() ?? 1;
        return _xPerWeek(completedDates, today, target, freezes, last, total);
      case 'custom':
        final cfg = _decode(frequencyCfg);
        final days = (cfg['days'] as List?)
                ?.map((e) => (e as num).toInt())
                .toSet() ??
            <int>{};
        return _custom(completedDates, today, days, freezes, last, total);
      case 'daily':
      default:
        return _daily(completedDates, today, freezes, last, total);
    }
  }

  static Map<String, dynamic> _decode(String? cfg) {
    if (cfg == null || cfg.isEmpty) return const {};
    return jsonDecode(cfg) as Map<String, dynamic>;
  }

  static String? _lastCompleted(Set<String> dates) {
    if (dates.isEmpty) return null;
    final sorted = dates.toList()..sort();
    return sorted.last;
  }

  static DateTime _prevDay(DateTime d) =>
      DateTime(d.year, d.month, d.day - 1);
  static DateTime _nextDay(DateTime d) =>
      DateTime(d.year, d.month, d.day + 1);
  static DateTime _prevWeek(DateTime d) =>
      DateTime(d.year, d.month, d.day - 7);
  static DateTime _weekStart(DateTime d) {
    final floor = DateTime(d.year, d.month, d.day);
    return DateTime(floor.year, floor.month, floor.day - (floor.weekday - 1));
  }

  static StreakResult _daily(
    Set<String> dates,
    DateTime today,
    int freezes,
    String? last,
    int total,
  ) {
    int current = 0;
    int remaining = freezes;
    int consumed = 0;

    DateTime cursor = today;
    if (!dates.contains(ymd(cursor))) {
      cursor = _prevDay(cursor);
    }

    while (true) {
      if (dates.contains(ymd(cursor))) {
        current++;
        cursor = _prevDay(cursor);
      } else if (remaining > 0) {
        remaining--;
        consumed++;
        cursor = _prevDay(cursor);
      } else {
        break;
      }
    }

    final longest = _longestConsecutiveDays(dates);

    return StreakResult(
      currentStreak: current,
      longestStreak: longest,
      lastCompletedDate: last,
      totalCompletions: total,
      freezesConsumed: consumed,
    );
  }

  static int _longestConsecutiveDays(Set<String> dates) {
    if (dates.isEmpty) return 0;
    final sorted = (dates.toList()..sort()).map(parseYmd).toList();
    int longest = 0;
    int run = 0;
    DateTime? prev;
    for (final d in sorted) {
      if (prev == null || ymd(_nextDay(prev)) != ymd(d)) {
        run = 1;
      } else {
        run++;
      }
      if (run > longest) longest = run;
      prev = d;
    }
    return longest;
  }

  static StreakResult _custom(
    Set<String> dates,
    DateTime today,
    Set<int> requiredDays,
    int freezes,
    String? last,
    int total,
  ) {
    if (requiredDays.isEmpty) {
      return StreakResult(
        currentStreak: 0,
        longestStreak: 0,
        lastCompletedDate: last,
        totalCompletions: total,
      );
    }

    bool isRequired(DateTime d) => requiredDays.contains(d.weekday - 1);

    int current = 0;
    int remaining = freezes;
    int consumed = 0;

    DateTime cursor = today;
    if (isRequired(cursor) && !dates.contains(ymd(cursor))) {
      cursor = _prevDay(cursor);
    }

    // Walk back through days. Non-required days are skipped.
    // Required days must be completed, or consume a freeze, else break.
    while (true) {
      if (!isRequired(cursor)) {
        cursor = _prevDay(cursor);
        continue;
      }
      if (dates.contains(ymd(cursor))) {
        current++;
        cursor = _prevDay(cursor);
      } else if (remaining > 0) {
        remaining--;
        consumed++;
        cursor = _prevDay(cursor);
      } else {
        break;
      }
    }

    final longest = _longestCustomRun(dates, requiredDays, today);

    return StreakResult(
      currentStreak: current,
      longestStreak: longest,
      lastCompletedDate: last,
      totalCompletions: total,
      freezesConsumed: consumed,
    );
  }

  static int _longestCustomRun(
    Set<String> dates,
    Set<int> requiredDays,
    DateTime today,
  ) {
    if (dates.isEmpty) return 0;
    final sortedDates = (dates.toList()..sort()).map(parseYmd).toList();
    final earliest = sortedDates.first;
    int longest = 0;
    int run = 0;
    DateTime d = DateTime(earliest.year, earliest.month, earliest.day);
    while (!d.isAfter(today)) {
      if (requiredDays.contains(d.weekday - 1)) {
        if (dates.contains(ymd(d))) {
          run++;
          if (run > longest) longest = run;
        } else {
          run = 0;
        }
      }
      d = _nextDay(d);
    }
    return longest;
  }

  static StreakResult _xPerWeek(
    Set<String> dates,
    DateTime today,
    int target,
    int freezes,
    String? last,
    int total,
  ) {
    if (target < 1) {
      return StreakResult(
        currentStreak: 0,
        longestStreak: 0,
        lastCompletedDate: last,
        totalCompletions: total,
      );
    }

    final weekCounts = <String, int>{};
    DateTime? earliestWeek;
    for (final s in dates) {
      final wk = _weekStart(parseYmd(s));
      final key = ymd(wk);
      weekCounts[key] = (weekCounts[key] ?? 0) + 1;
      if (earliestWeek == null || wk.isBefore(earliestWeek)) {
        earliestWeek = wk;
      }
    }

    int current = 0;
    int remaining = freezes;
    int consumed = 0;
    DateTime cursor = _weekStart(today);
    bool isCurrentWeek = true;

    while (true) {
      final count = weekCounts[ymd(cursor)] ?? 0;
      final met = count >= target;
      if (met) {
        current++;
      } else if (isCurrentWeek) {
        // ongoing week — don't count, don't break
      } else if (remaining > 0) {
        remaining--;
        consumed++;
      } else {
        break;
      }
      isCurrentWeek = false;
      cursor = _prevWeek(cursor);
      if (earliestWeek == null || cursor.isBefore(earliestWeek)) break;
    }

    int longest = 0;
    if (earliestWeek != null) {
      final latest = _weekStart(today);
      int run = 0;
      DateTime w = earliestWeek;
      while (!w.isAfter(latest)) {
        final count = weekCounts[ymd(w)] ?? 0;
        final met = count >= target;
        final isLatest = ymd(w) == ymd(latest);
        if (met) {
          run++;
          if (run > longest) longest = run;
        } else if (!isLatest) {
          run = 0;
        }
        w = DateTime(w.year, w.month, w.day + 7);
      }
    }

    return StreakResult(
      currentStreak: current,
      longestStreak: longest,
      lastCompletedDate: last,
      totalCompletions: total,
      freezesConsumed: consumed,
    );
  }
}
