import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/pill_schedule.dart';

final class MedicationNotificationService {
  MedicationNotificationService._();

  static final instance = MedicationNotificationService._();

  static const _channelId = 'medication_reminders';
  static const _payloadPrefix = 'medication:';
  static const _horizonDays = 30;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<String> _openedController =
      StreamController<String>.broadcast();
  bool _initialized = false;
  bool _permissionRequested = false;
  bool _pendingOpen = false;
  String? _lastFingerprint;

  Stream<String> get reminderOpened => _openedController.stream;

  bool consumePendingOpen() {
    final value = _pendingOpen;
    _pendingOpen = false;
    return value;
  }

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    }

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_medication_notification'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload?.startsWith(_payloadPrefix) != true) return;
        _pendingOpen = true;
        _openedController.add(payload!);
      },
    );
    final launchDetails = await _notifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchDetails?.notificationResponse?.payload
                ?.startsWith(_payloadPrefix) ==
            true) {
      _pendingOpen = true;
    }
    _initialized = true;
  }

  Future<void> _requestPermission() async {
    if (_permissionRequested) return;
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _permissionRequested = true;
  }

  Future<void> syncSchedules(
    String elderId,
    List<PillSchedule> schedules,
  ) async {
    if (kIsWeb) return;
    await initialize();
    await _requestPermission();
    final fingerprint = _fingerprint(elderId, schedules);
    if (_lastFingerprint == fingerprint) return;

    final pending = await _notifications.pendingNotificationRequests();
    for (final notification in pending) {
      if (notification.payload?.startsWith(_payloadPrefix) == true) {
        await _notifications.cancel(id: notification.id);
      }
    }

    final now = tz.TZDateTime.now(tz.local);
    final today = tz.TZDateTime(tz.local, now.year, now.month, now.day);
    final horizon = today.add(const Duration(days: _horizonDays));
    for (final schedule in schedules.where((item) => item.isActive)) {
      for (
        var day = today;
        day.isBefore(horizon);
        day = day.add(const Duration(days: 1))
      ) {
        if (!_isScheduleActiveOn(schedule, day)) continue;
        for (final minuteOfDay in schedule.timesInMinutes) {
          final scheduledDate = tz.TZDateTime(
            tz.local,
            day.year,
            day.month,
            day.day,
            minuteOfDay ~/ 60,
            minuteOfDay % 60,
          );
          if (!scheduledDate.isAfter(now)) continue;
          await _notifications.zonedSchedule(
            id: _notificationId(schedule.id, scheduledDate, minuteOfDay),
            title: 'Đã đến giờ uống thuốc',
            body:
                '${schedule.dosage} ${schedule.medicationName}. ${schedule.instruction}',
            scheduledDate: scheduledDate,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                _channelId,
                'Nhắc uống thuốc',
                channelDescription: 'Thông báo khi đến giờ uống thuốc',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                category: AndroidNotificationCategory.reminder,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: '$_payloadPrefix${schedule.id}',
          );
        }
      }
    }
    _lastFingerprint = fingerprint;
  }

  bool _isScheduleActiveOn(PillSchedule schedule, DateTime day) {
    final start = DateTime(
      schedule.startDate.year,
      schedule.startDate.month,
      schedule.startDate.day,
    );
    final value = DateTime(day.year, day.month, day.day);
    if (value.isBefore(start)) return false;
    final endDate = schedule.endDate;
    if (endDate == null) return true;
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !value.isAfter(end);
  }

  String _fingerprint(String elderId, List<PillSchedule> schedules) {
    final items = schedules.toList()..sort((a, b) => a.id.compareTo(b.id));
    return '$elderId|${items.map((item) => '${item.id}:${item.medicationName}:${item.dosage}:${item.instruction}:${item.timesInMinutes.join(',')}:${item.startDate.millisecondsSinceEpoch}:${item.endDate?.millisecondsSinceEpoch}:${item.isActive}').join('|')}';
  }

  int _notificationId(String scheduleId, DateTime day, int minuteOfDay) {
    var hash = 0x811c9dc5;
    final value = '$scheduleId:${day.year}-${day.month}-${day.day}:$minuteOfDay';
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
