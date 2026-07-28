import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/reminder_sync_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/approve_recurring_transaction_usecase.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/delete_recurring_transaction_usecase.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/get_all_recurring_templates_usecase.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/get_pending_recurring_transactions_usecase.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/save_recurring_transaction_usecase.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/skip_recurring_transaction_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringTransactionRepository extends Mock
    implements RecurringTransactionRepository {}

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockReminderSyncService extends Mock implements ReminderSyncService {}

/// Hatırlatmaların hangi tarihte/kimlikle kurulduğu ReminderSyncService'in
/// sorumluluğu ve orada test edilir (reminder_sync_service_test.dart).
/// Burada usecase'lerin o servise doğru devrettiği doğrulanır.
void main() {
  late MockRecurringTransactionRepository mockRecurringRepo;
  late MockTransactionsRepository mockTxRepo;
  late MockReminderSyncService mockReminderSync;

  late GetAllRecurringTemplatesUsecase getAllTemplatesUsecase;
  late GetPendingRecurringTransactionsUsecase getPendingUsecase;
  late SaveRecurringTransactionUsecase saveUsecase;
  late DeleteRecurringTransactionUsecase deleteUsecase;
  late SkipRecurringTransactionUsecase skipUsecase;
  late ApproveRecurringTransactionUsecase approveUsecase;

  setUpAll(() {
    registerFallbackValue(
      RecurringTransactionEntity(
        id: 'fallback_id',
        userId: 'fallback_user',
        walletId: 'fallback_wallet',
        title: 'Fallback',
        tag: 'tag',
        amount: 0.0,
        type: TransactionTypeModel.expense,
        frequency: RecurringFrequency.monthly,
        nextExecutionDate: DateTime(2026, 1, 1),
        anchorDay: 1,
      ),
    );
    registerFallbackValue(
      TransactionEntity(
        id: 'fallback_id',
        userId: 'fallback_user',
        walletId: 'fallback_wallet',
        title: 'Fallback',
        tag: 'tag',
        amount: 0.0,
        date: DateTime(2026, 1, 1),
        type: TransactionTypeModel.expense,
      ),
    );
  });

  setUp(() {
    mockRecurringRepo = MockRecurringTransactionRepository();
    mockTxRepo = MockTransactionsRepository();
    mockReminderSync = MockReminderSyncService();

    when(() => mockReminderSync.syncRecurringTemplate(any()))
        .thenAnswer((_) async {});
    when(() => mockReminderSync.cancelRecurringReminder(any()))
        .thenAnswer((_) async {});

    getAllTemplatesUsecase = GetAllRecurringTemplatesUsecase(mockRecurringRepo);
    getPendingUsecase =
        GetPendingRecurringTransactionsUsecase(mockRecurringRepo);
    saveUsecase =
        SaveRecurringTransactionUsecase(mockRecurringRepo, mockReminderSync);
    deleteUsecase =
        DeleteRecurringTransactionUsecase(mockRecurringRepo, mockReminderSync);
    // Onay ve atlama, vadeyi ilerletirken bildirimin de yeniden kurulması
    // için kaydetme usecase'inden geçer; gerçek örnek verilerek bu zincir
    // uçtan uca doğrulanır.
    skipUsecase = SkipRecurringTransactionUsecase(saveUsecase);
    approveUsecase =
        ApproveRecurringTransactionUsecase(mockTxRepo, saveUsecase);
  });

  final testTemplate = RecurringTransactionEntity(
    id: 'rec_123',
    userId: 'user_123',
    walletId: 'wallet_123',
    title: 'Netflix Subscription',
    tag: 'Entertainment',
    amount: 15.0,
    type: TransactionTypeModel.expense,
    frequency: RecurringFrequency.monthly,
    nextExecutionDate: DateTime(2026, 6, 20),
    anchorDay: 20,
    isActive: true,
  );

  group('GetAllRecurringTemplatesUsecase', () {
    test('should return all templates from repository', () async {
      // Arrange
      final list = [testTemplate];
      when(() => mockRecurringRepo.getAllTemplates())
          .thenAnswer((_) async => Right(list));

      // Act
      final result = await getAllTemplatesUsecase();

      // Assert
      expect(result.isRight(), true);
      expect((result as Right).value, list);
      verify(() => mockRecurringRepo.getAllTemplates()).called(1);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const failure = ServerFailure('Load error');
      when(() => mockRecurringRepo.getAllTemplates())
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await getAllTemplatesUsecase();

      // Assert
      expect(result, const Left(failure));
    });
  });

  group('GetPendingRecurringTransactionsUsecase', () {
    test('should return pending transactions from repository', () async {
      // Arrange
      final list = [testTemplate];
      when(() => mockRecurringRepo.getPendingTransactions())
          .thenAnswer((_) async => Right(list));

      // Act
      final result = await getPendingUsecase();

      // Assert
      expect(result.isRight(), true);
      expect((result as Right).value, list);
      verify(() => mockRecurringRepo.getPendingTransactions()).called(1);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const failure = ServerFailure('Pending load error');
      when(() => mockRecurringRepo.getPendingTransactions())
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await getPendingUsecase();

      // Assert
      expect(result, const Left(failure));
    });
  });

  group('SaveRecurringTransactionUsecase', () {
    test('should save template and re-sync its reminder', () async {
      // Arrange
      when(() => mockRecurringRepo.saveTemplate(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await saveUsecase(testTemplate);

      // Assert
      expect(result, const Right(null));
      verify(() => mockRecurringRepo.saveTemplate(testTemplate)).called(1);
      verify(() => mockReminderSync.syncRecurringTemplate(testTemplate))
          .called(1);
    });

    test('should return failure and not touch reminders on repository failure',
        () async {
      // Arrange
      const failure = ServerFailure('Save error');
      when(() => mockRecurringRepo.saveTemplate(any()))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await saveUsecase(testTemplate);

      // Assert
      expect(result, const Left(failure));
      verify(() => mockRecurringRepo.saveTemplate(testTemplate)).called(1);
      verifyNever(() => mockReminderSync.syncRecurringTemplate(any()));
    });
  });

  group('DeleteRecurringTransactionUsecase', () {
    test('should delete template and cancel notification', () async {
      // Arrange
      when(() => mockRecurringRepo.deleteTemplate(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await deleteUsecase('rec_123');

      // Assert
      expect(result, const Right(null));
      verify(() => mockRecurringRepo.deleteTemplate('rec_123')).called(1);
      verify(() => mockReminderSync.cancelRecurringReminder('rec_123'))
          .called(1);
    });

    test(
        'should return failure and not cancel notification on repository failure',
        () async {
      // Arrange
      const failure = ServerFailure('Delete error');
      when(() => mockRecurringRepo.deleteTemplate(any()))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await deleteUsecase('rec_123');

      // Assert
      expect(result, const Left(failure));
      verify(() => mockRecurringRepo.deleteTemplate('rec_123')).called(1);
      verifyNever(() => mockReminderSync.cancelRecurringReminder(any()));
    });
  });

  group('DeleteRecurringTemplatesForWalletUsecase', () {
    late DeleteRecurringTemplatesForWalletUsecase deleteForWalletUsecase;

    setUp(() {
      deleteForWalletUsecase = DeleteRecurringTemplatesForWalletUsecase(
          mockRecurringRepo, mockReminderSync);
    });

    test(
        'should delete only the wallet\'s templates and cancel their notifications',
        () async {
      // Arrange: iki cüzdana dağılmış üç şablon
      final otherWalletTemplate =
          testTemplate.copyWith(id: 'rec_other', walletId: 'wallet_other');
      final secondTemplate = testTemplate.copyWith(id: 'rec_456');
      when(() => mockRecurringRepo.getAllTemplates()).thenAnswer((_) async =>
          Right([testTemplate, otherWalletTemplate, secondTemplate]));
      when(() => mockRecurringRepo.deleteTemplate(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await deleteForWalletUsecase('wallet_123');

      // Assert
      expect(result, const Right(null));
      verify(() => mockRecurringRepo.deleteTemplate('rec_123')).called(1);
      verify(() => mockRecurringRepo.deleteTemplate('rec_456')).called(1);
      verifyNever(() => mockRecurringRepo.deleteTemplate('rec_other'));
      verify(() => mockReminderSync.cancelRecurringReminder('rec_123'))
          .called(1);
      verify(() => mockReminderSync.cancelRecurringReminder('rec_456'))
          .called(1);
      verifyNever(() => mockReminderSync.cancelRecurringReminder('rec_other'));
    });

    test('should return failure when template listing fails', () async {
      // Arrange
      const failure = ServerFailure('List error');
      when(() => mockRecurringRepo.getAllTemplates())
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await deleteForWalletUsecase('wallet_123');

      // Assert
      expect(result, const Left(failure));
      verifyNever(() => mockRecurringRepo.deleteTemplate(any()));
      verifyNever(() => mockReminderSync.cancelRecurringReminder(any()));
    });
  });

  group('SkipRecurringTransactionUsecase', () {
    test(
        'should skip current occurrence by advancing execution date and saving',
        () async {
      // Arrange
      when(() => mockRecurringRepo.saveTemplate(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await skipUsecase(testTemplate);

      // Assert
      expect(result, const Right(null));
      // Monthly freq on June 20 -> next is July 20
      final expectedNextDate = DateTime(2026, 7, 20);
      final captured =
          verify(() => mockRecurringRepo.saveTemplate(captureAny()))
              .captured
              .first as RecurringTransactionEntity;
      expect(captured.nextExecutionDate, expectedNextDate);
      expect(captured.id, testTemplate.id);
      // Atlama şablonu doğrudan repository'ye yazarsa bir SONRAKİ vadenin
      // bildirimi hiç kurulmaz; hatırlatma zinciri orada kopuyordu.
      final synced =
          verify(() => mockReminderSync.syncRecurringTemplate(captureAny()))
              .captured
              .single as RecurringTransactionEntity;
      expect(synced.nextExecutionDate, expectedNextDate);
    });

    test('should return failure when repository save fails', () async {
      // Arrange
      const failure = ServerFailure('Skip save error');
      when(() => mockRecurringRepo.saveTemplate(any()))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await skipUsecase(testTemplate);

      // Assert
      expect(result, const Left(failure));
    });
  });

  group('ApproveRecurringTransactionUsecase', () {
    test(
        'should add a transaction, advance next execution date, and save updated template on success',
        () async {
      // Arrange
      when(() => mockTxRepo.addTransaction(any()))
          .thenAnswer((_) async => const Right('tx_new'));
      when(() => mockRecurringRepo.saveTemplate(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await approveUsecase(testTemplate);

      // Assert
      expect(result, const Right(null));

      // Verify transaction addition
      final txCaptured = verify(() => mockTxRepo.addTransaction(captureAny()))
          .captured
          .first as TransactionEntity;
      expect(txCaptured.amount, testTemplate.amount);
      expect(txCaptured.walletId, testTemplate.walletId);
      expect(txCaptured.userId, testTemplate.userId);
      expect(txCaptured.title, testTemplate.title);
      expect(txCaptured.tag, testTemplate.tag);
      expect(txCaptured.type, testTemplate.type);
      expect(txCaptured.date, testTemplate.nextExecutionDate);
      // Kuplajlı (borç/yatırım/alacak) işlemlerin aksine, onaylanan düzenli
      // işlemin izlenecek bir kaynak kaydı yok; kilitlenmemeli (bkz.
      // isSystem alanının dokümantasyonu — sadece nakit kuplajı içindir).
      expect(txCaptured.isSystem, false);

      // Verify template save with advanced execution date (June 20 -> July 20)
      final tempCaptured =
          verify(() => mockRecurringRepo.saveTemplate(captureAny()))
              .captured
              .first as RecurringTransactionEntity;
      expect(tempCaptured.nextExecutionDate, DateTime(2026, 7, 20));

      // Onaydan sonra bildirim yeni vadeye göre yeniden kurulmalı.
      final synced =
          verify(() => mockReminderSync.syncRecurringTemplate(captureAny()))
              .captured
              .single as RecurringTransactionEntity;
      expect(synced.nextExecutionDate, DateTime(2026, 7, 20));
    });

    test('should add transaction with overrideAmount when provided', () async {
      // Arrange
      when(() => mockTxRepo.addTransaction(any()))
          .thenAnswer((_) async => const Right('tx_new'));
      when(() => mockRecurringRepo.saveTemplate(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await approveUsecase(testTemplate, overrideAmount: 50.0);

      // Assert
      expect(result, const Right(null));

      // Verify transaction addition with overrideAmount
      final txCaptured = verify(() => mockTxRepo.addTransaction(captureAny()))
          .captured
          .first as TransactionEntity;
      expect(txCaptured.amount, 50.0);
    });

    test(
        'should return failure and not save template when transaction addition fails',
        () async {
      // Arrange
      const failure = ServerFailure('Tx Save Fail');
      when(() => mockTxRepo.addTransaction(any()))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await approveUsecase(testTemplate);

      // Assert
      expect(result, const Left(failure));
      verifyNever(() => mockRecurringRepo.saveTemplate(any()));
      verifyNever(() => mockReminderSync.syncRecurringTemplate(any()));
    });

    test(
        'should return failure when template save fails after successful transaction addition',
        () async {
      // Arrange
      const failure = ServerFailure('Template Save Fail');
      when(() => mockTxRepo.addTransaction(any()))
          .thenAnswer((_) async => const Right('tx_new'));
      when(() => mockRecurringRepo.saveTemplate(any()))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await approveUsecase(testTemplate);

      // Assert
      expect(result, const Left(failure));
    });
  });

  group('nextExecutionDateAfter Date Calculations', () {
    test('daily frequency adds 1 day', () {
      final base = DateTime(2026, 6, 13);
      final next = ApproveRecurringTransactionUsecase.nextExecutionDateAfter(
          base, RecurringFrequency.daily, anchorDay: base.day);
      expect(next, DateTime(2026, 6, 14));
    });

    test('weekly frequency adds 7 days', () {
      final base = DateTime(2026, 6, 13);
      final next = ApproveRecurringTransactionUsecase.nextExecutionDateAfter(
          base, RecurringFrequency.weekly, anchorDay: base.day);
      expect(next, DateTime(2026, 6, 20));
    });

    test('monthly frequency clamps to last day of Feb (28th) on non-leap years',
        () {
      // 2027 is not a leap year, so Jan 31 + 1 month should be Feb 28
      final base = DateTime(2027, 1, 31);
      final next = ApproveRecurringTransactionUsecase.nextExecutionDateAfter(
          base, RecurringFrequency.monthly, anchorDay: base.day);
      expect(next, DateTime(2027, 2, 28));
    });

    test('monthly frequency clamps to last day of Feb (29th) on leap years',
        () {
      // 2028 is a leap year, so Jan 31 + 1 month should be Feb 29
      final base = DateTime(2028, 1, 31);
      final next = ApproveRecurringTransactionUsecase.nextExecutionDateAfter(
          base, RecurringFrequency.monthly, anchorDay: base.day);
      expect(next, DateTime(2028, 2, 29));
    });

    test(
        'yearly frequency clamps from Feb 29 on leap year to Feb 28 on non-leap year',
        () {
      // 2028 is leap year (Feb 29), 2029 is non-leap year (Feb 28)
      final base = DateTime(2028, 2, 29);
      final next = ApproveRecurringTransactionUsecase.nextExecutionDateAfter(
          base, RecurringFrequency.yearly, anchorDay: base.day);
      expect(next, DateTime(2029, 2, 28));
    });
  });
}
