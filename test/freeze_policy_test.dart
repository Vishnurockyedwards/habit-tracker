import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/logic/streak_engine.dart';

void main() {
  group('FreezePolicy.milestonesCrossed', () {
    test('crossing day 7 awards one milestone', () {
      expect(
        FreezePolicy.milestonesCrossed(prevStreak: 6, newStreak: 7),
        1,
      );
    });

    test('jumping from 0 to 14 via retroactive log awards two', () {
      expect(
        FreezePolicy.milestonesCrossed(prevStreak: 0, newStreak: 14),
        2,
      );
    });

    test('streak growing within the same bucket awards nothing', () {
      expect(
        FreezePolicy.milestonesCrossed(prevStreak: 8, newStreak: 10),
        0,
      );
    });

    test('streak breaking (now <= prev) never awards', () {
      expect(
        FreezePolicy.milestonesCrossed(prevStreak: 10, newStreak: 0),
        0,
      );
      expect(
        FreezePolicy.milestonesCrossed(prevStreak: 10, newStreak: 10),
        0,
      );
    });

    test('crossing two milestones in one step awards two', () {
      // e.g. ending a 6-day streak at day 20 via retroactive fills → milestones 7 and 14
      expect(
        FreezePolicy.milestonesCrossed(prevStreak: 6, newStreak: 20),
        2,
      );
    });
  });

  group('FreezePolicy.cap', () {
    test('clamps to max', () {
      expect(FreezePolicy.cap(5), FreezePolicy.maxFreezes);
    });

    test('clamps to zero floor', () {
      expect(FreezePolicy.cap(-2), 0);
    });

    test('preserves in-range values', () {
      expect(FreezePolicy.cap(2), 2);
    });
  });
}
