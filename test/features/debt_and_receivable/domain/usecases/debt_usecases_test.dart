import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/debt_repository.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/debt_usecases.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDebtRepository extends Mock implements DebtRepository {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockDebtRepository mockRepo;
  late MockNotificationService mockNotificationService;

  late GetDebtsUseCase getUseCase;
  late AddDebtUseCase addUseCase;
  late UpdateDebtUseCase updateUseCase;
  late DeleteDebtUseCase deleteUseCase;

  setUpAll(() {
    registerFallbackValue(
      DebtEntity(
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
    mockNotificationService = MockNotificationService();

    getUseCase = GetDebtsUseCase(mockRepo);
    addUseCase = AddDebtUseCase(mockRepo, mockNotificationService);
    updateUseCase = UpdateDebtUseCase(mockRepo, mockNotificationService);
    deleteUseCase = DeleteDebtUseCase(mockRepo, mockNotificationService);
  });

  final testDueDate = DateTime(2026, 6, 20);
  final testDebt = DebtEntity(
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
    test(
        'should assign v7 ID, save debt, and schedule notifications if not paid and has dueDate',
        () async {
      final debtWithoutId = DebtEntity(
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
        final d = inv.positionalArguments[0] as DebtEntity;
        capturedId = d.id;
        return const Right(null);
      });

      when(() => mockNotificationService.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
          )).thenAnswer((_) async {});

      final result = await addUseCase(debtWithoutId);

      expect(result, const Right<Failure, void>(null));
      expect(capturedId, isNotNull);
      expect(capturedId, isNotEmpty);

      final notifId = capturedId.hashCode;
      verify(() => mockRepo.addDebt(any())).called(1);
      verify(() => mockNotificationService.scheduleNotification(
            id: notifId,
            title: 'Borç Hatırlatması',
            body: 'Friend Loan başlıklı borcunuzun son ödeme tarihi yaklaştı.',
            scheduledDate: testDueDate.subtract(const Duration(days: 1)),
          )).called(1);

      verify(() => mockNotificationService.scheduleNotification(
            id: notifId + 1,
            title: 'Borç Son Ödeme Tarihi!',
            body: 'Friend Loan başlıklı borcunuzun son ödeme tarihi bugün.',
            scheduledDate: testDueDate,
          )).called(1);
    });

    test('should save debt but NOT schedule notifications if dueDate is null',
        () async {
      final debtNoDueDate = DebtEntity(
        id: 'debt_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Friend Loan',
        counterparty: 'John',
        type: DebtType.personalDebt,
        principalAmount: 1000.0,
        interestRate: 0,
        termMonths: 1,
        startDate: DateTime(2026, 6, 13),
        dueDate: null,
        isPaid: false,
      );

      when(() => mockRepo.addDebt(debtNoDueDate))
          .thenAnswer((_) async => const Right(null));

      final result = await addUseCase(debtNoDueDate);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRepo.addDebt(debtNoDueDate)).called(1);
      verifyZeroInteractions(mockNotificationService);
    });
  });

  group('UpdateDebtUseCase', () {
    test('should return Left(ValidationFailure) when ID is null', () async {
      final debtWithNullId = DebtEntity(
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
      verifyZeroInteractions(mockNotificationService);
    });

    test('should cancel old notifications and schedule new ones if not paid',
        () async {
      when(() => mockRepo.updateDebt(testDebt))
          .thenAnswer((_) async => const Right(null));
      when(() => mockNotificationService.cancelNotification(any()))
          .thenAnswer((_) async {});
      when(() => mockNotificationService.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
          )).thenAnswer((_) async {});

      final result = await updateUseCase(testDebt);

      expect(result, const Right<Failure, void>(null));

      final notifId = testDebt.id.hashCode;
      verify(() => mockRepo.updateDebt(testDebt)).called(1);
      verify(() => mockNotificationService.cancelNotification(notifId))
          .called(1);
      verify(() => mockNotificationService.cancelNotification(notifId + 1))
          .called(1);
      verify(() => mockNotificationService.scheduleNotification(
            id: notifId,
            title: 'Borç Hatırlatması',
            body: 'Bank Loan başlıklı borcunuzun son ödeme tarihi yaklaştı.',
            scheduledDate: testDueDate.subtract(const Duration(days: 1)),
          )).called(1);
      verify(() => mockNotificationService.scheduleNotification(
            id: notifId + 1,
            title: 'Borç Son Ödeme Tarihi!',
            body: 'Bank Loan başlıklı borcunuzun son ödeme tarihi bugün.',
            scheduledDate: testDueDate,
          )).called(1);
    });
  });

  group('DeleteDebtUseCase', () {
    test('should delete debt and cancel notifications', () async {
      when(() => mockRepo.deleteDebt('debt_123'))
          .thenAnswer((_) async => const Right(null));
      when(() => mockNotificationService.cancelNotification(any()))
          .thenAnswer((_) async {});

      final result = await deleteUseCase('debt_123');

      expect(result, const Right<Failure, void>(null));

      final notifId = 'debt_123'.hashCode;
      verify(() => mockRepo.deleteDebt('debt_123')).called(1);
      verify(() => mockNotificationService.cancelNotification(notifId))
          .called(1);
      verify(() => mockNotificationService.cancelNotification(notifId + 1))
          .called(1);
    });
  });
}
