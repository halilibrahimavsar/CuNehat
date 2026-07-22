/// Banka ekstresindeki running-balance (bakiye) sütununu, ayrıştırılan işlem
/// tutarlarıyla mutabık kılar. İki işi birden yapar:
///
/// 1. **İşaret türetme:** ardışık iki satırın bakiye farkı = o işlemin işaretli
///    tutarı. Böylece tutar işaretini tahmine bırakmadan (ör. tek pozitif
///    "Tutar" sütunu) doğrudan bakiyeden okuruz.
/// 2. **Doğrulama:** türetilen işaretli tutarın büyüklüğü, ayrıştırılan tutar
///    büyüklüğüyle uyuşuyor mu? Uyuşmuyorsa (kaçan satır, yanlış ondalık,
///    yanlış işaret) kullanıcı uyarılır.
///
/// Ekstre kronolojik olarak artan (eskiden yeniye) ya da azalan (yeniden
/// eskiye) sıralı olabilir; iki hipotez de denenip daha iyi eşleşen seçilir.
/// Saf/test-edilebilir: UI veya IO bağımlılığı yoktur.
library;

import 'package:cunehat/core/utils/money_math.dart';

enum ReconcileStatus {
  /// Bakiye sütunu yok ya da çok az satır → mutabakat yapılmadı (UI'da sessiz).
  notAvailable,

  /// Bakiye deltaları tutarlarla büyük oranda uyuştu.
  matched,

  /// Bakiye sütunu var ama deltalar tutarlarla uyuşmadı → kullanıcıyı uyar.
  mismatch,
}

class BalanceReconciliation {
  final ReconcileStatus status;

  /// Satır bazında bakiye-deltasından türetilen işaretli tutar (kuruş-temiz).
  /// `null` = o satır için türetilemedi (çapa/uç satır ya da eksik bakiye).
  /// Uzunluk giriş satır sayısına eşittir.
  final List<double?> derivedSigned;

  /// Kaç satır kontrol edilebildi ve kaçı uyuştu (özet çubuğu için).
  final int checked;
  final int matched;

  const BalanceReconciliation({
    required this.status,
    required this.derivedSigned,
    required this.checked,
    required this.matched,
  });

  int get mismatchCount => checked - matched;
}

/// [magnitudes]: satır başına ayrıştırılan İŞARETSİZ tutar büyüklüğü (yoksa null).
/// [balances]: satır başına running-balance (yoksa null). İki liste aynı uzunlukta
/// ve aynı satır sırasında olmalı.
BalanceReconciliation reconcileBalances({
  required List<double?> magnitudes,
  required List<double?> balances,
  double tolerance = 0.01,
}) {
  final n = balances.length;
  final empty = List<double?>.filled(n, null);
  final balanceCount = balances.where((b) => b != null).length;
  if (n < 2 || balanceCount < 2) {
    return BalanceReconciliation(
      status: ReconcileStatus.notAvailable,
      derivedSigned: empty,
      checked: 0,
      matched: 0,
    );
  }

  final forward = _hypothesis(magnitudes, balances, tolerance, reverse: false);
  final reverse = _hypothesis(magnitudes, balances, tolerance, reverse: true);

  // Daha çok satır eşleştiren hipotezi seç; berabere kalırsa forward (TR
  // ekstrelerinde eskiden-yeniye daha yaygın).
  final best = reverse.matched > forward.matched ? reverse : forward;

  if (best.checked == 0) {
    return BalanceReconciliation(
      status: ReconcileStatus.notAvailable,
      derivedSigned: empty,
      checked: 0,
      matched: 0,
    );
  }

  // Satırların çoğu tutuyorsa "matched" say; işaretleri türet. Aksi halde
  // bakiye var ama tutmuyor → mismatch (işaret türetme, yanlış olabilir).
  final ratio = best.matched / best.checked;
  if (ratio >= 0.6) {
    return BalanceReconciliation(
      status: ReconcileStatus.matched,
      derivedSigned: best.derivedSigned,
      checked: best.checked,
      matched: best.matched,
    );
  }
  return BalanceReconciliation(
    status: ReconcileStatus.mismatch,
    derivedSigned: empty,
    checked: best.checked,
    matched: best.matched,
  );
}

class _Hypothesis {
  final List<double?> derivedSigned;
  final int checked;
  final int matched;
  const _Hypothesis(this.derivedSigned, this.checked, this.matched);
}

/// Tek bir sıralama hipotezini dener.
/// - forward (artan): satır i'nin işlemi bakiyeyi `balances[i-1] → balances[i]`
///   taşır, yani `signed[i] = balances[i] - balances[i-1]` (ilk satır çapadır).
/// - reverse (azalan): satır i'nin işlemi bakiyeyi `balances[i+1] → balances[i]`
///   taşır, yani `signed[i] = balances[i] - balances[i+1]` (son satır çapadır).
_Hypothesis _hypothesis(
  List<double?> magnitudes,
  List<double?> balances,
  double tolerance, {
  required bool reverse,
}) {
  final n = balances.length;
  final derived = List<double?>.filled(n, null);
  var checked = 0;
  var matched = 0;

  for (var i = 0; i < n; i++) {
    final prevIdx = reverse ? i + 1 : i - 1;
    if (prevIdx < 0 || prevIdx >= n) continue;
    final cur = balances[i];
    final prev = balances[prevIdx];
    if (cur == null || prev == null) continue;

    final signed = roundToCents(cur - prev);
    if (signed == 0) continue; // sıfır hareket ayırt edilemez

    final mag = magnitudes[i];
    if (mag == null) continue;
    checked++;
    if ((signed.abs() - mag).abs() <= tolerance) {
      matched++;
      derived[i] = signed;
    }
  }
  return _Hypothesis(derived, checked, matched);
}
