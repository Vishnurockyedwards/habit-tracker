import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const Radius cardRadius = Radius.circular(md);
}

class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

class AppColors {
  static const Color seed = Color(0xFF6750A4);
  static const Color streakFlame = Color(0xFFFF6B35);
  static const Color streakAtRisk = Color(0xFFE53935);
  static const Color completionSuccess = Color(0xFF43A047);
  static const List<Color> habitPalette = [
    Color(0xFF6750A4),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
    Color(0xFF00897B),
    Color(0xFF5E35B1),
  ];
}
