import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:injectable/injectable.dart';

/// Transfer sonucu; UI mesajı buna göre seçer.
enum TransferResult { success, rateUnavailable, failed }

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

  Future<TransferResult> transfer({
    required WalletEntity from,
    required WalletEntity to,
    required double amount,
  }) async {
    if (from.id == null || to.id == null || from.id == to.id) {
      return TransferResult.failed;
    }

    final double converted;
    if (from.currency == to.currency) {
      // Aynı birim: kur gerekmez (çevrimdışı da çalışır).
      converted = roundToCents(amount);
    } else {
      final srcRate = await exchangeRateService.rateToTry(from.currency);
      final dstRate = await exchangeRateService.rateToTry(to.currency);
      if (srcRate == null || dstRate == null || dstRate <= 0) {
        return TransferResult.rateUnavailable;
      }
      converted = convertForTransfer(
        amount: amount,
        srcRateToTry: srcRate,
        dstRateToTry: dstRate,
      );
    }

    final outOk = await walletMetricsService.recordCashMovement(
      walletId: from.id!,
      userId: from.userId,
      amount: amount,
      isIncome: false,
      title: 'Transfer → ${to.name}',
      tag: CashMovementTags.transfer,
    );
    if (!outOk) return TransferResult.failed;

    final inOk = await walletMetricsService.recordCashMovement(
      walletId: to.id!,
      userId: to.userId,
      amount: converted,
      isIncome: true,
      title: 'Transfer ← ${from.name}',
      tag: CashMovementTags.transfer,
    );
    if (!inOk) {
      // Telafi: kaynaktan çıkan tutarı iade et (best-effort; başarısızsa
      // kullanıcı `failed` mesajıyla defteri kontrol etmeye yönlenir).
      await walletMetricsService.recordCashMovement(
        walletId: from.id!,
        userId: from.userId,
        amount: amount,
        isIncome: true,
        title: 'Transfer iadesi ← ${to.name}',
        tag: CashMovementTags.transfer,
      );
      return TransferResult.failed;
    }

    return TransferResult.success;
  }
}
