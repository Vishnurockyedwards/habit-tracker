import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/database.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'habit_reminders';
  static const String _channelName = 'Habit reminders';
  static const String _channelDescription =
      'Daily and scheduled reminders for your habits';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('Notification tz init fallback: $e');
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(settings);

    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.defaultImportance,
      ),
    );

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final androidGranted =
        await android?.requestNotificationsPermission() ?? true;
    // Exact alarms on Android 14+ require a separate user grant. If it isn't
    // granted the scheduler will silently fall back to inexact. We request it
    // so reminders fire on time; denial is acceptable.
    await android?.requestExactAlarmsPermission();
    final iosGranted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;
    return androidGranted && iosGranted;
  }

  Future<void> showTestNotification() async {
    await _plugin.show(
      999999,
      'Test notification',
      'If you see this, the pipeline works.',
      _details(),
    );
  }

  Future<void> scheduleForHabit(Habit habit) async {
    await cancelForHabit(habit.id);
    final minutes = habit.reminderMinutes;
    if (minutes == null || habit.archivedAt != null) return;

    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final details = _details();
    final body = 'Time for "${habit.name}"';

    switch (habit.frequencyType) {
      case 'custom':
        final days = _customDays(habit.frequencyCfg);
        for (final uiDay in days) {
          // UI day 0..6 (Mon..Sun); DateTime.weekday is 1..7 (Mon..Sun)
          final dartWeekday = uiDay + 1;
          final when =
              _nextInstanceOfWeekday(hour, minute, dartWeekday);
          await _plugin.zonedSchedule(
            _customNotificationId(habit.id, uiDay),
            'Habit reminder',
            body,
            when,
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
        break;
      case 'daily':
      case 'x_per_week':
      default:
        final when = _nextInstanceOfTime(hour, minute);
        await _plugin.zonedSchedule(
          _dailyNotificationId(habit.id),
          'Habit reminder',
          body,
          when,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
    }
  }

  Future<void> cancelForHabit(int habitId) async {
    await _plugin.cancel(_dailyNotificationId(habitId));
    for (var d = 0; d < 7; d++) {
      await _plugin.cancel(_customNotificationId(habitId, d));
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> rescheduleAll(List<Habit> habits) async {
    await cancelAll();
    for (final h in habits) {
      await scheduleForHabit(h);
    }
  }

  Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();

  NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );

  List<int> _customDays(String? cfg) {
    if (cfg == null || cfg.isEmpty) return const [];
    final decoded = jsonDecode(cfg) as Map<String, dynamic>;
    final list = (decoded['days'] as List?) ?? const [];
    return list.map((e) => (e as num).toInt()).toList();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int hour, int minute, int weekday) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // Stable id scheme: habit_id * 10 + slot. Daily uses slot 0, custom days 1..7.
  int _dailyNotificationId(int habitId) => habitId * 10;
  int _customNotificationId(int habitId, int uiDay) => habitId * 10 + 1 + uiDay;
}
