import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/enums/notification_frequency.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/notifications/notification_constants.dart';
import 'package:cunehat/core/notifications/notification_localizer.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/services/notification_settings_service.dart';
import 'package:cunehat/core/services/reminder_sync_service.dart';
import 'package:cunehat/features/settings/presentation/bloc/notification_settings/notification_settings_bloc.dart';
import 'package:cunehat/features/settings/presentation/bloc/notification_settings/notification_settings_event.dart';
import 'package:cunehat/features/settings/presentation/bloc/notification_settings/notification_settings_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationService extends Mock implements NotificationService {}

class MockNotificationSettingsService extends Mock
    implements NotificationSettingsService {}

class MockReminderSyncService extends Mock implements ReminderSyncService {}

class MockNotificationLocalizer extends Mock implements NotificationLocalizer {}

void main() {
  late MockNotificationService notifications;
  late MockNotificationSettingsService settings;
  late MockReminderSyncService reminderSync;
  late MockNotificationLocalizer localizer;

  setUpAll(() {
    registerFallbackValue(NotificationChannelKind.critical);
  });

  setUp(() {
    notifications = MockNotificationService();
    settings = MockNotificationSettingsService();
    reminderSync = MockReminderSyncService();
    localizer = MockNotificationLocalizer();

    when(() => localizer.l10n)
        .thenReturn(lookupAppLocalizations(const Locale('tr')));
    when(settings.getRandomFrequency).thenReturn(NotificationFrequency.none);
    when(() => settings.isDebtRemindersEnabled).thenReturn(true);
    when(() => settings.isRecurringRemindersEnabled).thenReturn(true);
    when(() => settings.isBudgetAlertsEnabled).thenReturn(true);
    when(reminderSync.syncAll).thenAnswer((_) async {});
  });

  NotificationSettingsBloc build() => NotificationSettingsBloc(
        settings,
        notifications,
        reminderSync,
        localizer,
      );

  void stubShow({required bool delivered}) {
    when(() => notifications.showNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
          channel: any(named: 'channel'),
        )).thenAnswer((_) async => delivered);
  }

  group('izin isteği', () {
    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'sistem hâlâ soruyorsa izin ister ve verilince hatırlatmaları kurar',
      setUp: () {
        when(notifications.canRequestPermissions).thenAnswer((_) async => true);
        when(notifications.requestPermissions).thenAnswer((_) async => true);
        when(notifications.areNotificationsEnabled)
            .thenAnswer((_) async => true);
      },
      build: build,
      act: (bloc) => bloc.add(const RequestNotificationPermission()),
      expect: () => [
        isA<NotificationSettingsState>()
            .having((s) => s.systemPermissionGranted, 'granted', isTrue)
            .having((s) => s.canRequestPermission, 'canRequest', isTrue),
      ],
      verify: (_) {
        verify(notifications.requestPermissions).called(1);
        verify(reminderSync.syncAll).called(1);
        verifyNever(notifications.openSystemNotificationSettings);
      },
    );

    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'ilk reddedişten sonra düğme "İzin Ver" olarak kalır (sistem hâlâ sorar)',
      setUp: () {
        when(notifications.canRequestPermissions).thenAnswer((_) async => true);
        when(notifications.requestPermissions).thenAnswer((_) async => false);
      },
      build: build,
      act: (bloc) => bloc.add(const RequestNotificationPermission()),
      expect: () => [
        isA<NotificationSettingsState>()
            .having((s) => s.systemPermissionGranted, 'granted', isFalse)
            .having((s) => s.canRequestPermission, 'canRequest', isTrue),
      ],
      verify: (_) => verifyNever(reminderSync.syncAll),
    );

    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'izin verilmiş ama bildirimler ayarlardan kapalıysa banner kalkmaz',
      setUp: () {
        when(notifications.canRequestPermissions).thenAnswer((_) async => true);
        when(notifications.requestPermissions).thenAnswer((_) async => true);
        // İzin var; kullanıcı bildirimleri sistem ayarlarından kapatmış.
        when(notifications.areNotificationsEnabled)
            .thenAnswer((_) async => false);
      },
      build: build,
      act: (bloc) => bloc.add(const RequestNotificationPermission()),
      expect: () => [
        isA<NotificationSettingsState>()
            .having((s) => s.systemPermissionGranted, 'granted', isFalse),
      ],
      // Bildirim gitmeyeceği için planlama da yapılmamalı.
      verify: (_) => verifyNever(reminderSync.syncAll),
    );

    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'sistem artık sormuyorsa istek yerine sistem ayarlarını açar',
      setUp: () {
        when(notifications.canRequestPermissions).thenAnswer((_) async => false);
        when(notifications.openSystemNotificationSettings)
            .thenAnswer((_) async => true);
      },
      build: build,
      act: (bloc) => bloc.add(const RequestNotificationPermission()),
      expect: () => <NotificationSettingsState>[],
      verify: (_) {
        verify(notifications.openSystemNotificationSettings).called(1);
        // Ölü çağrı: diyalog açılmayacağı için istek hiç yapılmamalı.
        verifyNever(notifications.requestPermissions);
      },
    );

    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'yükleme, izin diyaloğunun açılabilirliğini de okur',
      setUp: () {
        when(notifications.areNotificationsEnabled)
            .thenAnswer((_) async => false);
        when(notifications.canRequestPermissions).thenAnswer((_) async => false);
      },
      build: build,
      act: (bloc) => bloc.add(const LoadNotificationSettings()),
      skip: 1, // isLoading
      expect: () => [
        isA<NotificationSettingsState>()
            .having((s) => s.systemPermissionGranted, 'granted', isFalse)
            .having((s) => s.canRequestPermission, 'canRequest', isFalse),
      ],
    );
  });

  group('test bildirimi', () {
    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'izin kapalıyken GÖNDERİLDİ demez ve bildirimi hiç denemez',
      setUp: () {
        when(notifications.areNotificationsEnabled)
            .thenAnswer((_) async => false);
        when(notifications.canRequestPermissions).thenAnswer((_) async => true);
        stubShow(delivered: true);
      },
      build: build,
      act: (bloc) => bloc.add(const SendTestNotification()),
      expect: () => [
        isA<NotificationSettingsState>()
            .having((s) => s.testNotificationDelivered, 'delivered', isFalse)
            .having((s) => s.testNotificationSentAt, 'sentAt', isNotNull)
            // Banner da anında doğruyu göstermeli.
            .having((s) => s.systemPermissionGranted, 'granted', isFalse),
      ],
      verify: (_) => verifyNever(() => notifications.showNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
            channel: any(named: 'channel'),
          )),
    );

    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'izin açık ama platform gönderemezse başarısız raporlar',
      setUp: () {
        when(notifications.areNotificationsEnabled)
            .thenAnswer((_) async => true);
        stubShow(delivered: false);
      },
      build: build,
      act: (bloc) => bloc.add(const SendTestNotification()),
      expect: () => [
        isA<NotificationSettingsState>()
            .having((s) => s.testNotificationDelivered, 'delivered', isFalse)
            .having((s) => s.systemPermissionGranted, 'granted', isTrue),
      ],
    );

    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'izin açık ve teslim edildiyse başarı raporlar',
      setUp: () {
        when(notifications.areNotificationsEnabled)
            .thenAnswer((_) async => true);
        stubShow(delivered: true);
      },
      build: build,
      act: (bloc) => bloc.add(const SendTestNotification()),
      expect: () => [
        isA<NotificationSettingsState>()
            .having((s) => s.testNotificationDelivered, 'delivered', isTrue)
            .having((s) => s.testNotificationSentAt, 'sentAt', isNotNull),
      ],
    );
  });
}
