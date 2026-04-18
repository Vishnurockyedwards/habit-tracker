import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/date_key.dart';
import 'package:habit_tracker/logic/streak_engine.dart';

Set<String> datesFrom(DateTime anchor, List<int> offsets) {
  return {
    for (final o in offsets)
      ymd(DateTime(anchor.year, anchor.month, anchor.day - o)),
  };
}

void main() {
  group('StreakEngine.daily', () {
    final today = DateTime(2026, 4, 18);

    test('no completions → zero streak', () {
      final r = StreakEngine.compute(
        frequencyType: 'daily',
        completedDates: {},
        asOf: today,
      );
      expect(r.currentStreak, 0);
      expect(r.longestStreak, 0);
      expect(r.lastCompletedDate, isNull);
      expect(r.totalCompletions, 0);
    });

    test('today only → 1 / 1', () {
      final r = StreakEngine.compute(
        frequencyType: 'daily',
        completedDates: datesFrom(today, [0]),
        asOf: today,
      );
      expect(r.currentStreak, 1);
      expect(r.longestStreak, 1);
      expect(r.lastCompletedDate, ymd(today));
    });

    test('5 consecutive days ending today → 5', () {
      final r = StreakEngine.compute(
        frequencyType: 'daily',
        completedDates: datesFrom(today, [0, 1, 2, 3, 4]),
        asOf: today,
      );
      expect(r.currentStreak, 5);
      expect(r.longestStreak, 5);
    });

    test('today not yet done but yesterday done → grace preserves streak', () {
      final r = StreakEngine.compute(
        frequencyType: 'daily',
        completedDates: datesFrom(today, [1, 2, 3]),
        asOf: today,
      );
      expect(r.currentStreak, 3);
      expect(r.longestStreak, 3);
    });

    test('missed 2 days ago → current streak breaks', () {
      // today, yesterday done; 2 days ago missed; earlier done
      final r = StreakEngine.compute(
        frequencyType: 'daily',
        completedDates: datesFrom(today, [0, 1, 3, 4, 5]),
        asOf: today,
      );
      expect(r.currentStreak, 2);
      expect(r.longestStreak, 3);
    });

    test('freeze bridges single missed day', () {
      final r = StreakEngine.compute(
        frequencyType: 'daily',
        completedDates: datesFrom(today, [0, 1, 3, 4]),
        asOf: today,
        freezes: 1,
      );
      expect(r.currentStreak, 4);
      expect(r.freezesConsumed, 1);
    });

    test('freeze exhausted → streak still breaks on second gap', () {
      final r = StreakEngine.compute(
        frequencyType: 'daily',
        completedDates: datesFrom(today, [0, 1, 3, 5]),
        asOf: today,
        freezes: 1,
      );
      expect(r.currentStreak, 3);
      expect(r.freezesConsumed, 1);
    });

    test('retroactively logging fills gap and restores streak', () {
      final before = StreakEngine.compute(
        frequencyType: 'daily',
        completedDates: datesFrom(today, [0, 1, 3, 4]),
        asOf: today,
      );
      expect(before.currentStreak, 2);

      final after = StreakEngine.compute(
        frequencyType: 'daily',
        completedDates: datesFrom(today, [0, 1, 2, 3, 4]),
        asOf: today,
      );
      expect(after.currentStreak, 5);
      expect(after.longestStreak, 5);
    });

    test('longest streak spans past runs, not just current', () {
      // Old run of 7 days, then 3-day gap, then 2 consecutive ending today
      final dates = <String>{}
        ..addAll(datesFrom(today, [20, 19, 18, 17, 16, 15, 14]))
        ..addAll(datesFrom(today, [0, 1]));
      final r = StreakEngine.compute(
        frequencyType: 'daily',
        completedDates: dates,
        asOf: today,
      );
      expect(r.currentStreak, 2);
      expect(r.longestStreak, 7);
    });

    test('works across a DST spring-forward boundary', () {
      // US DST spring-forward 2026-03-08 (clocks jump 02:00 → 03:00 local).
      // ymd() strings are pure calendar dates so this should be unaffected.
      final dstToday = DateTime(2026, 3, 10);
      final r = StreakEngine.compute(
        frequencyType: 'daily',
        completedDates: datesFrom(dstToday, [0, 1, 2, 3, 4]), // 3/10..3/6
        asOf: dstToday,
      );
      expect(r.currentStreak, 5);
      expect(r.longestStreak, 5);
    });
  });

  group('StreakEngine.custom', () {
    // Days per UI: 0=Mon, 1=Tue, 2=Wed, 3=Thu, 4=Fri, 5=Sat, 6=Sun
    // "Saturday 2026-04-18" → weekday 6 → UI day 5.
    // Pick M/W/F (0,2,4) as the recurring required set.
    const cfg = '{"days":[0,2,4]}';

    test('today is not a required day → streak from prior required days', () {
      // today = Sat 2026-04-18. Required=M/W/F. Walk back to Fri 4/17, Wed 4/15, Mon 4/13.
      final today = DateTime(2026, 4, 18);
      final dates = {
        ymd(DateTime(2026, 4, 17)), // Fri
        ymd(DateTime(2026, 4, 15)), // Wed
        ymd(DateTime(2026, 4, 13)), // Mon
      };
      final r = StreakEngine.compute(
        frequencyType: 'custom',
        frequencyCfg: cfg,
        completedDates: dates,
        asOf: today,
      );
      expect(r.currentStreak, 3);
      expect(r.longestStreak, 3);
    });

    test('missed required day (no freeze) breaks streak', () {
      // Skip Wed 4/15.
      final today = DateTime(2026, 4, 18);
      final dates = {
        ymd(DateTime(2026, 4, 17)), // Fri
        ymd(DateTime(2026, 4, 13)), // Mon
      };
      final r = StreakEngine.compute(
        frequencyType: 'custom',
        frequencyCfg: cfg,
        completedDates: dates,
        asOf: today,
      );
      expect(r.currentStreak, 1); // only Fri counts
      expect(r.longestStreak, 1);
    });

    test('freeze saves a missed required day', () {
      final today = DateTime(2026, 4, 18);
      final dates = {
        ymd(DateTime(2026, 4, 17)), // Fri
        ymd(DateTime(2026, 4, 13)), // Mon (Wed missed)
      };
      final r = StreakEngine.compute(
        frequencyType: 'custom',
        frequencyCfg: cfg,
        completedDates: dates,
        asOf: today,
        freezes: 1,
      );
      expect(r.currentStreak, 2);
      expect(r.freezesConsumed, 1);
    });

    test('today is required and not yet done → grace', () {
      // Today = Fri 2026-04-17. Required M/W/F.
      final today = DateTime(2026, 4, 17);
      final dates = {
        ymd(DateTime(2026, 4, 15)), // Wed
        ymd(DateTime(2026, 4, 13)), // Mon
      };
      final r = StreakEngine.compute(
        frequencyType: 'custom',
        frequencyCfg: cfg,
        completedDates: dates,
        asOf: today,
      );
      expect(r.currentStreak, 2);
    });

    test('completion on a non-required day is ignored by streak', () {
      final today = DateTime(2026, 4, 18);
      final dates = {
        ymd(DateTime(2026, 4, 17)), // Fri required
        ymd(DateTime(2026, 4, 16)), // Thu not required — ignored
      };
      final r = StreakEngine.compute(
        frequencyType: 'custom',
        frequencyCfg: cfg,
        completedDates: dates,
        asOf: today,
      );
      expect(r.currentStreak, 1);
      expect(r.totalCompletions, 2);
    });
  });

  group('StreakEngine.xPerWeek', () {
    const cfg = '{"timesPerWeek":3}';

    test('3 completions this week → counts current week', () {
      // today = Saturday 2026-04-18 (weekStart Mon 4/13)
      final today = DateTime(2026, 4, 18);
      final dates = {
        ymd(DateTime(2026, 4, 13)),
        ymd(DateTime(2026, 4, 15)),
        ymd(DateTime(2026, 4, 17)),
      };
      final r = StreakEngine.compute(
        frequencyType: 'x_per_week',
        frequencyCfg: cfg,
        completedDates: dates,
        asOf: today,
      );
      expect(r.currentStreak, 1);
      expect(r.longestStreak, 1);
    });

    test('current week short → grace, prior week counted', () {
      // This week: only 2 done so far. Last week: 3 done.
      final today = DateTime(2026, 4, 18);
      final dates = {
        ymd(DateTime(2026, 4, 13)), // Mon this wk
        ymd(DateTime(2026, 4, 15)), // Wed this wk
        ymd(DateTime(2026, 4, 6)), // Mon last wk
        ymd(DateTime(2026, 4, 8)), // Wed last wk
        ymd(DateTime(2026, 4, 10)), // Fri last wk
      };
      final r = StreakEngine.compute(
        frequencyType: 'x_per_week',
        frequencyCfg: cfg,
        completedDates: dates,
        asOf: today,
      );
      expect(r.currentStreak, 1);
    });

    test('3 weeks in a row ending last week → streak 3 (with grace)', () {
      final today = DateTime(2026, 4, 18);
      final dates = <String>{};
      // Weeks ending 4/12, 4/5, 3/29 — each has Mon/Wed/Fri completions.
      for (final monday in [
        DateTime(2026, 4, 6),
        DateTime(2026, 3, 30),
        DateTime(2026, 3, 23),
      ]) {
        dates.addAll([
          ymd(monday),
          ymd(DateTime(monday.year, monday.month, monday.day + 2)),
          ymd(DateTime(monday.year, monday.month, monday.day + 4)),
        ]);
      }
      final r = StreakEngine.compute(
        frequencyType: 'x_per_week',
        frequencyCfg: cfg,
        completedDates: dates,
        asOf: today,
      );
      expect(r.currentStreak, 3);
      expect(r.longestStreak, 3);
    });

    test('gap in prior week breaks streak without freeze', () {
      final today = DateTime(2026, 4, 18);
      // This week: hit target already (3). Two weeks ago: missed. Three weeks ago: hit.
      final dates = <String>{
        // this week
        ymd(DateTime(2026, 4, 13)),
        ymd(DateTime(2026, 4, 15)),
        ymd(DateTime(2026, 4, 17)),
        // 2 weeks ago (the week of Mon 3/30): only 1 — misses target
        ymd(DateTime(2026, 3, 30)),
        // 3 weeks ago (Mon 3/23): 3 — hits target
        ymd(DateTime(2026, 3, 23)),
        ymd(DateTime(2026, 3, 25)),
        ymd(DateTime(2026, 3, 27)),
      };
      final r = StreakEngine.compute(
        frequencyType: 'x_per_week',
        frequencyCfg: cfg,
        completedDates: dates,
        asOf: today,
      );
      // Current week (met) + grace; walking back: last week (Mon 4/6) missing entirely → break.
      // Wait — "last week" (4/6..4/12) has no completions, so count=0 < 3, no freezes → break after current.
      expect(r.currentStreak, 1);
      expect(r.longestStreak, 1);
    });

    test('freeze covers a missed week', () {
      final today = DateTime(2026, 4, 18);
      // current week met, last week missing (0), 2 weeks ago met, 3 weeks ago met.
      final dates = <String>{
        ymd(DateTime(2026, 4, 13)),
        ymd(DateTime(2026, 4, 15)),
        ymd(DateTime(2026, 4, 17)),
        // last week 4/6..4/12: nothing
        ymd(DateTime(2026, 3, 30)),
        ymd(DateTime(2026, 4, 1)),
        ymd(DateTime(2026, 4, 3)),
        ymd(DateTime(2026, 3, 23)),
        ymd(DateTime(2026, 3, 25)),
        ymd(DateTime(2026, 3, 27)),
      };
      final r = StreakEngine.compute(
        frequencyType: 'x_per_week',
        frequencyCfg: cfg,
        completedDates: dates,
        asOf: today,
        freezes: 1,
      );
      expect(r.currentStreak, 3);
      expect(r.freezesConsumed, 1);
    });
  });
}
