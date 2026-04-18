import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../companion/companion.dart';

/// Level-up celebration — radial gradient, rotating conic rays, 14 confetti
/// particles radiating outward, popped companion at growth=1/bloom=true.
///
/// Shown via [showLevelUp]. Tap the CTA (or the 8s auto-dismiss timer) to
/// return. Reduced-motion disables the ray spin, confetti burst, and
/// companion pop.
Future<void> showLevelUp(
  BuildContext context, {
  required int level,
  required CompanionKind companion,
  required AccentPalette accent,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (ctx, a1, a2) => LevelUpOverlay(
      level: level,
      companion: companion,
      accent: accent,
    ),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
      opacity: anim,
      child: child,
    ),
  );
}

class LevelUpOverlay extends StatefulWidget {
  const LevelUpOverlay({
    super.key,
    required this.level,
    required this.companion,
    required this.accent,
  });

  final int level;
  final CompanionKind companion;
  final AccentPalette accent;

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _rays;
  late final AnimationController _pop;
  late final AnimationController _confetti;

  static const _confettiTotal = Duration(milliseconds: 2300);
  static const _confettiParticleMs = 1600;
  static const _confettiStaggerMs = 50;
  static const _confettiCount = 14;

  @override
  void initState() {
    super.initState();
    _rays = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _confetti = AnimationController(vsync: this, duration: _confettiTotal);
    // Start animations after first frame so reduced-motion check has MediaQuery.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduced = MediaQuery.of(context).disableAnimations;
      if (reduced) {
        _pop.value = 1;
        return;
      }
      _rays.repeat();
      _pop.forward();
      _confetti.forward();
    });
  }

  @override
  void dispose() {
    _rays.dispose();
    _pop.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 1.1,
            colors: [accent.soft, SP.cream],
          ),
        ),
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              _Rays(controller: _rays, accent: accent),
              _Confetti(controller: _confetti, accent: accent),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _pop,
                    builder: (context, child) {
                      final t = _pop.value;
                      final scale = _popCurve.transform(t);
                      return Opacity(
                        opacity: (t * 2.5).clamp(0.0, 1.0),
                        child: Transform.scale(scale: scale, child: child),
                      );
                    },
                    child: Companion(
                      kind: widget.companion,
                      growth: 1,
                      accent: accent,
                      bloom: true,
                      size: 200,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FadeIn(
                    delay: const Duration(milliseconds: 200),
                    child: _TitleBlock(level: widget.level, accent: accent),
                  ),
                  const SizedBox(height: 26),
                  _FadeIn(
                    delay: const Duration(milliseconds: 400),
                    child: _Cta(
                      accent: accent,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _popCurve = _PopCurve();

class _PopCurve extends Curve {
  @override
  double transform(double t) {
    // Keyframes: 0→0.4 scales 0.4→1.1, 0.4→1 scales 1.1→1.
    if (t < 0.6) {
      return 0.4 + ((1.1 - 0.4) * (t / 0.6));
    }
    return 1.1 + ((1.0 - 1.1) * ((t - 0.6) / 0.4));
  }
}

class _Rays extends StatelessWidget {
  const _Rays({required this.controller, required this.accent});
  final AnimationController controller;
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Transform.rotate(
            angle: controller.value * 2 * math.pi,
            child: Opacity(
              opacity: 0.5,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.transparent,
                      accent.soft,
                      Colors.transparent,
                      Colors.transparent,
                      accent.soft,
                      Colors.transparent,
                      Colors.transparent,
                      accent.soft,
                      Colors.transparent,
                      Colors.transparent,
                      accent.soft,
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const [
                      0.0,
                      20 / 360,
                      30 / 360,
                      90 / 360,
                      110 / 360,
                      120 / 360,
                      180 / 360,
                      200 / 360,
                      210 / 360,
                      270 / 360,
                      290 / 360,
                      300 / 360,
                      1.0,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Confetti extends StatelessWidget {
  const _Confetti({required this.controller, required this.accent});
  final AnimationController controller;
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    final colors = [accent.main, accent.deep, accent.glow, SP.gold];
    const particleMs = _LevelUpOverlayState._confettiParticleMs;
    const staggerMs = _LevelUpOverlayState._confettiStaggerMs;
    const totalMs = 2300.0;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final absMs = controller.value * totalMs;
          return Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < _LevelUpOverlayState._confettiCount; i++)
                _Particle(
                  absMs: absMs,
                  startMs: i * staggerMs.toDouble(),
                  durationMs: particleMs.toDouble(),
                  angleRad: (i / _LevelUpOverlayState._confettiCount) *
                      2 *
                      math.pi,
                  color: colors[i % colors.length],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Particle extends StatelessWidget {
  const _Particle({
    required this.absMs,
    required this.startMs,
    required this.durationMs,
    required this.angleRad,
    required this.color,
  });

  final double absMs;
  final double startMs;
  final double durationMs;
  final double angleRad;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final localT = ((absMs - startMs) / durationMs).clamp(0.0, 1.0);
    if (localT == 0 || localT == 1) return const SizedBox.shrink();

    final opacity = localT < 0.2 ? localT / 0.2 : 1.0 - (localT - 0.2) / 0.8;
    final translateY = localT * 200.0;
    final scale = 0.6 + 0.4 * localT;

    final m = Matrix4.rotationZ(angleRad)
      ..translateByDouble(0.0, translateY, 0.0, 1.0);

    return Transform(
      alignment: Alignment.center,
      transform: m,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            width: 8,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.delay, required this.child});
  final Duration delay;
  final Widget child;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(widget.delay);
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _c, child: widget.child);
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.level, required this.accent});
  final int level;
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'LEVEL UP',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: accent.deep,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 44,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.8,
              color: SP.cocoa,
              height: 1,
            ),
            children: [
              const TextSpan(text: 'Level '),
              TextSpan(
                text: '$level',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: accent.deep,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: SP.cocoaSoft,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: "Your garden just got a little "),
                TextSpan(
                  text: 'brighter',
                  style: TextStyle(
                    color: accent.deep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: '. Keep showing up.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _Cta extends StatelessWidget {
  const _Cta({required this.accent, required this.onPressed});

  final AccentPalette accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: accent.deep, offset: const Offset(0, 4)),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent.main,
          foregroundColor: SP.onAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        child: const Text('Keep growing →'),
      ),
    );
  }
}
