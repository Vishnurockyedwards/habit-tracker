import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

/// Continuous "life" signals driving companion motion.
///
/// - [blink] — true for ~130ms every 2.5–6s (random)
/// - [swayT] — 0..1, reverse-repeating over ~2.2s (feeds stem tilt, ear/tail
///   wag, head turn; each companion maps this to its own angle range)
/// - [bobT]  — 0..1, forward-repeating over ~3s (feeds a sin-curve Y offset
///   for the sprout creature)
@immutable
class Life {
  final bool blink;
  final double swayT;
  final double bobT;
  const Life({
    required this.blink,
    required this.swayT,
    required this.bobT,
  });

  static const still = Life(blink: false, swayT: 0, bobT: 0);
}

/// Ticks a [Life] struct into [builder]. Set [enabled] = false to freeze the
/// companion (reduced-motion, low-power, testing).
class LifeTicker extends StatefulWidget {
  const LifeTicker({
    super.key,
    required this.builder,
    this.enabled = true,
  });

  final Widget Function(BuildContext context, Life life) builder;
  final bool enabled;

  @override
  State<LifeTicker> createState() => _LifeTickerState();
}

class _LifeTickerState extends State<LifeTicker>
    with TickerProviderStateMixin {
  late final AnimationController _sway;
  late final AnimationController _bob;
  final _rng = Random();
  Timer? _blinkTimer;
  bool _blink = false;

  @override
  void initState() {
    super.initState();
    _sway = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    if (widget.enabled) _start();
  }

  void _start() {
    _sway.repeat(reverse: true);
    _bob.repeat();
    _scheduleBlink();
  }

  void _stop() {
    _sway.stop();
    _sway.value = 0;
    _bob.stop();
    _bob.value = 0;
    _blinkTimer?.cancel();
    _blink = false;
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(
      Duration(milliseconds: 2500 + _rng.nextInt(3500)),
      () {
        if (!mounted || !widget.enabled) return;
        setState(() => _blink = true);
        _blinkTimer = Timer(const Duration(milliseconds: 130), () {
          if (!mounted) return;
          setState(() => _blink = false);
          if (widget.enabled) _scheduleBlink();
        });
      },
    );
  }

  @override
  void didUpdateWidget(LifeTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _start();
      } else {
        _stop();
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _sway.dispose();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.builder(context, Life.still);
    }
    return AnimatedBuilder(
      animation: Listenable.merge([_sway, _bob]),
      builder: (context, _) => widget.builder(
        context,
        Life(
          blink: _blink,
          // ease in/out on reverse-repeat to mimic CSS ease-in-out
          swayT: Curves.easeInOut.transform(_sway.value),
          bobT: _bob.value,
        ),
      ),
    );
  }
}
