import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/core/services/transfer_service.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
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

    test('iki bacak ORTAK çift kimliği taşır (sonradan kaldırılabilsin)',
        () async {
      // "Geri al" birkaç saniye sunulur; sonrasında iki bacak da sistem
      // satırıdır. Çift kimliği olmadan transfer bir daha bulunamazdı.
      stubLegs();
      final outcome =
          await service.transfer(from: wallet('a'), to: wallet('b'), amount: 5);

      final out = capturedFor('a').single;
      final incoming = capturedFor('b').single;
      expect(out.linkedRecordId, isNotNull);
      expect(incoming.linkedRecordId, out.linkedRecordId);
      expect(outcome.pairId, out.linkedRecordId);
      expect(outcome.adoptedLegs, 0);
    });
  });

  // Kart ödemesi iki defterde de "Kart ödemesi" olarak okunsun.
  test('hedef KREDİ KARTIYSA bacak başlıkları "Kart ödemesi"', () async {
    stubLegs();
    final card = WalletEntity(
      id: 'b',
      userId: 'u',
      name: 'Bonus',
      balance: -500,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '0xFF37474F',
      iconName: 'credit_card',
      createdAt: DateTime(2026, 1, 1),
      openingBalance: 0,
      creditCard: const CreditCardInfo(closingDay: 15, dueDay: 25),
    );
    await service.transfer(from: wallet('a'), to: card, amount: 100);
    expect(capturedFor('a').single.title, 'Kart ödemesi → Bonus');
    expect(capturedFor('b').single.title, 'Kart ödemesi ← Wa');
  });

  test('düz cüzdanlar arasında başlık "Transfer" kalır', () async {
    stubLegs();
    await service.transfer(from: wallet('a'), to: wallet('b'), amount: 100);
    expect(capturedFor('a').single.title, 'Transfer → Wb');
    expect(capturedFor('b').single.title, 'Transfer ← Wa');
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

  // ─── Benimseme: defterde zaten duran satır transfer bacağı olur ──────────

  TransactionEntity row(
    String id, {
    required String walletId,
    required double amount,
    bool income = false,
    DateTime? date,
    bool isSystem = false,
    String tag = 'Market',
    String? linkedRecordId,
    String? adoptedFromTag,
  }) =>
      TransactionEntity(
        id: id,
        userId: 'u',
        walletId: walletId,
        title: 'SATIR $id',
        tag: tag,
        amount: amount,
        date: date ?? DateTime(2026, 9, 10, 14, 30),
        type:
            income ? TransactionTypeModel.income : TransactionTypeModel.expense,
        isSystem: isSystem,
        linkedRecordId: linkedRecordId,
        adoptedFromTag: adoptedFromTag,
      );

  void stubAdopt({String walletId = 'a', bool ok = true}) {
    when(() => metrics.adoptCashMovement(
          walletId: walletId,
          transactionId: any(named: 'transactionId'),
          tag: any(named: 'tag'),
          linkedRecordId: any(named: 'linkedRecordId'),
          expectIncome: any(named: 'expectIncome'),
          expectAmount: any(named: 'expectAmount'),
        )).thenAnswer((inv) async {
      if (!ok) return null;
      final id = inv.namedArguments[#transactionId] as String;
      return row(id, walletId: walletId, amount: 1).copyWith(
        isSystem: true,
        tag: CashMovementTags.transfer,
        linkedRecordId: inv.namedArguments[#linkedRecordId] as String,
        adoptedFromTag: 'Market',
      );
    });
  }

  void stubRelease(String walletId, {int count = 1}) {
    when(() => metrics.releaseAdoptedMovements(
              walletId: walletId,
              linkedRecordIds: any(named: 'linkedRecordIds'),
            ))
        .thenAnswer((_) async => [
              for (var i = 0; i < count; i++)
                row('r$i', walletId: walletId, amount: 1)
            ]);
  }

  String adoptedPairId(String walletId) =>
      verify(() => metrics.adoptCashMovement(
            walletId: walletId,
            transactionId: any(named: 'transactionId'),
            tag: CashMovementTags.transfer,
            linkedRecordId: captureAny(named: 'linkedRecordId'),
            expectIncome: any(named: 'expectIncome'),
            expectAmount: any(named: 'expectAmount'),
          )).captured.single as String;

  group('adoptAsTransfer', () {
    test(
        'gider satırı ÇIKIŞ bacağı olur: yeni çıkış YAZILMAZ, karşı cüzdana '
        'satırın tarihinde gelir yazılır', () async {
      // Ekstredeki "KARTA ODEME −5.000" düz gider olarak geliyordu: harcama
      // şişiyor, kart cüzdanı parayı hiç görmüyordu. Klasik transfer ise
      // çıkışı İKİNCİ kez yazardı.
      stubAdopt();
      stubLegs();
      final tx = row('tx1', walletId: 'a', amount: 5000);

      final outcome = await service.adoptAsTransfer(
        transaction: tx,
        wallet: wallet('a'),
        counterpart: wallet('b'),
      );

      expect(outcome.result, TransferResult.success);
      verify(() => metrics.adoptCashMovement(
            walletId: 'a',
            transactionId: 'tx1',
            tag: CashMovementTags.transfer,
            linkedRecordId: any(named: 'linkedRecordId'),
            expectIncome: false,
            expectAmount: 5000,
          )).called(1);
      verifyNever(() => metrics.recordCashMovements(
            walletId: 'a',
            entries: any(named: 'entries'),
          ));
      final incoming = capturedFor('b').single;
      expect(incoming.amount, 5000);
      expect(incoming.isIncome, isTrue);
      expect(incoming.tag, CashMovementTags.transfer);
      expect(incoming.date, tx.date);

      expect(outcome.fromWalletId, 'a');
      expect(outcome.toWalletId, 'b');
      expect(outcome.transactionIds, ['in-1']);
      expect(outcome.adoptedLegs, 1);
      expect(outcome.canUndo, isTrue);
    });

    test('iki bacak aynı çift kimliğini taşır', () async {
      stubAdopt();
      stubLegs();
      final outcome = await service.adoptAsTransfer(
        transaction: row('tx1', walletId: 'a', amount: 5000),
        wallet: wallet('a'),
        counterpart: wallet('b'),
      );
      final pairId = adoptedPairId('a');
      expect(capturedFor('b').single.linkedRecordId, pairId);
      expect(outcome.pairId, pairId);
    });

    test('GELİR satırı: para karşı cüzdandan geldi, karşı bacak GİDER',
        () async {
      // Kart cüzdanına aktarılan "ODEME ALINDI +5.000": para bankadan çıktı.
      stubAdopt();
      stubLegs();
      final tx = row('tx1', walletId: 'a', amount: 5000, income: true);

      final outcome = await service.adoptAsTransfer(
        transaction: tx,
        wallet: wallet('a'),
        counterpart: wallet('b'),
      );

      expect(outcome.result, TransferResult.success);
      verify(() => metrics.adoptCashMovement(
            walletId: 'a',
            transactionId: 'tx1',
            tag: CashMovementTags.transfer,
            linkedRecordId: any(named: 'linkedRecordId'),
            expectIncome: true,
            expectAmount: 5000,
          )).called(1);
      final leg = capturedFor('b').single;
      expect(leg.isIncome, isFalse);
      expect(outcome.fromWalletId, 'b');
      expect(outcome.toWalletId, 'a');
    });

    test('farklı birimde karşı bacak çevrilmiş tutarla yazılır', () async {
      stubAdopt();
      stubLegs();
      when(() => fx.rateToTry('TRY')).thenAnswer((_) async => 1.0);
      when(() => fx.rateToTry('USD')).thenAnswer((_) async => 40.0);

      await service.adoptAsTransfer(
        transaction: row('tx1', walletId: 'a', amount: 4100),
        wallet: wallet('a'),
        counterpart: wallet('b', currency: 'USD'),
      );

      expect(capturedFor('b').single.amount, 102.5);
    });

    test('kur yoksa satıra DOKUNULMAZ', () async {
      when(() => fx.rateToTry('TRY')).thenAnswer((_) async => 1.0);
      when(() => fx.rateToTry('USD')).thenAnswer((_) async => null);

      final outcome = await service.adoptAsTransfer(
        transaction: row('tx1', walletId: 'a', amount: 100),
        wallet: wallet('a'),
        counterpart: wallet('b', currency: 'USD'),
      );

      expect(outcome.result, TransferResult.rateUnavailable);
      verifyZeroInteractions(metrics);
    });

    test('satır benimsenemezse karşı bacak YAZILMAZ', () async {
      stubAdopt(ok: false);
      stubLegs();

      final outcome = await service.adoptAsTransfer(
        transaction: row('tx1', walletId: 'a', amount: 100),
        wallet: wallet('a'),
        counterpart: wallet('b'),
      );

      expect(outcome.result, TransferResult.adoptionFailed);
      verifyNever(() => metrics.recordCashMovements(
            walletId: any(named: 'walletId'),
            entries: any(named: 'entries'),
          ));
    });

    test('karşı bacak yazılamazsa benimseme BIRAKILIR (yarım transfer kalmaz)',
        () async {
      stubAdopt();
      stubLegs(destination: false);
      stubRelease('a');

      final outcome = await service.adoptAsTransfer(
        transaction: row('tx1', walletId: 'a', amount: 100),
        wallet: wallet('a'),
        counterpart: wallet('b'),
      );

      expect(outcome.result, TransferResult.failed);
      expect(outcome.canUndo, isFalse);
      final pairId = adoptedPairId('a');
      verify(() => metrics.releaseAdoptedMovements(
            walletId: 'a',
            linkedRecordIds: {pairId},
          )).called(1);
    });

    test('bırakma da düşerse refundFailed (defteri kontrol et)', () async {
      stubAdopt();
      stubLegs(destination: false);
      stubRelease('a', count: 0);

      final outcome = await service.adoptAsTransfer(
        transaction: row('tx1', walletId: 'a', amount: 100),
        wallet: wallet('a'),
        counterpart: wallet('b'),
      );

      expect(outcome.result, TransferResult.refundFailed);
    });

    test('başka cüzdanın satırı ya da aynı cüzdana transfer reddedilir',
        () async {
      final foreign = await service.adoptAsTransfer(
        transaction: row('tx1', walletId: 'x', amount: 100),
        wallet: wallet('a'),
        counterpart: wallet('b'),
      );
      final self = await service.adoptAsTransfer(
        transaction: row('tx1', walletId: 'a', amount: 100),
        wallet: wallet('a'),
        counterpart: wallet('a'),
      );
      expect(foreign.result, TransferResult.failed);
      expect(self.result, TransferResult.failed);
      verifyZeroInteractions(metrics);
    });
  });

  group('adoptPair', () {
    test('iki satır aynı çift kimliğiyle benimsenir, HİÇ satır yazılmaz',
        () async {
      // İki hesabın ekstresi de aktarılınca aynı para taşıması bir tarafta
      // gider, diğer tarafta gelir olarak iki kez sayılıyordu.
      stubAdopt(walletId: 'a');
      stubAdopt(walletId: 'b');

      final outcome = await service.adoptPair(
        outgoing: row('o1', walletId: 'a', amount: 5000),
        from: wallet('a'),
        incoming: row('i1', walletId: 'b', amount: 5000, income: true),
        to: wallet('b'),
      );

      expect(outcome.result, TransferResult.success);
      expect(adoptedPairId('a'), adoptedPairId('b'));
      verifyNever(() => metrics.recordCashMovements(
            walletId: any(named: 'walletId'),
            entries: any(named: 'entries'),
          ));
      expect(outcome.adoptedLegs, 2);
      expect(outcome.transactionIds, isEmpty);
      expect(outcome.canUndo, isTrue);
    });

    test('aynı birimde tutarlar farklıysa reddedilir (fark harcama kalmalı)',
        () async {
      final outcome = await service.adoptPair(
        outgoing: row('o1', walletId: 'a', amount: 5010),
        from: wallet('a'),
        incoming: row('i1', walletId: 'b', amount: 5000, income: true),
        to: wallet('b'),
      );
      expect(outcome.result, TransferResult.failed);
      verifyZeroInteractions(metrics);
    });

    test('farklı birimde tutarlar karşılaştırılmaz', () async {
      stubAdopt(walletId: 'a');
      stubAdopt(walletId: 'b');
      final outcome = await service.adoptPair(
        outgoing: row('o1', walletId: 'a', amount: 4100),
        from: wallet('a'),
        incoming: row('i1', walletId: 'b', amount: 102.4, income: true),
        to: wallet('b', currency: 'USD'),
      );
      expect(outcome.result, TransferResult.success);
    });

    test('yön ters verilirse reddedilir', () async {
      final outcome = await service.adoptPair(
        outgoing: row('o1', walletId: 'a', amount: 50, income: true),
        from: wallet('a'),
        incoming: row('i1', walletId: 'b', amount: 50, income: true),
        to: wallet('b'),
      );
      expect(outcome.result, TransferResult.failed);
      verifyZeroInteractions(metrics);
    });

    test('ikinci satır benimsenemezse ilki BIRAKILIR', () async {
      stubAdopt(walletId: 'a');
      stubAdopt(walletId: 'b', ok: false);
      stubRelease('a');

      final outcome = await service.adoptPair(
        outgoing: row('o1', walletId: 'a', amount: 50),
        from: wallet('a'),
        incoming: row('i1', walletId: 'b', amount: 50, income: true),
        to: wallet('b'),
      );

      expect(outcome.result, TransferResult.adoptionFailed);
      final pairId = adoptedPairId('a');
      verify(() => metrics.releaseAdoptedMovements(
            walletId: 'a',
            linkedRecordIds: {pairId},
          )).called(1);
    });
  });

  group('benimsenmiş transferin geri alınması', () {
    test('yazılan bacak SİLİNİR, benimsenen satır özgün hâline döner',
        () async {
      stubAdopt();
      stubLegs();
      stubRelease('a');
      stubRelease('b', count: 0);
      when(() => metrics.removeCashMovements(
            transactionIds: any(named: 'transactionIds'),
            walletIds: any(named: 'walletIds'),
          )).thenAnswer((_) async => true);

      final outcome = await service.adoptAsTransfer(
        transaction: row('tx1', walletId: 'a', amount: 5000),
        wallet: wallet('a'),
        counterpart: wallet('b'),
      );
      final ok = await service.undoTransfer(outcome);

      expect(ok, isTrue);
      verify(() => metrics.removeCashMovements(
            transactionIds: ['in-1'],
            walletIds: {'a', 'b'},
          )).called(1);
      verify(() => metrics.releaseAdoptedMovements(
            walletId: 'a',
            linkedRecordIds: {outcome.pairId!},
          )).called(1);
    });

    test('adoptPair geri alınınca iki satır da bırakılır, silme YOK', () async {
      stubAdopt(walletId: 'a');
      stubAdopt(walletId: 'b');
      stubRelease('a');
      stubRelease('b');

      final outcome = await service.adoptPair(
        outgoing: row('o1', walletId: 'a', amount: 50),
        from: wallet('a'),
        incoming: row('i1', walletId: 'b', amount: 50, income: true),
        to: wallet('b'),
      );
      expect(await service.undoTransfer(outcome), isTrue);
      for (final w in ['a', 'b']) {
        verify(() => metrics.releaseAdoptedMovements(
              walletId: w,
              linkedRecordIds: {outcome.pairId!},
            )).called(1);
      }
      verifyNever(() => metrics.removeCashMovements(
            transactionIds: any(named: 'transactionIds'),
            walletIds: any(named: 'walletIds'),
          ));
    });

    test('bırakılan satır sayısı tutmazsa false', () async {
      stubAdopt(walletId: 'a');
      stubAdopt(walletId: 'b');
      stubRelease('a');
      stubRelease('b', count: 0);

      final outcome = await service.adoptPair(
        outgoing: row('o1', walletId: 'a', amount: 50),
        from: wallet('a'),
        incoming: row('i1', walletId: 'b', amount: 50, income: true),
        to: wallet('b'),
      );
      expect(await service.undoTransfer(outcome), isFalse);
    });
  });

  group('unlinkTransfer (sonradan kaldırma)', () {
    void stubLinked(List<TransactionEntity> legs) {
      when(() => metrics.linkedMovements(
            walletId: any(named: 'walletId'),
            recordIds: any(named: 'recordIds'),
          )).thenAnswer((_) async => legs);
    }

    test(
        'benimsenen bacak bırakılır, yazılan bacak silinir — iki cüzdan da '
        'senkronlanır', () async {
      stubLinked([
        row('tx1',
            walletId: 'a',
            amount: 5000,
            isSystem: true,
            tag: CashMovementTags.transfer,
            linkedRecordId: 'p1',
            adoptedFromTag: 'Market'),
        row('in-1',
            walletId: 'b',
            amount: 5000,
            income: true,
            isSystem: true,
            tag: CashMovementTags.transfer,
            linkedRecordId: 'p1'),
      ]);
      stubRelease('a');
      when(() => metrics.removeCashMovements(
            transactionIds: any(named: 'transactionIds'),
            walletIds: any(named: 'walletIds'),
          )).thenAnswer((_) async => true);

      expect(await service.unlinkTransfer('p1'), isTrue);

      verify(() => metrics.linkedMovements(recordIds: {'p1'})).called(1);
      verify(() => metrics.releaseAdoptedMovements(
            walletId: 'a',
            linkedRecordIds: {'p1'},
          )).called(1);
      verifyNever(() => metrics.releaseAdoptedMovements(
            walletId: 'b',
            linkedRecordIds: any(named: 'linkedRecordIds'),
          ));
      verify(() => metrics.removeCashMovements(
            transactionIds: ['in-1'],
            walletIds: {'a', 'b'},
          )).called(1);
    });

    test('klasik transfer: iki bacak da silinir', () async {
      stubLinked([
        row('out-1',
            walletId: 'a',
            amount: 10,
            isSystem: true,
            tag: CashMovementTags.transfer,
            linkedRecordId: 'p1'),
        row('in-1',
            walletId: 'b',
            amount: 10,
            income: true,
            isSystem: true,
            tag: CashMovementTags.transfer,
            linkedRecordId: 'p1'),
      ]);
      when(() => metrics.removeCashMovements(
            transactionIds: any(named: 'transactionIds'),
            walletIds: any(named: 'walletIds'),
          )).thenAnswer((_) async => true);

      expect(await service.unlinkTransfer('p1'), isTrue);
      verify(() => metrics.removeCashMovements(
            transactionIds: ['out-1', 'in-1'],
            walletIds: {'a', 'b'},
          )).called(1);
    });

    test('kimliğe bağlı transfer bacağı yoksa deftere DOKUNMAZ', () async {
      // Aynı kimliği taşıyan transfer DIŞI bir hareket (ör. bir kaydın
      // kuplajı) asla silinmemeli.
      stubLinked([
        row('x',
            walletId: 'a',
            amount: 10,
            isSystem: true,
            tag: 'Yatırım Alımı',
            linkedRecordId: 'p1'),
      ]);

      expect(await service.unlinkTransfer('p1'), isFalse);
      verifyNever(() => metrics.removeCashMovements(
            transactionIds: any(named: 'transactionIds'),
            walletIds: any(named: 'walletIds'),
          ));
      verifyNever(() => metrics.releaseAdoptedMovements(
            walletId: any(named: 'walletId'),
            linkedRecordIds: any(named: 'linkedRecordIds'),
          ));
    });
  });
}
