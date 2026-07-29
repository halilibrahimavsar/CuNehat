import 'package:cunehat/core/enums/notification_frequency.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/notifications/notification_constants.dart';
import 'package:cunehat/core/notifications/notification_localizer.dart';
import 'package:cunehat/core/notifications/notification_permission_channel.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockNotificationLocalizer extends Mock implements NotificationLocalizer {}

class MockNotificationPermissionChannel extends Mock
    implements NotificationPermissionChannel {}

class FakeNotificationDetails extends Fake implements NotificationDetails {}

class FakeTZDateTime extends Fake implements tz.TZDateTime {}

void main() {
  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late MockNotificationLocalizer mockLocalizer;
  late MockNotificationPermissionChannel mockPermissionChannel;
  late NotificationServiceImpl service;

  setUpAll(() {
    registerFallbackValue(FakeNotificationDetails());
    registerFallbackValue(FakeTZDateTime());
    registerFallbackValue(UILocalNotificationDateInterpretation.absoluteTime);
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
  });

  setUp(() {
    tz_data.initializeTimeZones();
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    mockLocalizer = MockNotificationLocalizer();
    when(() => mockLocalizer.l10n)
        .thenReturn(lookupAppLocalizations(const Locale('tr')));
    when(() => mockPlugin.getNotificationAppLaunchDetails())
        .thenAnswer((_) async => null);
    mockPermissionChannel = MockNotificationPermissionChannel();
    when(() => mockPermissionChannel.markRequested())
        .thenAnswer((_) async {});
    service =
        NotificationServiceImpl(mockPlugin, mockLocalizer, mockPermissionChannel);
  });

  tearDown(() => service.dispose());

  group('NotificationServiceImpl', () {
    test('showNotification calls plugin.show with correct params', () async {
      when(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any<NotificationDetails>(),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async {});

      await service.showNotification(
        id: 1,
        title: 'Test Title',
        body: 'Test Body',
        payload: 'payload',
      );

      verify(() => mockPlugin.show(
            1,
            'Test Title',
            'Test Body',
            any<NotificationDetails>(),
            payload: 'payload',
          )).called(1);
    });

    test('showNotification handles plugin exception gracefully', () async {
      when(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any<NotificationDetails>(),
          )).thenThrow(Exception('Plugin error'));

      final delivered = await service.showNotification(
        id: 1,
        title: 'Test',
        body: 'Test',
      );

      // Yutulan hata "gönderildi" diye raporlanmamalı.
      expect(delivered, isFalse);
    });

    test('scheduleNotification calls plugin.zonedSchedule with correct params',
        () async {
      final scheduledDate = DateTime(2026, 12, 25, 10, 0);
      when(() => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any<tz.TZDateTime>(),
            any<NotificationDetails>(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            uiLocalNotificationDateInterpretation:
                any(named: 'uiLocalNotificationDateInterpretation'),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async {});

      await service.scheduleNotification(
        id: 1,
        title: 'Scheduled',
        body: 'Body',
        scheduledDate: scheduledDate,
      );

      verify(() => mockPlugin.zonedSchedule(
            1,
            'Scheduled',
            'Body',
            any<tz.TZDateTime>(),
            any<NotificationDetails>(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: null,
          )).called(1);
    });

    test('scheduleNotification skips when scheduledDate is in the past',
        () async {
      final pastDate = DateTime(2020, 1, 1);
      await service.scheduleNotification(
        id: 1,
        title: 'Past',
        body: 'Body',
        scheduledDate: pastDate,
      );

      verifyNever(() => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any<tz.TZDateTime>(),
            any<NotificationDetails>(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            uiLocalNotificationDateInterpretation:
                any(named: 'uiLocalNotificationDateInterpretation'),
          ));
    });

    test('cancelNotification calls plugin.cancel', () async {
      when(() => mockPlugin.cancel(any(), tag: any(named: 'tag')))
          .thenAnswer((_) async {});

      await service.cancelNotification(5);

      verify(() => mockPlugin.cancel(5, tag: null)).called(1);
    });

    test('cancelAllNotifications calls plugin.cancelAll', () async {
      when(() => mockPlugin.cancelAll()).thenAnswer((_) async {});

      await service.cancelAllNotifications();

      verify(() => mockPlugin.cancelAll()).called(1);
    });

    test('initialize registers callbacks', () async {
      registerFallbackValue((NotificationResponse response) {});
      registerFallbackValue(const InitializationSettings());

      when(() => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).thenAnswer((_) async => true);

      await service.initialize();

      verify(() => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).called(1);
    });

    test('onDidReceiveNotificationResponse callback works', () async {
      registerFallbackValue((NotificationResponse response) {});
      registerFallbackValue(const InitializationSettings());

      DidReceiveNotificationResponseCallback? capturedCallback;
      when(() => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).thenAnswer((invocation) async {
        capturedCallback =
            invocation.namedArguments[#onDidReceiveNotificationResponse]
                as DidReceiveNotificationResponseCallback?;
        return true;
      });

      await service.initialize();
      expect(capturedCallback, isNotNull);

      capturedCallback!(const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'test_payload',
      ));
    });
  });

  group('onNotificationTap', () {
    late DidReceiveNotificationResponseCallback? capturedCallback;

    Future<void> initializeCapturingCallback() async {
      registerFallbackValue((NotificationResponse response) {});
      registerFallbackValue(const InitializationSettings());
      when(() => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).thenAnswer((invocation) async {
        capturedCallback =
            invocation.namedArguments[#onDidReceiveNotificationResponse]
                as DidReceiveNotificationResponseCallback?;
        return true;
      });
      await service.initialize();
    }

    test('sıcak açılış: dokunulan bildirimin yükünü yayınlar', () async {
      await initializeCapturingCallback();

      final received = <String>[];
      service.onNotificationTap.listen(received.add);
      await Future<void>.delayed(Duration.zero);

      capturedCallback!(const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'pending_recurring',
      ));
      await Future<void>.delayed(Duration.zero);

      expect(received, ['pending_recurring']);
    });

    test(
        'soğuk açılış: initialize sırasında okunan yük, dinleyici SONRADAN '
        'bağlansa bile teslim edilir', () async {
      // Uygulama kapalıyken bildirime dokunulduğunda widget ağacı henüz
      // kurulmamıştır; tamponlanmadığı için yük kayboluyordu.
      when(() => mockPlugin.getNotificationAppLaunchDetails()).thenAnswer(
        (_) async => const NotificationAppLaunchDetails(
          true,
          notificationResponse: NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: 'pending_recurring',
          ),
        ),
      );
      await initializeCapturingCallback();

      final received = <String>[];
      service.onNotificationTap.listen(received.add);
      await Future<void>.delayed(Duration.zero);

      expect(received, ['pending_recurring']);
    });

    test('bildirim uygulamayı başlatmadıysa hiçbir şey yayınlanmaz', () async {
      when(() => mockPlugin.getNotificationAppLaunchDetails()).thenAnswer(
        (_) async => const NotificationAppLaunchDetails(false),
      );
      await initializeCapturingCallback();

      final received = <String>[];
      service.onNotificationTap.listen(received.add);
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
    });
  });

  group('scheduleRandomDailyReminders', () {
    test('kapalıyken tüm aralığı iptal eder ve hiçbir şey planlamaz', () async {
      when(() => mockPlugin.cancel(any(), tag: any(named: 'tag')))
          .thenAnswer((_) async {});

      await service.scheduleRandomDailyReminders(NotificationFrequency.none);

      verify(() => mockPlugin.cancel(any(), tag: any(named: 'tag')))
          .called(ReminderIds.randomReminderCapacity);
      verifyNever(() => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any<tz.TZDateTime>(),
            any<NotificationDetails>(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            uiLocalNotificationDateInterpretation:
                any(named: 'uiLocalNotificationDateInterpretation'),
            payload: any(named: 'payload'),
          ));
    });

    test('kapasiteyi aşmadan, hepsi gelecekte olacak şekilde planlar',
        () async {
      when(() => mockPlugin.cancel(any(), tag: any(named: 'tag')))
          .thenAnswer((_) async {});
      final scheduledDates = <tz.TZDateTime>[];
      when(() => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any<tz.TZDateTime>(),
            any<NotificationDetails>(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            uiLocalNotificationDateInterpretation:
                any(named: 'uiLocalNotificationDateInterpretation'),
            payload: any(named: 'payload'),
          )).thenAnswer((invocation) async {
        scheduledDates.add(invocation.positionalArguments[3] as tz.TZDateTime);
      });

      await service.scheduleRandomDailyReminders(NotificationFrequency.high);

      expect(scheduledDates, isNotEmpty);
      expect(scheduledDates.length,
          lessThanOrEqualTo(ReminderIds.randomReminderCapacity));
      // Geçmiş slotlar ertesi güne ÖTELENMEZ, atılır: akşam açılışlarında
      // günün tüm slotları yarına yığılıp ertesi gün iki kat bildirim
      // üretiyordu.
      final now = tz.TZDateTime.now(tz.local);
      expect(scheduledDates.every((date) => date.isAfter(now)), isTrue);
    });
  });
}
