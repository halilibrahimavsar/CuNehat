import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:cunehat/core/enums/notification_frequency.dart';
import 'package:cunehat/core/notifications/notification_constants.dart';
import 'package:cunehat/core/notifications/notification_localizer.dart';

abstract class NotificationService {
  Future<void> initialize();

  /// Kullanıcının dokunduğu bildirimin yükünü (payload) yayınlar.
  ///
  /// Hem sıcak açılışta (uygulama arkaplandayken dokunma) hem de soğuk
  /// açılışta (uygulama kapalıyken dokunma) çalışır. Soğuk açılışta yük,
  /// [initialize] sırasında okunur ve ilk dinleyici bağlanana kadar
  /// tamponlanır — widget ağacı henüz kurulmamış olduğu için aksi halde
  /// kaybolurdu.
  Stream<String> get onNotificationTap;

  /// Sistem bildirim iznini ister. Verildiyse `true`.
  Future<bool> requestPermissions();

  /// Sistem düzeyinde bildirimlerin açık olup olmadığı. Kullanıcı izni
  /// reddettiyse uygulama içi anahtarlar açık görünse de bildirim gitmez.
  Future<bool> areNotificationsEnabled();

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationChannelKind channel = NotificationChannelKind.critical,
  });

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationChannelKind channel = NotificationChannelKind.critical,
  });

  Future<void> scheduleRandomDailyReminders(NotificationFrequency frequency);

  Future<void> cancelNotification(int id);

  Future<void> cancelAllNotifications();

  /// GetIt kapatılırken çağrılır; dokunma akışını serbest bırakır.
  void dispose();
}

@LazySingleton(as: NotificationService)
class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final NotificationLocalizer _localizer;

  /// Motivasyon hatırlatıcılarının kaç gün ileriye planlanacağı.
  ///
  /// Yeniden planlama yalnızca uygulama açıldığında olur; pencere kısa
  /// olursa uygulamayı bir süre açmayan kullanıcı — yani hatırlatmaya en çok
  /// ihtiyaç duyan kullanıcı — hiç bildirim almaz. 14 gün × en yüksek frekans
  /// (3/gün) = 42 bildirim, [ReminderIds.randomReminderCapacity] sınırının
  /// altında kalır.
  static const int _randomReminderDays = 14;

  /// Motivasyon hatırlatıcılarının atılabileceği saat aralığı (yerel).
  static const int _randomWindowStartHour = 10;
  static const int _randomWindowEndHour = 20;

  final StreamController<String> _tapController;
  final List<String> _bufferedTaps = <String>[];

  /// Motivasyon hatırlatıcıları "önce hepsini iptal et, sonra yeniden kur"
  /// şeklinde çalışır. İki çalıştırma iç içe girerse birinin iptali
  /// diğerinin planladıklarını siler; çağrıları sıraya alıyoruz.
  Future<void> _randomRescheduleQueue = Future<void>.value();

  NotificationServiceImpl(
      this._flutterLocalNotificationsPlugin, this._localizer)
      : _tapController = StreamController<String>.broadcast() {
    _tapController.onListen = _flushBufferedTaps;
  }

  @override
  Stream<String> get onNotificationTap => _tapController.stream;

  @override
  Future<void> initialize() async {
    tz.initializeTimeZones();
    // tz.local UTC kalır; tek seferlik planlamada TZDateTime.from anı
    // (instant) koruduğu için bu sorun değil. Yinelemeli planlamaya
    // (matchDateTimeComponents) geçilirse setLocalLocation şart olur.

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

    // Soğuk açılış: uygulama kapalıyken bildirime dokunulduysa
    // onDidReceiveNotificationResponse güvenilir biçimde tetiklenmez;
    // yükü başlangıç ayrıntılarından okumak gerekir.
    await _emitLaunchPayload();
  }

  Future<void> _emitLaunchPayload() async {
    try {
      final details = await _flutterLocalNotificationsPlugin
          .getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        _emitTap(details?.notificationResponse?.payload);
      }
    } catch (e) {
      debugPrint('Error reading notification launch details: $e');
    }
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    _emitTap(response.payload);
  }

  void _emitTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    debugPrint('Notification tapped: $payload');
    if (_tapController.hasListener) {
      _tapController.add(payload);
    } else {
      _bufferedTaps.add(payload);
    }
  }

  void _flushBufferedTaps() {
    if (_bufferedTaps.isEmpty) return;
    final pending = List<String>.of(_bufferedTaps);
    _bufferedTaps.clear();
    // onListen sırasında add etmek dinleyiciye ulaşmaz; bir sonraki
    // mikrogöreve ertele.
    scheduleMicrotask(() {
      for (final payload in pending) {
        if (_tapController.isClosed) return;
        _tapController.add(payload);
      }
    });
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      if (Platform.isIOS) {
        final granted = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? false;
      }
      if (Platform.isAndroid) {
        final granted = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return false;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isAndroid) {
        final enabled = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled();
        return enabled ?? false;
      }
      if (Platform.isIOS) {
        final options = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.checkPermissions();
        return options?.isEnabled ?? false;
      }
    } catch (e) {
      debugPrint('Error reading notification permission state: $e');
    }
    // Masaüstü/test ortamı: izin kavramı yok, engellemeyelim.
    return true;
  }

  NotificationDetails _detailsFor(NotificationChannelKind kind) {
    final l10n = _localizer.l10n;

    final (String id, String name, String description, Importance importance) =
        switch (kind) {
      NotificationChannelKind.critical => (
          'cunehat_critical',
          l10n.notifChannelCriticalName,
          l10n.notifChannelCriticalDesc,
          Importance.max,
        ),
      NotificationChannelKind.recurring => (
          'cunehat_recurring',
          l10n.notifChannelRecurringName,
          l10n.notifChannelRecurringDesc,
          Importance.high,
        ),
      NotificationChannelKind.motivational => (
          'cunehat_motivational',
          l10n.notifChannelMotivationalName,
          l10n.notifChannelMotivationalDesc,
          Importance.defaultImportance,
        ),
    };

    return NotificationDetails(
      android: AndroidNotificationDetails(
        id,
        name,
        channelDescription: description,
        importance: importance,
        priority: importance == Importance.defaultImportance
            ? Priority.defaultPriority
            : Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationChannelKind channel = NotificationChannelKind.critical,
  }) async {
    try {
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        _detailsFor(channel),
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
    NotificationChannelKind channel = NotificationChannelKind.critical,
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
        _detailsFor(channel),
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
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  @override
  Future<void> scheduleRandomDailyReminders(NotificationFrequency frequency) {
    final run = _randomRescheduleQueue
        .then((_) => _rescheduleRandomReminders(frequency));
    // Kuyruk hata yüzünden kilitlenmesin.
    _randomRescheduleQueue = run.catchError((Object _) {});
    return run;
  }

  Future<void> _rescheduleRandomReminders(
      NotificationFrequency frequency) async {
    for (var i = 0; i < ReminderIds.randomReminderCapacity; i++) {
      await cancelNotification(ReminderIds.randomReminderStart + i);
    }

    if (frequency == NotificationFrequency.none) {
      debugPrint('Random reminders disabled.');
      return;
    }

    final l10n = _localizer.l10n;
    final messages = <String>[
      l10n.notifDailyReminder1,
      l10n.notifDailyReminder2,
      l10n.notifDailyReminder3,
      l10n.notifDailyReminder4,
      l10n.notifDailyReminder5,
      l10n.notifDailyReminder6,
    ];

    final random = Random();
    final now = DateTime.now();
    final slots = <DateTime>[];

    for (var day = 0; day < _randomReminderDays; day++) {
      final date = DateTime(now.year, now.month, now.day + day);
      for (var i = 0; i < frequency.dailyCount; i++) {
        final hour = _randomWindowStartHour +
            random.nextInt(_randomWindowEndHour - _randomWindowStartHour);
        slots.add(DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          random.nextInt(60),
        ));
      }
    }

    // Geçmişte kalan slotlar ERTELENMEZ, atılır. Ertelemek akşam açılışlarında
    // bugünün tüm slotlarını yarına yığıyor ve ertesi gün iki kat bildirim
    // üretiyordu.
    final upcoming = slots.where((slot) => slot.isAfter(now)).toList()..sort();

    var scheduled = 0;
    for (final slot in upcoming) {
      if (scheduled >= ReminderIds.randomReminderCapacity) break;
      await scheduleNotification(
        id: ReminderIds.randomReminderStart + scheduled,
        title: l10n.notifDailyReminderTitle,
        body: messages[random.nextInt(messages.length)],
        scheduledDate: slot,
        payload: NotificationPayloads.dailyReminder,
        channel: NotificationChannelKind.motivational,
      );
      scheduled++;
    }
    debugPrint('Scheduled $scheduled random reminders.');
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }

  @override
  @disposeMethod
  void dispose() => _tapController.close();
}
