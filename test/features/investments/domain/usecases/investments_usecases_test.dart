import 'dart:ui';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/entities/live_price_quote.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:cunehat/features/investments/domain/usecases/add_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/delete_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/get_investments_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/get_live_quote_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/update_investment_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockInvestmentRepository extends Mock implements InvestmentRepository {}

void main() {
  late MockInvestmentRepository mockRepository;
  late GetInvestmentsUseCase getInvestmentsUseCase;
  late AddInvestmentUseCase addInvestmentUseCase;
  late UpdateInvestmentUseCase updateInvestmentUseCase;
  late DeleteInvestmentUseCase deleteInvestmentUseCase;
  late GetLiveQuoteUseCase getLiveQuoteUseCase;

  setUpAll(() {
    registerFallbackValue(InvestmentType.stock);
    registerFallbackValue(
      InvestmentEntity(
        id: 'fallback_id',
        userId: 'fallback_user',
        walletId: 'fallback_wallet',
        name: 'Fallback',
        amount: 0.0,
        currentValue: 0.0,
        type: InvestmentType.stock,
        color: const Color(0xFF000000),
        dateAdded: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockRepository = MockInvestmentRepository();
    getInvestmentsUseCase = GetInvestmentsUseCase(mockRepository);
    addInvestmentUseCase = AddInvestmentUseCase(mockRepository);
    updateInvestmentUseCase = UpdateInvestmentUseCase(mockRepository);
    deleteInvestmentUseCase = DeleteInvestmentUseCase(mockRepository);
    getLiveQuoteUseCase = GetLiveQuoteUseCase(mockRepository);
  });

  final testInvestment = InvestmentEntity(
    id: 'inv_123',
    userId: 'user_123',
    walletId: 'wallet_123',
    name: 'Apple Inc.',
    amount: 1000.0,
    currentValue: 1200.0,
    type: InvestmentType.stock,
    color: const Color(0xFF00FF00),
    dateAdded: DateTime(2026, 6, 13),
    symbol: 'AAPL',
    quantity: 5,
  );

  group('GetInvestmentsUseCase', () {
    test('should return a list of investments from repository on success', () async {
      // Arrange
      final list = [testInvestment];
      when(() => mockRepository.getInvestments(
            userId: 'user_123',
            walletId: 'wallet_123',
          )).thenAnswer((_) async => Right(list));

      // Act
      final result = await getInvestmentsUseCase(
        userId: 'user_123',
        walletId: 'wallet_123',
      );

      // Assert
      expect(result.isRight(), true);
      expect((result as Right).value, list);
      verify(() => mockRepository.getInvestments(
            userId: 'user_123',
            walletId: 'wallet_123',
          )).called(1);
    });

    test('should return a failure from repository when call fails', () async {
      // Arrange
      const failure = ServerFailure('DB Error');
      when(() => mockRepository.getInvestments(
            userId: 'user_123',
            walletId: 'wallet_123',
          )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await getInvestmentsUseCase(
        userId: 'user_123',
        walletId: 'wallet_123',
      );

      // Assert
      expect(result, const Left(failure));
      verify(() => mockRepository.getInvestments(
            userId: 'user_123',
            walletId: 'wallet_123',
          )).called(1);
    });
  });

  group('AddInvestmentUseCase', () {
    test('should add investment directly when ID is provided', () async {
      // Arrange
      when(() => mockRepository.addInvestment(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await addInvestmentUseCase(testInvestment);

      // Assert
      expect(result, const Right(null));
      verify(() => mockRepository.addInvestment(testInvestment)).called(1);
    });

    test('should generate UUID v7 when ID is missing/empty', () async {
      // Arrange
      final investmentWithoutId = testInvestment.copyWith(id: '');
      when(() => mockRepository.addInvestment(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await addInvestmentUseCase(investmentWithoutId);

      // Assert
      expect(result, const Right(null));
      final captured = verify(() => mockRepository.addInvestment(captureAny()))
          .captured
          .first as InvestmentEntity;
      expect(captured.id, isNotEmpty);
      expect(captured.id, isNot(testInvestment.id));
    });

    test('should return failure when repository fails to add', () async {
      // Arrange
      const failure = ServerFailure('Add Error');
      when(() => mockRepository.addInvestment(any()))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await addInvestmentUseCase(testInvestment);

      // Assert
      expect(result, const Left(failure));
    });
  });

  group('UpdateInvestmentUseCase', () {
    test('should update investment when ID is present', () async {
      // Arrange
      when(() => mockRepository.updateInvestment(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await updateInvestmentUseCase(testInvestment);

      // Assert
      expect(result, const Right(null));
      verify(() => mockRepository.updateInvestment(testInvestment)).called(1);
    });

    test('should return ValidationFailure when ID is null/empty', () async {
      // Arrange
      final investmentWithoutId = testInvestment.copyWith(id: '');

      // Act
      final result = await updateInvestmentUseCase(investmentWithoutId);

      // Assert
      expect(result.isLeft(), true);
      expect((result as Left).value, isA<ValidationFailure>());
      verifyNever(() => mockRepository.updateInvestment(any()));
    });

    test('should return failure when repository fails to update', () async {
      // Arrange
      const failure = ServerFailure('Update Error');
      when(() => mockRepository.updateInvestment(any()))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await updateInvestmentUseCase(testInvestment);

      // Assert
      expect(result, const Left(failure));
    });
  });

  group('DeleteInvestmentUseCase', () {
    test('should call repository delete when called', () async {
      // Arrange
      when(() => mockRepository.deleteInvestment(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await deleteInvestmentUseCase('inv_123');

      // Assert
      expect(result, const Right(null));
      verify(() => mockRepository.deleteInvestment('inv_123')).called(1);
    });

    test('should return failure when repository fails to delete', () async {
      // Arrange
      const failure = ServerFailure('Delete Error');
      when(() => mockRepository.deleteInvestment(any()))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await deleteInvestmentUseCase('inv_123');

      // Assert
      expect(result, const Left(failure));
    });
  });

  group('GetLiveQuoteUseCase', () {
    test('should return LivePriceQuote when symbol is valid', () async {
      // Arrange
      const quote = LivePriceQuote(price: 180.0, currency: 'USD', priceTl: 5400.0);
      when(() => mockRepository.getLiveQuote(
            symbol: 'AAPL',
            type: InvestmentType.stock,
          )).thenAnswer((_) async => const Right(quote));

      // Act
      final result = await getLiveQuoteUseCase(
        symbol: 'AAPL',
        type: InvestmentType.stock,
      );

      // Assert
      expect(result, const Right(quote));
      verify(() => mockRepository.getLiveQuote(
            symbol: 'AAPL',
            type: InvestmentType.stock,
          )).called(1);
    });

    test('should trim symbol and query repository', () async {
      // Arrange
      const quote = LivePriceQuote(price: 180.0, currency: 'USD', priceTl: 5400.0);
      when(() => mockRepository.getLiveQuote(
            symbol: 'AAPL',
            type: InvestmentType.stock,
          )).thenAnswer((_) async => const Right(quote));

      // Act
      final result = await getLiveQuoteUseCase(
        symbol: ' AAPL ',
        type: InvestmentType.stock,
      );

      // Assert
      expect(result, const Right(quote));
      verify(() => mockRepository.getLiveQuote(
            symbol: 'AAPL',
            type: InvestmentType.stock,
          )).called(1);
    });

    test('should return ValidationFailure when symbol is empty/whitespace', () async {
      // Act
      final result = await getLiveQuoteUseCase(
        symbol: '   ',
        type: InvestmentType.stock,
      );

      // Assert
      expect(result.isLeft(), true);
      expect((result as Left).value, isA<ValidationFailure>());
      verifyNever(() => mockRepository.getLiveQuote(
            symbol: any(named: 'symbol'),
            type: any(named: 'type'),
          ));
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const failure = ServerFailure('Quote Fetch Error');
      when(() => mockRepository.getLiveQuote(
            symbol: 'AAPL',
            type: InvestmentType.stock,
          )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await getLiveQuoteUseCase(
        symbol: 'AAPL',
        type: InvestmentType.stock,
      );

      // Assert
      expect(result, const Left(failure));
    });
  });
}
