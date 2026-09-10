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

  /// Test bildiriminin SONUCUNU sahteler. Artık `bool` değil tiplenmiş sonuç:
  /// "gönderilemedi" tek bir metne düşerken kullanıcı ne yapacağını
  /// bilemiyordu — izin, kanal ve platform hatası ayrı çözümler ister.
  void stubShow(NotificationSendResult result) {
    when(() => notifications.showNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
          channel: any(named: 'channel'),
        )).thenAnswer((_) async => result);
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
    // İzin kapısı artık BLOC'ta değil SERVİSTE: servis hem uygulama iznine hem
    // de kanalın susturulmuş olup olmadığına bakıp sebebi tiplenmiş döner.
    // Bloc'un işi o sebebi state'e taşımak — eskiden hepsi tek bir
    // "gönderilemedi"ye düşüyordu.

    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'izin kapalıysa sebebi taşır ve banner\'ı da düzeltir',
      setUp: () {
        when(notifications.canRequestPermissions).thenAnswer((_) async => true);
        stubShow(const NotificationSendResult.failed(
            NotificationFailure.noAppPermission));
      },
      build: build,
      act: (bloc) => bloc.add(const SendTestNotification()),
      expect: () => [
        isA<NotificationSettingsState>()
            .having((s) => s.testNotificationDelivered, 'delivered', isFalse)
            .having((s) => s.testNotificationFailure, 'failure',
                NotificationFailure.noAppPermission)
            .having((s) => s.testNotificationSentAt, 'sentAt', isNotNull)
            // Kullanıcı izni ekran dışında kapatmış olabilir; banner anında
            // doğruyu göstermeli.
            .having((s) => s.systemPermissionGranted, 'granted', isFalse)
            .having((s) => s.canRequestPermission, 'canRequest', isTrue),
      ],
    );

    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'kanal susturulmuşsa kanal adını taşır ve izni KAPALI göstermez',
      setUp: () => stubShow(const NotificationSendResult.failed(
          NotificationFailure.channelBlocked,
          detail: 'Kritik Hatırlatmalar')),
      build: build,
      act: (bloc) => bloc.add(const SendTestNotification()),
      expect: () => [
        isA<NotificationSettingsState>()
            .having((s) => s.testNotificationDelivered, 'delivered', isFalse)
            .having((s) => s.testNotificationFailure, 'failure',
                NotificationFailure.channelBlocked)
            .having((s) => s.testNotificationDetail, 'detail',
                'Kritik Hatırlatmalar')
            // Uygulama izni AÇIK; yalnız o kanal kapalı. İkisi karıştırılırsa
            // kullanıcı yanlış ayara gönderilir.
            .having((s) => s.systemPermissionGranted, 'granted', isTrue),
      ],
      verify: (_) => verifyNever(notifications.canRequestPermissions),
    );

    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'platform hatasında istisna metni state\'e taşınır',
      setUp: () => stubShow(const NotificationSendResult.failed(
          NotificationFailure.platformError,
          detail: 'PlatformException(invalid icon)')),
      build: build,
      act: (bloc) => bloc.add(const SendTestNotification()),
      expect: () => [
        isA<NotificationSettingsState>()
            .having((s) => s.testNotificationFailure, 'failure',
                NotificationFailure.platformError)
            // Release'te debugPrint hiçbir yere gitmiyor; ayrıntının TEK
            // taşıyıcısı bu alan.
            .having((s) => s.testNotificationDetail, 'detail',
                'PlatformException(invalid icon)'),
      ],
    );

    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'sisteme iletilip gösterilmediyse ayrı bir sebep raporlar',
      setUp: () => stubShow(const NotificationSendResult.failed(
          NotificationFailure.notDelivered)),
      build: build,
      act: (bloc) => bloc.add(const SendTestNotification()),
      expect: () => [
        isA<NotificationSettingsState>()
            .having((s) => s.testNotificationDelivered, 'delivered', isFalse)
            .having((s) => s.testNotificationFailure, 'failure',
                NotificationFailure.notDelivered),
      ],
    );

    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'teslim edildiyse başarı raporlar ve ÖNCEKİ sebebi temizler',
      setUp: () => stubShow(const NotificationSendResult.delivered()),
      build: build,
      seed: () => NotificationSettingsState(
        testNotificationFailure: NotificationFailure.channelBlocked,
        testNotificationDetail: 'eski',
        testNotificationSentAt: DateTime(2026),
      ),
      act: (bloc) => bloc.add(const SendTestNotification()),
      expect: () => [
        isA<NotificationSettingsState>()
            .having((s) => s.testNotificationDelivered, 'delivered', isTrue)
            .having((s) => s.testNotificationSentAt, 'sentAt', isNotNull)
            // Bayat sebep ekranda kalırsa kullanıcı düzelen şeyi düzelmemiş
            // sanır: copyWith'in `??` davranışı bunu sessizce yapıyordu.
            .having((s) => s.testNotificationFailure, 'failure', isNull)
            .having((s) => s.testNotificationDetail, 'detail', isNull),
      ],
    );

    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'test KRİTİK kanaldan atılır — motivasyon kanalı banner çıkarmıyor',
      setUp: () => stubShow(const NotificationSendResult.delivered()),
      build: build,
      act: (bloc) => bloc.add(const SendTestNotification()),
      verify: (_) => verify(() => notifications.showNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
            channel: NotificationChannelKind.critical,
          )).called(1),
    );
  });
}
