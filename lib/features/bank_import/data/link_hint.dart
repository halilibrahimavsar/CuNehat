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
}

/// [description]'dan bağlama ipucu. [inInvestmentCategory]: satırın
/// kategorisi kullanıcının "Yatırım" kategorisi (tahminle ya da elle seçilmiş).
///
/// Sözlük BİLEREK dar: yanlış öneri kullanıcıyı yorar, kaçan satır ise işlem
/// listesindeki "Bağla…" ile yine bağlanabilir. Gerçek ekstrelerde ölçüldü
/// (23 Eyl 2026, 5 dosya): kart ÖDEMESİ satırları ("... NOLU KART ODEMESI")
/// borç ödemesi DEĞİLDİR — kart cüzdanına transferdir (kredi kartı fazı);
/// "kredi karti" geçen satır bu yüzden borç ödemesi sayılmaz.
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
  if (any(_cardPaymentWords)) return null;
  if (any(_debtPaymentWords)) return LinkHint.debtPayment;
  return null;
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

const _cardPaymentWords = [
  'kredi karti',
  'kredi kart',
  'kart odeme',
];

/// Yazılmış bir satır + neden bağlanmaya aday olduğu (bitiş ekranı listesi).
class LinkSuggestion {
  final TransactionEntity transaction;
  final LinkHint hint;

  const LinkSuggestion(this.transaction, this.hint);
}
