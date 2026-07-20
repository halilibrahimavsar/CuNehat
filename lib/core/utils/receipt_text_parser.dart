/// Fiş OCR ham metninden tutar/tarih/satıcı çıkaran SAF sezgisel ayrıştırıcı.
///
/// Bilerek ML Kit'ten bağımsızdır: girdi düz metin, çıktı [ReceiptScanResult].
/// Böylece cihaz/kamera olmadan birim testle doğrulanabilir. Sonuç yalnızca
/// formu ÖN-DOLDURUR; kullanıcı kaydetmeden önce kontrol eder (asla otomatik
/// kayıt yok).
library;

import 'package:cunehat/core/utils/money_math.dart';

class ReceiptScanResult {
  /// Bulunan toplam tutar (kuruşa yuvarlı) — bulunamazsa null.
  final double? amount;

  /// Bulunan fiş tarihi — bulunamazsa null.
  final DateTime? date;

  /// Tahmini satıcı/başlık (en üst anlamlı satır) — bulunamazsa null.
  final String? merchant;

  /// OCR'ın döndürdüğü ham metin (hata ayıklama/gösterim için).
  final String rawText;

  const ReceiptScanResult({
    this.amount,
    this.date,
    this.merchant,
    required this.rawText,
  });

  /// Forma yazılacak anlamlı bir şey bulunduysa true.
  bool get hasAnyField => amount != null || date != null || merchant != null;
}

/// Toplam tutar anahtarları, DÜŞÜK→YÜKSEK öncelik sırasıyla (indeks = skor;
/// büyük indeks kazanır). "GENEL TOPLAM" zaten "TOPLAM" içerdiğinden en sonda
/// olmalı ki bir GENEL TOPLAM satırı yalın TOPLAM'ı geçsin. "ARA TOPLAM"/"KDV"
/// satırları toplam DEĞİLDİR; [_totalNegativeKeywords] ile ayıklanır.
const _totalKeywords = <String>[
  'ODENE', // ÖDENEN / ODENEN
  'TOTAL',
  'TUTAR',
  'TOPLAM',
  'GENEL TOPLAM',
];

const _totalNegativeKeywords = <String>['ARA TOPLAM', 'KDV', 'ARA'];

/// Para benzeri token: en az iki rakam ya da tek rakam.
final _moneyToken = RegExp(r'\d[\d.,]*\d|\d');

/// gg.aa.yyyy / gg/aa/yy gibi tarihler (ayraç . / -).
final _dateRe = RegExp(r'(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})');

ReceiptScanResult parseReceiptText(String raw) {
  final lines = raw
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  return ReceiptScanResult(
    amount: _extractAmount(lines),
    date: _extractDate(raw),
    merchant: _extractMerchant(lines),
    rawText: raw,
  );
}

/// Türkçe "ı" / diğer aksanları anahtar eşleşmesi için kabaca normalize eder.
String _normalizeUpper(String s) => s
    .toUpperCase()
    .replaceAll('İ', 'I')
    .replaceAll('Ö', 'O')
    .replaceAll('Ü', 'U')
    .replaceAll('Ş', 'S')
    .replaceAll('Ç', 'C')
    .replaceAll('Ğ', 'G');

double? _extractAmount(List<String> lines) {
  double? best;
  int bestScore = -1;

  for (var i = 0; i < lines.length; i++) {
    final upper = _normalizeUpper(lines[i]);
    if (_totalNegativeKeywords.any(upper.contains)) continue;

    // Öncelik: listede sonra gelen anahtar (GENEL TOPLAM) daha yüksek skor.
    var score = -1;
    for (var k = 0; k < _totalKeywords.length; k++) {
      if (upper.contains(_normalizeUpper(_totalKeywords[k]))) {
        score = k;
      }
    }
    if (score < 0) continue;

    // Anahtarın olduğu satırda; yoksa bir alt satırda tutarı ara.
    var value = _largestMoneyInLine(lines[i]);
    if (value == null && i + 1 < lines.length) {
      value = _largestMoneyInLine(lines[i + 1]);
    }
    if (value == null) continue;

    // Yüksek öncelikli anahtar kazanır; eşitlikte büyük tutar (toplamlar en
    // büyüktür — mükerrer TOPLAM satırlarında güvenli seçim).
    if (score > bestScore || (score == bestScore && (best == null || value > best))) {
      bestScore = score;
      best = value;
    }
  }

  // Hiç anahtar eşleşmediyse: tüm belgedeki en büyük para benzeri değer.
  best ??= _largestMoneyOverall(lines);
  return best == null ? null : roundToCents(best);
}

double? _largestMoneyInLine(String line) {
  double? max;
  for (final m in _moneyToken.allMatches(line)) {
    final token = m.group(0)!;
    if (!_looksLikeMoney(token)) continue;
    final v = parseMoneyToken(token);
    if (v != null && (max == null || v > max)) max = v;
  }
  return max;
}

double? _largestMoneyOverall(List<String> lines) {
  double? max;
  for (final line in lines) {
    if (_totalNegativeKeywords.any(_normalizeUpper(line).contains)) continue;
    final v = _largestMoneyInLine(line);
    if (v != null && (max == null || v > max)) max = v;
  }
  return max;
}

/// Ondalık ayracı (son `,` veya `.`) 1-2 rakam ile bitiyorsa "para gibi".
/// Böylece yıl/adet gibi düz tam sayılar toplam sanılmaz.
bool _looksLikeMoney(String token) {
  final idx = _lastSepIndex(token);
  if (idx == -1) return false;
  final frac = token.substring(idx + 1);
  return frac.isNotEmpty && frac.length <= 2 && int.tryParse(frac) != null;
}

int _lastSepIndex(String token) {
  final lastComma = token.lastIndexOf(',');
  final lastDot = token.lastIndexOf('.');
  return lastComma > lastDot ? lastComma : lastDot;
}

/// Karışık ayraçlı bir parasal token'ı double'a çevirir.
/// Son ayraçtan sonra 1-2 rakam varsa o ondalıktır; kalan tüm ayraçlar
/// binlik gruplamadır. 3+ rakamsa (ör. "1.500") token bütünüyle tam sayıdır.
double? parseMoneyToken(String token) {
  final cleaned = token.replaceAll(RegExp(r'[^\d.,]'), '');
  if (cleaned.isEmpty) return null;

  final idx = _lastSepIndex(cleaned);
  if (idx == -1) {
    return double.tryParse(cleaned);
  }

  final frac = cleaned.substring(idx + 1);
  final intPart = cleaned.substring(0, idx).replaceAll(RegExp(r'[.,]'), '');

  if (frac.isNotEmpty && frac.length <= 2 && int.tryParse(frac) != null) {
    final digits = intPart.isEmpty ? '0' : intPart;
    return double.tryParse('$digits.$frac');
  }
  // Ondalık değil → tüm ayraçlar gruplama.
  return double.tryParse(cleaned.replaceAll(RegExp(r'[.,]'), ''));
}

DateTime? _extractDate(String raw) {
  for (final m in _dateRe.allMatches(raw)) {
    var day = int.parse(m.group(1)!);
    var month = int.parse(m.group(2)!);
    var year = int.parse(m.group(3)!);

    // 4 haneli grup önce gelirse (yyyy.aa.gg) day/year yer değiştirir.
    if (day > 31 && year <= 31) {
      final t = day;
      day = year;
      year = t;
    }
    if (year < 100) year += 2000;

    if (month < 1 || month > 12 || day < 1 || day > 31) continue;
    if (year < 2000 || year > 2100) continue;
    return DateTime(year, month, day);
  }
  return null;
}

String? _extractMerchant(List<String> lines) {
  for (final line in lines) {
    // Harf içeren, en az 3 karakterlik ilk anlamlı satır.
    if (line.length < 3) continue;
    if (!RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]').hasMatch(line)) continue;
    final upper = _normalizeUpper(line);
    if (_totalKeywords.any((k) => upper.contains(_normalizeUpper(k)))) continue;
    return line;
  }
  return null;
}
