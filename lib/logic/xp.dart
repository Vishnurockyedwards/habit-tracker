import 'dart:math' as math;

/// XP math per FEATURES §2.1.
///
/// Difficulty isn't stored in Drift yet (added in phase 4 port of the
/// Create Habit form). Until then, every completion is worth [perCompletion]
/// XP — treated as "medium" difficulty from the spec.
class XpMath {
  static const int perCompletion = 15;

  static int totalFor(int completions) => completions * perCompletion;

  /// `floor(sqrt(totalXp / 50)) + 1` — level 1 at 0 XP, level 2 at 50 XP,
  /// level 3 at 200 XP, level 4 at 450 XP…
  static int levelFor(int totalXp) =>
      math.sqrt(totalXp / 50).floor() + 1;

  /// Threshold XP needed to reach the *next* level after [level].
  static int thresholdForLevel(int level) => 50 * level * level;

  /// 0..1 position between the previous level's threshold and the current.
  static double progressInLevel(int totalXp) {
    final lvl = levelFor(totalXp);
    final floor = thresholdForLevel(lvl - 1);
    final ceil = thresholdForLevel(lvl);
    final span = ceil - floor;
    if (span <= 0) return 0;
    return ((totalXp - floor) / span).clamp(0.0, 1.0);
  }
}
