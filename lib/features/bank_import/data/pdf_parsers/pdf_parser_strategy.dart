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

  /// Satır başındaki tarih. Yıl-önce (ISO) biçimi ÖNCE denenir: aksi halde
  /// `2026-07-16` satırında hiçbir alternatif tutmaz (`\d{1,2}` "20"yi alır,
  /// ardından ayraç gelmez) ve satır bir öncekinin devamı sanılırdı.
  static final _dateRe = RegExp(
      r'\d{4}[./-]\d{1,2}[./-]\d{1,2}|\d{1,2}[./-]\d{1,2}[./-]\d{2,4}');

  /// Tutarın hemen ardından gelen para birimi eki ("-4.400,00 TL12,28 TL").
  /// Sayı çıkarıldığında bu ek açıklamada kalıp her satırın sonuna "TLTL"
  /// yapıştırıyordu.
  static final _currencyAfterRe = RegExp(
    r'^[ \t]*(?:TL|TRY|USD|EUR|GBP|₺|\$|€|£)(?![A-Za-zÇĞİÖŞÜçğıöşü])',
    caseSensitive: false,
  );

  /// Tutardan ÖNCE gelen para birimi SİMGESİ ("₺1.234,56"). Yalnız simge:
  /// harfli biçimi burada aramak "… TL" ile biten gerçek açıklamaları
  /// kırpma riskini getirirdi.
  static final _currencySymbolBeforeRe = RegExp(r'[₺\$€£]\s*$');

  /// Sayfa numarası satırı ("1 / 3", "2/3").
  static final _pageNumberRe = RegExp(r'^\d+\s*/\s*\d+$');

  /// Bazı bankalar (ör. Garanti) hareket satırında KENDİ kategori etiketini de
  /// verir. `layoutText` çıktısında ayrı bir sütun olmadığı için bu etiket
  /// açıklamaya BİTİŞİK gelir ("…-SULAlışveriş", "MAAŞ ÖDEMESİMaaş"). Uzun
  /// olanlar önce denenmeli ("Fatura Ödemesi", "Fatura"dan önce).
  static const statementTags = <String>[
    'Fatura Ödemesi',
    'Para Transferi',
    'Para Yatırma',
    'Kredi Kartı',
    'Para Çekme',
    'Alışveriş',
    'Yatırım',
    'Komisyon',
    'Fatura',
    'Kredi',
    'Vergi',
    'Faiz',
    'Maaş',
    'Diğer',
  ];

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
    final lines = [
      for (final raw in text.split('\n'))
        if (raw.trim().isNotEmpty) raw.trim(),
    ];
    final boilerplate = _boilerplateLines(lines);

    final records = <StringBuffer>[];
    for (final line in lines) {
      if (_dateRe.matchAsPrefix(line) != null) {
        records.add(StringBuffer(line));
        continue;
      }
      if (records.isEmpty) continue; // ilk kayıttan önceki başlık — yok sayılır
      if (!_isContinuation(line, boilerplate)) continue;
      records.last
        ..write(' ')
        ..write(line);
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

      final cleaned = _withoutMoneyTokens(after, moneyMatches);
      final (description, sourceTag) = splitTrailingTag(cleaned);

      drafts.add(ImportDraft(
        date: date,
        description:
            description.isEmpty ? emptyDescriptionFallback : description,
        amount: magnitude.abs(),
        type: signOf(token, text),
        sourceTag: sourceTag,
      ));
    }

    return (drafts: drafts, skippedLines: skipped);
  }

  /// Bir kayıtta birebir tekrar eden sayfa üstbilgi/altbilgi satırları.
  /// Çok sayfalı ekstrelerde banka adı, adres, vergi no ve sütun başlığı her
  /// sayfada aynen tekrar eder; tarihle başlamadıkları için bir önceki kaydın
  /// devamı sanılıp açıklamasına yapışıyorlardı (gerçek Garanti ekstresinde
  /// son hareketin başlığı 5 satırlık künyeyle birlikte kaydediliyordu).
  static Set<String> _boilerplateLines(List<String> lines) {
    final counts = <String, int>{};
    for (final line in lines) {
      if (_dateRe.matchAsPrefix(line) != null) continue;
      counts.update(line, (v) => v + 1, ifAbsent: () => 1);
    }
    return {
      for (final e in counts.entries)
        if (e.value > 1) e.key,
    };
  }

  /// Tek sayfalık ekstrede tekrar sezgisi tutmaz (künye bir kez geçer), ama
  /// künye satırları kendi başlarına da oldukça belirgindir. Hareket
  /// açıklamalarında bu ifadeler pratikte geçmez.
  static const _footerKeywords = <String>[
    'genel mudurluk',
    'vergi dairesi',
    'vergi no',
    'mersis',
    'ticaret sicil',
    'www.',
    'http',
  ];

  /// [line], önceki kaydın görsel devamı mı (sarılmış açıklama / ayrı satıra
  /// düşmüş Tutar-Bakiye) yoksa sayfa süsü mü?
  ///
  /// "Kayıtta 2 parasal token varsa tamamlanmıştır" gibi bir kural CAZİP ama
  /// YANLIŞ: gerçek bir Akbank ekstresinde Tutar+Bakiye tarih satırındayken
  /// açıklama yine de ikinci satıra sarabiliyor. Bu yüzden ayrım paranın
  /// yerinden değil, satırın KENDİSİNDEN yapılır: her sayfada tekrarlayan
  /// satırlar, sayfa numaraları ve künye ifadeleri devam değildir.
  static bool _isContinuation(String line, Set<String> boilerplate) {
    if (boilerplate.contains(line)) return false;
    if (_pageNumberRe.hasMatch(line)) return false;
    final folded = _foldTr(line);
    return !_footerKeywords.any(folded.contains);
  }

  /// Açıklamanın sonuna BİTİŞİK gelmiş banka etiketini ayırır (bkz.
  /// [statementTags]). Etiketten hemen önce boşluk varsa ayırmaz: o durumda
  /// kelime açıklamanın gerçek bir parçasıdır ("ODEME FATURA" kırpılmamalı),
  /// ayrı sütundan gelen etiket ise daima bitişiktir.
  static (String, String?) splitTrailingTag(String description) {
    final lowered = _foldTr(description);
    for (final tag in statementTags) {
      final loweredTag = _foldTr(tag);
      if (!lowered.endsWith(loweredTag)) continue;
      final start = description.length - tag.length;
      if (start <= 0) continue; // açıklamanın tamamı etiket — dokunma
      if (description[start - 1] == ' ') continue; // bitişik değil
      final rest = description.substring(0, start).trim();
      if (rest.isEmpty) continue;
      return (rest, tag);
    }
    return (description, null);
  }

  /// Türkçe aksanı sadeleştirip küçük harfe çevirir (etiket eşleşmesi için;
  /// `toLowerCase` tek başına 'İ'/'I' çiftinde güvenilir değil).
  static String _foldTr(String s) => s
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

  /// [text]'ten [matches] ile eşleşen tüm alt-dizeleri çıkarıp kalanı
  /// boşlukları sadeleştirerek döner (tutar/bakiye devam satırının önünde ya
  /// da arkasında olsa da açıklamadan doğru çıkarılsın diye).
  ///
  /// Sayıya BİTİŞİK para birimi eki de atılır: "-4.400,00 TL12,28 TL"
  /// satırında yalnız sayılar silinince açıklamanın sonunda "TLTL" kalıyordu
  /// (gerçek Garanti ekstresindeki 85 hareketin tamamında).
  static String _withoutMoneyTokens(String text, List<RegExpMatch> matches) {
    final buffer = StringBuffer();
    var last = 0;
    for (final m in matches) {
      var gap = text.substring(last, m.start);
      // Bir önceki tutarın ardından gelen birim eki ("… 4.400,00 TL12,28 …").
      if (last > 0) gap = gap.replaceFirst(_currencyAfterRe, '');
      // Bu tutarın önündeki birim simgesi ("₺1.234,56").
      gap = gap.replaceFirst(_currencySymbolBeforeRe, '');
      buffer.write(gap);
      last = m.end;
    }
    var tail = text.substring(last);
    if (last > 0) tail = tail.replaceFirst(_currencyAfterRe, '');
    buffer.write(tail);

    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
