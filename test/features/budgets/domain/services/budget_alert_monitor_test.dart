import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/services/notification_settings_service.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/services/budget_alert_monitor.dart';
import 'package:cunehat/features/budgets/domain/usecases/get_budgets_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetBudgetsUsecase extends Mock implements GetBudgetsUsecase {}

class MockNotificationService extends Mock implements NotificationService {}

class MockNotificationSettingsService extends Mock
    implements NotificationSettingsService {}

void main() {
  late MockGetBudgetsUsecase mockGetBudgets;
  late MockNotificationService mockNotifications;
  late MockNotificationSettingsService mockNotificationSettings;
  late TransactionsChangedNotifier notifier;
  late BudgetAlertMonitor monitor;

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
        )).thenAnswer((_) async {});
  }

  setUp(() {
    mockGetBudgets = MockGetBudgetsUsecase();
    mockNotifications = MockNotificationService();
    mockNotificationSettings = MockNotificationSettingsService();
    when(() => mockNotificationSettings.isBudgetAlertsEnabled)
        .thenReturn(true);
    notifier = TransactionsChangedNotifier();
    monitor = BudgetAlertMonitor(
        mockGetBudgets, mockNotifications, mockNotificationSettings, notifier);
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
          id: 'Food'.hashCode,
          title: 'Bütçe Uyarısı',
          body: 'Dikkat: Bütçenizin %80\'ine ulaştınız.',
        )).called(1);
  });

  test('aşımda exceeded bildirimi', () async {
    when(() => mockGetBudgets('u', 'w'))
        .thenAnswer((_) async => Right([b('Food', 100, 120)]));
    stubNotify();

    notifier.notify(userId: 'u', walletId: 'w');
    await settle();

    verify(() => mockNotifications.showNotification(
          id: 'Food'.hashCode,
          title: 'Bütçe Aşıldı!',
          body: 'Dikkat: Bütçenizi aştınız!',
        )).called(1);
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
        )).called(1);
  });
}
