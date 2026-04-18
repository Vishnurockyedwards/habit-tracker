import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifications/notification_service.dart';
import '../theme/tokens.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Use this to confirm your reminders will actually reach you.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('Send test notification'),
                    onPressed: () async {
                      await NotificationService.instance.requestPermissions();
                      await NotificationService.instance
                          .showTestNotification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Test fired — check your notification shade',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Show pending reminders'),
                    onPressed: () async {
                      final pending =
                          await NotificationService.instance.pending();
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
