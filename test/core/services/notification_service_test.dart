import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class FakeNotificationDetails extends Fake implements NotificationDetails {}

class FakeTZDateTime extends Fake implements tz.TZDateTime {}

void main() {
  late MockFlutterLocalNotificationsPlugin mockPlugin;
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
    service = NotificationServiceImpl(mockPlugin);
  });

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

      await service.showNotification(
        id: 1,
        title: 'Test',
        body: 'Test',
      );
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
}
