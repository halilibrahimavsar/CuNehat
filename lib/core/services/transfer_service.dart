import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Transfer sonucu; UI mesajı buna göre seçer.
enum TransferResult {
  success,
  rateUnavailable,
  failed,

  /// İkinci bacak YAZILAMADI ve telafi iadesi de başarısız oldu:
  /// kaynak cüzdan kalıcı olarak eksik ve defterde hiçbir iz yok.
  /// Benimsemede: karşı bacak yazılamadı ve benimseme de bırakılamadı —
  /// satır karşılıksız bir transfer bacağı olarak kaldı.
  /// Kullanıcı defteri elle kontrol etmeye yönlendirilmeli.
  refundFailed,

  /// Defterdeki satır transfer bacağı olarak BENİMSENEMEDİ (bu arada
  /// değişmiş, silinmiş ya da başka bir kayda bağlanmış); hiçbir şey
  /// yazılmadı.
  adoptionFailed,
}

/// Transferin sonucu + GERİ ALMA için gereken bilgi.
///
/// Transferin iki bacağı da sistem işlemidir ve UI'dan silinemez; arkasında
/// düzenlenebilir bir kayıt da yoktur. Yani yanlış girilen bir transferi
/// düzeltmenin HİÇBİR yolu yoktu. Yazılan satırların kimlikleri burada
/// taşınır ki çağıran "Geri al" sunabilsin — eşleştirme (tag + tarih + tutar)
/// aynı gün aynı tutarlı iki transferi ayırt edemezdi.
@immutable
class TransferOutcome {
  final TransferResult result;

  /// Bu çağrının deftere YAZDIĞI sistem işlemlerinin kimlikleri (kaynak +
  /// hedef bacağı; benimsemede yalnız karşı bacak). Yalnız
  /// [TransferResult.success] durumunda doludur.
  final List<String> transactionIds;

  final String fromWalletId;
  final String toWalletId;

  /// İki bacağın ortak `linkedRecordId`'si (transfer çifti kimliği): transfer
  /// sonradan bununla bulunup kaldırılır (bkz. [TransferService.unlinkTransfer]).
  final String? pairId;

  /// Defterde zaten duran satırlardan kaçı bacak olarak BENİMSENDİ:
  /// 0 klasik transfer, 1 [TransferService.adoptAsTransfer],
  /// 2 [TransferService.adoptPair]. Geri alma bunları silmez, bırakır.
  final int adoptedLegs;

  const TransferOutcome({
    required this.result,
    this.transactionIds = const <String>[],
    this.fromWalletId = '',
    this.toWalletId = '',
    this.pairId,
    this.adoptedLegs = 0,
  });

  const TransferOutcome.failure(TransferResult result) : this(result: result);

  bool get isSuccess => result == TransferResult.success;

  /// Geri alma yalnız İKİ bacak da kurulabilmişse (yazılmış ya da
  /// benimsenmiş) sunulur; tek bacağı silmek defteri daha da bozardı.
  bool get canUndo =>
      isSuccess &&
      transactionIds.length + adoptedLegs == 2 &&
      (adoptedLegs == 0 || pairId != null);
}

/// Cüzdanlar arası transfer: kaynakta gider + hedefte (kur çevrimli) gelir.
///
/// Her bacak [WalletMetricsService.recordCashMovement] ile yazılır — yani
/// transferler işlem geçmişinde görünür ve bakiyeler defterden yeniden
/// hesaplanır. Cüzdan başına yazma kuyruğu (_serialized) bakiye yarışlarını
/// zaten önler. İkinci bacak yazılamazsa kaynağa best-effort telafi iadesi
/// yapılır ve sonuç `failed` döner.
@lazySingleton
class TransferService {
  final WalletMetricsService walletMetricsService;
  final ExchangeRateService exchangeRateService;

  TransferService({
    required this.walletMetricsService,
    required this.exchangeRateService,
  });

  /// Kaynak tutarını TL köprüsüyle hedef birime çevirir, kuruşa yuvarlar.
  /// Örn. 100 USD → TRY: 100 × kur(USD) / 1.0.
  static double convertForTransfer({
    required double amount,
    required double srcRateToTry,
    required double dstRateToTry,
  }) =>
      roundToCents(amount * srcRateToTry / dstRateToTry);

  /// Kaynak bacağın başlığı. Hedef bir kredi kartıysa "Kart ödemesi": iki
  /// defterde de ne olduğu okunsun ("Transfer → Bonus" kartın borcunun
  /// kapandığını söylemiyordu). Başlık yalnız gösterimdir — hiçbir kod onu
  /// ayrıştırmaz (tür bilgisi `tag` + `linkedRecordId`'de).
  static String outgoingTransferTitle(WalletEntity to) =>
      to.isCreditCard ? 'Kart ödemesi → ${to.name}' : 'Transfer → ${to.name}';

  /// Hedef bacağın başlığı; bkz. [outgoingTransferTitle].
  static String incomingTransferTitle({
    required WalletEntity from,
    required WalletEntity to,
  }) =>
      to.isCreditCard
          ? 'Kart ödemesi ← ${from.name}'
          : 'Transfer ← ${from.name}';

  /// [date] verilmezse "şimdi". Geçmişte yapılmış bir para taşımasını
  /// kaydeden kullanıcıda iki bacak da bugüne düşüyordu: bakiye doğru çıkar
  /// ama her iki cüzdanın DÖNEM defteri yanlış aya yazılırdı.
  Future<TransferOutcome> transfer({
    required WalletEntity from,
    required WalletEntity to,
    required double amount,
    DateTime? date,
  }) async {
    if (from.id == null || to.id == null || from.id == to.id) {
      return const TransferOutcome.failure(TransferResult.failed);
    }

    final converted = await _convert(amount, from: from, to: to);
    if (converted == null) {
      return const TransferOutcome.failure(TransferResult.rateUnavailable);
    }

    // Çift kimliği iki bacağa da yazılır: "Geri al" penceresi kapandıktan
    // sonra da transfer bulunup kaldırılabilsin (bkz. [unlinkTransfer]).
    final pairId = UidGenerator.generateV7();

    // Çoğul yol: geri alma bacakları KİMLİKLE bulmak zorunda (tekil çağrı
    // yalnız bool döner).
    final out = await walletMetricsService.recordCashMovements(
      walletId: from.id!,
      entries: [
        CashMovement(
          userId: from.userId,
          amount: amount,
          isIncome: false,
          title: outgoingTransferTitle(to),
          tag: CashMovementTags.transfer,
          date: date,
          linkedRecordId: pairId,
        ),
      ],
    );
    if (!out.ok) return const TransferOutcome.failure(TransferResult.failed);

    final incoming = await walletMetricsService.recordCashMovements(
      walletId: to.id!,
      entries: [
        CashMovement(
          userId: to.userId,
          amount: converted,
          isIncome: true,
          title: incomingTransferTitle(from: from, to: to),
          tag: CashMovementTags.transfer,
          date: date,
          linkedRecordId: pairId,
        ),
      ],
    );
    if (!incoming.ok) {
      // Telafi: kaynaktan çıkan tutarı KENDİ tarihinde iade et. Bugüne
      // yazılsaydı geçmişe tarihli bir transferin çıkışı o ayda, iadesi bu
      // ayda kalır ve iki dönem birden bozulurdu.
      final refund = await walletMetricsService.recordCashMovements(
        walletId: from.id!,
        entries: [
          CashMovement(
            userId: from.userId,
            amount: amount,
            isIncome: true,
            title: 'Transfer iadesi ← ${to.name}',
            tag: CashMovementTags.transfer,
            date: date,
            linkedRecordId: pairId,
          ),
        ],
      );
      // İade de yazılamadıysa kaynak cüzdan KALICI olarak eksik ve defterde
      // hiçbir iz yok; çağıran bunu ayrı ve daha sert bir mesajla söylemeli.
      return TransferOutcome(
        result: refund.ok ? TransferResult.failed : TransferResult.refundFailed,
        fromWalletId: from.id!,
        toWalletId: to.id!,
      );
    }

    return TransferOutcome(
      result: TransferResult.success,
      transactionIds: [...out.transactionIds, ...incoming.transactionIds],
      fromWalletId: from.id!,
      toWalletId: to.id!,
      pairId: pairId,
    );
  }

  /// Defterde ZATEN duran düz bir satırı transferin bir bacağı yapar ve
  /// karşı bacağı [counterpart] cüzdanına yazar.
  ///
  /// **Neden:** kendi hesapların arasındaki para taşıması ekstreden düz gider
  /// (ya da gelir) olarak geliyordu: harcama şişiyor, karşı cüzdan parayı hiç
  /// görmüyordu. Aynı taşımayı [transfer] ile girmek ise çıkışı İKİNCİ kez
  /// yazardı.
  ///
  /// Satırın yönü transferin yönüdür: gider ise para [wallet]'tan
  /// [counterpart]'a, gelir ise [counterpart]'tan [wallet]'a gitti. Karşı
  /// bacak satırın TARİHİNE yazılır; birimler farklıysa bugünkü kurla
  /// çevrilir ([transfer] ile aynı kural).
  ///
  /// Önce satır benimsenir (taze okunup doğrulanır); karşı bacak
  /// yazılamazsa benimseme bırakılır — yarım transfer kalmaz.
  Future<TransferOutcome> adoptAsTransfer({
    required TransactionEntity transaction,
    required WalletEntity wallet,
    required WalletEntity counterpart,
  }) async {
    if (transaction.id == null ||
        wallet.id == null ||
        counterpart.id == null ||
        wallet.id == counterpart.id ||
        transaction.walletId != wallet.id) {
      return const TransferOutcome.failure(TransferResult.failed);
    }
    final converted = await _convert(
      transaction.amount,
      from: wallet,
      to: counterpart,
    );
    if (converted == null) {
      return const TransferOutcome.failure(TransferResult.rateUnavailable);
    }

    final outgoing = transaction.isExpense;
    final fromId = outgoing ? wallet.id! : counterpart.id!;
    final toId = outgoing ? counterpart.id! : wallet.id!;
    final pairId = UidGenerator.generateV7();

    final adopted = await walletMetricsService.adoptCashMovement(
      walletId: wallet.id!,
      transactionId: transaction.id!,
      tag: CashMovementTags.transfer,
      linkedRecordId: pairId,
      expectIncome: transaction.isIncome,
      expectAmount: transaction.amount,
    );
    if (adopted == null) {
      return const TransferOutcome.failure(TransferResult.adoptionFailed);
    }

    final leg = await walletMetricsService.recordCashMovements(
      walletId: counterpart.id!,
      entries: [
        CashMovement(
          userId: counterpart.userId,
          amount: converted,
          isIncome: outgoing,
          title: outgoing
              ? incomingTransferTitle(from: wallet, to: counterpart)
              : outgoingTransferTitle(wallet),
          tag: CashMovementTags.transfer,
          date: transaction.date,
          linkedRecordId: pairId,
        ),
      ],
    );
    // Kimlik döndüyse bacak YAZILDI (yalnız bakiye senkronu düşmüş olabilir;
    // bakiye defterden türediği için sonraki senkronda düzelir). Yazılmış
    // bacağı bırakıp benimsemeyi geri almak parayı karşı cüzdanda yoktan
    // var ederdi.
    if (leg.transactionIds.isEmpty) {
      final released = await walletMetricsService.releaseAdoptedMovements(
        walletId: wallet.id!,
        linkedRecordIds: {pairId},
      );
      return TransferOutcome(
        result: released.isEmpty
            ? TransferResult.refundFailed
            : TransferResult.failed,
        fromWalletId: fromId,
        toWalletId: toId,
      );
    }

    return TransferOutcome(
      result: TransferResult.success,
      transactionIds: leg.transactionIds,
      fromWalletId: fromId,
      toWalletId: toId,
      pairId: pairId,
      adoptedLegs: 1,
    );
  }

  /// İki cüzdanda da ZATEN duran iki düz satırı tek bir transferin iki
  /// bacağı yapar; deftere hiçbir satır yazılmaz.
  ///
  /// İki hesabın ekstresi de aktarılınca aynı para taşıması bir tarafta
  /// gider, diğer tarafta gelir olarak İKİ KEZ sayılıyordu (harcama da gelir
  /// de şişiyordu).
  ///
  /// Aynı birimde tutarlar kuruşuyla eşit olmalı: fark varsa arada masraf ya
  /// da başka bir hareket vardır ve o fark harcama olarak kalmalı. Farklı
  /// birimde tutarlar karşılaştırılamaz (o günün kuru bilinmiyor); kullanıcının
  /// eşleştirmesine güvenilir.
  Future<TransferOutcome> adoptPair({
    required TransactionEntity outgoing,
    required WalletEntity from,
    required TransactionEntity incoming,
    required WalletEntity to,
  }) async {
    if (outgoing.id == null ||
        incoming.id == null ||
        from.id == null ||
        to.id == null ||
        from.id == to.id ||
        outgoing.walletId != from.id ||
        incoming.walletId != to.id ||
        !outgoing.isExpense ||
        !incoming.isIncome ||
        (from.currency == to.currency &&
            !moneyEquals(outgoing.amount, incoming.amount))) {
      return const TransferOutcome.failure(TransferResult.failed);
    }
    final pairId = UidGenerator.generateV7();

    final first = await walletMetricsService.adoptCashMovement(
      walletId: from.id!,
      transactionId: outgoing.id!,
      tag: CashMovementTags.transfer,
      linkedRecordId: pairId,
      expectIncome: false,
      expectAmount: outgoing.amount,
    );
    if (first == null) {
      return const TransferOutcome.failure(TransferResult.adoptionFailed);
    }
    final second = await walletMetricsService.adoptCashMovement(
      walletId: to.id!,
      transactionId: incoming.id!,
      tag: CashMovementTags.transfer,
      linkedRecordId: pairId,
      expectIncome: true,
      expectAmount: incoming.amount,
    );
    if (second == null) {
      final released = await walletMetricsService.releaseAdoptedMovements(
        walletId: from.id!,
        linkedRecordIds: {pairId},
      );
      return TransferOutcome(
        result: released.isEmpty
            ? TransferResult.refundFailed
            : TransferResult.adoptionFailed,
        fromWalletId: from.id!,
        toWalletId: to.id!,
      );
    }

    return TransferOutcome(
      result: TransferResult.success,
      fromWalletId: from.id!,
      toWalletId: to.id!,
      pairId: pairId,
      adoptedLegs: 2,
    );
  }

  /// [amount]'u [from] biriminden [to] birimine çevirir; kur yoksa `null`.
  /// Aynı birimde kur sorulmaz (çevrimdışı da çalışır).
  Future<double?> _convert(
    double amount, {
    required WalletEntity from,
    required WalletEntity to,
  }) async {
    if (from.currency == to.currency) return roundToCents(amount);
    final srcRate = await exchangeRateService.rateToTry(from.currency);
    final dstRate = await exchangeRateService.rateToTry(to.currency);
    if (srcRate == null || dstRate == null || dstRate <= 0) return null;
    return convertForTransfer(
      amount: amount,
      srcRateToTry: srcRate,
      dstRateToTry: dstRate,
    );
  }

  /// Transferi geri alır: yazılan bacakları defterden siler, BENİMSENEN
  /// bacakları özgün düz hâllerine döndürür (bankada para gerçekten hareket
  /// etti; satır silinirse ekstreyle bağ kopardı) ve iki cüzdanı yeniden
  /// senkronlar. Kısmi başarıda `false` döner (bakiye yine defterden türer).
  Future<bool> undoTransfer(TransferOutcome outcome) async {
    if (!outcome.canUndo) return false;
    return _dismantle(
      pairId: outcome.pairId,
      adoptedIn: outcome.adoptedLegs > 0
          ? {outcome.fromWalletId, outcome.toWalletId}
          : const {},
      expectedAdopted: outcome.adoptedLegs,
      writtenIds: outcome.transactionIds,
      walletIds: {outcome.fromWalletId, outcome.toWalletId},
    );
  }

  /// Kurulmuş bir transferi SONRADAN kaldırır: [pairId]'ye bağlı bacaklardan
  /// benimsenmiş olanlar özgün düz hâllerine döner, uygulamanın yazdıkları
  /// silinir.
  ///
  /// "Geri al" yalnız birkaç saniye sunulur; sonrasında iki bacak da sistem
  /// satırıdır ve düzenlenemez. Yanlış bağlanan bir ekstre satırı ya da
  /// yanlış girilen bir transfer bu eylem olmadan kalıcı kalırdı. Çift
  /// kimliği olmayan eski transferler (şema 11 öncesi) buradan kaldırılamaz:
  /// bacaklarını güvenle eşlemenin yolu yok.
  Future<bool> unlinkTransfer(String pairId) async {
    final legs = [
      for (final t
          in await walletMetricsService.linkedMovements(recordIds: {pairId}))
        if (t.isSystem && t.tag == CashMovementTags.transfer) t,
    ];
    if (legs.isEmpty) return false;
    return _dismantle(
      pairId: pairId,
      adoptedIn: {
        for (final t in legs)
          if (t.isAdopted) t.walletId
      },
      expectedAdopted: legs.where((t) => t.isAdopted).length,
      writtenIds: [
        for (final t in legs)
          if (!t.isAdopted && t.id != null) t.id!,
      ],
      walletIds: {for (final t in legs) t.walletId},
    );
  }

  Future<bool> _dismantle({
    required String? pairId,
    required Set<String> adoptedIn,
    required int expectedAdopted,
    required List<String> writtenIds,
    required Set<String> walletIds,
  }) async {
    var ok = true;
    if (expectedAdopted > 0 && pairId != null) {
      var released = 0;
      for (final walletId in adoptedIn) {
        released += (await walletMetricsService.releaseAdoptedMovements(
          walletId: walletId,
          linkedRecordIds: {pairId},
        ))
            .length;
      }
      ok = released == expectedAdopted;
    }
    if (writtenIds.isNotEmpty) {
      ok = await walletMetricsService.removeCashMovements(
            transactionIds: writtenIds,
            walletIds: walletIds,
          ) &&
          ok;
    }
    return ok;
  }
}
