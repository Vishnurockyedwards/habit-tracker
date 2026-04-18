import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/calendar_screen.dart';
import '../screens/create_habit_screen.dart';
import '../screens/habit_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/today_screen.dart';
import 'app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/today',
  routes: [
    GoRoute(
      path: '/create',
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const CreateHabitScreen(),
    ),
    GoRoute(
      path: '/edit/:id',
      parentNavigatorKey: _rootKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return CreateHabitScreen(editingId: id);
      },
    ),
    GoRoute(
      path: '/habit/:id',
      parentNavigatorKey: _rootKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return HabitDetailScreen(habitId: id);
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/today',
              builder: (context, state) => const TodayScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/stats',
              builder: (context, state) => const StatsScreen(),
              routes: [
                GoRoute(
                  path: 'habit/:id',
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id'] ?? '0');
                    return HabitDetailScreen(habitId: id);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calendar',
              builder: (context, state) => const CalendarScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
