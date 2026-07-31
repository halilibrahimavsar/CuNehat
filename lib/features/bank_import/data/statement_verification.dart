/// İçe aktarmanın **doğruluğunu kanıtlayan** katman.
///
/// Bir ekstre ayrıştırıcısı "makul görünen" satırlar üretebilir ve yine de
/// yanlış olabilir — kullanıcının bunu fark etmesinin tek yolu, aylar sonra
/// bakiyenin tutmamasıdır. Oysa banka ekstreleri kendi doğrulama verilerini
/// zaten taşır:
///
/// - **Bakiye sütunu**: ardışık iki satırın farkı = o hareketin işaretli
///   tutarı. Her satırı BAĞIMSIZ olarak doğrular (ölçüm: gerçek QNB
///   ekstresinde 163/163, Garanti'de 84/84).
/// - **Beyan edilen kayıt sayısı**: "85 kayıt bulunmuştur" → hiçbir satır
///   kaçmadığını kanıtlar.
/// - **Devreden/kapanış bakiyesi**: "DEVREDEN BAKİYE 0.00", "Bakiye : 12,28 TL".
/// - **Borç/Alacak toplamları**: Ziraat ekstresi sayfanın altında verir.
///
/// Bu katman o beyanları metinden okur, ayrıştırılan veriden hesaplananla
/// karşılaştırır ve sonucu üç durumda özetler. Amaç kullanıcıya "muhtemelen
/// doğru" değil, **"aritmetik olarak doğrulandı"** ya da **"doğrulanamadı,
/// kontrol et"** diyebilmektir. Özellikle OCR yolunu (taranmış ekstre)
/// güvenle yayınlanabilir kılan tek mekanizma budur.
///
/// Saf/test edilebilir: UI, dosya ya da PDF bağımlılığı yok.
library;

import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/bank_import/data/balance_reconciler.dart';

enum StatementCheckKind {
  /// Bakiye sütunu zinciri her satırın tutar+işaretini doğruladı mı?
  balanceChain,

  /// Ekstrenin beyan ettiği hareket sayısı ile bulunan eşleşiyor mu?
  recordCount,

  /// Beyan edilen devreden (açılış) bakiyesi tutuyor mu?
  openingBalance,

  /// Beyan edilen kapanış bakiyesi tutuyor mu?
  closingBalance,

  /// Beyan edilen Borç/Alacak toplamları tutuyor mu?
  totals,
}

class StatementCheck {
  final StatementCheckKind kind;
  final bool passed;

  /// Kullanıcıya gösterilecek kısa kanıt ("85 / 85", "beklenen 12,28 —
  /// hesaplanan 12,28").
  final String detail;

  const StatementCheck({
    required this.kind,
    required this.passed,
    required this.detail,
  });
}

enum StatementVerificationStatus {
  /// Çalıştırılabilen tüm kontroller geçti → aritmetik olarak doğrulandı.
  verified,

  /// En az bir kontrol TUTMADI → veri eksik/yanlış olabilir, kullanıcı bakmalı.
  failed,

  /// Hiçbir kontrol çalıştırılamadı (bakiye sütunu yok, beyan yok) → sessiz.
  unavailable,
}

class StatementVerification {
  final StatementVerificationStatus status;
  final List<StatementCheck> checks;

  const StatementVerification({
    required this.status,
    required this.checks,
  });

  static const none = StatementVerification(
    status: StatementVerificationStatus.unavailable,
    checks: [],
  );

  Iterable<StatementCheck> get failures => checks.where((c) => !c.passed);
  Iterable<StatementCheck> get passes => checks.where((c) => c.passed);
}

/// [signedAmounts] ve [balances] DOSYA SIRASINDA ve aynı uzunlukta olmalıdır.
/// [sourceText] ekstrenin ham metni (beyan edilen değerler oradan okunur).
StatementVerification verifyStatement({
  required List<double> signedAmounts,
  required List<double?> balances,
  required BalanceReconciliation reconciliation,
  required String sourceText,
  required bool englishGrouping,
  double tolerance = 0.02,
}) {
  final checks = <StatementCheck>[];

  // Beyan arama TÜRKÇE KATLANMIŞ metin üzerinde yapılır. `caseSensitive: false`
  // tek başına yetmez: 'İ' (U+0130) küçük harfe çevrilince 'i' + birleşen
  // nokta olur ve 'i' ile EŞLEŞMEZ — bu yüzden gerçek bir QNB ekstresindeki
  // "DEVREDEN BAKİYE" beyanı hiç bulunamıyordu. Katlama uzunluğu korur
  // (her karakter tek karaktere gider), böylece pencere indeksleri geçerli
  // kalır ve rakam/ayraçlara dokunulmaz.
  final text = _foldTr(sourceText);

  // --- 1) Bakiye zinciri ---
  if (reconciliation.checked > 0) {
    final all = reconciliation.matched == reconciliation.checked;
    checks.add(StatementCheck(
      kind: StatementCheckKind.balanceChain,
      passed: all,
      detail: '${reconciliation.matched} / ${reconciliation.checked}',
    ));
  }

  // --- 2) Beyan edilen kayıt sayısı ---
  final declaredCount = _declaredRecordCount(text);
  if (declaredCount != null) {
    checks.add(StatementCheck(
      kind: StatementCheckKind.recordCount,
      passed: declaredCount == signedAmounts.length,
      detail: '${signedAmounts.length} / $declaredCount',
    ));
  }

  // --- 3/4) Açılış ve kapanış bakiyesi ---
  final (computedOpening, computedClosing) = _chainEnds(
    signedAmounts: signedAmounts,
    balances: balances,
    reverseOrder: reconciliation.reverseOrder,
  );

  final declaredOpening = _declaredMoney(
    text,
    RegExp(r'devreden[ \t]*bakiye'),
    englishGrouping,
  );
  if (declaredOpening != null && computedOpening != null) {
    checks.add(StatementCheck(
      kind: StatementCheckKind.openingBalance,
      passed: (declaredOpening - computedOpening).abs() <= tolerance,
      detail: '${_fmt(computedOpening)} / ${_fmt(declaredOpening)}',
    ));
  }

  // Kapanış bakiyesi yalnız İKİ NOKTA ile beyan edilmiş sayılır
  // ("Bakiye : 12,28 TL"). Aksi halde tablonun "Bakiye" sütun BAŞLIĞI da
  // eşleşir ve ardındaki ilk hareketin bakiyesi beyan sanılırdı.
  final declaredClosing = _declaredMoney(
    text,
    RegExp(r'(?:kullanilabilir[ \t]+)?bakiye[ \t]*:'),
    englishGrouping,
  );
  if (declaredClosing != null && computedClosing != null) {
    checks.add(StatementCheck(
      kind: StatementCheckKind.closingBalance,
      passed: (declaredClosing - computedClosing).abs() <= tolerance,
      detail: '${_fmt(computedClosing)} / ${_fmt(declaredClosing)}',
    ));
  }

  // --- 5) Borç/Alacak toplamları ---
  final declaredDebit = _declaredMoney(
    text,
    RegExp(r'borc[ \t]*:'),
    englishGrouping,
  );
  final declaredCredit = _declaredMoney(
    text,
    RegExp(r'alacak[ \t]*:'),
    englishGrouping,
  );
  if (declaredDebit != null || declaredCredit != null) {
    final computedDebit = roundToCents(signedAmounts
        .where((a) => a < 0)
        .fold<double>(0, (sum, a) => sum + a.abs()));
    final computedCredit = roundToCents(
        signedAmounts.where((a) => a > 0).fold<double>(0, (sum, a) => sum + a));
    final debitOk = declaredDebit == null ||
        (declaredDebit.abs() - computedDebit).abs() <= tolerance;
    final creditOk = declaredCredit == null ||
        (declaredCredit.abs() - computedCredit).abs() <= tolerance;
    checks.add(StatementCheck(
      kind: StatementCheckKind.totals,
      passed: debitOk && creditOk,
      detail: 'B ${_fmt(computedDebit)}/${_fmt(declaredDebit?.abs())} · '
          'A ${_fmt(computedCredit)}/${_fmt(declaredCredit?.abs())}',
    ));
  }

  if (checks.isEmpty) return StatementVerification.none;
  final failed = checks.any((c) => !c.passed);
  return StatementVerification(
    status: failed
        ? StatementVerificationStatus.failed
        : StatementVerificationStatus.verified,
    checks: checks,
  );
}

/// Bakiye zincirinin uçları. Artan sırada (eskiden yeniye) kapanış SON
/// satırın bakiyesi, açılış İLK satırın bakiyesinden o satırın tutarının
/// çıkarılmasıdır; azalan sırada tam tersi.
(double?, double?) _chainEnds({
  required List<double> signedAmounts,
  required List<double?> balances,
  required bool reverseOrder,
}) {
  if (balances.isEmpty || balances.length != signedAmounts.length) {
    return (null, null);
  }
  final firstBalance = balances.first;
  final lastBalance = balances.last;
  if (firstBalance == null || lastBalance == null) return (null, null);

  if (reverseOrder) {
    return (
      roundToCents(lastBalance - signedAmounts.last),
      firstBalance,
    );
  }
  return (
    roundToCents(firstBalance - signedAmounts.first),
    lastBalance,
  );
}

/// "85 kayıt bulunmuştur" / "85 hareket" gibi bir beyan (katlanmış metinde).
///
/// İki sınırlama kasıtlı ve GERÇEK bir yanlış-pozitiften öğrenildi: gevşek
/// bir `\s+` satır sonunu da geçtiği için QNB ekstresinde "…21/07/2026" ile
/// sonraki satırın "Hareket Tipi"si birleşip beyan **2026** okunuyor ve
/// doğrulama sahte biçimde "TUTMADI" diyordu.
/// - Ayırıcı yalnız aynı satırdaki boşluk/sekme olabilir.
/// - Sayı bir tarihin parçası olamaz (öncesinde rakam ya da tarih ayracı yok).
int? _declaredRecordCount(String text) {
  final m = RegExp(
    r'(?<![\d/.\-])(\d{1,6})[ \t]+(?:kayit|hareket|islem|record|transaction)',
  ).firstMatch(text);
  if (m == null) return null;
  return int.tryParse(m.group(1)!);
}

/// Türkçe aksanı ASCII'ye indirir ve küçük harfe çevirir. **Uzunluk korunur**
/// (her karakter tek karaktere gider) — `_declaredMoney` katlanmış metinde
/// indeks penceresi kullandığı için bu şart.
String _foldTr(String s) => s
    .replaceAll('İ', 'i')
    .replaceAll('I', 'i')
    .replaceAll('ı', 'i')
    .replaceAll('Ş', 's')
    .replaceAll('ş', 's')
    .replaceAll('Ğ', 'g')
    .replaceAll('ğ', 'g')
    .replaceAll('Ü', 'u')
    .replaceAll('ü', 'u')
    .replaceAll('Ö', 'o')
    .replaceAll('ö', 'o')
    .replaceAll('Ç', 'c')
    .replaceAll('ç', 'c')
    .toLowerCase();

/// [label] etiketinden SONRA gelen ilk para değerini okur (aynı satırda ya da
/// hemen ardından). Etiket bulunamazsa `null`.
double? _declaredMoney(String text, RegExp label, bool englishGrouping) {
  final m = label.firstMatch(text);
  if (m == null) return null;
  // Etiketten sonraki kısa pencere: daha uzağa bakmak, tabloların ilk
  // satırındaki alakasız bir tutarı beyan sanma riskini getirir.
  final start = m.end;
  final end = (start + 60).clamp(0, text.length);
  final window = text.substring(start, end);
  final moneyRe = englishGrouping
      ? RegExp(r'[-+(]?\d{1,3}(?:,\d{3})*\.\d{2}\)?')
      : RegExp(r'[-+(]?\d{1,3}(?:\.\d{3})*,\d{2}\)?');
  final money = moneyRe.firstMatch(window);
  if (money == null) return null;
  final raw = money.group(0)!;
  final negative =
      raw.contains('-') || (raw.startsWith('(') && raw.endsWith(')'));
  final digits = raw
      .replaceAll(RegExp(r'[-+()]'), '')
      .replaceAll(englishGrouping ? ',' : '.', '')
      .replaceAll(englishGrouping ? '.' : ',', '.');
  final v = double.tryParse(digits);
  if (v == null) return null;
  return roundToCents(negative ? -v : v);
}

String _fmt(double? v) => v == null ? '—' : v.toStringAsFixed(2);
