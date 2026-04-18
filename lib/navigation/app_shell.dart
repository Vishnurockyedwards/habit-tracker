import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/tweaks.dart';
import '../theme/tokens.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: SP.cream,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 14, left: 20, right: 20),
        child: _FloatingPillNav(
          currentIndex: navigationShell.currentIndex,
          onTap: (i) => navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}

class _FloatingPillNav extends ConsumerWidget {
  const _FloatingPillNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <_NavItem>[
    _NavItem('Today', Icons.local_florist_outlined, Icons.local_florist),
    _NavItem('Stats', Icons.bar_chart_outlined, Icons.bar_chart),
    _NavItem(
      'Calendar',
      Icons.calendar_today_outlined,
      Icons.calendar_today,
    ),
    _NavItem('You', Icons.person_outline, Icons.person),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentPaletteProvider);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SP.cocoa,
        borderRadius: BorderRadius.circular(100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x402D1F16),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < _items.length; i++)
              _PillTab(
                item: _items[i],
                active: i == currentIndex,
                accent: accent,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem(this.label, this.icon, this.activeIcon);
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.item,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final _NavItem item;
  final bool active;
  final AccentPalette accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: active,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: active ? 14 : 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: active ? accent.main : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? item.activeIcon : item.icon,
                size: 18,
                color: SP.onAccent,
              ),
              if (active) ...[
                const SizedBox(width: 6),
                Text(
                  item.label,
                  style: const TextStyle(
                    color: SP.onAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
