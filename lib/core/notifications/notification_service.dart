import 'dart:async';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:cunehat/core/enums/notification_frequency.dart';
import 'package:cunehat/core/notifications/notification_constants.dart';
import 'package:cunehat/core/notifications/notification_diagnostics.dart';
import 'package:cunehat/core/notifications/notification_localizer.dart';
import 'package:cunehat/core/notifications/notification_permission_channel.dart';

export 'package:cunehat/core/notifications/notification_diagnostics.dart';

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

  /// Sistem izin diyaloğunun hâlâ açılabildiği durumlarda `true`. `false` ise
  /// [requestPermissions] diyaloğu göstermeden anında `false` döner; tek çıkış
  /// yolu [openSystemNotificationSettings].
  Future<bool> canRequestPermissions();

  /// Uygulamanın sistem bildirim ayarlarını açar; açılabildiyse `true`.
  Future<bool> openSystemNotificationSettings();

  /// Sistem düzeyinde bildirimlerin açık olup olmadığı. Kullanıcı izni
  /// reddettiyse uygulama içi anahtarlar açık görünse de bildirim gitmez.
  Future<bool> areNotificationsEnabled();

  /// Bildirimi gösterir ve **gerçekten göründüğünü** doğrular.
  ///
  /// Eskiden yalnız "istisna atmadı" anlamına gelen bir `bool` dönüyordu;
  /// kanal susturulmuşsa `show` sessizce başarılı görünüyor ve kullanıcıya
  /// "gönderildi" deniyordu. Artık başarısızlığın SEBEBİ tiplenmiş döner.
  Future<NotificationSendResult> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationChannelKind channel = NotificationChannelKind.critical,
  });

  /// [repeatDaily] `true` ise bildirim **her gün** [scheduledDate]'in
  /// SAATİNDE düşer.
  ///
  /// ⚠️ Tekrarlı planda [scheduledDate]'in TARİHİ yok sayılır, yalnız
  /// saat:dakikası kullanılır: ilk atış bu saatin bir sonraki gelişidir
  /// (bugün ya da yarın). Plugin bunu hem ilk kurulumda hem de yeniden
  /// kurarken böyle hesaplıyor
  /// (`FlutterLocalNotificationsPlugin.zonedSchedule` →
  /// `getNextFireDateMatchingDateTimeComponents`, tarihi HER ZAMAN bugünden
  /// kurar). Yani "3 hafta sonra başla, sonra her gün" DİYE BİR ŞEY YOK —
  /// gelecek tarihli bir hatırlatma tekrarlı kurulursa yarın sabah çalmaya
  /// başlar. Gelecek vadeli kalemler tek atışlık planlanmalı; vadesi
  /// geldiğinde tekrarlıya dönerler (bkz. [ReminderSyncService]).
  ///
  /// Tekrarı sistem kendi kurar (`ScheduledNotificationReceiver` →
  /// `scheduleNextNotification`), yani uygulama hiç açılmasa da sürer. Tek
  /// atışlık planlar ise yalnızca uygulama bir daha açıldığında yenilenebilir —
  /// uygulamayı açmayan kullanıcı ömrü boyunca TEK hatırlatma alıyordu.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationChannelKind channel = NotificationChannelKind.critical,
    bool repeatDaily = false,
  });

  Future<void> scheduleRandomDailyReminders(NotificationFrequency frequency);

  /// Eski sürümlerin motivasyon aralığına yazdığı TEK ATIŞLIK planları düşürür.
  ///
  /// Ayrı bir metot çünkü PAHALI ve bir kez yeterli: 60 kimliğin her biri için
  /// plugin planlı bildirim listesinin tamamını JSON'a serileştirip prefs'e
  /// yazıyor. Her açılışta yapılırsa ödenen bedel kalıcı olur.
  Future<void> purgeLegacyRandomReminders();

  /// Servis DIŞINDA oluşan ama bildirim kurulmasını engelleyen hatayı
  /// tanılamaya taşır (ör. hatırlatmaların kaynağı olan defter okunamadı).
  ///
  /// Bu olmadan hata yalnız `debugPrint`'e gidiyordu; release'te `debugPrint`
  /// hiçbir yere gitmez, yani "hatırlatmalarım kurulmamış" durumunun izi
  /// tamamen kayboluyordu.
  void noteFailure(String context, Object error);

  Future<void> cancelNotification(int id);

  Future<void> cancelAllNotifications();

  /// Bildirim boru hattının o anki durumu — "neden bildirim gelmiyor"
  /// sorusunun CİHAZDA cevaplanabilmesi için.
  Future<NotificationDiagnostics> readDiagnostics();

  /// GetIt kapatılırken çağrılır; dokunma akışını serbest bırakır.
  void dispose();
}

@LazySingleton(as: NotificationService)
class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final NotificationLocalizer _localizer;
  final NotificationPermissionChannel _permissionChannel;

  final StreamController<String> _tapController;
  final List<String> _bufferedTaps = <String>[];

  /// Motivasyon hatırlatıcıları "önce hepsini iptal et, sonra yeniden kur"
  /// şeklinde çalışır. İki çalıştırma iç içe girerse birinin iptali
  /// diğerinin planladıklarını siler; çağrıları sıraya alıyoruz.
  Future<void> _randomRescheduleQueue = Future<void>.value();

  /// Bu oturumda kurulan planların zamanı. Plugin bekleyen kayıtlarda zaman
  /// vermiyor; tanılamada "sıradaki bildirim ne zaman" sorusunu ancak kendi
  /// kaydımızdan cevaplayabiliyoruz. `syncAll` her açılışta hepsini yeniden
  /// kurduğu için tablo pratikte tamdır.
  final Map<int, ({DateTime at, bool repeatDaily})> _scheduledAt =
      <int, ({DateTime at, bool repeatDaily})>{};

  /// Yutulan SON hata. Bu alan olmadan release'te hiçbir iz kalmıyordu:
  /// `debugPrint` release derlemesinde hiçbir yere gitmez.
  String? _lastError;

  /// `tz.local` gerçekten cihazın bölgesine kurulabildi mi. Kurulamadıysa
  /// tekrarlayan alarmların bir sonraki kurulumu yanlış saate düşer — bu
  /// yüzden tanılamada görünür.
  String _localTimeZone = 'UTC';

  NotificationServiceImpl(
    this._flutterLocalNotificationsPlugin,
    this._localizer,
    this._permissionChannel,
  ) : _tapController = StreamController<String>.broadcast() {
    _tapController.onListen = _flushBufferedTaps;
  }

  @override
  Stream<String> get onNotificationTap => _tapController.stream;

  @override
  Future<void> initialize() async {
    tz.initializeTimeZones();
    await _initializeLocalTimeZone();

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');
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

  /// `tz.local`'ı cihazın gerçek bölgesine kurar.
  ///
  /// Tek atışlık planlamada bu gerekmiyordu (`TZDateTime.from` anı korur), ama
  /// **tekrarlayan** planlamada plugin bölge ADINI kaydedip bir sonraki
  /// tetiklemeyi native tarafta o bölgede hesaplıyor. UTC bırakılırsa yaz saati
  /// uygulanan bölgelerde hatırlatma yılda iki kez bir saat kayar.
  Future<void> _initializeLocalTimeZone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      _localTimeZone = info.identifier;
    } catch (e) {
      // Bölge okunamazsa UTC'de kalıyoruz: bildirim yine gider, yalnız yaz
      // saati geçişinde kayabilir. Sessizce yutmuyoruz — tanılamada görünsün.
      _recordError('local timezone', e);
      _localTimeZone = tz.local.name;
    }
  }

  Future<void> _emitLaunchPayload() async {
    try {
      final details = await _flutterLocalNotificationsPlugin
          .getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        _emitTap(details?.notificationResponse?.payload);
      }
    } catch (e) {
      _recordError('launch details', e);
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
  void noteFailure(String context, Object error) => _recordError(context, error);

  void _recordError(String context, Object error) {
    _lastError = '$context: $error';
    debugPrint('Notification error — $_lastError');
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> requestPermissions() async {
    // İzin isteğinin YAPILDIĞI tek yer burası; "hiç sorulmadı" ile "kalıcı
    // reddedildi" ayrımı bu kayda dayandığı için işaretleme de burada durmalı.
    await _permissionChannel.markRequested();
    try {
      if (Platform.isIOS) {
        final granted = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? false;
      }
      if (Platform.isAndroid) {
        final granted = await _android?.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (e) {
      _recordError('requestPermissions', e);
    }
    return false;
  }

  @override
  Future<bool> canRequestPermissions() => _permissionChannel.canPrompt();

  @override
  Future<bool> openSystemNotificationSettings() =>
      _permissionChannel.openSettings();

  @override
  Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isAndroid) {
        final enabled = await _android?.areNotificationsEnabled();
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
      _recordError('areNotificationsEnabled', e);
    }
    // Masaüstü/test ortamı: izin kavramı yok, engellemeyelim.
    return true;
  }

  /// Kanalın kimliği, adı, açıklaması ve önem düzeyi tek yerde.
  /// [_detailsFor] ve [readDiagnostics] ikisi de buradan okur; kopyalanırsa
  /// tanılama, gerçekte kullanılan kanaldan farklı bir kanalı raporlar.
  ({String id, String name, String description, Importance importance})
      _channelMeta(NotificationChannelKind kind) {
    final l10n = _localizer.l10n;
    return switch (kind) {
      NotificationChannelKind.critical => (
          id: 'cunehat_critical',
          name: l10n.notifChannelCriticalName,
          description: l10n.notifChannelCriticalDesc,
          importance: Importance.max,
        ),
      NotificationChannelKind.recurring => (
          id: 'cunehat_recurring',
          name: l10n.notifChannelRecurringName,
          description: l10n.notifChannelRecurringDesc,
          importance: Importance.high,
        ),
      NotificationChannelKind.motivational => (
          id: 'cunehat_motivational',
          name: l10n.notifChannelMotivationalName,
          description: l10n.notifChannelMotivationalDesc,
          importance: Importance.defaultImportance,
        ),
    };
  }

  NotificationDetails _detailsFor(NotificationChannelKind kind) {
    final meta = _channelMeta(kind);

    return NotificationDetails(
      android: AndroidNotificationDetails(
        meta.id,
        meta.name,
        channelDescription: meta.description,
        importance: meta.importance,
        priority: meta.importance == Importance.defaultImportance
            ? Priority.defaultPriority
            : Priority.high,
        // İKİ İKON DA `res/raw/keep.xml` ile korunuyor: buradaki adlar yalnız
        // Dart string'i olduğu için kaynak küçültücü onları "kullanılmıyor"
        // sayıp release derlemesinden atıyordu (ölçüldü).
        icon: '@drawable/ic_notification',
        // Sistem küçük ikonu bu renge boyar. İkonun halkasından alındı;
        // hem açık hem koyu bildirim zemininde 3:1 üstünde.
        color: const Color(0xFF0A6CF7),
        // largeIcon BitmapFactory.decodeResource ile açılıyor; adaptive
        // ikon (@mipmap/launcher_icon) XML olduğu için sessizce null döner,
        // o yüzden ayrı bir PNG kaynağı.
        largeIcon: const DrawableResourceAndroidBitmap(
            '@drawable/ic_notification_large'),
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  /// Kanal susturulmuşsa `true`. Uygulama izni açıkken bile bu kanaldan
  /// bildirim gitmez ve `show` istisna ATMAZ — sessiz başarısızlığın kaynağı.
  Future<bool> _isChannelBlocked(String channelId) async {
    try {
      final channels = await _android?.getNotificationChannels();
      if (channels == null) return false; // Android değil ya da okunamadı.
      for (final channel in channels) {
        if (channel.id == channelId) {
          return channel.importance == Importance.none;
        }
      }
      // Kanal henüz yaratılmamış (ilk bildirimle yaratılır) → engelli değil.
      return false;
    } catch (e) {
      _recordError('getNotificationChannels', e);
      return false;
    }
  }

  /// Bildirim gerçekten gösterilenler arasında mı.
  ///
  /// `null` = doğrulanamadı (platform desteklemiyor). Doğrulanamayan durumu
  /// başarısızlık saymıyoruz: olmayan bir hata uydurmak, hatayı kaçırmaktan
  /// daha kötü.
  Future<bool?> _isActive(int id) async {
    try {
      // Sistem listeyi hemen yansıtmayabiliyor; kısa bir pencere tanı.
      for (var attempt = 0; attempt < 3; attempt++) {
        final active =
            await _flutterLocalNotificationsPlugin.getActiveNotifications();
        if (active.any((n) => n.id == id)) return true;
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      return false;
    } catch (e) {
      _recordError('getActiveNotifications', e);
      return null;
    }
  }

  @override
  Future<NotificationSendResult> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationChannelKind channel = NotificationChannelKind.critical,
  }) async {
    if (!await areNotificationsEnabled()) {
      return const NotificationSendResult.failed(
          NotificationFailure.noAppPermission);
    }

    final meta = _channelMeta(channel);
    if (await _isChannelBlocked(meta.id)) {
      return NotificationSendResult.failed(
        NotificationFailure.channelBlocked,
        detail: meta.name,
      );
    }

    try {
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        _detailsFor(channel),
        payload: payload,
      );
    } catch (e) {
      _recordError('show($id)', e);
      return NotificationSendResult.failed(
        NotificationFailure.platformError,
        detail: e.toString(),
      );
    }

    final active = await _isActive(id);
    if (active == false) {
      return const NotificationSendResult.failed(
          NotificationFailure.notDelivered);
    }
    return const NotificationSendResult.delivered();
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationChannelKind channel = NotificationChannelKind.critical,
    bool repeatDaily = false,
  }) async {
    try {
      final now = DateTime.now();
      // Tekrarlı planda tarihi biz de bugüne çekiyoruz — süsleme değil,
      // plugin'in yaptığının AYNISI (bkz. yukarıdaki uyarı). Böylece
      // tanılamadaki "sıradaki bildirim" gerçekte ne zaman çalacağını söyler;
      // ham tarihi saklasaydık 2099 yazıp yarın çalardı. Ayrıca geçmiş-tarih
      // kapısına takılmamış olur: gecikmiş kalem — hatırlatması en kritik
      // olanı — sessizce atlanıyordu.
      final effectiveDate =
          repeatDaily ? _nextDailyOccurrence(scheduledDate, now) : scheduledDate;

      if (effectiveDate.isBefore(now)) {
        debugPrint('Scheduled date is in the past, skipping notification: $id');
        return;
      }

      AndroidScheduleMode scheduleMode;
      final androidImpl = _android;
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
        tz.TZDateTime.from(effectiveDate, tz.local),
        _detailsFor(channel),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
      );
      _scheduledAt[id] = (at: effectiveDate, repeatDaily: repeatDaily);
      debugPrint('Scheduled notification $id at $effectiveDate '
          '(mode: $scheduleMode, repeatDaily: $repeatDaily)');
    } catch (e) {
      _recordError('schedule($id)', e);
    }
  }

  /// [slot]'un saat:dakikasını koruyarak [now]'dan sonraki ilk anı verir.
  ///
  /// Gün aritmetiği takvimden yapılır: yaz saati geçişinde 24 saat eklemek
  /// aynı güne düşebiliyor.
  static DateTime _nextDailyOccurrence(DateTime slot, DateTime now) {
    final today =
        DateTime(now.year, now.month, now.day, slot.hour, slot.minute);
    if (today.isAfter(now)) return today;
    return DateTime(now.year, now.month, now.day + 1, slot.hour, slot.minute);
  }

  @override
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      _scheduledAt.remove(id);
    } catch (e) {
      _recordError('cancel($id)', e);
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

  @override
  Future<void> purgeLegacyRandomReminders() async {
    // Eski sürümler bu aralığa 14 gün × 3/gün = 42 adede kadar TEK ATIŞLIK
    // rastgele plan yazıyordu. Yükselten kullanıcıda temizlenmezse yeni sabit
    // saatlerin yanında günlerce rastgele bildirim düşmeye devam eder.
    for (var i = 0; i < ReminderIds.randomReminderCapacity; i++) {
      await cancelNotification(ReminderIds.randomReminderStart + i);
    }
  }

  Future<void> _rescheduleRandomReminders(
      NotificationFrequency frequency) async {
    // Kullanılabilecek EN FAZLA kimlik kadar iptal: sıklık "çok"tan "az"a
    // düşürüldüğünde artan iki bildirim iptal edilmeden kalırdı. Aralığın
    // tamamını (60) her seferinde gezmiyoruz — plugin her iptalde planlı
    // bildirim listesinin tamamını yeniden serileştiriyor, bkz.
    // [purgeLegacyRandomReminders].
    for (var i = 0; i < maxDailyReminderSlots; i++) {
      await cancelNotification(ReminderIds.randomReminderStart + i);
    }

    final slots = frequency.dailySlots;
    if (slots.isEmpty) {
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

    final now = DateTime.now();
    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      await scheduleNotification(
        id: ReminderIds.randomReminderStart + i,
        title: l10n.notifDailyReminderTitle,
        // Mesaj slot'a göre SABİT seçilir, rastgele değil: tekrarlayan alarmın
        // metni ilk kurulumda donar, her gün yeniden seçilemez. Rastgele
        // seçmek yalnızca "hangi metinde donacağı" belirsiz olurdu.
        body: messages[i % messages.length],
        scheduledDate: DateTime(
            now.year, now.month, now.day, slot.hour, slot.minute),
        payload: NotificationPayloads.dailyReminder,
        channel: NotificationChannelKind.motivational,
        repeatDaily: true,
      );
    }
    debugPrint('Scheduled ${slots.length} daily reminders.');
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      _scheduledAt.clear();
    } catch (e) {
      _recordError('cancelAll', e);
    }
  }

  @override
  Future<NotificationDiagnostics> readDiagnostics() async {
    final appLevelEnabled = await areNotificationsEnabled();
    final canRequest = await canRequestPermissions();

    var canScheduleExact = false;
    try {
      canScheduleExact = await _android?.canScheduleExactNotifications() ?? true;
    } catch (e) {
      _recordError('canScheduleExactNotifications', e);
    }

    var pendingCount = 0;
    try {
      final pending =
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      pendingCount = pending.length;
    } catch (e) {
      _recordError('pendingNotificationRequests', e);
    }

    List<AndroidNotificationChannel>? systemChannels;
    try {
      systemChannels = await _android?.getNotificationChannels();
    } catch (e) {
      _recordError('getNotificationChannels', e);
    }

    final channels = <NotificationChannelStatus>[
      for (final kind in NotificationChannelKind.values)
        _statusFor(kind, systemChannels),
    ];

    return NotificationDiagnostics(
      appLevelEnabled: appLevelEnabled,
      canRequestPermission: canRequest,
      canScheduleExactAlarms: canScheduleExact,
      localTimeZone: _localTimeZone,
      channels: channels,
      pendingCount: pendingCount,
      nextScheduledAt: _nextScheduledAt(),
      lastError: _lastError,
    );
  }

  /// Kanalın sistemdeki karşılığını bulup kullanıcıya gösterilecek duruma
  /// çevirir. Kanal listesi okunamadıysa (Android değil) engelli sayılmaz.
  NotificationChannelStatus _statusFor(
    NotificationChannelKind kind,
    List<AndroidNotificationChannel>? systemChannels,
  ) {
    final meta = _channelMeta(kind);
    Importance? systemImportance;
    for (final channel in systemChannels ?? const <AndroidNotificationChannel>[]) {
      if (channel.id == meta.id) {
        systemImportance = channel.importance;
        break;
      }
    }
    return NotificationChannelStatus(
      kind: kind,
      id: meta.id,
      name: meta.name,
      blocked: systemImportance == Importance.none,
    );
  }

  DateTime? _nextScheduledAt() {
    final now = DateTime.now();
    DateTime? soonest;
    for (final entry in _scheduledAt.values) {
      final at = entry.repeatDaily
          ? _nextDailyOccurrence(entry.at, now)
          : entry.at;
      if (at.isBefore(now)) continue;
      if (soonest == null || at.isBefore(soonest)) soonest = at;
    }
    return soonest;
  }

  @override
  @disposeMethod
  void dispose() => _tapController.close();
}
