import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import 'creature_companion.dart';
import 'life.dart';
import 'pet_companion.dart';
import 'plant_companion.dart';

/// Dispatcher — chooses plant/pet/creature based on [kind] and drives
/// motion via an internal [LifeTicker]. Growth changes are smoothed via a
/// 600ms cubic-ease tween so stem/flower scale feels organic.
///
/// Respects [MediaQueryData.disableAnimations]. When reduced-motion is on,
/// companions render static (no blink/sway/bob, instant growth changes).
class Companion extends StatelessWidget {
  const Companion({
    super.key,
    required this.kind,
    required this.growth,
    required this.accent,
    this.bloom = false,
    this.size = 180,
    this.animate = true,
  });

  final CompanionKind kind;
  final double growth;
  final AccentPalette accent;
  final bool bloom;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).disableAnimations;
    final enabled = animate && !reduced;
    final g = growth.clamp(0.0, 1.0);

    return Semantics(
      label: '${companionName(kind)} — ${(g * 100).round()}% grown',
      child: LifeTicker(
      enabled: enabled,
      builder: (context, life) {
        Widget child(double smoothed) {
          switch (kind) {
            case CompanionKind.plant:
              return PlantCompanion(
                growth: smoothed,
                accent: accent,
                life: life,
                bloom: bloom,
                size: size,
              );
            case CompanionKind.pet:
              return PetCompanion(
                growth: smoothed,
                accent: accent,
                life: life,
                bloom: bloom,
                size: size,
              );
            case CompanionKind.creature:
              return CreatureCompanion(
                growth: smoothed,
                accent: accent,
                life: life,
                bloom: bloom,
                size: size,
              );
          }
        }

        if (!enabled) return child(g);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: g, end: g),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => child(value),
        );
      },
      ),
    );
  }
}
