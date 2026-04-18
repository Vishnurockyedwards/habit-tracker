import 'package:flutter/material.dart';

const habitIconOptions = <String, IconData>{
  'check_circle': Icons.check_circle,
  'water_drop': Icons.water_drop,
  'self_improvement': Icons.self_improvement,
  'directions_run': Icons.directions_run,
  'menu_book': Icons.menu_book,
  'fitness_center': Icons.fitness_center,
  'bedtime': Icons.bedtime,
  'restaurant': Icons.restaurant,
  'code': Icons.code,
  'brush': Icons.brush,
};

/// Default emoji for each legacy Material icon key. Phase 4 Create Habit
/// will store the emoji directly; until then, old rows render via this
/// mapping. If [stored] doesn't match a key, it's assumed to already be an
/// emoji and returned as-is.
const _iconKeyToEmoji = <String, String>{
  'check_circle': '✅',
  'water_drop': '💧',
  'self_improvement': '🧘',
  'directions_run': '🏃',
  'menu_book': '📖',
  'fitness_center': '🏋️',
  'bedtime': '😴',
  'restaurant': '🥗',
  'code': '💻',
  'brush': '🎨',
};

const _fallbackEmoji = '🌱';

IconData iconFor(String name) =>
    habitIconOptions[name] ?? Icons.check_circle;

String emojiFor(String stored) {
  if (stored.isEmpty) return _fallbackEmoji;
  final mapped = _iconKeyToEmoji[stored];
  if (mapped != null) return mapped;
  // Stored string isn't a known key — assume it's already an emoji.
  return stored;
}

Color colorFromHex(String hex) {
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}

String hexFromColor(Color color) {
  final r = (color.r * 255).round();
  final g = (color.g * 255).round();
  final b = (color.b * 255).round();
  final value = (r << 16) | (g << 8) | b;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
