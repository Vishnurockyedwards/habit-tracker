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

IconData iconFor(String name) =>
    habitIconOptions[name] ?? Icons.check_circle;

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
