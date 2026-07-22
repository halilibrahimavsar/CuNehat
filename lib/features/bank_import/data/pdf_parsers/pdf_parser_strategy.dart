import 'package:cunehat/features/bank_import/data/statement_amount_parser.dart';
import 'package:cunehat/features/bank_import/data/statement_date_parser.dart';
import 'package:cunehat/features/bank_import/domain/column_mapping.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';

/// Bir [parse] çağrısının sonucu: üretilen taslaklar + tarih/tutarı
/// çözülemediği için atlanan satır sayısı (UI'da "N satır atlandı" için).
typedef PdfParseLines = ({List<ImportDraft> drafts, int skippedLines});

/// PDF metninden taslak çıkaran stratejilerin arayüzü. Satır-sezgisel ortak
/// gövde burada tek yerde yaşar; bankaya özel alt sınıflar yalnız anahtar
/// kelime + (varsa) işaret/açıklama sapmalarını sağlar — [akbank_pdf_parser],
/// [garanti_pdf_parser], [ziraat_pdf_parser] aksi halde birebir aynı
/// regex/döngüyü kopyalıyordu.
abstract class PdfParserStrategy {
  const PdfParserStrategy();

  static final _dateRe = RegExp(r'\d{1,2}[./-]\d{1,2}[./-]\d{2,4}');

  /// Virgül-binlik/nokta-ondalık ("6,500.00" — İngilizce/Akbank-QNB biçimi).
  static const _englishGroupedSrc =
      r'[-+(]?\s*\d{1,3}(?:,\d{3})+\.\d{2}\s*\)?\s*-?';

  /// Nokta-binlik/virgül-ondalık ("1.234,56" — TR biçimi).
  static const _turkishGroupedSrc =
      r'[-+(]?\s*\d{1,3}(?:\.\d{3})+,\d{2}\s*\)?\s*-?';

  /// Binliksiz sade ondalık ("67.00"/"90,00") — biçimden bağımsız, KESİN 2
  /// haneli ondalık aranır (açgözlü değil).
  static const _simpleDecimalSrc = r'[-+(]?\s*\d+[.,]\d{2}\s*\)?\s*-?';

  /// Belge genelinde binlik-ayraç biçimini (varsa) tespit etmek için işaretçi:
  /// bir rakamdan sonra virgül/nokta + TAM 3 rakam (4.+ rakam değil).
  static final _englishGroupMarker = RegExp(r'\d,\d{3}(?!\d)');
  static final _turkishGroupMarker = RegExp(r'\d\.\d{3}(?!\d)');

  /// Belgede GERÇEKTEN kullanılan binlik biçimine göre parasal token regex'i
  /// kurar. İki biçimi TEK regex'te birlikte aramak (eski hâl) bitişik
  /// (boşluksuz) Tutar+Bakiye durumunda birbirine karışabiliyordu: ör.
  /// "263.44" (Tutar, İngilizce ondalık) hemen ardından boşluksuz "3,902.50"
  /// (Bakiye) gelirse "263.443,902.50" oluşur ve TR-biçim alternatifi bunu
  /// TEK sayı sanıp "263.443,90" (=263443.90) diye YANLIŞ eşleşir — tutar
  /// 1000 kat büyür. Çözüm: belge genelinde hangi biçim baskınsa (bir banka
  /// exportu asla iki biçimi karıştırmaz) yalnız O gruplu biçimi + biçimden
  /// bağımsız sade ondalığı ara; öteki biçimin gruplu alternatifi hiç
  /// denenmediği için bitişik durumda köprü kuramaz.
  static RegExp moneyPatternFor(String text) {
    final english = _englishGroupMarker.allMatches(text).length;
    final turkish = _turkishGroupMarker.allMatches(text).length;
    final grouped = turkish > english ? _turkishGroupedSrc : _englishGroupedSrc;
    return RegExp('$grouped|$_simpleDecimalSrc');
  }

  /// Başlıkta anahtar kelime aramasının sınırlandığı satır sayısı.
  static const _headerLineLimit = 20;

  /// Anahtar kelimeleri yalnız belge BAŞLIĞINDA (ilk [_headerLineLimit]
  /// satır) arar. Tüm belgede aramak yerine bunu tercih etmemizin nedeni:
  /// bir Garanti/Ziraat ekstresindeki bir EFT açıklamasında karşı tarafın
  /// bankası olarak "Akbank" geçebilir — tüm metinde arama bu durumda yanlış
  /// stratejiyi (Akbank) sessizce tetikler. Banka adı gerçekte hep ekstre
  /// başlığında/logosunda yer alır, satır listesinde değil.
  static bool keywordInHeader(String text, List<String> keywords) {
    final header =
        text.split('\n').take(_headerLineLimit).join('\n').toLowerCase();
    return keywords.any(header.contains);
  }

  static bool isNegativeToken(String token) {
    final t = token.trim();
    return t.contains('-') || (t.startsWith('(') && t.endsWith(')'));
  }

  /// Bu strateji, verilen metni (veya bankayı) ayrıştırabilir mi?
  bool canParse(String text);

  /// Açıklama hücresi boş çıkarsa kullanılacak yedek metin (bankaya özel).
  String get emptyDescriptionFallback => 'İşlem';

  /// İşaret → yön. Varsayılan: '-' ya da '(...)' = gider, aksi = gelir.
  /// Belge geneli sezgi gereken stratejiler (ör. [DefaultHeuristicPdfParser])
  /// [fullText]'i kullanarak override eder.
  TransactionTypeModel signOf(String token, String fullText) =>
      isNegativeToken(token)
          ? TransactionTypeModel.expense
          : TransactionTypeModel.income;

  /// Ortak satır-sezgisel ayrıştırma.
  ///
  /// Adım 1 — KAYIT gruplama: syncfusion'ın `layoutText: true` çıktısında bir
  /// satırın BAŞINDA tarih varsa bu yeni bir hareket kaydıdır; tarihle
  /// BAŞLAMAYAN satırlar bir önceki kaydın görsel devamıdır (uzun açıklama
  /// ikinci fiziksel satıra sarar). Gerçek ekstrelerde bu devam satırı bazen
  /// yalnız açıklama metni taşır, bazen — ör. QNB ekstresinde — Tutar/Bakiye
  /// SAYILARININ KENDİSİ bu ikinci satırdadır (tarih satırında değil).
  /// Bu yüzden tarih satırıyla devam satırlarını ÖNCE TEK METİNDE birleştirip
  /// tutar/bakiyeyi bu birleşik metinden aramak zorunludur; aksi halde uzun
  /// açıklamalı (çoğu zaman gelir niteliğindeki havale) satırlar sessizce
  /// kaybolur/başka bir kayda karışır.
  ///
  /// Adım 2 — her kayıtta: [Tutar, Bakiye] yan yanadır; 2+ tutar varsa sondan
  /// bir önceki Tutar'dır (en sondaki Bakiye). Açıklama, kayıttan tarih VE
  /// eşleşen tüm parasal alt-dizeler çıkarılarak elde edilir (devam metni
  /// paradan önce de sonra da gelmiş olsa fark etmez).
  PdfParseLines parseLines(String text) {
    final moneyRe = moneyPatternFor(text);
    final records = <StringBuffer>[];
    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (_dateRe.matchAsPrefix(line) != null) {
        records.add(StringBuffer(line));
      } else if (records.isNotEmpty) {
        records.last
          ..write(' ')
          ..write(line);
      }
      // else: ilk kayıttan önceki başlık/köşe metni — yok sayılır.
    }

    final drafts = <ImportDraft>[];
    var skipped = 0;

    for (final record in records) {
      final line = record.toString();
      final dm = _dateRe.matchAsPrefix(line)!; // gruplama bunu garanti eder
      final date = parseStatementDate(dm.group(0)!, StatementDateFormat.auto);
      if (date == null) {
        skipped++;
        continue;
      }

      final after = line.substring(dm.end);
      final moneyMatches = moneyRe.allMatches(after).toList();
      if (moneyMatches.isEmpty) {
        skipped++;
        continue;
      }

      final amountMatch = moneyMatches.length >= 2
          ? moneyMatches[moneyMatches.length - 2]
          : moneyMatches.last;

      final token = amountMatch.group(0)!;
      final magnitude = parseSignedMoney(token);
      if (magnitude == null || magnitude == 0) {
        skipped++;
        continue;
      }

      final description = _withoutMoneyTokens(after, moneyMatches);

      drafts.add(ImportDraft(
        date: date,
        description:
            description.isEmpty ? emptyDescriptionFallback : description,
        amount: magnitude.abs(),
        type: signOf(token, text),
      ));
    }

    return (drafts: drafts, skippedLines: skipped);
  }

  /// [text]'ten [matches] ile eşleşen tüm alt-dizeleri çıkarıp kalanı
  /// boşlukları sadeleştirerek döner (tutar/bakiye devam satırının önünde ya
  /// da arkasında olsa da açıklamadan doğru çıkarılsın diye).
  static String _withoutMoneyTokens(String text, List<RegExpMatch> matches) {
    final buffer = StringBuffer();
    var last = 0;
    for (final m in matches) {
      buffer.write(text.substring(last, m.start));
      last = m.end;
    }
    buffer.write(text.substring(last));
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
