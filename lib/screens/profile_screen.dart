import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prefs.dart';
import '../data/providers.dart';
import '../data/tweaks.dart';
import '../logic/xp.dart';
import '../notifications/notification_service.dart';
import '../theme/tokens.dart';
import '../widgets/sprout/level_up_overlay.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentPaletteProvider);
    return Scaffold(
      backgroundColor: SP.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          children: [
            _Header(accent: accent),
            const SizedBox(height: 20),
            _StatsStrip(),
            const SizedBox(height: 20),
            _TweaksCard(accent: accent),
            const SizedBox(height: 12),
            _AppearanceCard(accent: accent),
            const SizedBox(height: 12),
            const _AboutCard(),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              _DevDiagnosticsCard(accent: accent),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.accent});
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOU',
          style: TextStyle(
            fontSize: 11,
            color: SP.muted,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 26,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.4,
              color: SP.cocoa,
            ),
            children: [
              const TextSpan(text: 'Your '),
              TextSpan(
                text: 'garden',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: accent.deep,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streaks = ref.watch(allStreaksProvider).asData?.value ?? const [];
    final accent = ref.watch(accentPaletteProvider);
    final total = streaks.fold<int>(0, (s, st) => s + st.totalCompletions);
    final longest = streaks.isEmpty
        ? 0
        : streaks.map((s) => s.longestStreak).fold<int>(0, math.max);
    final totalXp = total * XpMath.perCompletion;
    final level = XpMath.levelFor(totalXp);

    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: 'Level',
            value: '$level',
            accent: accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStat(
            label: 'Total XP',
            value: '$totalXp',
            accent: accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStat(
            label: 'Best streak',
            value: '$longest',
            accent: accent,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final AccentPalette accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SP.creamSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SP.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              color: SP.muted,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: accent.deep,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TweaksCard extends ConsumerWidget {
  const _TweaksCard({required this.accent});
  final AccentPalette accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tweaks = ref.watch(tweaksProvider);
    return _Card(
      title: 'Customize',
      children: [
        const _SubLabel('Companion'),
        Row(
          children: [
            for (var i = 0; i < CompanionKind.values.length; i++) ...[
              Expanded(
                child: _ToggleChip(
                  label: companionName(CompanionKind.values[i]),
                  active: tweaks.companion == CompanionKind.values[i],
                  accent: accent,
                  onTap: () => ref
                      .read(tweaksProvider.notifier)
                      .setCompanion(CompanionKind.values[i]),
                ),
              ),
              if (i < CompanionKind.values.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 14),
        const _SubLabel('Accent color'),
        Row(
          children: [
            for (var i = 0; i < AccentKind.values.length; i++) ...[
              GestureDetector(
                onTap: () => ref
                    .read(tweaksProvider.notifier)
                    .setAccent(AccentKind.values[i]),
                child: Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: tweaks.accent == AccentKind.values[i]
                          ? SP.cocoa
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentPalettes[AccentKind.values[i]]!.main,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (i < AccentKind.values.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 14),
        const _SubLabel('Density'),
        Row(
          children: [
            for (var i = 0; i < DensityKind.values.length; i++) ...[
              Expanded(
                child: _ToggleChip(
                  label: DensityKind.values[i].name,
                  active: tweaks.density == DensityKind.values[i],
                  accent: accent,
                  onTap: () => ref
                      .read(tweaksProvider.notifier)
                      .setDensity(DensityKind.values[i]),
                ),
              ),
              if (i < DensityKind.values.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }
}

class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard({required this.accent});
  final AccentPalette accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return _Card(
      title: 'Appearance',
      subtitle: 'The palette is warm-cream by design; dark mode is future work.',
      children: [
        Row(
          children: [
            for (var i = 0; i < ThemeMode.values.length; i++) ...[
              Expanded(
                child: _ToggleChip(
                  label: _modeLabel(ThemeMode.values[i]),
                  active: mode == ThemeMode.values[i],
                  accent: accent,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .set(ThemeMode.values[i]),
                ),
              ),
              if (i < ThemeMode.values.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }

  String _modeLabel(ThemeMode m) => switch (m) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return const _Card(
      title: 'About',
      children: [
        Text(
          'Sprout — offline-first habit tracker with a companion that '
          'grows alongside you.',
          style: TextStyle(fontSize: 13, color: SP.cocoaSoft, height: 1.5),
        ),
      ],
    );
  }
}

class _DevDiagnosticsCard extends ConsumerWidget {
  const _DevDiagnosticsCard({required this.accent});
  final AccentPalette accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tweaks = ref.watch(tweaksProvider);
    return _Card(
      title: 'Debug tools',
      subtitle: 'Only shown in debug builds.',
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.notifications_active, size: 16),
          label: const Text('Send test notification'),
          onPressed: () async {
            await NotificationService.instance.requestPermissions();
            await NotificationService.instance.showTestNotification();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test fired — check your shade'),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.list_alt, size: 16),
          label: const Text('Show pending reminders'),
          onPressed: () async {
            final pending = await NotificationService.instance.pending();
            if (!context.mounted) return;
            showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text('Pending (${pending.length})'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: pending.isEmpty
                      ? const Text('Nothing scheduled.')
                      : ListView(
                          shrinkWrap: true,
                          children: [
                            for (final p in pending)
                              ListTile(
                                dense: true,
                                title: Text(p.title ?? '—'),
                                subtitle: Text(
                                  'id ${p.id} · ${p.body ?? ''}',
                                ),
                              ),
                          ],
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.celebration_outlined, size: 16),
          label: const Text('Trigger level-up overlay'),
          onPressed: () => showLevelUp(
            context,
            level: 8,
            companion: tweaks.companion,
            accent: accent,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.restart_alt, size: 16),
          label: const Text('Reset onboarding'),
          onPressed: () async {
            await ref.read(hasOnboardedProvider.notifier).reset();
          },
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.children,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SP.creamSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SP.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: SP.cocoa,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 11, color: SP.muted),
            ),
          ],
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  const _SubLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          color: SP.muted,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool active;
  final AccentPalette accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? accent.soft : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active ? accent.main : SP.hairline,
            width: 1.5,
          ),
        ),
        child: Text(
          '${label[0].toUpperCase()}${label.substring(1)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? accent.deep : SP.cocoaSoft,
          ),
        ),
      ),
    );
  }
}
