import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:flutter/material.dart';

/// Para anlamı taşıyan renkler — İşlemler, İçgörü ve Rapor aynı dili konuşur.
///
/// Eskiden üç sayfa üç ayrı dil konuşuyordu: işlemler `AppGradients`'in
/// yeşil/kırmızısını, rapor Material `Colors.green`/`Colors.redAccent`'ını,
/// net için `Colors.blue`/`Colors.orange`'ı kullanıyordu; İçgörü aynı ekranda
/// iki farklı yeşil ve iki farklı kırmızı gösteriyordu. Üstelik transfer ve
/// kart ödemesi gibi PARA TAŞIMA hareketleri gider kırmızısıyla çiziliyordu
/// ama hiçbir toplamda gider sayılmıyordu — kullanıcı ekrandan "bu gider mi"
/// sorusuna cevap bulamıyordu.
abstract final class MoneyColors {
  static const Color income = AppGradients.savings;
  static const Color expense = AppGradients.debt;

  /// Pozitif net (birikim): uygulamanın işlem mavisi. Negatif net gider
  /// rengini alır — eskiden `Colors.orange`'dı, dördüncü bir anlam rengi.
  static const Color netPositive = AppGradients.transactions;

  static Color net(double value) => value >= 0 ? netPositive : expense;

  /// İyi/kötü sinyali (bütçe içinde / aşıldı, lehte / aleyhte değişim)
  /// gelir/gider renklerini paylaşır: kullanıcı için yeşil "iyi", kırmızı
  /// "dikkat" demek; ayrı bir ton bir anlam daha öğretmek olurdu.
  static const Color good = income;
  static const Color bad = expense;

  /// Para taşıma (transfer, borç, yatırım, kart ödemesi): harcama DEĞİL.
  /// Kırmızı/yeşil çağrışımı taşımayan nötr arduvaz tonu. Koyu temada bir
  /// ton açık: 500'lük ton koyu zeminde büyük metin için bile sınırda
  /// kalıyordu.
  static const Color _movedLight = Color(0xFF64748B); // slate-500
  static const Color _movedDark = Color(0xFF94A3B8); // slate-400

  static Color moved(Brightness brightness) =>
      brightness == Brightness.dark ? _movedDark : _movedLight;

  /// Bir işlemin satır/tutar rengi: para taşıma nötr, gelir yeşil, gider
  /// kırmızı. Evren kuralı ortak fonksiyondan gelir ([isSpendingMovement]).
  static Color of(TransactionEntity t, Brightness brightness) {
    if (!isSpendingMovement(t)) return moved(brightness);
    return t.isIncome ? income : expense;
  }
}
