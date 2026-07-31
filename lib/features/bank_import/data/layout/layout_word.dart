/// Bir belgeden çıkarılmış TEK kelime ve sayfadaki yeri.
///
/// İki farklı kaynak bunu üretir ve [StatementLayoutEngine] ikisini de aynı
/// şekilde işler:
/// - PDF: syncfusion `PdfTextExtractor.extractTextLines()` → `TextWord.bounds`
/// - Görüntü/taranmış PDF: ML Kit `TextElement.boundingBox`
///
/// Koordinat birimi kaynağa göre değişir (PDF'te punto, OCR'da piksel); motor
/// mutlak eşik KULLANMAZ, hep medyan kelime yüksekliğine oranlar — böylece
/// aynı kod 124 DPI bir taramada da 72 punto bir PDF'te de çalışır.
class LayoutWord {
  final String text;

  /// Sınırlayıcı kutu. [top] yukarıdan aşağıya artar (her iki kaynak da böyle).
  final double left;
  final double right;
  final double top;
  final double bottom;

  /// 0 tabanlı sayfa/görüntü indeksi. Satır kümeleme sayfa sınırını AŞMAZ:
  /// aksi halde bir sayfanın son satırıyla ötekinin ilk satırı, y değerleri
  /// yakın olduğu için birleşirdi.
  final int page;

  const LayoutWord({
    required this.text,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.page,
  });

  double get centerY => (top + bottom) / 2;
  double get height => bottom - top;
}
