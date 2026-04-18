import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../companion/companion.dart';

/// Gradient card with companion on the left, state copy + progress on the
/// right. Fires a 1.6s ✨ flash when [growth] crosses 0→1.
class CompanionCard extends StatefulWidget {
  const CompanionCard({
    super.key,
    required this.companion,
    required this.accent,
    required this.growth,
    required this.done,
    required this.total,
    required this.xpToday,
    this.companionSize = 140,
  });

  final CompanionKind companion;
  final AccentPalette accent;
  final double growth;
  final int done;
  final int total;
  final int xpToday;
  final double companionSize;

  @override
  State<CompanionCard> createState() => _CompanionCardState();
}

class _CompanionCardState extends State<CompanionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash;
  double? _prevGrowth;

  @override
  void initState() {
    super.initState();
    _flash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didUpdateWidget(CompanionCard old) {
    super.didUpdateWidget(old);
    final prev = _prevGrowth ?? widget.growth;
    if (prev < 1.0 && widget.growth >= 1.0) {
      if (!MediaQuery.of(context).disableAnimations) {
        _flash.forward(from: 0);
      }
    }
    _prevGrowth = widget.growth;
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  String _headline(double g) {
    final name = companionName(widget.companion);
    if (g < 0.34) return '$name is waking up.';
    if (g < 0.67) return '$name is stretching.';
    if (g < 1.0) return 'Almost in full bloom!';
    return '$name is radiant. 🌼';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = widget.accent;
    final g = widget.growth.clamp(0.0, 1.0);
    final bloom = g >= 1.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SP.creamGradTop, SP.creamGradBottom],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Companion(
                kind: widget.companion,
                growth: g,
                accent: a,
                bloom: bloom,
                size: widget.companionSize,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _headline(g),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: 'Fraunces',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                        color: SP.cocoa,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.done} of ${widget.total} habits · +${widget.xpToday} xp today',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: SP.cocoaSoft,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 6,
                        child: Stack(
                          children: [
                            const ColoredBox(color: Color(0x142D1F16)),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: g, end: g),
                              duration: const Duration(milliseconds: 600),
                              curve: const Cubic(0.2, 0.8, 0.2, 1),
                              builder: (context, value, _) => FractionallySizedBox(
                                widthFactor: value,
                                child: ColoredBox(color: a.main),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _flash,
                builder: (context, _) {
                  if (_flash.value == 0 || _flash.value == 1) {
                    return const SizedBox.shrink();
                  }
                  final t = _flash.value;
                  final scale = t < 0.4
                      ? _lerp(0.3, 1.4, t / 0.4)
                      : _lerp(1.4, 2.0, (t - 0.4) / 0.6);
                  final opacity = t < 0.4
                      ? _lerp(0.0, 1.0, t / 0.4)
                      : _lerp(1.0, 0.0, (t - 0.4) / 0.6);
                  return Center(
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: scale,
                        child: const Text(
                          '✨',
                          style: TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
