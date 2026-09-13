import 'package:cunehat/core/enums/notification_frequency.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/notifications/notification_constants.dart';
import 'package:cunehat/core/notifications/notification_localizer.dart';
import 'package:cunehat/core/notifications/notification_permission_channel.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:flutter/services.dart';
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

/// `tz.TZDateTime` `tz.local`'da tutulur ve testte `tz.local` UTC'dir;
/// `toLocal()` de timezone paketinin "local"ini (yine UTC) verir. Slot
/// saatleri ise CİHAZIN yerel saatinde tanımlı, o yüzden aynı ANI cihazın
/// saatinde okuyoruz.
DateTime asDeviceLocal(tz.TZDateTime value) =>
    DateTime.fromMillisecondsSinceEpoch(value.millisecondsSinceEpoch);

void main() {
  // `flutter_timezone` platform kanalı sahtelenecek: binding olmadan
  // TestDefaultBinaryMessengerBinding.instance okunamıyor.
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late MockNotificationLocalizer mockLocalizer;
  late MockNotificationPermissionChannel mockPermissionChannel;
  late NotificationServiceImpl service;

  setUpAll(() {
    registerFallbackValue(FakeNotificationDetails());
    registerFallbackValue(FakeTZDateTime());
    registerFallbackValue(UILocalNotificationDateInterpretation.absoluteTime);
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
    registerFallbackValue(DateTimeComponents.time);
  });

  /// `flutter_timezone` platform kanalının döneceği bölge. `null` = kanal
  /// hata versin (cihazda bölge okunamama hâli).
  String? nativeTimeZone;

  setUp(() {
    tz_data.initializeTimeZones();
    nativeTimeZone = 'Europe/Istanbul';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (call) async {
        if (call.method != 'getLocalTimezone') return null;
        final zone = nativeTimeZone;
        if (zone == null) {
          throw PlatformException(code: 'unavailable');
        }
        return zone;
      },
    );
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    mockLocalizer = MockNotificationLocalizer();
    when(() => mockLocalizer.l10n)
        .thenReturn(lookupAppLocalizations(const Locale('tr')));
    when(() => mockPlugin.getNotificationAppLaunchDetails())
        .thenAnswer((_) async => null);
    // `show` artık teslimatı DOĞRULUYOR: gösterilenler listesinde bulamazsa
    // "gönderildi" demiyor. Varsayılan sahte: her şey gösterildi.
    when(() => mockPlugin.getActiveNotifications())
        .thenAnswer((_) async => const [ActiveNotification(id: 1)]);
    when(() => mockPlugin.pendingNotificationRequests())
        .thenAnswer((_) async => const <PendingNotificationRequest>[]);
    mockPermissionChannel = MockNotificationPermissionChannel();
    when(() => mockPermissionChannel.markRequested())
        .thenAnswer((_) async {});
    when(() => mockPermissionChannel.canPrompt()).thenAnswer((_) async => true);
    service =
        NotificationServiceImpl(mockPlugin, mockLocalizer, mockPermissionChannel);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_timezone'), null);
    service.dispose();
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

    test('showNotification platform hatasını SEBEBİYLE birlikte döner',
        () async {
      when(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any<NotificationDetails>(),
            payload: any(named: 'payload'),
          )).thenThrow(Exception('Plugin error'));

      final result = await service.showNotification(
        id: 1,
        title: 'Test',
        body: 'Test',
      );

      // Yutulan hata "gönderildi" diye raporlanmamalı.
      expect(result.delivered, isFalse);
      expect(result.failure, NotificationFailure.platformError);
      // İstisna metni state'e taşınmalı: release'te debugPrint hiçbir yere
      // gitmediği için kullanıcıya ulaşan TEK ayrıntı budur.
      expect(result.detail, contains('Plugin error'));
    });

    test('show başarılıysa teslim edildi döner', () async {
      when(() => mockPlugin.show(any(), any(), any(), any<NotificationDetails>(),
          payload: any(named: 'payload'))).thenAnswer((_) async {});
      when(() => mockPlugin.getActiveNotifications())
          .thenAnswer((_) async => const [ActiveNotification(id: 7)]);

      final result = await service.showNotification(
        id: 7,
        title: 'Test',
        body: 'Test',
      );

      expect(result.delivered, isTrue);
      expect(result.failure, isNull);
    });

    test(
        'sisteme iletilip GÖSTERİLMEDİYSE başarısız sayılır — sessiz '
        'başarısızlığın yakalandığı yer burası', () async {
      when(() => mockPlugin.show(any(), any(), any(), any<NotificationDetails>(),
          payload: any(named: 'payload'))).thenAnswer((_) async {});
      // Kanal susturulmuş / pil kısıtı: `show` istisna ATMAZ, bildirim de
      // görünmez. Eskiden bu durum "gönderildi" diye raporlanıyordu.
      when(() => mockPlugin.getActiveNotifications())
          .thenAnswer((_) async => const <ActiveNotification>[]);

      final result = await service.showNotification(
        id: 7,
        title: 'Test',
        body: 'Test',
      );

      expect(result.delivered, isFalse);
      expect(result.failure, NotificationFailure.notDelivered);
    });

    test('teslimat DOĞRULANAMIYORSA başarısızlık uydurulmaz', () async {
      when(() => mockPlugin.show(any(), any(), any(), any<NotificationDetails>(),
          payload: any(named: 'payload'))).thenAnswer((_) async {});
      // Masaüstü/eski platform: sorgu desteklenmiyor. Olmayan bir hata
      // uydurmak, hatayı kaçırmaktan daha kötü.
      when(() => mockPlugin.getActiveNotifications())
          .thenThrow(UnimplementedError());

      final result = await service.showNotification(
        id: 7,
        title: 'Test',
        body: 'Test',
      );

      expect(result.delivered, isTrue);
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

    test('eklenti başlatılamazsa initialize fırlatmaz ve tanılamaya yazar',
        () async {
      // Bildirim kritik bir alt sistem değil: bu hata eskiden açılıştan
      // yukarı sızıyor, uygulama "başlatılamadı" ekranında kalıyordu.
      registerFallbackValue((NotificationResponse response) {});
      registerFallbackValue(const InitializationSettings());
      when(() => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).thenThrow(PlatformException(code: 'invalid_icon'));

      await expectLater(service.initialize(), completes);

      final diagnostics = await service.readDiagnostics();
      expect(diagnostics.lastError, contains('initialize'));
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
    /// Planlanan (id, zaman, tekrar) üçlülerini toplar.
    List<({int id, tz.TZDateTime at, bool repeats})> captureSchedules() {
      final captured = <({int id, tz.TZDateTime at, bool repeats})>[];
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
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          )).thenAnswer((invocation) async {
        captured.add((
          id: invocation.positionalArguments[0] as int,
          at: invocation.positionalArguments[3] as tz.TZDateTime,
          repeats: invocation.namedArguments[#matchDateTimeComponents] ==
              DateTimeComponents.time,
        ));
      });
      return captured;
    }

    test('kapalıyken kullanılabilecek kimlikleri iptal eder, plan kurmaz',
        () async {
      when(() => mockPlugin.cancel(any(), tag: any(named: 'tag')))
          .thenAnswer((_) async {});
      final captured = captureSchedules();

      await service.scheduleRandomDailyReminders(NotificationFrequency.none);

      expect(captured, isEmpty);
      verify(() => mockPlugin.cancel(any(), tag: any(named: 'tag')))
          .called(maxDailyReminderSlots);
    });

    test(
        'sıklık düşürülünce ARTAN kimlikler de iptal edilir — "çok"tan "az"a '
        'dönen kullanıcıda iki bildirim ayakta kalıyordu', () async {
      final cancelled = <int>[];
      when(() => mockPlugin.cancel(any(), tag: any(named: 'tag')))
          .thenAnswer((invocation) async {
        cancelled.add(invocation.positionalArguments[0] as int);
      });
      captureSchedules();

      await service.scheduleRandomDailyReminders(NotificationFrequency.low);

      // "az" tek slot kurar ama iptal EN FAZLA slot kadar geniş olmalı.
      expect(cancelled.length, maxDailyReminderSlots);
      expect(cancelled.first, ReminderIds.randomReminderStart);
      expect(cancelled.last,
          ReminderIds.randomReminderStart + maxDailyReminderSlots - 1);
    });

    test(
        'rutin yeniden kurulum 60 kimliği GEZMEZ — plugin her iptalde planlı '
        'listenin tamamını yeniden serileştiriyor', () async {
      when(() => mockPlugin.cancel(any(), tag: any(named: 'tag')))
          .thenAnswer((_) async {});
      captureSchedules();

      await service.scheduleRandomDailyReminders(NotificationFrequency.high);

      // Eski davranış her açılışta 60 tur ödüyordu; temizlik artık ayrı ve
      // tek seferlik (purgeLegacyRandomReminders).
      verifyNever(() => mockPlugin
          .cancel(ReminderIds.randomReminderStart + 30, tag: any(named: 'tag')));
    });

    test('purgeLegacyRandomReminders ESKİ aralığın TAMAMINI iptal eder',
        () async {
      final cancelled = <int>[];
      when(() => mockPlugin.cancel(any(), tag: any(named: 'tag')))
          .thenAnswer((invocation) async {
        cancelled.add(invocation.positionalArguments[0] as int);
      });

      await service.purgeLegacyRandomReminders();

      // Eski sürüm bu aralığa 14 günlük rastgele plan yazıyordu; temizlenmezse
      // yeni sabit saatlerin yanında günlerce rastgele bildirim düşer.
      expect(cancelled.length, ReminderIds.randomReminderCapacity);
      expect(cancelled.first, ReminderIds.randomReminderStart);
      expect(
          cancelled.last,
          ReminderIds.randomReminderStart +
              ReminderIds.randomReminderCapacity -
              1);
    });

    test('sıklık, sabit günlük saatlere çevrilir', () async {
      when(() => mockPlugin.cancel(any(), tag: any(named: 'tag')))
          .thenAnswer((_) async {});
      final captured = captureSchedules();

      await service.scheduleRandomDailyReminders(NotificationFrequency.high);

      expect(captured.length, NotificationFrequency.high.dailySlots.length);
      final expected = NotificationFrequency.high.dailySlots;
      for (var i = 0; i < expected.length; i++) {
        final local = asDeviceLocal(captured[i].at);
        expect(local.hour, expected[i].hour);
        expect(local.minute, expected[i].minute);
        // Kimlikler aralığın başından SIRAYLA verilir; formül kopyalanırsa
        // toplu iptal bildirimi bulamaz.
        expect(captured[i].id, ReminderIds.randomReminderStart + i);
      }
    });

    test(
        'hepsi GÜNLÜK TEKRARLI ve gelecekte kurulur — tek atışlık plan '
        'uygulama açılmadan yenilenemiyordu', () async {
      when(() => mockPlugin.cancel(any(), tag: any(named: 'tag')))
          .thenAnswer((_) async {});
      final captured = captureSchedules();

      await service.scheduleRandomDailyReminders(NotificationFrequency.medium);

      expect(captured, isNotEmpty);
      expect(captured.every((c) => c.repeats), isTrue);
      final now = tz.TZDateTime.now(tz.local);
      expect(captured.every((c) => c.at.isAfter(now)), isTrue);
    });
  });

  group('scheduleNotification — tekrar', () {
    late List<({tz.TZDateTime at, bool repeats})> captured;

    setUp(() {
      captured = <({tz.TZDateTime at, bool repeats})>[];
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
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          )).thenAnswer((invocation) async {
        captured.add((
          at: invocation.positionalArguments[3] as tz.TZDateTime,
          repeats: invocation.namedArguments[#matchDateTimeComponents] ==
              DateTimeComponents.time,
        ));
      });
    });

    test('repeatDaily varsayılan olarak KAPALI', () async {
      await service.scheduleNotification(
        id: 1,
        title: 'x',
        body: 'y',
        scheduledDate: DateTime.now().add(const Duration(days: 2)),
      );

      expect(captured.single.repeats, isFalse);
    });

    test('repeatDaily true iken saat bileşeni eşleştirilir', () async {
      await service.scheduleNotification(
        id: 1,
        title: 'x',
        body: 'y',
        scheduledDate: DateTime.now().add(const Duration(minutes: 5)),
        repeatDaily: true,
      );

      // Tekrarı sistem kendi kurar (ScheduledNotificationReceiver →
      // scheduleNextNotification); uygulama hiç açılmasa da sürer.
      expect(captured.single.repeats, isTrue);
    });

    test(
        'günlük tekrarda GEÇMİŞ saat atlanmaz, yarına kurulur — geçmiş-tarih '
        'kapısı hatırlatmayı tamamen yutuyordu', () async {
      final now = DateTime.now();
      final passedToday = now.subtract(const Duration(hours: 3));

      await service.scheduleNotification(
        id: 1,
        title: 'x',
        body: 'y',
        scheduledDate: passedToday,
        repeatDaily: true,
      );

      expect(captured, hasLength(1));
      expect(captured.single.at.isAfter(tz.TZDateTime.now(tz.local)), isTrue);
      final local = asDeviceLocal(captured.single.at);
      expect(local.hour, passedToday.hour);
      expect(local.minute, passedToday.minute);
    });

    test(
        'tekrarlı planda TARİH yok sayılır — plugin\'in gerçek davranışı '
        'kayda geçiyor', () async {
      final future = DateTime(2099, 6, 20, 9);

      await service.scheduleNotification(
        id: 1,
        title: 'x',
        body: 'y',
        scheduledDate: future,
        repeatDaily: true,
      );

      // TUZAK: plugin `matchDateTimeComponents.time` gördüğünde tarihi HEM
      // ilk kurulumda hem yeniden kurarken bugünden hesaplıyor
      // (zonedSchedule → getNextFireDateMatchingDateTimeComponents), yani
      // "3 hafta sonra başla, sonra her gün" diye bir şey yok. Servis de aynı
      // normalizasyonu yapıyor ki tanılamadaki "sıradaki bildirim" yalan
      // söylemesin. Gelecek vadeli kalemleri tekrarlı KURMAMAK çağıranın
      // sorumluluğu — ReminderSyncService bunu `isReminderOverdue` ile yapar.
      expect(captured, hasLength(1));
      final local = asDeviceLocal(captured.single.at);
      expect(local.year, isNot(2099));
      expect(local.hour, 9);
      expect(local.isAfter(DateTime.now()), isTrue);
      expect(captured.single.repeats, isTrue);
    });

    test('tek atışlık planda geçmiş tarih hâlâ atlanır', () async {
      await service.scheduleNotification(
        id: 1,
        title: 'x',
        body: 'y',
        scheduledDate: DateTime(2020, 1, 1),
      );

      expect(captured, isEmpty);
    });
  });

  group('saat dilimi', () {
    Future<void> initialize() async {
      registerFallbackValue((NotificationResponse response) {});
      registerFallbackValue(const InitializationSettings());
      when(() => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).thenAnswer((_) async => true);
      await service.initialize();
    }

    test('initialize cihazın bölgesini tz.local yapar', () async {
      nativeTimeZone = 'Europe/Istanbul';

      await initialize();

      // Tekrarlayan planlamada plugin bölge ADINI kaydedip bir sonraki
      // tetiklemeyi native tarafta o bölgede hesaplıyor; UTC bırakılırsa
      // yaz saati uygulanan bölgelerde hatırlatma yılda iki kez kayar.
      expect(tz.local.name, 'Europe/Istanbul');
      final diagnostics = await service.readDiagnostics();
      expect(diagnostics.localTimeZone, 'Europe/Istanbul');
    });

    test('bölge okunamazsa UTC\'ye düşer ve bunu TANILAMADA söyler', () async {
      nativeTimeZone = null;

      await initialize();

      final diagnostics = await service.readDiagnostics();
      expect(diagnostics.localTimeZone, 'UTC');
      // Sessizce yutulmaz: kullanıcı neden kaydığını görebilmeli.
      expect(diagnostics.lastError, contains('local timezone'));
    });
  });

  group('readDiagnostics', () {
    test('bekleyen bildirim sayısını ve kanalları raporlar', () async {
      when(() => mockPlugin.pendingNotificationRequests()).thenAnswer(
        (_) async => const [
          PendingNotificationRequest(1, 'a', 'b', null),
          PendingNotificationRequest(2, 'c', 'd', null),
        ],
      );

      final diagnostics = await service.readDiagnostics();

      expect(diagnostics.pendingCount, 2);
      // Üç kanalın üçü de raporlanır; kanal listesi okunamadığında (Android
      // değil) hiçbiri "engelli" sayılmaz.
      expect(diagnostics.channels, hasLength(NotificationChannelKind.values.length));
      expect(diagnostics.anyChannelBlocked, isFalse);
    });

    test('sıradaki hatırlatma bu oturumda kurulanlardan türetilir', () async {
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
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          )).thenAnswer((_) async {});
      final near = DateTime.now().add(const Duration(hours: 2));
      final far = DateTime.now().add(const Duration(days: 3));

      await service.scheduleNotification(
          id: 1, title: 'x', body: 'y', scheduledDate: far);
      await service.scheduleNotification(
          id: 2, title: 'x', body: 'y', scheduledDate: near);

      final diagnostics = await service.readDiagnostics();
      expect(diagnostics.nextScheduledAt, near);
    });

    test('iptal edilen plan sıradakilerden düşer', () async {
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
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          )).thenAnswer((_) async {});
      when(() => mockPlugin.cancel(any(), tag: any(named: 'tag')))
          .thenAnswer((_) async {});

      await service.scheduleNotification(
        id: 1,
        title: 'x',
        body: 'y',
        scheduledDate: DateTime.now().add(const Duration(hours: 2)),
      );
      await service.cancelNotification(1);

      expect((await service.readDiagnostics()).nextScheduledAt, isNull);
    });
  });
}
