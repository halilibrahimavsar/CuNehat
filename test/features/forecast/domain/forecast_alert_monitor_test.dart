import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/notifications/notification_constants.dart';
import 'package:cunehat/core/notifications/notification_localizer.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/services/notification_settings_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/forecast/data/forecast_service.dart';
import 'package:cunehat/features/forecast/domain/forecast_alert_monitor.dart';
import 'package:cunehat/features/forecast/domain/forecast_engine.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart'
    show AmountVisibilityCubit;

class _MockNotifications extends Mock implements NotificationService {}

class _MockWallets extends Mock implements WalletRepository {}

class _FakeForecasts extends Fake implements ForecastService {
  double balance;
  int calls = 0;
  _FakeForecasts(this.balance);

  @override
  Future<ForecastResult> forecast({
    required String? userId,
    required DateTimeRange period,
    DateTimeRange? previousPeriod,
    DateTime? today,
    int horizonDays = 30,
  }) async {
    calls++;
    final at = today!;
    return ForecastResult(
      wallets: ForecastEngine(today: at, period: period).projectAll([
        WalletForecastInput(
          wallet: _wallet(balance),
          ledger: [
            for (var i = 0; i < 28; i++)
              TransactionEntity(
                id: '$i',
                userId: 'u',
                walletId: 'w',
                title: 'x',
                tag: 'food',
                amount: 100,
                date: DateTime(2026, 10, 13 + i, 12),
                type: TransactionTypeModel.expense,
              ),
          ],
          templates: [
            RecurringTransactionEntity(
              id: 'rent',
              userId: 'u',
              walletId: 'w',
              title: 'Kira',
              tag: 'rent',
              amount: 8000,
              type: TransactionTypeModel.expense,
              frequency: RecurringFrequency.monthly,
              nextExecutionDate: DateTime(2026, 11, 18),
              anchorDay: 18,
            ),
          ],
        ),
      ]),
      categories: const [],
    );
  }
}

WalletEntity _wallet(double balance) => WalletEntity(
      id: 'w',
      userId: 'u',
      name: 'Maaş hesabı',
      balance: balance,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '0xFF000000',
      iconName: 'x',
      createdAt: DateTime(2026, 1, 1),
      openingBalance: 0,
      isActive: true,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockNotifications notifications;
  late _MockWallets wallets;
  late SharedPreferences prefs;
  late NotificationSettingsService settings;
  late AppLocalizations tr;
  late DateTime now;

  setUpAll(() async {
    // Uygulama açılışta yükler (AppInitialization); monitör widget ağacının
    // dışında biçimlendirir.
    await initializeDateFormatting('tr_TR');
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(NotificationChannelKind.critical);
  });

  setUp(() async {
    Intl.defaultLocale = 'tr_TR';
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    settings = NotificationSettingsService(prefs);
    tr = lookupAppLocalizations(const Locale('tr'));
    notifications = _MockNotifications();
    wallets = _MockWallets();
    when(() => wallets.getAllWallets())
        .thenAnswer((_) async => Right([_wallet(1000)]));
    when(() => notifications.showNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
          channel: any(named: 'channel'),
        )).thenAnswer((_) async => const NotificationSendResult.delivered());
    when(() => notifications.scheduleNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          payload: any(named: 'payload'),
          channel: any(named: 'channel'),
          repeatDaily: any(named: 'repeatDaily'),
        )).thenAnswer((_) async {});
    when(() => notifications.cancelNotification(any()))
        .thenAnswer((_) async {});
    now = DateTime(2026, 11, 10, 20);
  });

  ForecastAlertMonitor build(ForecastService forecasts,
          {AmountVisibilityCubit? visibility}) =>
      ForecastAlertMonitor.forTest(
        forecasts,
        notifications,
        settings,
        NotificationLocalizer(prefs),
        prefs,
        wallets,
        visibility ?? AmountVisibilityCubit(),
        clock: () => now,
      );

  void verifyNoWarning() => verifyNever(() => notifications.showNotification(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
        channel: any(named: 'channel'),
      ));

  test('haftalık özet varsayılan AÇIK (kullanıcı kararı)', () {
    expect(settings.isWeeklyDigestEnabled, isTrue);
    expect(settings.isForecastWarningsEnabled, isTrue);
  });

  test('iki ayar da kapalıysa tahmin HESAPLANMAZ, planlı özet iptal edilir',
      () async {
    await settings.setForecastWarningsEnabled(false);
    await settings.setWeeklyDigestEnabled(false);
    final forecasts = _FakeForecasts(1000);
    await build(forecasts).run();

    expect(forecasts.calls, 0);
    verify(() => notifications.cancelNotification(ReminderIds.weeklyDigest))
        .called(1);
    verify(() =>
            notifications.cancelNotification(ReminderIds.weeklyDigestStale))
        .called(1);
    verifyNoWarning();
  });

  test('nakit uyarısı bir kez gider; aynı olay ertesi gün TEKRAR gitmez',
      () async {
    final monitor = build(_FakeForecasts(1000));
    await monitor.run();

    // 1.000 − 100/gün → 19 Kas (kira 18'inde 8.000 → 18 Kas).
    verify(() => notifications.showNotification(
          id: ReminderIds.forecastWarning('cash:w:2026-11'),
          title: tr.notifForecastCashTitle,
          body: tr.notifForecastCashBody('Maaş hesabı', '18 Kas'),
          payload: NotificationPayloads.forecast,
        )).called(1);

    now = DateTime(2026, 11, 11, 20);
    await monitor.run();
    verifyNoWarning();
  });

  test('günde en fazla BİR uyarı', () async {
    final monitor = build(_FakeForecasts(1000));
    await monitor.run();
    clearInteractions(notifications);
    // Aynı gün başka bir olay oluşsa da (yeni anahtar) ikinci uyarı yok.
    await prefs.setString(ForecastAlertMonitor.sentKey, '[]');
    await monitor.run();
    verifyNoWarning();
  });

  test('teslim edilemeyen uyarı "gönderildi" sayılmaz', () async {
    when(() => notifications.showNotification(
              id: any(named: 'id'),
              title: any(named: 'title'),
              body: any(named: 'body'),
              payload: any(named: 'payload'),
              channel: any(named: 'channel'),
            ))
        .thenAnswer((_) async => const NotificationSendResult.failed(
            NotificationFailure.noAppPermission));
    await build(_FakeForecasts(1000)).run();

    expect(prefs.getString(ForecastAlertMonitor.sentKey), isNull);
    expect(prefs.getString(ForecastAlertMonitor.lastDayKey), isNull);
  });

  test(
      'haftalık özet: Pazartesi 09:00 TEK ATIŞLIK + bir hafta sonrasına '
      '"kayıt yok" yedeği; önce eskiler iptal', () async {
    await settings.setForecastWarningsEnabled(false);
    await build(_FakeForecasts(20000)).run();

    final captured = verify(() => notifications.scheduleNotification(
          id: captureAny(named: 'id'),
          title: captureAny(named: 'title'),
          body: captureAny(named: 'body'),
          scheduledDate: captureAny(named: 'scheduledDate'),
          payload: NotificationPayloads.forecast,
          channel: NotificationChannelKind.motivational,
        )).captured;
    expect(captured, hasLength(8));
    // Önce "kayıt yok" yedeği (her durumda), sonra asıl özet.
    expect(captured[0], ReminderIds.weeklyDigestStale);
    expect(captured[1], tr.notifDigestStaleTitle);
    expect(captured[3], DateTime(2026, 11, 23, 9));
    expect(captured[4], ReminderIds.weeklyDigest);
    expect(captured[5], tr.notifDigestTitle);
    // Haftanın tek planlı ödemesi: 18 Kas kirası.
    expect(captured[6], contains(tr.notifDigestPayments(1, '8.000,00 ₺')));
    expect(captured[7], DateTime(2026, 11, 16, 9));
    verify(() => notifications.cancelNotification(ReminderIds.weeklyDigest))
        .called(1);
  });

  test('tutarlar gizliyken özet tutar YAZMAZ', () async {
    SharedPreferences.setMockInitialValues({'amount_visibility': false});
    prefs = await SharedPreferences.getInstance();
    settings = NotificationSettingsService(prefs);
    await settings.setForecastWarningsEnabled(false);
    await settings.setWeeklyDigestEnabled(true);
    final visibility = AmountVisibilityCubit();
    await Future<void>.delayed(Duration.zero);
    expect(visibility.state, isFalse);

    await build(_FakeForecasts(20000), visibility: visibility).run();

    final body = verify(() => notifications.scheduleNotification(
          id: ReminderIds.weeklyDigest,
          title: any(named: 'title'),
          body: captureAny(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          payload: any(named: 'payload'),
          channel: any(named: 'channel'),
        )).captured.single as String;
    expect(body, isNot(contains('8.000')));
    expect(body, contains('****'));
  });

  test(
      'söyleyecek bir şey yoksa (hız yok, plan yok) asıl özet GİTMEZ; '
      '"kayıt yok" yedeği yine kurulur', () async {
    await settings.setForecastWarningsEnabled(false);
    await build(_EmptyForecasts()).run();

    verify(() => notifications.scheduleNotification(
          id: ReminderIds.weeklyDigestStale,
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          payload: any(named: 'payload'),
          channel: any(named: 'channel'),
        )).called(1);
    verifyNever(() => notifications.scheduleNotification(
          id: ReminderIds.weeklyDigest,
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          payload: any(named: 'payload'),
          channel: any(named: 'channel'),
        ));
  });
}

/// Yeni kurulum: tek cüzdan, kayıt yok, şablon yok.
class _EmptyForecasts extends Fake implements ForecastService {
  @override
  Future<ForecastResult> forecast({
    required String? userId,
    required DateTimeRange period,
    DateTimeRange? previousPeriod,
    DateTime? today,
    int horizonDays = 30,
  }) async =>
      ForecastResult(
        wallets: ForecastEngine(today: today!, period: period).projectAll([
          WalletForecastInput(wallet: _wallet(0), ledger: const []),
        ]),
        categories: const [],
      );
}
