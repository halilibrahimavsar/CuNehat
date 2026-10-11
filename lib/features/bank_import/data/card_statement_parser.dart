/// Kredi kartı ekstresi okuyucusu.
///
/// Banka hesabı ekstresinden üç temel farkı var ve genel okuyucu üçünde de
/// yanılıyordu (gerçek QNB kart ekstreleriyle ölçüldü, 24 Eyl 2026):
///
/// 1. **İşaret ters:** kartta ARTI tutar harcamadır, EKSİ tutar ödeme/iadedir.
///    Genel okuyucu artıyı gelir sayıyordu — 23 satırın 20'si ters yazılırdı.
/// 2. **Tutar biçimi:** "Dönem içi hareketler" dökümü tutarı tek ondalıkla
///    yazar (`-3363,0 TRY`, `75,0 TRY`); genel okuyucu kesin iki ondalık
///    aradığı için 26 satırın 13'ünü atlıyordu. Tek ondalık YALNIZ burada
///    kabul edilir: genel regex'e eklenseydi ParaPuan (`0,0`) ve taksit
///    (`1/3,0`) sütunları da tutar sanılırdı.
/// 3. **Künye:** hesap ekstresi kesim tarihi, son ödeme, dönem borcu, asgari
///    ve limiti verir — kart cüzdanının "son ekstre" bilgisi buradan dolar ve
///    önceki bakiye + hareketler = dönem borcu özdeşliği satırların TAMAMININ
///    doğru okunduğunu kanıtlar.
///
/// Tanınan biçimler (QNB): kapanmış **hesap ekstresi** ("Kredi Kartı
/// Numarası" + "Hesap Kesim Tarihi") ve **dönem içi hareketler** ("… kartınıza
/// ait Dönem İçi Hareketler"). Tanınmayan metin için `null` döner; genel
/// okuyucu devam eder.
library;

import 'package:cunehat/core/utils/date_math.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/bank_import/data/statement_amount_parser.dart';
import 'package:cunehat/features/bank_import/data/statement_verification.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';

/// Kart ekstresinin künyesi (bankanın beyanı). Dönem içi dökümde yalnız
/// [last4] bulunur.
class CardStatementFacts {
  final DateTime? closingDate;
  final DateTime? dueDate;
  final double? statementBalance;
  final double? minimumPayment;
  final double? limit;
  final double? previousBalance;
  final String? last4;

  const CardStatementFacts({
    this.closingDate,
    this.dueDate,
    this.statementBalance,
    this.minimumPayment,
    this.limit,
    this.previousBalance,
    this.last4,
  });

  /// Kapanmış bir ekstre mi (kesim tarihi + dönem borcu beyan edilmiş)?
  bool get isClosedStatement => closingDate != null && statementBalance != null;
}

class CardStatementParseResult {
  final List<ImportDraft> drafts;
  final int skippedLines;
  final CardStatementFacts facts;
  final StatementVerification verification;

  const CardStatementParseResult({
    required this.drafts,
    required this.skippedLines,
    required this.facts,
    required this.verification,
  });
}

/// [rawText] tanınan bir kart ekstresiyse ayrıştırır; değilse `null`.
CardStatementParseResult? parseCardStatement(String rawText) {
  final folded = _ascii(rawText);
  final isClosed = folded.contains('kredi karti numarasi') &&
      folded.contains('hesap kesim tarihi');
  final isPeriod = folded.contains('kartiniza ait donem ici hareketler');
  if (!isClosed && !isPeriod) return null;

  // Künye ÖNCE: taksit satırları kapanmış ekstrede kesim tarihine göre
  // dönemine oturtulur (bkz. [_installmentOf]).
  final facts = isClosed ? _facts(rawText) : _periodFacts(rawText);
  final drafts = <ImportDraft>[];
  var skipped = 0;
  for (final raw in rawText.split('\n')) {
    final line = raw.trim();
    if (!_startsWithDate.hasMatch(line)) continue;
    final row =
        isPeriod ? _periodRow(line) : _closedRow(line, facts.closingDate);
    if (row == null) {
      // Tarihle başlayan başlık ("23/09/2026 tarihli … Dönem İçi Hareketler")
      // hareket değildir; yalnız tutar taşıyan okunamamış satır sayılır.
      if (_hasAmount.hasMatch(line)) skipped++;
      continue;
    }
    drafts.add(row);
  }

  return CardStatementParseResult(
    drafts: drafts,
    skippedLines: skipped,
    facts: facts,
    verification: _verify(drafts, facts),
  );
}

final _startsWithDate = RegExp(r'^\d{2}/\d{2}/\d{4}\s');
final _hasAmount = RegExp(r'\d[.,]\d');

/// Hesap ekstresi satırı: `27/07/2026 AÇIKLAMA 3,481.71 [2/6]` — İngilizce
/// gruplama, iki ondalık, isteğe bağlı taksit sütunu.
final _closedRowRe = RegExp(
  r'^(\d{2}/\d{2}/\d{4})\s+(.+?)\s+(-?\d{1,3}(?:,\d{3})*\.\d{2})'
  r'(?:\s+(\d{1,2})\s*/\s*(\d{1,2}))?\s*$',
);

/// Dönem içi satırı: `27/08/2026 AÇIKLAMA -3363,0 TRY 1/3,0 0,0` — virgül
/// ondalık (tek ya da iki hane), para birimi, "güncel/toplam" taksit,
/// ParaPuan.
final _periodRowRe = RegExp(
  r'^(\d{2}/\d{2}/\d{4})\s+(.+?)\s+(-?\d{1,3}(?:\.\d{3})+(?:,\d{1,2})?|-?\d+(?:,\d{1,2})?)'
  r'\s+(?:TRY|TL)\s+(\d{1,2})/(\d{1,2})(?:,\d+)?(?:\s+\S+)?\s*$',
);

ImportDraft? _closedRow(String line, DateTime? closingDate) {
  final m = _closedRowRe.firstMatch(line);
  if (m == null) return null;
  final amount = parseSignedMoney(m.group(3)!);
  return _draft(
    date: m.group(1)!,
    description: m.group(2)!,
    signed: amount,
    current: int.tryParse(m.group(4) ?? ''),
    total: int.tryParse(m.group(5) ?? ''),
    closingDate: closingDate,
  );
}

ImportDraft? _periodRow(String line) {
  final m = _periodRowRe.firstMatch(line);
  if (m == null) return null;
  final text = m.group(3)!.replaceAll('.', '').replaceAll(',', '.');
  return _draft(
    date: m.group(1)!,
    description: m.group(2)!,
    signed: double.tryParse(text),
    current: int.tryParse(m.group(4)!),
    total: int.tryParse(m.group(5)!),
  );
}

ImportDraft? _draft({
  required String date,
  required String description,
  required double? signed,
  int? current,
  int? total,
  DateTime? closingDate,
}) {
  final parts = date.split('/');
  var day = DateTime(
    int.parse(parts[2]),
    int.parse(parts[1]),
    int.parse(parts[0]),
  );
  if (signed == null || moneyEquals(signed, 0)) return null;
  var text = description.replaceAll(RegExp(r'\s+'), ' ').trim();
  // Ödeme satırının açıklaması bazı ekstrelerde font eşlemesi bozuk gelir
  // ("4 deme - Tesekk0 r Ederiz"); bankanın sabit metni olduğu için
  // tanınıp düzeltilir.
  if (signed < 0 && _ascii(text).contains('tesekk')) {
    text = 'Ödeme - Teşekkür Ederiz';
  }
  DraftInstallment? installment;
  if (signed > 0 &&
      total != null &&
      total > 1 &&
      current != null &&
      current > 0 &&
      current <= total) {
    installment = _installmentOf(day, current, total, closingDate);
    // Satır TAKSİTİN ayına yazılır (bkz. [DraftInstallment]).
    day = installment.dateOf(current);
    // İki döküm aynı alışverişi farklı yazar ("20260911 TRENDYOL.COM 2.
    // Taksit" / "TRENDYOL.COM"); ortak ada indirilir ki biri ötekinin
    // tekrarı olarak bulunabilsin.
    text = _installmentTitle(text);
    // Taksit numarası kimliğin PARÇASIDIR: 2/6, 1/6'nın tekrarı sanılmasın.
    final marker = '($current/$total)';
    if (!text.contains(marker)) text = '$text $marker'.trim();
  }
  return ImportDraft(
    date: day,
    description: text.isEmpty ? 'Kart işlemi' : text,
    amount: roundToCents(signed.abs()),
    // Kart kuralı: ARTI harcama, EKSİ ödeme/iade.
    type:
        signed > 0 ? TransactionTypeModel.expense : TransactionTypeModel.income,
    installment: installment,
  );
}

/// Taksit satırının hangi alışverişe ve hangi aya ait olduğu.
///
/// Banka satıra alışverişin ÖZGÜN tarihini yazar; [no]. taksit o tarihten
/// `no − 1` ay sonradır. Kapanmış ekstrede ([closingDate] biliniyor) daha
/// sağlam bir kanıt var: satır BU ekstrededir, yani taksit bu ekstrenin
/// dönemine düşer — alışveriş günü o döneme oturtulur. Ertelemeli taksit ya
/// da geç yansıyan işlemde de satır doğru ekstrede kalır.
DraftInstallment _installmentOf(
  DateTime rowDay,
  int no,
  int count,
  DateTime? closingDate,
) {
  if (closingDate == null) {
    return DraftInstallment(no: no, count: count, purchaseDate: rowDay);
  }
  // Dönem: önceki kesimin ertesi günü … kesim günü. Alışveriş günü kesim
  // gününden büyükse dönemin İLK ayına, değilse kesim ayına düşer.
  var inPeriod = addMonthsAnchored(
    DateTime(closingDate.year, closingDate.month),
    0,
    rowDay.day,
  );
  if (inPeriod.isAfter(closingDate)) {
    inPeriod = addMonthsAnchored(inPeriod, -1, rowDay.day);
  }
  return DraftInstallment(
    no: no,
    count: count,
    purchaseDate: addMonthsAnchored(inPeriod, -(no - 1), rowDay.day),
  );
}

/// "20260911 TRENDYOL.COM 2. Taksit" → "TRENDYOL.COM": dönem içi dökümünün
/// başa yazdığı alışveriş tarihi ve sona yazdığı taksit sırası atılır.
String _installmentTitle(String text) => text
    .replaceFirst(RegExp(r'^\d{8}\s+'), '')
    .replaceFirst(
        RegExp(r'\s+\d{1,2}\.\s*taksit\s*$', caseSensitive: false), '')
    .trim();

CardStatementFacts _facts(String raw) {
  double? money(RegExp re) {
    final m = re.firstMatch(raw);
    return m == null ? null : parseSignedMoney(m.group(1)!);
  }

  DateTime? date(RegExp re) {
    final m = re.firstMatch(raw);
    if (m == null) return null;
    final p = m.group(1)!.split('/');
    return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
  }

  return CardStatementFacts(
    closingDate: date(RegExp(r'Hesap Kesim Tarihi\s*:\s*(\d{2}/\d{2}/\d{4})')),
    dueDate: _dueDate(raw),
    // Bazı glifler eşlemesiz gelir ("D2 nem Borcu", "Asgari 3 deme"):
    // desenler bozulabilen harflerin ÇEVRESİNE dayanır.
    statementBalance:
        money(RegExp(r'nem Borcu\s*:\s*(-?[\d.,]+)\s*(?:TL|TRY)')),
    minimumPayment: money(
        RegExp(r'Asgari[^:\n]{0,12}Tutar[ıi]\s*:\s*([\d.,]+)\s*(?:TL|TRY)')),
    limit: money(RegExp(r'Kredi Kart[ıi] Limiti\s*:\s*([\d.,]+)')),
    previousBalance:
        money(RegExp(r'nceki\s+D\S*\s*nem Bakiyeniz\s+(-?[\d.,]+)')),
    last4: _last4Of(RegExp(r'Kredi Kart[ıi] Numaras[ıi]\s*:\s*([\d\s*]{8,25})')
        .firstMatch(raw)
        ?.group(1)),
  );
}

/// Maskeli kart numarasının ("5458 47** **** 5690") son dört rakamı.
String? _last4Of(String? masked) {
  if (masked == null) return null;
  final m = RegExp(r'(\d{4})\s*$').firstMatch(masked.trim());
  return m?.group(1);
}

CardStatementFacts _periodFacts(String raw) => CardStatementFacts(
      last4: RegExp(r'son 4 hanesi (\d{4})').firstMatch(raw)?.group(1),
    );

/// "Son Ödeme Tarihi: 04 Eylül 2026, Cuma" — ay adı font yüzünden bozuk
/// gelebilir ("Eyl6 l"); yalnız ilk üç harfine bakılır.
DateTime? _dueDate(String raw) {
  final m = RegExp(
    r'deme Tarihi\s*:\s*(\d{1,2})\s+([^\s\d,]+)[^\n,]*?(\d{4})',
  ).firstMatch(raw);
  if (m == null) return null;
  final prefix = _ascii(m.group(2)!).replaceAll(RegExp(r'[^a-z]'), '');
  if (prefix.length < 3) return null;
  const months = [
    'oca', 'sub', 'mar', 'nis', 'may', 'haz', //
    'tem', 'agu', 'eyl', 'eki', 'kas', 'ara',
  ];
  final month = months.indexOf(prefix.substring(0, 3)) + 1;
  if (month == 0) return null;
  return DateTime(int.parse(m.group(3)!), month, int.parse(m.group(1)!));
}

/// Önceki dönem bakiyesi + Σ(harcama) − Σ(ödeme/iade) = dönem borcu.
StatementVerification _verify(
  List<ImportDraft> drafts,
  CardStatementFacts facts,
) {
  final declared = facts.statementBalance;
  if (declared == null) return StatementVerification.none;
  final previous = facts.previousBalance ?? 0;
  var computed = previous;
  for (final d in drafts) {
    computed += d.isIncome ? -d.amount : d.amount;
  }
  computed = roundToCents(computed);
  final passed = (computed - declared).abs() <= 0.02;
  return StatementVerification(
    status: passed
        ? StatementVerificationStatus.verified
        : StatementVerificationStatus.failed,
    checks: [
      StatementCheck(
        kind: StatementCheckKind.closingBalance,
        passed: passed,
        detail: 'beklenen ${declared.toStringAsFixed(2)} — '
            'hesaplanan ${computed.toStringAsFixed(2)}',
      ),
    ],
  );
}

/// Türkçe harfleri ASCII'ye katlar, küçültür (tanıma ve ay adı için).
String _ascii(String s) => CategoryGuesser.normalized(s);
