import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Placeholder — full Calendar implementation lands in Phase 5.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: SP.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 48,
                  color: SP.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Calendar',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Coming soon — month view with per-day completion dots.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: SP.muted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
