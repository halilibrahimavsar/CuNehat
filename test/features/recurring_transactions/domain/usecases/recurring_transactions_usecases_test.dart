import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
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

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockRecurringTransactionRepository mockRecurringRepo;
  late MockTransactionsRepository mockTxRepo;
  late MockNotificationService mockNotificationService;

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
    mockNotificationService = MockNotificationService();

    getAllTemplatesUsecase = GetAllRecurringTemplatesUsecase(mockRecurringRepo);
    getPendingUsecase =
        GetPendingRecurringTransactionsUsecase(mockRecurringRepo);
    saveUsecase = SaveRecurringTransactionUsecase(
        mockRecurringRepo, mockNotificationService);
    deleteUsecase = DeleteRecurringTransactionUsecase(
        mockRecurringRepo, mockNotificationService);
    skipUsecase = SkipRecurringTransactionUsecase(mockRecurringRepo);
    approveUsecase =
        ApproveRecurringTransactionUsecase(mockRecurringRepo, mockTxRepo);

    // Setup default mock answers for notification service since they return void
    when(() => mockNotificationService.cancelNotification(any()))
        .thenAnswer((_) async {});
    when(() => mockNotificationService.scheduleNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          payload: any(named: 'payload'),
        )).thenAnswer((_) async {});
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
    test(
        'should save template and schedule notification 1 day before execution',
        () async {
      // Arrange
      when(() => mockRecurringRepo.saveTemplate(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await saveUsecase(testTemplate);

      // Assert
      expect(result, const Right(null));
      verify(() => mockRecurringRepo.saveTemplate(testTemplate)).called(1);
      verify(() => mockNotificationService
          .cancelNotification(testTemplate.id.hashCode)).called(1);
      verify(() => mockNotificationService.scheduleNotification(
            id: testTemplate.id.hashCode,
            title: 'Düzenli İşlem Yaklaşıyor',
            body: 'Netflix Subscription başlıklı işleminizin zamanı yaklaştı.',
            scheduledDate: DateTime(2026, 6, 19),
          )).called(1);
    });

    test(
        'should return failure and not cancel/schedule notification on repository failure',
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
      verifyNever(() => mockNotificationService.cancelNotification(any()));
      verifyNever(() => mockNotificationService.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
          ));
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
      verify(() =>
              mockNotificationService.cancelNotification('rec_123'.hashCode))
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
      verifyNever(() => mockNotificationService.cancelNotification(any()));
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
          base, RecurringFrequency.daily);
      expect(next, DateTime(2026, 6, 14));
    });

    test('weekly frequency adds 7 days', () {
      final base = DateTime(2026, 6, 13);
      final next = ApproveRecurringTransactionUsecase.nextExecutionDateAfter(
          base, RecurringFrequency.weekly);
      expect(next, DateTime(2026, 6, 20));
    });

    test('monthly frequency clamps to last day of Feb (28th) on non-leap years',
        () {
      // 2027 is not a leap year, so Jan 31 + 1 month should be Feb 28
      final base = DateTime(2027, 1, 31);
      final next = ApproveRecurringTransactionUsecase.nextExecutionDateAfter(
          base, RecurringFrequency.monthly);
      expect(next, DateTime(2027, 2, 28));
    });

    test('monthly frequency clamps to last day of Feb (29th) on leap years',
        () {
      // 2028 is a leap year, so Jan 31 + 1 month should be Feb 29
      final base = DateTime(2028, 1, 31);
      final next = ApproveRecurringTransactionUsecase.nextExecutionDateAfter(
          base, RecurringFrequency.monthly);
      expect(next, DateTime(2028, 2, 29));
    });

    test(
        'yearly frequency clamps from Feb 29 on leap year to Feb 28 on non-leap year',
        () {
      // 2028 is leap year (Feb 29), 2029 is non-leap year (Feb 28)
      final base = DateTime(2028, 2, 29);
      final next = ApproveRecurringTransactionUsecase.nextExecutionDateAfter(
          base, RecurringFrequency.yearly);
      expect(next, DateTime(2029, 2, 28));
    });
  });
}
