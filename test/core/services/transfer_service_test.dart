import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/core/services/transfer_service.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWalletMetricsService extends Mock implements WalletMetricsService {}

class MockExchangeRateService extends Mock implements ExchangeRateService {}

void main() {
  late MockWalletMetricsService metrics;
  late MockExchangeRateService fx;
  late TransferService service;

  WalletEntity wallet(String id, {String currency = 'TRY'}) => WalletEntity(
        id: id,
        userId: 'u',
        name: 'W$id',
        balance: 1000,
        debt: 0,
        credit: 0,
        investment: 0,
        colorHex: '0xFF2196F3',
        iconName: 'wallet',
        createdAt: DateTime(2026, 1, 1),
        currency: currency,
      );

  setUp(() {
    metrics = MockWalletMetricsService();
    fx = MockExchangeRateService();
    service =
        TransferService(walletMetricsService: metrics, exchangeRateService: fx);
  });

  void stubMovement({bool income = true, bool expense = true}) {
    when(() => metrics.recordCashMovement(
          walletId: any(named: 'walletId'),
          userId: any(named: 'userId'),
          amount: any(named: 'amount'),
          isIncome: false,
          title: any(named: 'title'),
          tag: any(named: 'tag'),
          date: any(named: 'date'),
        )).thenAnswer((_) async => expense);
    when(() => metrics.recordCashMovement(
          walletId: any(named: 'walletId'),
          userId: any(named: 'userId'),
          amount: any(named: 'amount'),
          isIncome: true,
          title: any(named: 'title'),
          tag: any(named: 'tag'),
          date: any(named: 'date'),
        )).thenAnswer((_) async => income);
  }

  group('convertForTransfer', () {
    test('TL köprüsüyle çevirir ve kuruşa yuvarlar', () {
      // 100 USD (kur 40) → EUR (kur 44): 4000/44 = 90.909… → 90.91
      expect(
        TransferService.convertForTransfer(
            amount: 100, srcRateToTry: 40, dstRateToTry: 44),
        90.91,
      );
      // 4000 TL → USD (kur 40): 100.00
      expect(
        TransferService.convertForTransfer(
            amount: 4000, srcRateToTry: 1, dstRateToTry: 40),
        100.0,
      );
    });
  });

  group('transfer', () {
    test('aynı birimde kur sorgusu yapılmaz, iki bacak aynı tutarla yazılır',
        () async {
      stubMovement();

      final result = await service.transfer(
        from: wallet('a'),
        to: wallet('b'),
        amount: 250,
      );

      expect(result, TransferResult.success);
      verifyNever(() => fx.rateToTry(any()));
      verify(() => metrics.recordCashMovement(
            walletId: 'a',
            userId: 'u',
            amount: 250,
            isIncome: false,
            title: any(named: 'title'),
            tag: CashMovementTags.transfer,
            date: any(named: 'date'),
          )).called(1);
      verify(() => metrics.recordCashMovement(
            walletId: 'b',
            userId: 'u',
            amount: 250,
            isIncome: true,
            title: any(named: 'title'),
            tag: CashMovementTags.transfer,
            date: any(named: 'date'),
          )).called(1);
    });

    test('çapraz birimde hedef bacak çevrilmiş (yuvarlı) tutarla yazılır',
        () async {
      stubMovement();
      when(() => fx.rateToTry('TRY')).thenAnswer((_) async => 1.0);
      when(() => fx.rateToTry('USD')).thenAnswer((_) async => 40.0);

      final result = await service.transfer(
        from: wallet('a'), // TRY
        to: wallet('b', currency: 'USD'),
        amount: 4100, // → 102.5 USD
      );

      expect(result, TransferResult.success);
      verify(() => metrics.recordCashMovement(
            walletId: 'b',
            userId: 'u',
            amount: 102.5,
            isIncome: true,
            title: any(named: 'title'),
            tag: CashMovementTags.transfer,
            date: any(named: 'date'),
          )).called(1);
    });

    test('kur yoksa hiçbir bacak yazılmaz, rateUnavailable döner', () async {
      when(() => fx.rateToTry('TRY')).thenAnswer((_) async => 1.0);
      when(() => fx.rateToTry('USD')).thenAnswer((_) async => null);

      final result = await service.transfer(
        from: wallet('a'),
        to: wallet('b', currency: 'USD'),
        amount: 100,
      );

      expect(result, TransferResult.rateUnavailable);
      verifyZeroInteractions(metrics);
    });

    test('ilk bacak başarısızsa ikinci bacak hiç denenmez', () async {
      stubMovement(expense: false);

      final result = await service.transfer(
        from: wallet('a'),
        to: wallet('b'),
        amount: 100,
      );

      expect(result, TransferResult.failed);
      verifyNever(() => metrics.recordCashMovement(
            walletId: 'b',
            userId: any(named: 'userId'),
            amount: any(named: 'amount'),
            isIncome: true,
            title: any(named: 'title'),
            tag: any(named: 'tag'),
            date: any(named: 'date'),
          ));
    });

    test('ikinci bacak başarısızsa kaynağa telafi iadesi yazılır', () async {
      // Gider bacağı OK; gelir bacağı hedefte başarısız, kaynakta (iade) OK.
      when(() => metrics.recordCashMovement(
            walletId: any(named: 'walletId'),
            userId: any(named: 'userId'),
            amount: any(named: 'amount'),
            isIncome: false,
            title: any(named: 'title'),
            tag: any(named: 'tag'),
            date: any(named: 'date'),
          )).thenAnswer((_) async => true);
      when(() => metrics.recordCashMovement(
            walletId: 'b',
            userId: any(named: 'userId'),
            amount: any(named: 'amount'),
            isIncome: true,
            title: any(named: 'title'),
            tag: any(named: 'tag'),
            date: any(named: 'date'),
          )).thenAnswer((_) async => false);
      when(() => metrics.recordCashMovement(
            walletId: 'a',
            userId: any(named: 'userId'),
            amount: any(named: 'amount'),
            isIncome: true,
            title: any(named: 'title'),
            tag: any(named: 'tag'),
            date: any(named: 'date'),
          )).thenAnswer((_) async => true);

      final result = await service.transfer(
        from: wallet('a'),
        to: wallet('b'),
        amount: 100,
      );

      expect(result, TransferResult.failed);
      // Telafi: kaynağa gelir olarak aynı tutar geri yazıldı.
      verify(() => metrics.recordCashMovement(
            walletId: 'a',
            userId: 'u',
            amount: 100,
            isIncome: true,
            title: any(named: 'title'),
            tag: CashMovementTags.transfer,
            date: any(named: 'date'),
          )).called(1);
    });

    test('aynı cüzdana transfer reddedilir', () async {
      final result = await service.transfer(
        from: wallet('a'),
        to: wallet('a'),
        amount: 100,
      );
      expect(result, TransferResult.failed);
      verifyZeroInteractions(metrics);
    });
  });
}
