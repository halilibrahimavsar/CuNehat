import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/reminder_sync_service.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/debt_repository.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/debt_usecases.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDebtRepository extends Mock implements DebtRepository {}

class MockReminderSyncService extends Mock implements ReminderSyncService {}

/// Hatırlatmaların NE ZAMAN/hangi kimlikle kurulduğu ReminderSyncService'in
/// sorumluluğu ve orada test edilir (reminder_sync_service_test.dart).
/// Burada yalnızca usecase'lerin o servise doğru şekilde devrettiği doğrulanır.
void main() {
  late MockDebtRepository mockRepo;
  late MockReminderSyncService mockReminderSync;

  late GetDebtsUseCase getUseCase;
  late AddDebtUseCase addUseCase;
  late UpdateDebtUseCase updateUseCase;
  late DeleteDebtUseCase deleteUseCase;

  setUpAll(() {
    registerFallbackValue(
      DebtEntity(
        calcMode: DebtCalcMode.none,
        expectedTotalAmount: 0,
        id: 'fallback_id',
        userId: 'fallback_user',
        walletId: 'fallback_wallet',
        title: 'Fallback',
        counterparty: 'counterparty',
        type: DebtType.personalDebt,
        principalAmount: 0,
        interestRate: 0,
        termMonths: 1,
        startDate: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockRepo = MockDebtRepository();
    mockReminderSync = MockReminderSyncService();

    when(() => mockReminderSync.syncDebt(any())).thenAnswer((_) async {});
    when(() => mockReminderSync.cancelDebtReminders(any()))
        .thenAnswer((_) async {});

    getUseCase = GetDebtsUseCase(mockRepo);
    addUseCase = AddDebtUseCase(mockRepo, mockReminderSync);
    updateUseCase = UpdateDebtUseCase(mockRepo, mockReminderSync);
    deleteUseCase = DeleteDebtUseCase(mockRepo, mockReminderSync);
  });

  final testDueDate = DateTime(2026, 6, 20);
  final testDebt = DebtEntity(
    calcMode: DebtCalcMode.none,
    expectedTotalAmount: 5000.0,
    id: 'debt_123',
    userId: 'user_123',
    walletId: 'wallet_123',
    title: 'Bank Loan',
    counterparty: 'Garanti Bank',
    type: DebtType.bankLoan,
    principalAmount: 5000.0,
    interestRate: 1.5,
    termMonths: 12,
    startDate: DateTime(2026, 6, 13),
    dueDate: testDueDate,
    isPaid: false,
  );

  group('GetDebtsUseCase', () {
    test('should return Right(List<DebtEntity>) when query succeeds', () async {
      final list = [testDebt];
      when(() => mockRepo.getDebtsByWalletId('wallet_123'))
          .thenAnswer((_) async => Right(list));

      final result = await getUseCase('wallet_123');

      expect(result, Right<Failure, List<DebtEntity>>(list));
      verify(() => mockRepo.getDebtsByWalletId('wallet_123')).called(1);
    });
  });

  group('AddDebtUseCase', () {
    test('should assign v7 ID, save debt, and sync its reminders', () async {
      final debtWithoutId = DebtEntity(
        calcMode: DebtCalcMode.none,
        expectedTotalAmount: 1000.0,
        id: null,
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Friend Loan',
        counterparty: 'John',
        type: DebtType.personalDebt,
        principalAmount: 1000.0,
        interestRate: 0,
        termMonths: 1,
        startDate: DateTime(2026, 6, 13),
        dueDate: testDueDate,
        isPaid: false,
      );

      String? capturedId;
      when(() => mockRepo.addDebt(any())).thenAnswer((inv) async {
        capturedId = (inv.positionalArguments[0] as DebtEntity).id;
        return const Right(null);
      });

      final result = await addUseCase(debtWithoutId);

      expect(result, const Right<Failure, void>(null));
      expect(capturedId, isNotNull);
      expect(capturedId, isNotEmpty);
      verify(() => mockRepo.addDebt(any())).called(1);

      // Kaydedilen kayıtla AYNI kimliğe sahip borç senkronize edilmeli;
      // aksi halde hatırlatma başka bir kimlikle kurulup iptal edilemezdi.
      final synced = verify(() => mockReminderSync.syncDebt(captureAny()))
          .captured
          .single as DebtEntity;
      expect(synced.id, capturedId);
    });

    test('should not sync reminders when repository fails', () async {
      const failure = CacheFailure('Add error');
      when(() => mockRepo.addDebt(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await addUseCase(testDebt);

      expect(result, const Left<Failure, void>(failure));
      verifyNever(() => mockReminderSync.syncDebt(any()));
    });
  });

  group('UpdateDebtUseCase', () {
    test('should return Left(ValidationFailure) when ID is null', () async {
      final debtWithNullId = DebtEntity(
        calcMode: DebtCalcMode.none,
        expectedTotalAmount: 100,
        id: null,
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Title',
        counterparty: 'Counterparty',
        type: DebtType.personalDebt,
        principalAmount: 100,
        interestRate: 0,
        termMonths: 1,
        startDate: DateTime(2026, 6, 13),
      );

      final result = await updateUseCase(debtWithNullId);

      expect(
          result,
          const Left<Failure, void>(ValidationFailure(
              'Debt ID cannot be null for update operation')));
      verifyZeroInteractions(mockRepo);
      verifyZeroInteractions(mockReminderSync);
    });

    test('should save and re-sync reminders', () async {
      when(() => mockRepo.updateDebt(testDebt))
          .thenAnswer((_) async => const Right(null));

      final result = await updateUseCase(testDebt);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRepo.updateDebt(testDebt)).called(1);
      verify(() => mockReminderSync.syncDebt(testDebt)).called(1);
    });

    test('should not sync reminders when repository fails', () async {
      const failure = CacheFailure('Update error');
      when(() => mockRepo.updateDebt(testDebt))
          .thenAnswer((_) async => const Left(failure));

      final result = await updateUseCase(testDebt);

      expect(result, const Left<Failure, void>(failure));
      verifyNever(() => mockReminderSync.syncDebt(any()));
    });
  });

  group('DeleteDebtUseCase', () {
    test('should delete debt and cancel its reminders', () async {
      when(() => mockRepo.deleteDebt('debt_123'))
          .thenAnswer((_) async => const Right(null));

      final result = await deleteUseCase('debt_123');

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRepo.deleteDebt('debt_123')).called(1);
      verify(() => mockReminderSync.cancelDebtReminders('debt_123')).called(1);
    });

    test('should not cancel reminders when repository fails', () async {
      const failure = CacheFailure('Delete error');
      when(() => mockRepo.deleteDebt('debt_123'))
          .thenAnswer((_) async => const Left(failure));

      final result = await deleteUseCase('debt_123');

      expect(result, const Left<Failure, void>(failure));
      verifyNever(() => mockReminderSync.cancelDebtReminders(any()));
    });
  });
}
