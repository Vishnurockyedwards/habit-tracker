import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/prefs.dart';
import 'data/providers.dart';
import 'data/tweaks.dart';
import 'navigation/app_router.dart';
import 'notifications/notification_service.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  final prefs = await SharedPreferences.getInstance();
  final onboarded = prefs.getBool('has_onboarded') ?? false;

  runApp(
    ProviderScope(
      overrides: [
        initialOnboardedProvider.overrideWithValue(onboarded),
      ],
      child: const HabitTrackerApp(),
    ),
  );
}

class HabitTrackerApp extends ConsumerStatefulWidget {
  const HabitTrackerApp({super.key});

  @override
  ConsumerState<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends ConsumerState<HabitTrackerApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeModeProvider.notifier).load();
      ref.read(tweaksProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(databaseSeedProvider);
    final themeMode = ref.watch(themeModeProvider);
    final onboarded = ref.watch(hasOnboardedProvider);

    if (!onboarded) {
      return MaterialApp(
        title: 'Habit Tracker',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        color: SP.cream,
        home: const OnboardingScreen(),
      );
    }

    return MaterialApp.router(
      title: 'Habit Tracker',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
