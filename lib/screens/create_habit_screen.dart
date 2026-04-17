import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';

class CreateHabitScreen extends ConsumerWidget {
  const CreateHabitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Habit')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Habit creation form will go here.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
