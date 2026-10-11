import 'package:cunehat/core/l10n/app_strings.dart';
import 'package:flutter/foundation.dart';

/// Nakit kuplajı yapan bloc'ların (borç/alacak/yatırım) ortak parçaları:
/// başarısız nakit hareketinde kullanıcı mesajına eklenen uyarı kuyruğu ve
/// asla fırlatmayan metrik senkronu. Para zinciri semantiği
/// WalletMetricsService'te; burada yalnız sunum tesisatı var.
mixin CashCouplingMixin {
  static String get cashWarning => appStrings.blocMsgCashWarningSuffix;

  /// Başarı mesajının sonuna eklenecek ek: nakit hareketi yazılamadıysa uyarı.
  String cashWarningSuffix(bool cashOk) => cashOk ? '' : cashWarning;

  /// debt/credit/investment metrik senkronu — hata yutulur, loglanır;
  /// bloc handler'ı Loading'de takılı bırakmaz.
  Future<void> safeSyncMetric(
      Future<void> Function() sync, String label) async {
    try {
      await sync();
    } catch (e) {
      debugPrint('Wallet $label sync failed: $e');
    }
  }
}
