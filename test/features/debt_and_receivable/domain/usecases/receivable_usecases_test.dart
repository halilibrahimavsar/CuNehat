import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/receivable_repository.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/receivable_usecases.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReceivableRepository extends Mock implements ReceivableRepository {}

void main() {
  late MockReceivableRepository mockRepo;

  late GetReceivablesUseCase getUseCase;
  late AddReceivableUseCase addUseCase;
  late UpdateReceivableUseCase updateUseCase;
  late DeleteReceivableUseCase deleteUseCase;

  setUpAll(() {
    registerFallbackValue(
      ReceivableEntity(
        id: 'fallback_id',
        userId: 'fallback_user',
        walletId: 'fallback_wallet',
        debtorName: 'Debtor',
        amount: 0,
        dueDate: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockRepo = MockReceivableRepository();

    getUseCase = GetReceivablesUseCase(mockRepo);
    addUseCase = AddReceivableUseCase(mockRepo);
    updateUseCase = UpdateReceivableUseCase(mockRepo);
    deleteUseCase = DeleteReceivableUseCase(mockRepo);
  });

  final testDueDate = DateTime(2026, 6, 20);
  final testReceivable = ReceivableEntity(
    id: 'receivable_123',
    userId: 'user_123',
    walletId: 'wallet_123',
    debtorName: 'Alice',
    amount: 1200.0,
    dueDate: testDueDate,
    isPaid: false,
  );

  group('GetReceivablesUseCase', () {
    test('should return Right(List<ReceivableEntity>) when query succeeds',
        () async {
      final list = [testReceivable];
      when(() => mockRepo.getReceivablesByWalletId('wallet_123'))
          .thenAnswer((_) async => Right(list));

      final result = await getUseCase('wallet_123');

      expect(result, Right<Failure, List<ReceivableEntity>>(list));
      verify(() => mockRepo.getReceivablesByWalletId('wallet_123')).called(1);
    });
  });

  group('AddReceivableUseCase', () {
    test('should assign v7 ID and save receivable', () async {
      final recWithoutId = ReceivableEntity(
        id: null,
        userId: 'user_123',
        walletId: 'wallet_123',
        debtorName: 'Alice',
        amount: 1000.0,
        dueDate: testDueDate,
      );

      String? capturedId;
      when(() => mockRepo.addReceivable(any())).thenAnswer((inv) async {
        final r = inv.positionalArguments[0] as ReceivableEntity;
        capturedId = r.id;
        return const Right(null);
      });

      final result = await addUseCase(recWithoutId);

      expect(result, const Right<Failure, void>(null));
      expect(capturedId, isNotNull);
      expect(capturedId, isNotEmpty);
      verify(() => mockRepo.addReceivable(any())).called(1);
    });
  });

  group('UpdateReceivableUseCase', () {
    test('should return Left(ValidationFailure) when ID is null', () async {
      final recWithNullId = ReceivableEntity(
        id: null,
        userId: 'user_123',
        walletId: 'wallet_123',
        debtorName: 'Debtor',
        amount: 100,
        dueDate: testDueDate,
      );

      final result = await updateUseCase(recWithNullId);

      expect(
          result,
          const Left<Failure, void>(ValidationFailure(
              'Receivable ID cannot be null for update operation')));
      verifyZeroInteractions(mockRepo);
    });

    test('should update receivable successfully', () async {
      when(() => mockRepo.updateReceivable(testReceivable))
          .thenAnswer((_) async => const Right(null));

      final result = await updateUseCase(testReceivable);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRepo.updateReceivable(testReceivable)).called(1);
    });
  });

  group('DeleteReceivableUseCase', () {
    test('should delete receivable successfully', () async {
      when(() => mockRepo.deleteReceivable('receivable_123'))
          .thenAnswer((_) async => const Right(null));

      final result = await deleteUseCase('receivable_123');

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRepo.deleteReceivable('receivable_123')).called(1);
    });
  });
}
