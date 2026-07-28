/// İçe aktarılan banka ekstresinin dosya biçimi (okuyucu seçimi bunun üstünden).
enum StatementFormat {
  csv,

  /// Modern Excel (.xlsx, zip tabanlı) — `excel` paketi.
  excel,

  /// Eski ikili Excel (.xls, OLE2/BIFF8) — kendi okuyucumuz
  /// (`data/xls/biff8_reader.dart`).
  legacyExcel,

  pdf,

  /// Ekran görüntüsü / fotoğraf (JPG, PNG). Metin OCR ile çıkarılır — en
  /// düşük güvenilirlikli yol, yalnız başka biçim yoksa.
  image;

  /// Kullanıcıya "desteklenen biçimler" olarak gösterilen uzantılar.
  /// Dosya SEÇİCİYE artık verilmez (bkz. [detectStatementFormat]).
  static const supportedExtensions = [
    'csv',
    'txt',
    'xlsx',
    'xls',
    'pdf',
    'jpg',
    'png',
  ];
}

/// Bir dosyanın biçim tespiti. Desteklenen biçimlerin yanında, desteklenmeyen
/// ama TANINAN durumları da taşır ki kullanıcıya "olmadı" yerine ne yapması
/// gerektiği söylenebilsin.
enum DetectedStatementFormat {
  csv,
  excel,
  pdf,

  /// Eski ikili Excel (.xls / OLE2 bileşik dosya). `excel` paketi bunu
  /// okuyamaz; kendi BIFF8 okuyucumuz devreye girer.
  legacyExcel,

  /// Ekran görüntüsü / fotoğraf — OCR yolundan okunur.
  image,

  /// Ne imzadan ne uzantıdan tanınabildi.
  unknown;

  /// Okuyucusu olan bir biçimse onu, yoksa `null` döner.
  StatementFormat? get supported => switch (this) {
        DetectedStatementFormat.csv => StatementFormat.csv,
        DetectedStatementFormat.excel => StatementFormat.excel,
        DetectedStatementFormat.pdf => StatementFormat.pdf,
        DetectedStatementFormat.legacyExcel => StatementFormat.legacyExcel,
        DetectedStatementFormat.image => StatementFormat.image,
        DetectedStatementFormat.unknown => null,
      };
}

const _pdfSignature = [0x25, 0x50, 0x44, 0x46]; // %PDF
const _zipSignature = [0x50, 0x4B, 0x03, 0x04]; // PK.. (xlsx = zip)
const _ole2Signature = [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1];
const _jpegSignature = [0xFF, 0xD8, 0xFF];
const _pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
const _webpRiff = [0x52, 0x49, 0x46, 0x46]; // RIFF….WEBP

/// Biçimi ÖNCE dosyanın ilk baytlarından (imza), sonra uzantıdan belirler.
///
/// İmzanın uzantıdan önce gelmesinin nedeni Android: SAF/DocumentsProvider
/// üzerinden gelen dosyalarda görünen ad uzantısız olabiliyor ya da indirme
/// sağlayıcısı yanlış tür bildiriyor. İçerik imzası bu katmanların hiçbirine
/// güvenmez.
///
/// [head] dosyanın ilk baytları (≥8 bayt yeterli). Metin dosyalarının imzası
/// olmadığı için orada uzantıya, o da yoksa "metne benziyor mu"ya düşülür —
/// bu sayede uzantısı `.xls` olan ama aslında HTML/TSV olan (bazı Türk
/// bankalarının export'u) dosyalar da CSV yolundan okunabilir.
DetectedStatementFormat detectStatementFormat({
  required String path,
  required List<int> head,
}) {
  if (_startsWith(head, _pdfSignature)) return DetectedStatementFormat.pdf;
  if (_startsWith(head, _zipSignature)) return DetectedStatementFormat.excel;
  if (_startsWith(head, _ole2Signature)) {
    return DetectedStatementFormat.legacyExcel;
  }
  if (_startsWith(head, _jpegSignature) ||
      _startsWith(head, _pngSignature) ||
      (_startsWith(head, _webpRiff) && _hasAt(head, 8, 'WEBP'))) {
    return DetectedStatementFormat.image;
  }

  // İmza yok → metin ailesi. Uzantı yalnızca ipucu; içerik metne benzemiyorsa
  // (ikili bir dosya) tanınmamış sayılır.
  final textLike = _looksLikeText(head);
  final ext = _extensionOf(path);
  return switch (ext) {
    'csv' || 'txt' => DetectedStatementFormat.csv,
    // .xlsx/.xls uzantılı ama imzası tutmayan dosya: gerçekte metin export'u
    // olabilir; metne benziyorsa CSV olarak dene.
    'xlsx' || 'xls' when textLike => DetectedStatementFormat.csv,
    'xlsx' || 'xls' => DetectedStatementFormat.legacyExcel,
    'pdf' => DetectedStatementFormat.unknown, // imzası yok → bozuk PDF
    _ => textLike
        ? DetectedStatementFormat.csv
        : DetectedStatementFormat.unknown,
  };
}

String _extensionOf(String path) {
  final slash = path.lastIndexOf(RegExp(r'[/\\]'));
  final name = slash == -1 ? path : path.substring(slash + 1);
  final dot = name.lastIndexOf('.');
  if (dot <= 0) return '';
  return name.substring(dot + 1).toLowerCase();
}

bool _hasAt(List<int> bytes, int offset, String ascii) {
  if (bytes.length < offset + ascii.length) return false;
  for (var i = 0; i < ascii.length; i++) {
    if (bytes[offset + i] != ascii.codeUnitAt(i)) return false;
  }
  return true;
}

bool _startsWith(List<int> bytes, List<int> signature) {
  if (bytes.length < signature.length) return false;
  for (var i = 0; i < signature.length; i++) {
    if (bytes[i] != signature[i]) return false;
  }
  return true;
}

/// Baytların büyük çoğunluğu ASCII yazdırılabilir/boşlukla ise metin sayılır.
/// NUL bayt tek başına ikili göstergesidir.
///
/// 0x80+ baytlar metin OLABİLİR (cp1254/UTF-8 Türkçe harfler) ama bir ikili
/// dosyada da baskındır; bu yüzden "metin" oranına sayılmaz, yalnız pay
/// içinde kalırlar. Türkçe bir ekstrede yüksek baytların oranı %10'u geçmez,
/// bir JPEG/ikili başlıkta ise çoğunluktadır — eşik ikisini ayırır.
bool _looksLikeText(List<int> bytes) {
  if (bytes.isEmpty) return false;
  var ascii = 0;
  for (final b in bytes) {
    if (b == 0) return false;
    if ((b >= 0x20 && b < 0x7F) || b == 0x09 || b == 0x0A || b == 0x0D) {
      ascii++;
    }
  }
  return ascii / bytes.length > 0.75;
}
