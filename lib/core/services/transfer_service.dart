import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/core/utils/money_math.dart';
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
  /// Kullanıcı defteri elle kontrol etmeye yönlendirilmeli.
  refundFailed,
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

  /// Deftere yazılan sistem işlemlerinin kimlikleri (kaynak + hedef bacağı).
  /// Yalnız [TransferResult.success] durumunda doludur.
  final List<String> transactionIds;

  final String fromWalletId;
  final String toWalletId;

  const TransferOutcome({
    required this.result,
    this.transactionIds = const <String>[],
    this.fromWalletId = '',
    this.toWalletId = '',
  });

  const TransferOutcome.failure(TransferResult result) : this(result: result);

  bool get isSuccess => result == TransferResult.success;

  /// Geri alma yalnız İKİ bacak da yazılabilmişse sunulur; tek bacağı silmek
  /// defteri daha da bozardı.
  bool get canUndo => isSuccess && transactionIds.length == 2;
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

    final double converted;
    if (from.currency == to.currency) {
      // Aynı birim: kur gerekmez (çevrimdışı da çalışır).
      converted = roundToCents(amount);
    } else {
      final srcRate = await exchangeRateService.rateToTry(from.currency);
      final dstRate = await exchangeRateService.rateToTry(to.currency);
      if (srcRate == null || dstRate == null || dstRate <= 0) {
        return const TransferOutcome.failure(TransferResult.rateUnavailable);
      }
      converted = convertForTransfer(
        amount: amount,
        srcRateToTry: srcRate,
        dstRateToTry: dstRate,
      );
    }

    // Çoğul yol: geri alma bacakları KİMLİKLE bulmak zorunda (tekil çağrı
    // yalnız bool döner).
    final out = await walletMetricsService.recordCashMovements(
      walletId: from.id!,
      entries: [
        CashMovement(
          userId: from.userId,
          amount: amount,
          isIncome: false,
          title: 'Transfer → ${to.name}',
          tag: CashMovementTags.transfer,
          date: date,
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
          title: 'Transfer ← ${from.name}',
          tag: CashMovementTags.transfer,
          date: date,
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
    );
  }

  /// Transferin iki bacağını da defterden siler ve iki cüzdanı yeniden
  /// senkronlar. Kısmi başarıda `false` döner (bakiye yine defterden türer).
  Future<bool> undoTransfer(TransferOutcome outcome) {
    if (!outcome.canUndo) return Future<bool>.value(false);
    return walletMetricsService.removeCashMovements(
      transactionIds: outcome.transactionIds,
      walletIds: {outcome.fromWalletId, outcome.toWalletId},
    );
  }
}
