import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tweaks.dart';
import '../theme/tokens.dart';
import '../widgets/companion/companion.dart';

/// Placeholder — Phase 5 will replace this with the full month-calendar
/// view. For now we surface a companion preview so the port progress
/// is visible and the new tokens can be exercised.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  double _growth = 0.6;
  bool _bloom = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tweaks = ref.watch(tweaksProvider);
    final accent = ref.watch(accentPaletteProvider);

    return Scaffold(
      backgroundColor: SP.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Calendar', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'Full month view coming in phase 5. Companion preview for now.',
                style: theme.textTheme.bodySmall?.copyWith(color: SP.muted),
              ),
              const SizedBox(height: AppSpacing.lg),

              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [SP.creamGradTop, SP.creamGradBottom],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: SP.hairline),
                  ),
                  child: Companion(
                    kind: tweaks.companion,
                    growth: _growth,
                    accent: accent,
                    bloom: _bloom,
                    size: 220,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              Text(
                'Companion · ${tweaks.companion.name} (${companionName(tweaks.companion)})',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(color: SP.cocoaSoft),
              ),

              const SizedBox(height: AppSpacing.lg),
              Text('Growth · ${(_growth * 100).round()}%',
                  style: theme.textTheme.labelSmall),
              Slider(
                value: _growth,
                onChanged: (v) => setState(() => _growth = v),
                activeColor: accent.main,
                inactiveColor: SP.creamDeep,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final k in CompanionKind.values)
                    FilledButton.tonal(
                      onPressed: () =>
                          ref.read(tweaksProvider.notifier).setCompanion(k),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            tweaks.companion == k ? accent.soft : SP.creamSoft,
                        foregroundColor: accent.deep,
                      ),
                      child: Text(companionName(k)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final a in AccentKind.values)
                    GestureDetector(
                      onTap: () =>
                          ref.read(tweaksProvider.notifier).setAccent(a),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accentPalettes[a]!.main,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tweaks.accent == a
                                ? SP.cocoa
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                value: _bloom,
                onChanged: (v) => setState(() => _bloom = v),
                title: const Text('Bloom'),
                subtitle: const Text('Sparkles + popped flower'),
                activeThumbColor: accent.main,
                tileColor: SP.creamSoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: SP.hairline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
