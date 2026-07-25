import 'package:cunehat/core/enums/notification_frequency.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/notifications/notification_constants.dart';
import 'package:cunehat/core/notifications/notification_localizer.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/services/notification_settings_service.dart';
import 'package:cunehat/core/services/reminder_sync_service.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/debt_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringTransactionRepository extends Mock
    implements RecurringTransactionRepository {}

class MockDebtRepository extends Mock implements DebtRepository {}

class MockNotificationService extends Mock implements NotificationService {}

class MockNotificationSettingsService extends Mock
    implements NotificationSettingsService {}

class MockNotificationLocalizer extends Mock implements NotificationLocalizer {}

void main() {
  late MockRecurringTransactionRepository recurringRepo;
  late MockDebtRepository debtRepo;
  late MockNotificationService notifications;
  late MockNotificationSettingsService settings;
  late MockNotificationLocalizer localizer;
  late ReminderSyncService service;
  late AppLocalizations tr;

  final template = RecurringTransactionEntity(
    id: 'rec_1',
    userId: 'u',
    walletId: 'w',
    title: 'Netflix',
    tag: 'Abonelik',
    amount: 100,
    type: TransactionTypeModel.expense,
    frequency: RecurringFrequency.monthly,
    // Testin bugüne göre "gelecek" kalması için sabit uzak tarih.
    nextExecutionDate: DateTime(2099, 6, 20),
  );

  final debt = DebtEntity(
    id: 'debt_1',
    userId: 'u',
    walletId: 'w',
    title: 'Kredi',
    counterparty: 'Banka',
    type: DebtType.bankLoan,
    principalAmount: 1000,
    interestRate: 0,
    termMonths: 12,
    startDate: DateTime(2099, 6, 1),
    dueDate: DateTime(2099, 6, 20),
    isPaid: false,
  );

  setUpAll(() {
    registerFallbackValue(NotificationChannelKind.critical);
    registerFallbackValue(NotificationFrequency.none);
  });

  setUp(() {
    tr = lookupAppLocalizations(const Locale('tr'));
    recurringRepo = MockRecurringTransactionRepository();
    debtRepo = MockDebtRepository();
    notifications = MockNotificationService();
    settings = MockNotificationSettingsService();
    localizer = MockNotificationLocalizer();

    when(() => localizer.l10n).thenReturn(tr);
    when(() => settings.isRecurringRemindersEnabled).thenReturn(true);
    when(() => settings.isDebtRemindersEnabled).thenReturn(true);
    when(() => settings.getRandomFrequency())
        .thenReturn(NotificationFrequency.none);
    when(() => notifications.cancelNotification(any()))
        .thenAnswer((_) async {});
    when(() => notifications.scheduleNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          payload: any(named: 'payload'),
          channel: any(named: 'channel'),
        )).thenAnswer((_) async {});
    when(() => notifications.scheduleRandomDailyReminders(any()))
        .thenAnswer((_) async {});

    service = ReminderSyncService(
      recurringRepo,
      debtRepo,
      notifications,
      settings,
      localizer,
    );
  });

  group('syncRecurringTemplate', () {
    test(
        'vade GÜNÜNDE (bir gün önce değil) 09:00 için, bekleyen-diyalog yüküyle '
        'planlar', () async {
      await service.syncRecurringTemplate(template);

      verify(() =>
              notifications.cancelNotification(ReminderIds.recurring('rec_1')))
          .called(1);
      verify(() => notifications.scheduleNotification(
            id: ReminderIds.recurring('rec_1'),
            title: tr.notifRecurringDueTitle,
            body: tr.notifRecurringDueBody('Netflix'),
            // Bir gün önce atılan bildirime dokunulduğunda bekleyen listesi
            // (nextExecutionDate <= now) henüz boş oluyor ve diyalog açılmıyordu.
            scheduledDate: DateTime(2099, 6, 20, kReminderHour),
            payload: NotificationPayloads.pendingRecurring,
            channel: NotificationChannelKind.recurring,
          )).called(1);
    });

    test('hatırlatmalar kapalıyken iptal eder ama yeniden kurmaz', () async {
      when(() => settings.isRecurringRemindersEnabled).thenReturn(false);

      await service.syncRecurringTemplate(template);

      verify(() =>
              notifications.cancelNotification(ReminderIds.recurring('rec_1')))
          .called(1);
      verifyNever(() => notifications.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            payload: any(named: 'payload'),
            channel: any(named: 'channel'),
          ));
    });

    test('duraklatılmış (isActive=false) şablon için planlama yapmaz',
        () async {
      await service.syncRecurringTemplate(template.copyWith(isActive: false));

      verify(() =>
              notifications.cancelNotification(ReminderIds.recurring('rec_1')))
          .called(1);
      verifyNever(() => notifications.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            payload: any(named: 'payload'),
            channel: any(named: 'channel'),
          ));
    });
  });

  group('syncDebt', () {
    test('vade öncesi ve vade günü olmak üzere iki hatırlatma kurar', () async {
      await service.syncDebt(debt);

      verify(() => notifications
          .cancelNotification(ReminderIds.debtUpcoming('debt_1'))).called(1);
      verify(() =>
              notifications.cancelNotification(ReminderIds.debtDue('debt_1')))
          .called(1);
      verify(() => notifications.scheduleNotification(
            id: ReminderIds.debtUpcoming('debt_1'),
            title: tr.notifDebtUpcomingTitle,
            body: tr.notifDebtUpcomingBody('Kredi'),
            scheduledDate: DateTime(2099, 6, 19, kReminderHour),
            payload: NotificationPayloads.debtDue,
          )).called(1);
      verify(() => notifications.scheduleNotification(
            id: ReminderIds.debtDue('debt_1'),
            title: tr.notifDebtDueTitle,
            body: tr.notifDebtDueBody('Kredi'),
            scheduledDate: DateTime(2099, 6, 20, kReminderHour),
            payload: NotificationPayloads.debtDue,
          )).called(1);
    });

    test('ödenmiş borç için yalnızca iptal eder', () async {
      await service.syncDebt(debt.copyWith(isPaid: true));

      verify(() => notifications.cancelNotification(any())).called(2);
      verifyNever(() => notifications.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            payload: any(named: 'payload'),
            channel: any(named: 'channel'),
          ));
    });

    test('borç hatırlatmaları kapalıyken planlama yapmaz', () async {
      when(() => settings.isDebtRemindersEnabled).thenReturn(false);

      await service.syncDebt(debt);

      verify(() => notifications.cancelNotification(any())).called(2);
      verifyNever(() => notifications.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            payload: any(named: 'payload'),
            channel: any(named: 'channel'),
          ));
    });
  });

  group('toplu senkronizasyon', () {
    test('ayar kapatıldığında ZATEN PLANLANMIŞ tüm hatırlatmalar iptal edilir',
        () async {
      when(() => settings.isDebtRemindersEnabled).thenReturn(false);
      when(() => debtRepo.getAllDebts()).thenAnswer((_) async => Right([debt]));

      await service.syncAllDebtReminders();

      verify(() => notifications
          .cancelNotification(ReminderIds.debtUpcoming('debt_1'))).called(1);
      verify(() =>
              notifications.cancelNotification(ReminderIds.debtDue('debt_1')))
          .called(1);
      verifyNever(() => notifications.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            payload: any(named: 'payload'),
            channel: any(named: 'channel'),
          ));
    });

    test('şablon listesi alınamazsa sessizce geçer', () async {
      when(() => recurringRepo.getAllTemplates())
          .thenAnswer((_) async => const Left(CacheFailure('boom')));

      await service.syncAllRecurringReminders();

      verifyNever(() => notifications.cancelNotification(any()));
    });

    test('syncAll üç hatırlatma türünü de tazeler', () async {
      when(() => recurringRepo.getAllTemplates())
          .thenAnswer((_) async => Right([template]));
      when(() => debtRepo.getAllDebts()).thenAnswer((_) async => Right([debt]));

      await service.syncAll();

      verify(() =>
              notifications.cancelNotification(ReminderIds.recurring('rec_1')))
          .called(1);
      verify(() => notifications
          .cancelNotification(ReminderIds.debtUpcoming('debt_1'))).called(1);
      verify(() => notifications
          .scheduleRandomDailyReminders(NotificationFrequency.none)).called(1);
    });
  });
}
