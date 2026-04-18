import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';
import 'prefs.dart';

const _kCompanionKey = 'tweak_companion';
const _kAccentKey = 'tweak_accent';
const _kDensityKey = 'tweak_density';
const _kHasOnboardedKey = 'has_onboarded';

class Tweaks {
  final CompanionKind companion;
  final AccentKind accent;
  final DensityKind density;
  const Tweaks({
    required this.companion,
    required this.accent,
    required this.density,
  });

  Tweaks copyWith({
    CompanionKind? companion,
    AccentKind? accent,
    DensityKind? density,
  }) => Tweaks(
    companion: companion ?? this.companion,
    accent: accent ?? this.accent,
    density: density ?? this.density,
  );

  static const defaults = Tweaks(
    companion: CompanionKind.plant,
    accent: AccentKind.terracotta,
    density: DensityKind.airy,
  );
}

class TweaksController extends Notifier<Tweaks> {
  @override
  Tweaks build() => Tweaks.defaults;

  Future<void> load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = Tweaks(
      companion: _decode(
        prefs.getString(_kCompanionKey),
        CompanionKind.values,
        Tweaks.defaults.companion,
      ),
      accent: _decode(
        prefs.getString(_kAccentKey),
        AccentKind.values,
        Tweaks.defaults.accent,
      ),
      density: _decode(
        prefs.getString(_kDensityKey),
        DensityKind.values,
        Tweaks.defaults.density,
      ),
    );
  }

  Future<void> setCompanion(CompanionKind value) async {
    state = state.copyWith(companion: value);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_kCompanionKey, value.name);
  }

  Future<void> setAccent(AccentKind value) async {
    state = state.copyWith(accent: value);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_kAccentKey, value.name);
  }

  Future<void> setDensity(DensityKind value) async {
    state = state.copyWith(density: value);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_kDensityKey, value.name);
  }

  static T _decode<T extends Enum>(String? raw, List<T> values, T fallback) {
    if (raw == null) return fallback;
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return fallback;
  }
}

final tweaksProvider = NotifierProvider<TweaksController, Tweaks>(
  TweaksController.new,
);

final accentPaletteProvider = Provider<AccentPalette>(
  (ref) => accentPalettes[ref.watch(tweaksProvider).accent]!,
);

final densityProvider = Provider<DensityTokens>(
  (ref) => densityTokens[ref.watch(tweaksProvider).density]!,
);

class OnboardingController extends Notifier<bool> {
  @override
  bool build() => true; // assume onboarded until load() tells us otherwise

  Future<void> load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getBool(_kHasOnboardedKey) ?? false;
  }

  Future<void> markDone() async {
    state = true;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_kHasOnboardedKey, true);
  }
}

final hasOnboardedProvider = NotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);
