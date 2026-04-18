import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// Small-caps "N day streak" pill with flame. Accent-soft bg, accent-deep text.
class StreakChip extends StatelessWidget {
  const StreakChip({
    super.key,
    required this.streak,
    required this.accent,
  });

  final int streak;
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.soft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            '$streak day streak',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent.deep,
            ),
          ),
        ],
      ),
    );
  }
}
