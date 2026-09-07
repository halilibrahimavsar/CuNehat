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
        openingBalance: 1000,
        currency: currency,
      );

  setUp(() {
    metrics = MockWalletMetricsService();
    fx = MockExchangeRateService();
    service =
        TransferService(walletMetricsService: metrics, exchangeRateService: fx);
  });

  /// Bacakları CÜZDANA göre stub'lar: transfer artık çoğul yolu kullanıyor
  /// (geri alma bacakları kimlikle bulmak zorunda; tekil çağrı yalnız bool
  /// döner).
  void stubLegs({
    bool source = true,
    bool destination = true,
    List<String> sourceIds = const ['out-1'],
    List<String> destinationIds = const ['in-1'],
  }) {
    when(() => metrics.recordCashMovements(
          walletId: 'a',
          entries: any(named: 'entries'),
        )).thenAnswer((_) async => CashWriteResult(
          ok: source,
          transactionIds: source ? sourceIds : const [],
        ));
    when(() => metrics.recordCashMovements(
          walletId: 'b',
          entries: any(named: 'entries'),
        )).thenAnswer((_) async => CashWriteResult(
          ok: destination,
          transactionIds: destination ? destinationIds : const [],
        ));
  }

  List<CashMovement> capturedFor(String walletId) =>
      verify(() => metrics.recordCashMovements(
            walletId: walletId,
            entries: captureAny(named: 'entries'),
          )).captured.cast<List<CashMovement>>().expand((e) => e).toList();

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
      stubLegs();

      final outcome = await service.transfer(
        from: wallet('a'),
        to: wallet('b'),
        amount: 250,
      );

      expect(outcome.result, TransferResult.success);
      expect(outcome.isSuccess, isTrue);
      verifyNever(() => fx.rateToTry(any()));

      final out = capturedFor('a').single;
      expect(out.amount, 250);
      expect(out.isIncome, isFalse);
      expect(out.tag, CashMovementTags.transfer);

      final incoming = capturedFor('b').single;
      expect(incoming.amount, 250);
      expect(incoming.isIncome, isTrue);
    });

    test('çapraz birimde hedef bacak çevrilmiş (yuvarlı) tutarla yazılır',
        () async {
      stubLegs();
      when(() => fx.rateToTry('TRY')).thenAnswer((_) async => 1.0);
      when(() => fx.rateToTry('USD')).thenAnswer((_) async => 40.0);

      final outcome = await service.transfer(
        from: wallet('a'), // TRY
        to: wallet('b', currency: 'USD'),
        amount: 4100, // → 102.5 USD
      );

      expect(outcome.result, TransferResult.success);
      expect(capturedFor('b').single.amount, 102.5);
    });

    test('kur yoksa hiçbir bacak yazılmaz, rateUnavailable döner', () async {
      when(() => fx.rateToTry('TRY')).thenAnswer((_) async => 1.0);
      when(() => fx.rateToTry('USD')).thenAnswer((_) async => null);

      final outcome = await service.transfer(
        from: wallet('a'),
        to: wallet('b', currency: 'USD'),
        amount: 100,
      );

      expect(outcome.result, TransferResult.rateUnavailable);
      expect(outcome.canUndo, isFalse);
      verifyZeroInteractions(metrics);
    });

    test('ilk bacak başarısızsa ikinci bacak hiç denenmez', () async {
      stubLegs(source: false);

      final outcome = await service.transfer(
        from: wallet('a'),
        to: wallet('b'),
        amount: 100,
      );

      expect(outcome.result, TransferResult.failed);
      verifyNever(() => metrics.recordCashMovements(
            walletId: 'b',
            entries: any(named: 'entries'),
          ));
    });

    test('ikinci bacak başarısızsa kaynağa telafi iadesi yazılır', () async {
      stubLegs(destination: false);

      final outcome = await service.transfer(
        from: wallet('a'),
        to: wallet('b'),
        amount: 100,
      );

      expect(outcome.result, TransferResult.failed);
      // Telafi: kaynağa gelir olarak aynı tutar geri yazıldı.
      final sourceLegs = capturedFor('a');
      expect(sourceLegs, hasLength(2));
      expect(sourceLegs[1].amount, 100);
      expect(sourceLegs[1].isIncome, isTrue);
      expect(sourceLegs[1].tag, CashMovementTags.transfer);
      // Yarım transfer geri ALINAMAZ: tek bacağı silmek defteri daha da bozar.
      expect(outcome.canUndo, isFalse);
    });

    test('telafi iadesi de yazılamazsa refundFailed döner', () async {
      // Kaynak bacağı: ilk çağrı OK, iade çağrısı BAŞARISIZ.
      var sourceCalls = 0;
      when(() => metrics.recordCashMovements(
            walletId: 'a',
            entries: any(named: 'entries'),
          )).thenAnswer((_) async {
        sourceCalls++;
        return sourceCalls == 1
            ? const CashWriteResult(ok: true, transactionIds: ['out-1'])
            : const CashWriteResult(ok: false);
      });
      when(() => metrics.recordCashMovements(
            walletId: 'b',
            entries: any(named: 'entries'),
          )).thenAnswer((_) async => const CashWriteResult(ok: false));

      final outcome = await service.transfer(
        from: wallet('a'),
        to: wallet('b'),
        amount: 100,
      );

      // Kaynak cüzdan KALICI olarak eksik ve defterde iz yok; düz bir
      // "başarısız" mesajı bunu kullanıcıya söylemiyordu.
      expect(outcome.result, TransferResult.refundFailed);
    });

    test('aynı cüzdana transfer reddedilir', () async {
      final outcome = await service.transfer(
        from: wallet('a'),
        to: wallet('a'),
        amount: 100,
      );
      expect(outcome.result, TransferResult.failed);
      verifyZeroInteractions(metrics);
    });

    test('TARİH verilirse iki bacak da o güne yazılır', () async {
      // Geçmişte yapılmış bir para taşımasında iki bacak da bugüne düşüyordu:
      // bakiye doğru çıkar ama her iki cüzdanın DÖNEM defteri yanlış aya
      // yazılır ve hata sessiz kalırdı.
      stubLegs();
      final when_ = DateTime(2026, 3, 5);

      await service.transfer(
        from: wallet('a'),
        to: wallet('b'),
        amount: 250,
        date: when_,
      );

      expect(capturedFor('a').single.date, when_);
      expect(capturedFor('b').single.date, when_);
    });

    test('tarih verilmezse null taşınır (defter "şimdi"ye yazar)', () async {
      stubLegs();
      await service.transfer(from: wallet('a'), to: wallet('b'), amount: 250);
      expect(capturedFor('a').single.date, isNull);
    });
  });

  group('undoTransfer', () {
    test('iki bacağı da siler ve İKİ cüzdanı senkronlar', () async {
      // Transferin iki bacağı da sistem işlemi olduğu için UI'dan silinemez
      // ve arkasında düzenlenebilir bir kayıt yok: bu eylem olmadan yanlış
      // girilen bir transferi düzeltmenin hiçbir yolu yoktu.
      stubLegs();
      when(() => metrics.removeCashMovements(
            transactionIds: any(named: 'transactionIds'),
            walletIds: any(named: 'walletIds'),
          )).thenAnswer((_) async => true);

      final outcome = await service.transfer(
        from: wallet('a'),
        to: wallet('b'),
        amount: 250,
      );
      expect(outcome.canUndo, isTrue);

      final ok = await service.undoTransfer(outcome);

      expect(ok, isTrue);
      verify(() => metrics.removeCashMovements(
            transactionIds: ['out-1', 'in-1'],
            walletIds: {'a', 'b'},
          )).called(1);
    });

    test('geri alınamaz sonuçta deftere DOKUNMAZ', () async {
      const outcome = TransferOutcome.failure(TransferResult.failed);
      expect(await service.undoTransfer(outcome), isFalse);
      verifyNever(() => metrics.removeCashMovements(
            transactionIds: any(named: 'transactionIds'),
            walletIds: any(named: 'walletIds'),
          ));
    });
  });
}
