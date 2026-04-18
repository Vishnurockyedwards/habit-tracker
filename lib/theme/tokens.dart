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

/// Sprout base palette — warm/earthy, stable across accents.
class SP {
  static const Color cream = Color(0xFFF6EDE0);
  static const Color creamDeep = Color(0xFFEFE3D0);
  static const Color creamSoft = Color(0xFFFFFBF4);
  static const Color cocoa = Color(0xFF2D1F16);
  static const Color cocoaSoft = Color(0xFF4A3828);
  static const Color muted = Color(0xFF8C7A66);
  static const Color mutedSoft = Color(0xFFB8A68E);
  static const Color hairline = Color(0x142D1F16); // rgba(45,31,22,0.08)
  static const Color gold = Color(0xFFE8A94A);
  static const Color creamGradTop = Color(0xFFFFF4E0);
  static const Color creamGradBottom = Color(0xFFFFE7C7);
  static const Color onAccent = Color(0xFFFFF4E0);
}

enum AccentKind { terracotta, sage, plum, ochre }

@immutable
class AccentPalette {
  final Color main;
  final Color deep;
  final Color soft;
  final Color glow;
  const AccentPalette({
    required this.main,
    required this.deep,
    required this.soft,
    required this.glow,
  });
}

const accentPalettes = <AccentKind, AccentPalette>{
  AccentKind.terracotta: AccentPalette(
    main: Color(0xFFD96B4A),
    deep: Color(0xFFB2512F),
    soft: Color(0xFFFFE8D6),
    glow: Color(0xFFF4A58C),
  ),
  AccentKind.sage: AccentPalette(
    main: Color(0xFF6B9862),
    deep: Color(0xFF4E7A47),
    soft: Color(0xFFDDEAD6),
    glow: Color(0xFFA8C49C),
  ),
  AccentKind.plum: AccentPalette(
    main: Color(0xFF9B5E88),
    deep: Color(0xFF774368),
    soft: Color(0xFFEBDAE4),
    glow: Color(0xFFC494B5),
  ),
  AccentKind.ochre: AccentPalette(
    main: Color(0xFFC48A3C),
    deep: Color(0xFF986A24),
    soft: Color(0xFFF3E4C4),
    glow: Color(0xFFE0B978),
  ),
};

enum CompanionKind { plant, pet, creature }

String companionName(CompanionKind k) => switch (k) {
  CompanionKind.plant => 'Basil',
  CompanionKind.pet => 'Moss',
  CompanionKind.creature => 'Pip',
};

enum DensityKind { airy, compact }

@immutable
class DensityTokens {
  final double rowPadY;
  final double rowGap;
  final double iconSize;
  final double radius;
  final double headerSize;
  const DensityTokens({
    required this.rowPadY,
    required this.rowGap,
    required this.iconSize,
    required this.radius,
    required this.headerSize,
  });
}

const densityTokens = <DensityKind, DensityTokens>{
  DensityKind.airy: DensityTokens(
    rowPadY: 16,
    rowGap: 8,
    iconSize: 44,
    radius: 18,
    headerSize: 32,
  ),
  DensityKind.compact: DensityTokens(
    rowPadY: 10,
    rowGap: 6,
    iconSize: 36,
    radius: 14,
    headerSize: 26,
  ),
};

/// Back-compat shim so existing (pre-port) screens still compile
/// while each screen is rewritten in later phases.
class AppColors {
  static const Color seed = Color(0xFFD96B4A);
  static const Color streakFlame = Color(0xFFD96B4A);
  static const Color streakAtRisk = Color(0xFFB2512F);
  static const Color completionSuccess = Color(0xFF6B9862);
  static const List<Color> habitPalette = [
    Color(0xFFD96B4A),
    Color(0xFF6B9862),
    Color(0xFF9B5E88),
    Color(0xFFC48A3C),
    Color(0xFFB2512F),
    Color(0xFF4E7A47),
    Color(0xFF774368),
    Color(0xFF986A24),
  ];
}
