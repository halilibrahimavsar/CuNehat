import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

/// İçe aktarılan bir satırın BAĞLANMAYA aday olduğu kayıt türü (bkz.
/// `startLinkTransactionFlow`). Yalnız ÖNERİDİR: hiçbir satır kendiliğinden
/// bağlanmaz — kullanıcı "Bağla" demeden defter değişmez.
///
/// **Neden:** ekstredeki yatırım alımı, kredi taksidi ya da kredi girişi düz
/// gider/gelir olarak yazılır; kullanıcı aynı hareketi modülüne de girerse
/// para iki kez sayılır. Bitiş ekranı bu satırları gösterip "Bağla"yı
/// hatırlatır.
enum LinkHint {
  /// Gider: yatırım alımı (hisse, fon, altın, kripto).
  investment,

  /// Gider: kredi taksidi / borç ödemesi.
  debtPayment,

  /// Gelir: çekilen kredinin hesaba yatması.
  loanDisbursement,

  /// Gider: bankadan KREDİ KARTINA ödeme — kart cüzdanına transferdir
  /// (harcama değil; kartın harcamaları kart cüzdanında zaten sayılır).
  cardPayment,
}

/// [description]'dan bağlama ipucu. [inInvestmentCategory]: satırın
/// kategorisi kullanıcının "Yatırım" kategorisi (tahminle ya da elle seçilmiş).
///
/// Sözlük BİLEREK dar: yanlış öneri kullanıcıyı yorar, kaçan satır ise işlem
/// listesindeki "Bağla…" ile yine bağlanabilir. Gerçek ekstrelerde ölçüldü
/// (23 Eyl 2026, 5 dosya): kart ÖDEMESİ satırları ("... NOLU KART ODEMESI",
/// "... ILE BITEN KREDI KARTI ODEMESI", 10+ satır) borç ödemesi DEĞİLDİR —
/// kart cüzdanına transferdir ([LinkHint.cardPayment]).
LinkHint? linkHintOf(
  String description, {
  required bool isIncome,
  bool inInvestmentCategory = false,
}) {
  final text = ' ${CategoryGuesser.normalized(description)} ';
  bool any(List<String> words) => words.any(text.contains);
  if (isIncome) {
    return any(_disbursementWords) ? LinkHint.loanDisbursement : null;
  }
  if (inInvestmentCategory) return LinkHint.investment;
  if (_isCardPayment(text)) return LinkHint.cardPayment;
  if (any(_debtPaymentWords)) return LinkHint.debtPayment;
  return null;
}

/// "Kart ödemesi" — çıplak "kredi karti" YETMEZ (kart aidatı, kartla alışveriş
/// açıklamaları da içerir); ödeme/otomatik/tahsilat sözcüğüyle birlikte.
bool _isCardPayment(String text) =>
    text.contains('kart odeme') ||
    (text.contains('kredi kart') &&
        (text.contains('odeme') ||
            text.contains('otomatik') ||
            text.contains('tahsilat')));

/// [description]'da son 4 hanesi AYRI bir sayı olarak geçen TEK kartın
/// kimliği ("545847 5690 NOLU KART ODEMESI", "…******5690"); hiçbiri ya da
/// birden fazlası uyuyorsa `null` — yanlış karta bağlamaktansa sormak yeğdir.
String? cardIdByLast4(
  String description,
  Iterable<({String id, String last4})> cards,
) {
  String? found;
  for (final c in cards) {
    if (c.last4.length != 4) continue;
    final pattern = RegExp('(?<![0-9])${RegExp.escape(c.last4)}(?![0-9])');
    if (!pattern.hasMatch(description)) continue;
    if (found != null && found != c.id) return null;
    found = c.id;
  }
  return found;
}

const _debtPaymentWords = [
  'kredi taksit',
  'taksit tahsil',
  'kredi odemesi',
  'kredi geri odeme',
  'ihtiyac kredisi',
  'konut kredisi',
  'tasit kredisi',
];

const _disbursementWords = [
  'kullandirim',
  'kredi acilis',
  'ihtiyac kredisi',
  'konut kredisi',
  'tasit kredisi',
];

/// Yazılmış bir satır + neden bağlanmaya aday olduğu (bitiş ekranı listesi).
class LinkSuggestion {
  final TransactionEntity transaction;
  final LinkHint hint;

  const LinkSuggestion(this.transaction, this.hint);
}
