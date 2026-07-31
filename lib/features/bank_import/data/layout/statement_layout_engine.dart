/// Konumlu kelimelerden ekstrenin TABLO YAPISINI yeniden kurar.
///
/// **Neden gerekli.** Eski yol ekstreyi düz metne indirip satırı regex'le
/// çözüyordu. Bu, sütun bilgisini yok ettiği için gerçek bir QNB ekstresinde
/// iki ayrı felakete yol açıyordu (ölçüldü, tahmin değil):
///
/// 1. **Tire hırsızlığı.** Açıklama bir referansla bitiyor
///    (`… Sorgu No: 2076317 - 999/4888152-`) ve hemen ardından tutar geliyor.
///    Metinde bunlar yan yana düştüğü için para regex'inin işaret öneki
///    açıklamanın tiresini yutuyor, `- 2,000.00` okunuyordu: 7 satırda
///    toplam 38.420 TL'lik GELİR, gider olarak yazılıyordu.
/// 2. **Rakam sızması.** Dekont numarası tutara bitişik geliyor
///    (`… PARA YATIRMA, 55636820,000.00`); regex ortadan `820,000.00` gibi
///    var olmayan bir sayı çıkarıyor, gerçek tutar kayboluyordu (2 satır,
///    25.000 TL sessizce atlanmıştı).
///
/// Her ikisi de aynı kök nedenin belirtisi: **tutar bir metin parçası değil,
/// bir SÜTUNDUR.** Sütun kimliği korunduğunda açıklamadaki hiçbir karakter
/// tutara karışamaz. Ölçüm: aynı QNB ekstresi 164/164 satır birebir, Garanti
/// 85/85 — ve bakiye zinciri her satırı bağımsız olarak doğruluyor.
///
/// **Tasarım.** Mutlak piksel/punto eşiği YOKTUR; tüm toleranslar medyan
/// kelime yüksekliğine orandır. Aynı kod hem 72 punto PDF'te hem 124 DPI
/// taranmış sayfada (ML Kit çıktısı) çalışır — iki kaynak da [LayoutWord]
/// üretir. Saf/test edilebilir: dosya, PDF kütüphanesi ya da UI bağımlılığı
/// yok.
library;

import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/bank_import/data/layout/layout_word.dart';

/// Sütunlarından çözülmüş tek bir hareket satırı.
class LayoutRecord {
  final String dateText;
  final String description;

  /// Tutar sütunundan okunan İŞARETLİ değer. Borç/Alacak ayrı sütunlardaysa
  /// işaret sütunun kendisinden gelir (borç negatif).
  final double? amount;

  /// Bakiye (running balance) sütunu — varsa. Doğrulama katmanının işaret
  /// türetmesi ve mutabakatı bunun üstünde çalışır.
  final double? balance;

  /// Bankanın kendi kategori etiketi ("Alışveriş", "Para Çekme"…) — ekstrede
  /// böyle bir sütun varsa (Garanti). Başlıktan adlandırılır.
  final String? sourceTag;

  /// Dekont/Fiş/İşlem no sütunu — varsa.
  final String? reference;

  const LayoutRecord({
    required this.dateText,
    required this.description,
    required this.amount,
    required this.balance,
    this.sourceTag,
    this.reference,
  });
}

class StatementLayoutResult {
  final List<LayoutRecord> records;

  /// Tarih çapası bulundu ama tutar sütunu çözülemedi (kullanıcıya "N satır
  /// atlandı" olarak bildirilir).
  final int skippedRows;

  /// Hareket listesinden ÖNCE gelen devreden/açılış bakiyesi (QNB'de
  /// "DEVREDEN BAKİYE"). Doğrulama katmanı zincirin başlangıcını buna dayar.
  final double? openingBalance;

  /// Belge binlik ayracı olarak virgül kullanıyor mu (`10,000.00`)? Metinden
  /// beyan edilen toplamları ayrıştıracak katmanın da bilmesi gerekir.
  final bool englishGrouping;

  final bool hasBalanceColumn;

  /// Motor güvenilir bir tablo kurabildi mi? `false` ise çağıran eski
  /// satır-sezgisel yola düşer (asla eskisinden kötü sonuç vermeyiz).
  final bool usable;

  /// Tanılama özeti (ham metin ekranında gösterilir).
  final String diagnostics;

  const StatementLayoutResult({
    required this.records,
    required this.skippedRows,
    required this.openingBalance,
    required this.englishGrouping,
    required this.hasBalanceColumn,
    required this.usable,
    required this.diagnostics,
  });

  static const unusable = StatementLayoutResult(
    records: [],
    skippedRows: 0,
    openingBalance: null,
    englishGrouping: false,
    hasBalanceColumn: false,
    usable: false,
    diagnostics: 'düzen çözülemedi',
  );
}

/// Satır içinde yatay olarak bitişik kelimelerin birleşmesiyle oluşan hücre.
class _Cell {
  final String text;
  final double left;
  final double right;
  const _Cell(this.text, this.left, this.right);
}

class _Row {
  final List<_Cell> cells;
  final double centerY;
  final int page;
  const _Row(this.cells, this.centerY, this.page);
}

/// Tarih görünümlü hücre (gün-önce, ay-önce ya da ISO). Sıra burada
/// ÇÖZÜLMEZ — yalnız "bu bir tarih hücresi mi" sorusu yanıtlanır; gün/ay
/// kararı sütunun tamamına bakan `resolveStatementDateFormat` işidir.
final _dateCellRe =
    RegExp(r'^\d{1,2}[./-]\d{1,2}[./-]\d{2,4}$|^\d{4}[./-]\d{1,2}[./-]\d{1,2}');

/// Hücrenin başındaki/sonundaki para birimi eki.
final _currencyRe = RegExp(
  r'^[₺$€£]\s*|\s*(TL|TRY|USD|EUR|GBP|₺|\$|€|£)$',
  caseSensitive: false,
);

const _headerKeywords = <String>[
  'tarih',
  'date',
  'aciklama',
  'description',
  'tutar',
  'amount',
  'bakiye',
  'balance',
  'borc',
  'debit',
  'alacak',
  'credit',
];

const _tagHeaderKeywords = <String>['etiket', 'kategori', 'label'];
const _referenceHeaderKeywords = <String>[
  'dekont',
  'fis no',
  'referans',
  'reference',
  'islem no',
  'makbuz',
];
const _debitHeaderKeywords = <String>['borc', 'debit', 'cikan', 'gider'];
const _creditHeaderKeywords = <String>['alacak', 'credit', 'giren', 'gelir'];

/// Kelimeleri görsel satır/hücre düzenine göre düz metne çevirir.
///
/// Geometri yolu tutmadığında eski satır-sezgisel ayrıştırıcıya verilecek
/// metin ve tanılama ekranında gösterilecek "ham metin" budur. Hücreler
/// arasına tek boşluk konur; syncfusion'ın `layoutText` çıktısının aksine
/// bir satırın parçaları BURADA doğru şekilde yan yana gelir.
String layoutTextFromWords(List<LayoutWord> words) {
  final usable = [
    for (final w in words)
      if (w.text.trim().isNotEmpty) w,
  ];
  if (usable.isEmpty) return '';
  final rows = _buildRows(usable, _medianHeight(usable));
  return [
    for (final r in rows) r.cells.map((c) => c.text).join(' '),
  ].join('\n');
}

/// [words]'ten tablo yapısını kurar. Kelime listesi boşsa ya da güvenilir bir
/// sütun düzeni bulunamazsa [StatementLayoutResult.usable] `false` döner.
StatementLayoutResult analyzeStatementLayout(List<LayoutWord> words) {
  final usable = [
    for (final w in words)
      if (w.text.trim().isNotEmpty) w,
  ];
  if (usable.length < 10) return StatementLayoutResult.unusable;

  final englishGrouping = _detectEnglishGrouping(usable);
  final medianHeight = _medianHeight(usable);
  final rows = _buildRows(usable, medianHeight);
  if (rows.length < 4) return StatementLayoutResult.unusable;

  // --- tarih sütunu: tarih hücrelerinin baskın SOL kenarı ---
  final dateCells = <_Cell>[];
  for (final r in rows) {
    for (final c in r.cells) {
      if (_dateCellRe.hasMatch(c.text)) dateCells.add(c);
    }
  }
  if (dateCells.length < 3) return StatementLayoutResult.unusable;
  final columnTolerance = medianHeight * 0.5;
  final dateLeft = _dominantEdge(
    [for (final c in dateCells) c.left],
    columnTolerance,
  );

  // --- para sütunları: para hücrelerinin SAĞ kenarları (sayısal sütunlar
  // sağa dayalıdır; sol kenar rakam sayısına göre oynar) ---
  final moneyRights = <double>[];
  for (final r in rows) {
    for (final c in r.cells) {
      if (parseLayoutMoney(c.text, englishGrouping: englishGrouping) != null) {
        moneyRights.add(c.right);
      }
    }
  }
  final minMembers =
      (dateCells.length * 0.3).round().clamp(3, dateCells.length);
  final moneyColumns = _clusterEdges(moneyRights, columnTolerance, minMembers);
  if (moneyColumns.isEmpty) return StatementLayoutResult.unusable;

  // --- çapa (tarihli) satırlar ---
  final anchorIdx = <int>[];
  for (var i = 0; i < rows.length; i++) {
    final hasDate = rows[i].cells.any((c) =>
        _dateCellRe.hasMatch(c.text) &&
        (c.left - dateLeft).abs() <= columnTolerance);
    if (hasDate) anchorIdx.add(i);
  }
  if (anchorIdx.length < 3) return StatementLayoutResult.unusable;

  // --- sütun rollerini ata ---
  final roles = _assignMoneyRoles(
    rows: rows,
    anchorIdx: anchorIdx,
    columns: moneyColumns,
    tolerance: columnTolerance,
    englishGrouping: englishGrouping,
  );
  if (roles == null) return StatementLayoutResult.unusable;

  final header = _findHeaderRow(rows, anchorIdx.first);
  final tagRange = _namedColumnRange(header, _tagHeaderKeywords);
  final refRange = _namedColumnRange(header, _referenceHeaderKeywords);

  // Borç/Alacak ikilisinde hangisinin borç olduğunu başlıktan doğrula;
  // başlık yoksa soldaki borç sayılır (TR ekstrelerinin yerleşik sırası).
  var debitRight = roles.debitRight;
  var creditRight = roles.creditRight;
  if (header != null && debitRight != null && creditRight != null) {
    final debitFromHeader = _namedColumnRange(header, _debitHeaderKeywords);
    final creditFromHeader = _namedColumnRange(header, _creditHeaderKeywords);
    if (debitFromHeader != null && creditFromHeader != null) {
      final headerSaysLeftIsDebit = debitFromHeader.$1 < creditFromHeader.$1;
      if (!headerSaysLeftIsDebit) {
        final swap = debitRight;
        debitRight = creditRight;
        creditRight = swap;
      }
    }
  }

  // --- tarihsiz satırları en yakın çapaya bağla ---
  final headerRows = _headerRowIndices(rows);
  final attachments = _attachContinuationRows(
    rows: rows,
    anchorIdx: anchorIdx,
    excluded: headerRows,
    medianHeight: medianHeight,
  );

  // --- açılış (devreden) bakiyesi: ilk çapanın ÜSTÜNDEKİ, bakiye sütununda
  // değer taşıyan tarihsiz satır ---
  double? openingBalance;
  if (roles.balanceRight != null) {
    for (var i = 0; i < anchorIdx.first; i++) {
      for (final c in rows[i].cells) {
        if ((c.right - roles.balanceRight!).abs() > columnTolerance) continue;
        final v = parseLayoutMoney(c.text, englishGrouping: englishGrouping);
        if (v != null) openingBalance = v;
      }
    }
  }

  // --- kayıtlar ---
  final records = <LayoutRecord>[];
  var skipped = 0;
  for (final a in anchorIdx) {
    final cells = <_Cell>[
      ...rows[a].cells,
      for (final i in attachments[a] ?? const <int>[]) ...rows[i].cells,
    ];

    _Cell? dateCell;
    _Cell? amountCell;
    _Cell? balanceCell;
    _Cell? debitCell;
    _Cell? creditCell;
    _Cell? tagCell;
    _Cell? refCell;
    final descriptionCells = <_Cell>[];

    for (final c in cells) {
      if (dateCell == null &&
          _dateCellRe.hasMatch(c.text) &&
          (c.left - dateLeft).abs() <= columnTolerance) {
        dateCell = c;
        continue;
      }
      final value = parseLayoutMoney(c.text, englishGrouping: englishGrouping);
      if (value != null) {
        if (roles.amountRight != null &&
            (c.right - roles.amountRight!).abs() <= columnTolerance) {
          amountCell = c;
          continue;
        }
        if (roles.balanceRight != null &&
            (c.right - roles.balanceRight!).abs() <= columnTolerance) {
          balanceCell = c;
          continue;
        }
        if (debitRight != null &&
            (c.right - debitRight).abs() <= columnTolerance) {
          debitCell = c;
          continue;
        }
        if (creditRight != null &&
            (c.right - creditRight).abs() <= columnTolerance) {
          creditCell = c;
          continue;
        }
        // Hiçbir para sütununa oturmayan sayı (açıklama içindeki bir tutar):
        // açıklamada kalır — tutar sanılmaz.
      }
      if (tagRange != null && _overlaps(c, tagRange)) {
        tagCell = c;
        continue;
      }
      if (refRange != null && _overlaps(c, refRange)) {
        refCell = c;
        continue;
      }
      descriptionCells.add(c);
    }

    if (dateCell == null) continue; // çapa tanımı gereği olamaz
    final amount = _resolveAmount(
      amountCell: amountCell,
      debitCell: debitCell,
      creditCell: creditCell,
      englishGrouping: englishGrouping,
    );
    if (amount == null) {
      skipped++;
      continue;
    }

    records.add(LayoutRecord(
      dateText: dateCell.text,
      description: descriptionCells.map((c) => c.text).join(' ').trim(),
      amount: amount,
      balance: balanceCell == null
          ? null
          : parseLayoutMoney(balanceCell.text,
              englishGrouping: englishGrouping),
      sourceTag: tagCell?.text,
      reference: refCell?.text,
    ));
  }

  // Çapaların çok azı tutara bağlanabildiyse düzen okuması güvenilir değil;
  // eski yola düşmek daha doğru.
  final resolved = records.length;
  if (resolved < 3 || resolved < anchorIdx.length * 0.8) {
    return StatementLayoutResult.unusable;
  }

  return StatementLayoutResult(
    records: records,
    skippedRows: skipped,
    openingBalance: openingBalance,
    englishGrouping: englishGrouping,
    hasBalanceColumn: roles.balanceRight != null,
    usable: true,
    diagnostics: 'düzen: ${rows.length} satır, ${records.length} hareket, '
        'tarih@${dateLeft.toStringAsFixed(0)}, '
        'tutar@${roles.amountRight?.toStringAsFixed(0) ?? "borç/alacak"}, '
        'bakiye@${roles.balanceRight?.toStringAsFixed(0) ?? "yok"}',
  );
}

/// Hücre metnini işaretli para değerine çevirir; hücrenin TAMAMI bir sayı
/// değilse `null` (böylece açıklama metni asla tutar sanılmaz).
///
/// Belge biçimi ([englishGrouping]) dışarıdan verilir: bir banka exportu iki
/// biçimi asla karıştırmaz, ama tek bir hücreye bakarak `1.234` ayrımını
/// yapmak imkânsızdır.
double? parseLayoutMoney(String raw, {required bool englishGrouping}) {
  var t = raw.trim();
  if (t.isEmpty) return null;
  t = t.replaceAll(_currencyRe, '').trim();
  if (t.isEmpty) return null;

  final pattern = englishGrouping
      ? RegExp(r'^([-+(]?)(\d{1,3}(?:,\d{3})*|\d+)\.(\d{2})(\)?)([-+]?)$')
      : RegExp(r'^([-+(]?)(\d{1,3}(?:\.\d{3})*|\d+),(\d{2})(\)?)([-+]?)$');
  final m = pattern.firstMatch(t);
  if (m == null) return null;

  final digits = m.group(2)!.replaceAll(englishGrouping ? ',' : '.', '');
  final whole = int.tryParse(digits);
  if (whole == null) return null;
  final cents = int.parse(m.group(3)!);

  final prefix = m.group(1)!;
  final suffix = m.group(5)!;
  final negative =
      prefix == '-' || suffix == '-' || (prefix == '(' && m.group(4) == ')');
  final value = whole + cents / 100;
  return roundToCents(negative ? -value : value);
}

bool _detectEnglishGrouping(List<LayoutWord> words) =>
    detectEnglishGrouping(words.map((w) => w.text).join(' '));

/// Belge binlik ayracı olarak virgül mü kullanıyor (`10,000.00`)? Gruplama
/// işareti ondalıktan daha güçlü kanıt olduğu için iki katı ağırlıklı.
///
/// Karar BELGE genelinde bir kez verilir: bir banka exportu iki biçimi asla
/// karıştırmaz, ama tek bir hücreye bakarak `1.234` ayrımını yapmak
/// imkânsızdır.
bool detectEnglishGrouping(String text) {
  final englishGroup = RegExp(r'\d,\d{3}(?!\d)').allMatches(text).length;
  final turkishGroup = RegExp(r'\d\.\d{3}(?!\d)').allMatches(text).length;
  final englishDecimal =
      RegExp(r'(?<!\d)\d+\.\d{2}(?!\d)').allMatches(text).length;
  final turkishDecimal =
      RegExp(r'(?<!\d)\d+,\d{2}(?!\d)').allMatches(text).length;
  return englishGroup * 2 + englishDecimal > turkishGroup * 2 + turkishDecimal;
}

double _medianHeight(List<LayoutWord> words) {
  final heights = [
    for (final w in words)
      if (w.height > 0) w.height,
  ]..sort();
  if (heights.isEmpty) return 1;
  return heights[heights.length ~/ 2];
}

/// Kelimeleri görsel satırlara, satır içinde de hücrelere böler.
///
/// Çapa, grubun İLK kelimesinin merkezidir (grup ortalaması değil): hafif
/// eğik taranmış sayfalarda kayan ortalama grupları birbirine akıtır.
List<_Row> _buildRows(List<LayoutWord> words, double medianHeight) {
  final sorted = [...words]..sort((a, b) =>
      a.page != b.page ? a.page - b.page : a.centerY.compareTo(b.centerY));

  final groups = <List<LayoutWord>>[];
  for (final w in sorted) {
    final last = groups.isEmpty ? null : groups.last;
    if (last != null &&
        last.first.page == w.page &&
        (w.centerY - last.first.centerY).abs() < medianHeight * 0.6) {
      last.add(w);
    } else {
      groups.add([w]);
    }
  }

  // Yatay boşluk eşiği: yarım satır yüksekliği. Bunun altındaki boşluk kelime
  // arasıdır ("Para Çekme"), üstündeki sütun aralığıdır. Eşik olmadan
  // Garanti'nin `-4.400` + `,00` + `TL` parçaları ayrı hücreler olarak kalır
  // ve hiçbiri para olarak ayrıştırılamazdı.
  final gapThreshold = medianHeight * 0.55;
  final rows = <_Row>[];
  for (final g in groups) {
    g.sort((a, b) => a.left.compareTo(b.left));
    final cells = <_Cell>[];
    var buffer = StringBuffer(g.first.text.trim());
    var left = g.first.left;
    var right = g.first.right;
    for (var i = 1; i < g.length; i++) {
      final w = g[i];
      if (w.left - right <= gapThreshold) {
        if (w.left - right > 0.5) buffer.write(' ');
        buffer.write(w.text.trim());
        right = w.right > right ? w.right : right;
      } else {
        cells.add(_Cell(buffer.toString().trim(), left, right));
        buffer = StringBuffer(w.text.trim());
        left = w.left;
        right = w.right;
      }
    }
    cells.add(_Cell(buffer.toString().trim(), left, right));
    rows.add(_Row(cells, g.first.centerY, g.first.page));
  }
  return rows;
}

/// Kenar değerlerini kümeleyip her kümenin ortalamasını döner (yalnız
/// [minMembers] üyeli kümeler). Sıralı listede ardışık fark eşiğin altındaysa
/// aynı sütun sayılır.
List<double> _clusterEdges(
    List<double> edges, double tolerance, int minMembers) {
  if (edges.isEmpty) return const [];
  final sorted = [...edges]..sort();
  final clusters = <List<double>>[
    [sorted.first]
  ];
  for (final x in sorted.skip(1)) {
    if ((x - clusters.last.last).abs() <= tolerance) {
      clusters.last.add(x);
    } else {
      clusters.add([x]);
    }
  }
  return [
    for (final c in clusters)
      if (c.length >= minMembers) c.reduce((a, b) => a + b) / c.length,
  ];
}

double _dominantEdge(List<double> edges, double tolerance) {
  final clusters = _clusterEdges(edges, tolerance, 1);
  if (clusters.isEmpty) return edges.first;
  // En çok üyeli kümeyi bul: _clusterEdges ortalamayı döndüğü için üye
  // sayısını burada yeniden hesaplıyoruz (küçük veri, maliyeti yok).
  var best = clusters.first;
  var bestCount = 0;
  for (final c in clusters) {
    final count = edges.where((e) => (e - c).abs() <= tolerance).length;
    if (count > bestCount) {
      bestCount = count;
      best = c;
    }
  }
  return best;
}

/// Para sütunlarının rolleri.
class _MoneyRoles {
  final double? amountRight;
  final double? balanceRight;
  final double? debitRight;
  final double? creditRight;
  const _MoneyRoles({
    this.amountRight,
    this.balanceRight,
    this.debitRight,
    this.creditRight,
  });
}

/// Para sütunlarına rol dağıtır.
///
/// - En sağdaki sütun çapaların çoğunda doluysa BAKİYE'dir (running balance
///   her satırda vardır; tutar da her satırda vardır ama bakiye daima sağda).
/// - Kalanlardan biri çoğunlukla doluysa TUTAR'dır.
/// - İki sütun tek başına yarı yarıya dolu ama BİRLİKTE çoğunluğu kaplıyorsa
///   bu bir Borç/Alacak ikilisidir (TR ekstrelerinde yaygın): bir satırda
///   yalnız biri dolar.
_MoneyRoles? _assignMoneyRoles({
  required List<_Row> rows,
  required List<int> anchorIdx,
  required List<double> columns,
  required double tolerance,
  required bool englishGrouping,
}) {
  double fillRatio(double right) {
    var filled = 0;
    for (final a in anchorIdx) {
      final hit = rows[a].cells.any((c) =>
          (c.right - right).abs() <= tolerance &&
          parseLayoutMoney(c.text, englishGrouping: englishGrouping) != null);
      if (hit) filled++;
    }
    return filled / anchorIdx.length;
  }

  // Çok satırlı kayıtlarda tutar/bakiye çapa satırında olmayabilir (QNB): bu
  // yüzden doluluk oranı düşük çıkabilir, eşikler buna göre toleranslı.
  final ratios = {for (final c in columns) c: fillRatio(c)};
  final sorted = [...columns]..sort();

  if (sorted.length == 1) {
    return _MoneyRoles(amountRight: sorted.first);
  }

  final rightmost = sorted.last;
  final rest = sorted.sublist(0, sorted.length - 1);

  // Borç/Alacak ikilisi mi? (ikisi de tek başına zayıf, birlikte güçlü)
  if (rest.length >= 2) {
    final a = rest[rest.length - 2];
    final b = rest[rest.length - 1];
    final ra = ratios[a] ?? 0;
    final rb = ratios[b] ?? 0;
    if (ra < 0.75 && rb < 0.75 && ra + rb >= 0.7) {
      return _MoneyRoles(
        debitRight: a,
        creditRight: b,
        balanceRight: rightmost,
      );
    }
  }

  return _MoneyRoles(
    amountRight: rest.last,
    balanceRight: rightmost,
  );
}

double? _resolveAmount({
  required _Cell? amountCell,
  required _Cell? debitCell,
  required _Cell? creditCell,
  required bool englishGrouping,
}) {
  if (amountCell != null) {
    return parseLayoutMoney(amountCell.text, englishGrouping: englishGrouping);
  }
  if (debitCell != null) {
    final v =
        parseLayoutMoney(debitCell.text, englishGrouping: englishGrouping);
    if (v != null && v != 0) return -v.abs();
  }
  if (creditCell != null) {
    final v =
        parseLayoutMoney(creditCell.text, englishGrouping: englishGrouping);
    if (v != null && v != 0) return v.abs();
  }
  return null;
}

/// Sütun başlığı satırı (ilk çapadan önceki, en az iki başlık anahtarı taşıyan
/// satır). Etiket/dekont sütunlarını ADLANDIRMAK için kullanılır.
_Row? _findHeaderRow(List<_Row> rows, int firstAnchor) {
  for (var i = firstAnchor - 1; i >= 0; i--) {
    if (_headerHitCount(rows[i]) >= 2) return rows[i];
  }
  return null;
}

/// TÜM başlık satırlarının indeksleri (çok sayfalı ekstrede her sayfada
/// tekrar eder). Devam satırı olarak bir kayda yapışmamaları için elenir.
Set<int> _headerRowIndices(List<_Row> rows) => {
      for (var i = 0; i < rows.length; i++)
        if (_headerHitCount(rows[i]) >= 2) i,
    };

int _headerHitCount(_Row row) {
  var hits = 0;
  for (final c in row.cells) {
    final n = _foldTr(c.text);
    if (_headerKeywords.any(n.contains)) hits++;
  }
  return hits;
}

/// Başlıkta [keywords] ile eşleşen hücrenin x aralığı.
(double, double)? _namedColumnRange(_Row? header, List<String> keywords) {
  if (header == null) return null;
  for (final c in header.cells) {
    final n = _foldTr(c.text);
    if (keywords.any(n.contains)) return (c.left, c.right);
  }
  return null;
}

bool _overlaps(_Cell cell, (double, double) range) {
  final start = cell.left > range.$1 ? cell.left : range.$1;
  final end = cell.right < range.$2 ? cell.right : range.$2;
  return end > start;
}

/// Tarihsiz satırları en yakın çapaya bağlar.
///
/// Sayfa üstbilgisi/altbilgisi ve künye satırları BANT dışında kalır: bir
/// sayfadaki hareketlerin dikey bandı en üst ve en alt çapa arasıdır; bu
/// bandın belirgin biçimde dışındaki satır bir hareketin devamı olamaz.
/// (Eski metin yolunda bu ayrım "satır her sayfada tekrar ediyor mu"
/// sezgisiyle yapılıyordu ve tek sayfalık ekstrede tutmuyordu.)
Map<int, List<int>> _attachContinuationRows({
  required List<_Row> rows,
  required List<int> anchorIdx,
  required Set<int> excluded,
  required double medianHeight,
}) {
  final anchors = anchorIdx.toSet();
  final byPage = <int, List<int>>{};
  for (final a in anchorIdx) {
    (byPage[rows[a].page] ??= []).add(a);
  }
  final bands = <int, (double, double)>{};
  byPage.forEach((page, list) {
    var min = double.infinity;
    var max = -double.infinity;
    for (final a in list) {
      final y = rows[a].centerY;
      if (y < min) min = y;
      if (y > max) max = y;
    }
    bands[page] = (min - medianHeight * 1.5, max + medianHeight * 1.5);
  });

  final result = <int, List<int>>{};
  for (var i = 0; i < rows.length; i++) {
    if (anchors.contains(i) || excluded.contains(i)) continue;
    final band = bands[rows[i].page];
    if (band == null) continue;
    if (rows[i].centerY < band.$1 || rows[i].centerY > band.$2) continue;

    int? best;
    var bestDistance = double.infinity;
    for (final a in anchorIdx) {
      if (rows[a].page != rows[i].page) continue;
      final d = (rows[a].centerY - rows[i].centerY).abs();
      if (d < bestDistance) {
        bestDistance = d;
        best = a;
      }
    }
    if (best != null && bestDistance <= medianHeight * 2.2) {
      (result[best] ??= []).add(i);
    }
  }
  return result;
}

/// Türkçe aksanı sadeleştirip küçük harfe indirir (başlık eşleşmesi için;
/// `toLowerCase` tek başına 'İ'/'I' çiftinde güvenilir değil).
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
    .toLowerCase()
    .trim();
