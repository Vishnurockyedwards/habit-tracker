import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/habit_templates.dart';
import '../data/providers.dart';
import '../data/tweaks.dart';
import '../notifications/notification_service.dart';
import '../theme/tokens.dart';
import '../widgets/companion/companion.dart';

/// Subset of the starter templates the onboarding offers — "small and
/// honest" per the design spec.
const _starterIndexes = <int>[0, 1, 3]; // Water · Meditate · Read

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  bool _saving = false;
  late Set<int> _pickedStarters;

  @override
  void initState() {
    super.initState();
    _pickedStarters = Set.of(_starterIndexes);
  }

  @override
  Widget build(BuildContext context) {
    final tweaks = ref.watch(tweaksProvider);
    final accent = ref.watch(accentPaletteProvider);

    final steps = _buildSteps(accent);
    final s = steps[_step];

    return Scaffold(
      backgroundColor: SP.cream,
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accent.soft, SP.cream],
              stops: const [0, 0.6],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProgressDots(
                  count: steps.length,
                  current: _step,
                  accent: accent,
                ),
                Expanded(
                  child: Center(
                    child: Transform.scale(
                      scale: 1.2,
                      child: Companion(
                        kind: tweaks.companion,
                        growth: 0.6 + _step * 0.1,
                        accent: accent,
                        bloom: _step == steps.length - 1,
                        size: 180,
                      ),
                    ),
                  ),
                ),
                _TitleBody(title: s.title, body: s.body, accent: accent),
                const SizedBox(height: 20),
                _stepControls(tweaks, accent),
                _PrimaryCta(
                  label: s.cta,
                  accent: accent,
                  busy: _saving,
                  onPressed: _saving
                      ? null
                      : () => _step < steps.length - 1
                          ? setState(() => _step++)
                          : _finish(),
                ),
                if (_step > 0 && _step < steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextButton(
                      onPressed: () => setState(() => _step--),
                      style: TextButton.styleFrom(
                        foregroundColor: SP.muted,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_Step> _buildSteps(AccentPalette accent) => [
        _Step(
          title: _titleSpan('Welcome to ', 'Sprout', '.', accent),
          body:
              'A tiny companion grows alongside your daily habits. The more you show up, the more they bloom.',
          cta: 'Meet your companion',
        ),
        _Step(
          title: _titleSpan('Pick a ', 'companion', '.', accent),
          body:
              'You can change this anytime. Each has their own personality.',
          cta: 'Continue',
        ),
        _Step(
          title: _titleSpan('Your mood ', 'color', '.', accent),
          body:
              'Pick the accent that feels right. It colors your blooms, rings, and ribbons.',
          cta: 'Continue',
        ),
        _Step(
          title: _titleSpan('One small ', 'promise', ' a day.', accent),
          body:
              "Start with one or two. We'll add more once showing up becomes natural.",
          cta: 'Start growing',
        ),
      ];

  TextSpan _titleSpan(
    String pre,
    String accentWord,
    String post,
    AccentPalette accent,
  ) {
    return TextSpan(
      style: const TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 30,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.6,
        height: 1.1,
        color: SP.cocoa,
      ),
      children: [
        TextSpan(text: pre),
        TextSpan(
          text: accentWord,
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: accent.deep,
          ),
        ),
        TextSpan(text: post),
      ],
    );
  }

  Widget _stepControls(Tweaks tweaks, AccentPalette accent) {
    switch (_step) {
      case 1:
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              for (var i = 0; i < CompanionKind.values.length; i++) ...[
                Expanded(
                  child: _CompanionPicker(
                    kind: CompanionKind.values[i],
                    active:
                        tweaks.companion == CompanionKind.values[i],
                    accent: accent,
                    onTap: () => ref
                        .read(tweaksProvider.notifier)
                        .setCompanion(CompanionKind.values[i]),
                  ),
                ),
                if (i < CompanionKind.values.length - 1)
                  const SizedBox(width: 8),
              ],
            ],
          ),
        );
      case 2:
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < AccentKind.values.length; i++) ...[
                _AccentSwatch(
                  kind: AccentKind.values[i],
                  active: tweaks.accent == AccentKind.values[i],
                  onTap: () => ref
                      .read(tweaksProvider.notifier)
                      .setAccent(AccentKind.values[i]),
                ),
                if (i < AccentKind.values.length - 1)
                  const SizedBox(width: 10),
              ],
            ],
          ),
        );
      case 3:
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              for (final i in _starterIndexes) ...[
                _StarterRow(
                  template: kHabitTemplates[i],
                  picked: _pickedStarters.contains(i),
                  accent: accent,
                  onToggle: () => setState(() {
                    if (_pickedStarters.contains(i)) {
                      _pickedStarters.remove(i);
                    } else {
                      _pickedStarters.add(i);
                    }
                  }),
                ),
                if (i != _starterIndexes.last) const SizedBox(height: 6),
              ],
            ],
          ),
        );
      default:
        return const SizedBox(height: 20);
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);

    if (_pickedStarters.isNotEmpty) {
      final db = ref.read(databaseProvider);
      final templates = [
        for (final i in _pickedStarters) kHabitTemplates[i],
      ];
      await applyTemplates(db, templates);
      final habits = await db.watchActiveHabits().first;
      await NotificationService.instance.rescheduleAll(habits);
    }

    await ref.read(hasOnboardedProvider.notifier).markDone();
    // HabitTrackerApp watches hasOnboardedProvider and will swap to the
    // router automatically; no navigation needed.
  }
}

class _Step {
  final TextSpan title;
  final String body;
  final String cta;
  _Step({required this.title, required this.body, required this.cta});
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({
    required this.count,
    required this.current,
    required this.accent,
  });

  final int count;
  final int current;
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= current ? accent.main : const Color(0x1A2D1F16),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i < count - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _TitleBody extends StatelessWidget {
  const _TitleBody({
    required this.title,
    required this.body,
    required this.accent,
  });

  final TextSpan title;
  final String body;
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(title),
        const SizedBox(height: 10),
        Text(
          body,
          style: const TextStyle(
            fontSize: 14,
            color: SP.cocoaSoft,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _CompanionPicker extends StatelessWidget {
  const _CompanionPicker({
    required this.kind,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final CompanionKind kind;
  final bool active;
  final AccentPalette accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const subs = {
      CompanionKind.plant: 'quiet',
      CompanionKind.pet: 'playful',
      CompanionKind.creature: 'curious',
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: active ? accent.soft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? accent.main : SP.hairline,
            width: active ? 2 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              companionName(kind),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: SP.cocoa,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subs[kind]!,
              style: const TextStyle(
                fontSize: 10,
                color: SP.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.kind,
    required this.active,
    required this.onTap,
  });

  final AccentKind kind;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = accentPalettes[kind]!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? SP.cocoa : Colors.transparent,
            width: 3,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: palette.main,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _StarterRow extends StatelessWidget {
  const _StarterRow({
    required this.template,
    required this.picked,
    required this.accent,
    required this.onToggle,
  });

  final HabitTemplate template;
  final bool picked;
  final AccentPalette accent;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SP.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: SP.cream,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                _emojiForTemplate(template.icon),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                template.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SP.cocoa,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: picked ? accent.main : Colors.white,
                border: Border.all(
                  color: picked ? accent.main : SP.mutedSoft,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: picked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _emojiForTemplate(String icon) {
    const map = {
      'water_drop': '💧',
      'self_improvement': '🧘',
      'menu_book': '📖',
      'directions_run': '🏃',
      'fitness_center': '🏋️',
      'bedtime': '😴',
      'restaurant': '🥗',
      'code': '💻',
      'brush': '🎨',
    };
    return map[icon] ?? '🌱';
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.accent,
    required this.onPressed,
    required this.busy,
  });

  final String label;
  final AccentPalette accent;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed == null
            ? null
            : [BoxShadow(color: accent.deep, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent.main,
          foregroundColor: SP.onAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        child: busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: SP.onAccent,
                ),
              )
            : Text(label),
      ),
    );
  }
}
