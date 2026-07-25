import 'dart:io';

import 'dart:math';

import 'package:cunehat/core/enums/notification_frequency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

abstract class NotificationService {
  Future<void> initialize();
  Future<void> requestPermissions();
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  });
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  });
  Future<void> scheduleRandomDailyReminders(NotificationFrequency frequency);
  Future<void> cancelNotification(int id);
  Future<void> cancelAllNotifications();
}

@LazySingleton(as: NotificationService)
class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  NotificationServiceImpl(this._flutterLocalNotificationsPlugin);

  @override
  Future<void> initialize() async {
    tz.initializeTimeZones();
    // Default local timezone can be set if needed, usually UTC is fine if we use TZDateTime.from

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('Notification Clicked: ${response.payload}');
    // Handle notification tapped logic here if needed
  }

  @override
  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    }
  }

  NotificationDetails _getNotificationDetails() {
    const androidNotificationDetails = AndroidNotificationDetails(
      'cunehat_channel_id',
      'CuNehat Notifications',
      channelDescription: 'Notifications for CuNehat app',
      importance: Importance.max,
      priority: Priority.high,
    );
    const darwinNotificationDetails = DarwinNotificationDetails();

    return const NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        _getNotificationDetails(),
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      if (scheduledDate.isBefore(DateTime.now())) {
        debugPrint('Scheduled date is in the past, skipping notification: $id');
        return;
      }

      final androidImpl = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      AndroidScheduleMode scheduleMode;
      if (Platform.isAndroid && androidImpl != null) {
        final canScheduleExact =
            await androidImpl.canScheduleExactNotifications() ?? false;
        scheduleMode = canScheduleExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle;
      } else {
        scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        _getNotificationDetails(),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint(
          'Scheduled notification $id at $scheduledDate (mode: $scheduleMode)');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('Canceled notification $id');
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  @override
  Future<void> scheduleRandomDailyReminders(NotificationFrequency frequency) async {
    const int startId = 10000;
    const int daysToSchedule = 7;
    const int maxNotifications = 60; // Safe limit under iOS 64

    // 1. Cancel all previously scheduled random notifications
    for (int i = 0; i < maxNotifications; i++) {
      await cancelNotification(startId + i);
    }

    if (frequency == NotificationFrequency.none) {
      debugPrint('Random reminders disabled.');
      return;
    }

    // 2. Schedule new ones
    final int countPerDay = frequency.dailyCount;
    final random = Random();
    int currentId = startId;
    
    final messages = [
      'Bugün hiç harcama girdin mi? Bütçeni güncel tut!',
      'Finansal durumunu kontrol etme vakti!',
      'Gelir ve giderlerini takip etmek bütçeni korur.',
      'Küçük birikimler büyük hedeflere ulaştırır!',
      'Harcamalarını gözden geçirmeyi unutma.',
      'Bütçeni planla, rahat yaşa!'
    ];

    final now = DateTime.now();

    for (int day = 0; day < daysToSchedule; day++) {
      final scheduleDate = now.add(Duration(days: day));
      
      for (int c = 0; c < countPerDay; c++) {
        if (currentId - startId >= maxNotifications) break;

        // Random hour between 10 AM and 8 PM (20)
        final hour = 10 + random.nextInt(10);
        final minute = random.nextInt(60);

        var timeToSchedule = DateTime(
          scheduleDate.year,
          scheduleDate.month,
          scheduleDate.day,
          hour,
          minute,
        );

        if (timeToSchedule.isBefore(now)) {
           timeToSchedule = timeToSchedule.add(const Duration(days: 1));
        }

        final msgIndex = random.nextInt(messages.length);

        await scheduleNotification(
          id: currentId,
          title: 'CuNehat',
          body: messages[msgIndex],
          scheduledDate: timeToSchedule,
        );

        currentId++;
      }
    }
    debugPrint('Scheduled ${currentId - startId} random reminders.');
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('Canceled all notifications');
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }
}
