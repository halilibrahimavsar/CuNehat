import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/notifications/notification_constants.dart';
import 'package:cunehat/core/notifications/notification_localizer.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/services/notification_settings_service.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/services/budget_alert_monitor.dart';
import 'package:cunehat/features/budgets/domain/usecases/get_budgets_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGetBudgetsUsecase extends Mock implements GetBudgetsUsecase {}

class MockNotificationService extends Mock implements NotificationService {}

class MockNotificationSettingsService extends Mock
    implements NotificationSettingsService {}

class MockNotificationLocalizer extends Mock implements NotificationLocalizer {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGetBudgetsUsecase mockGetBudgets;
  late MockNotificationService mockNotifications;
  late MockNotificationSettingsService mockNotificationSettings;
  late MockNotificationLocalizer mockLocalizer;
  late TransactionsChangedNotifier notifier;
  late SharedPreferences prefs;
  late BudgetAlertMonitor monitor;
  late AppLocalizations tr;

  BudgetEntity b(String cat, double limit, double spent) =>
      BudgetEntity(categoryId: cat, limitAmount: limit, spentAmount: spent);

  // Async stream dinleyicisinin tamamlanmasını bekle.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 10));

  void stubNotify() {
    when(() => mockNotifications.showNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        )).thenAnswer((_) async {});
  }

  BudgetAlertMonitor buildMonitor() => BudgetAlertMonitor(
        mockGetBudgets,
        mockNotifications,
        mockNotificationSettings,
        mockLocalizer,
        prefs,
        notifier,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tr = lookupAppLocalizations(const Locale('tr'));

    mockGetBudgets = MockGetBudgetsUsecase();
    mockNotifications = MockNotificationService();
    mockNotificationSettings = MockNotificationSettingsService();
    mockLocalizer = MockNotificationLocalizer();
    when(() => mockLocalizer.l10n).thenReturn(tr);
    when(() => mockNotificationSettings.isBudgetAlertsEnabled).thenReturn(true);
    notifier = TransactionsChangedNotifier();
    monitor = buildMonitor();
  });

  tearDown(() {
    monitor.dispose();
    notifier.dispose();
  });

  test('cüzdan bağlamı yoksa (walletId null) bütçe sorgulanmaz, bildirim yok',
      () async {
    notifier.notify();
    await settle();
    verifyNever(() => mockGetBudgets(any(), any()));
    verifyZeroInteractions(mockNotifications);
  });

  test('eşik geçişinde uyarı bildirimi (ilk kez: önceki 0 kabul)', () async {
    when(() => mockGetBudgets('u', 'w'))
        .thenAnswer((_) async => Right([b('Food', 100, 85)]));
    stubNotify();

    notifier.notify(userId: 'u', walletId: 'w');
    await settle();

    verify(() => mockNotifications.showNotification(
          id: ReminderIds.budget('w', 'Food'),
          title: tr.notifBudgetWarningTitle,
          body: tr.notifBudgetWarningBody('Food'),
          payload: NotificationPayloads.budgetAlert,
        )).called(1);
  });

  test('aşımda exceeded bildirimi', () async {
    when(() => mockGetBudgets('u', 'w'))
        .thenAnswer((_) async => Right([b('Food', 100, 120)]));
    stubNotify();

    notifier.notify(userId: 'u', walletId: 'w');
    await settle();

    verify(() => mockNotifications.showNotification(
          id: ReminderIds.budget('w', 'Food'),
          title: tr.notifBudgetExceededTitle,
          body: tr.notifBudgetExceededBody('Food'),
          payload: NotificationPayloads.budgetAlert,
        )).called(1);
  });

  test('aynı kategori iki cüzdanda farklı bildirim kimliği alır', () {
    // Bütçeler cüzdan bazlı; yalnız categoryId kullanılsaydı ikinci cüzdanın
    // uyarısı birincinin üstüne yazardı (Android'de aynı id = replace).
    expect(
      ReminderIds.budget('w1', 'Food'),
      isNot(ReminderIds.budget('w2', 'Food')),
    );
  });

  test('bütçe uyarıları ayardan kapatılınca bildirim gönderilmez', () async {
    when(() => mockNotificationSettings.isBudgetAlertsEnabled)
        .thenReturn(false);
    when(() => mockGetBudgets('u', 'w'))
        .thenAnswer((_) async => Right([b('Food', 100, 120)]));

    notifier.notify(userId: 'u', walletId: 'w');
    await settle();

    verifyZeroInteractions(mockNotifications);
  });

  test('band içinde ikinci değişimde tekrar bildirim yok (önceki takip)',
      () async {
    stubNotify();

    when(() => mockGetBudgets('u', 'w'))
        .thenAnswer((_) async => Right([b('Food', 100, 85)]));
    notifier.notify(userId: 'u', walletId: 'w');
    await settle();

    // 90% — hâlâ band içinde, yeni geçiş yok
    when(() => mockGetBudgets('u', 'w'))
        .thenAnswer((_) async => Right([b('Food', 100, 90)]));
    notifier.notify(userId: 'u', walletId: 'w');
    await settle();

    verify(() => mockNotifications.showNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        )).called(1);
  });

  test('temel durum diske yazılır: yeni oturumda aynı eşik tekrar bildirilmez',
      () async {
    stubNotify();
    when(() => mockGetBudgets('u', 'w'))
        .thenAnswer((_) async => Right([b('Food', 100, 85)]));

    notifier.notify(userId: 'u', walletId: 'w');
    await settle();

    // Uygulama yeniden başlatıldı: monitör yeniden kuruluyor. Temel durum
    // yalnız bellekte tutulsaydı "önceki oran 0" varsayımıyla her oturumun
    // ilk işleminde aynı uyarı tekrar giderdi.
    monitor.dispose();
    monitor = buildMonitor();

    notifier.notify(userId: 'u', walletId: 'w');
    await settle();

    verify(() => mockNotifications.showNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        )).called(1);
  });

  test('yeni oturumda eşik gerçekten aşılırsa bildirim gider', () async {
    stubNotify();
    when(() => mockGetBudgets('u', 'w'))
        .thenAnswer((_) async => Right([b('Food', 100, 85)]));
    notifier.notify(userId: 'u', walletId: 'w');
    await settle();

    monitor.dispose();
    monitor = buildMonitor();

    when(() => mockGetBudgets('u', 'w'))
        .thenAnswer((_) async => Right([b('Food', 100, 130)]));
    notifier.notify(userId: 'u', walletId: 'w');
    await settle();

    verify(() => mockNotifications.showNotification(
          id: ReminderIds.budget('w', 'Food'),
          title: tr.notifBudgetExceededTitle,
          body: tr.notifBudgetExceededBody('Food'),
          payload: NotificationPayloads.budgetAlert,
        )).called(1);
  });
}
