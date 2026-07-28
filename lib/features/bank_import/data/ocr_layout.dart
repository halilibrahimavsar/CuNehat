/// OCR'ın döndürdüğü konumlu metin parçalarını, satır düzeni KORUNMUŞ düz
/// metne çevirir.
///
/// Neden gerekli: `PdfStatementParser` (ve tüm banka stratejileri) bir hareketin
/// TEK satırda geldiğini varsayar — syncfusion `extractText(layoutText: true)`
/// bunu sağlar. ML Kit ise metni "blok"lar hâlinde verir ve `recognized.text`
/// bloğu blok sırasına göre birleştirir: bir tablo satırının tarihi, açıklaması
/// ve tutarı ayrı bloklara düşerse düz metinde birbirinden KOPUK çıkar ve
/// hiçbir satır ayrıştırılamaz.
///
/// Çözüm: parçaları DİKEY konumlarına göre satırlara grupla, satır içinde
/// soldan sağa sırala. Saf ve test edilebilir — ML Kit'e (dolayısıyla cihaza)
/// bağımlı değil.
library;

/// OCR'dan gelen tek bir metin parçası ve ekrandaki yeri.
class OcrLine {
  final String text;

  /// Sınırlayıcı kutunun üst kenarı ve yüksekliği (piksel).
  final double top;
  final double height;

  /// Sol kenar — satır içi sıralama için.
  final double left;

  const OcrLine({
    required this.text,
    required this.top,
    required this.height,
    required this.left,
  });

  double get centerY => top + height / 2;
}

/// [lines]'ı satırlara gruplayıp düzen korunmuş metne çevirir.
///
/// İki parça, dikey merkezleri tipik satır yüksekliğinin [rowToleranceRatio]
/// katından yakınsa AYNI satır sayılır. Oran medyan yükseklikten türetilir:
/// mutlak piksel eşiği, farklı çözünürlükteki ekran görüntülerinde (fotoğraf
/// vs. 1080p ekran görüntüsü) tutmazdı.
String layoutTextFromLines(
  List<OcrLine> lines, {
  double rowToleranceRatio = 0.6,
}) {
  final usable = [
    for (final l in lines)
      if (l.text.trim().isNotEmpty) l,
  ];
  if (usable.isEmpty) return '';

  final tolerance = _medianHeight(usable) * rowToleranceRatio;
  final sorted = [...usable]..sort((a, b) => a.centerY.compareTo(b.centerY));

  final rows = <List<OcrLine>>[];
  var current = <OcrLine>[sorted.first];
  var anchor = sorted.first.centerY;

  for (final line in sorted.skip(1)) {
    if ((line.centerY - anchor).abs() <= tolerance) {
      current.add(line);
    } else {
      rows.add(current);
      current = [line];
      // Çapa, satırın İLK parçasının merkezi: satır ortalamasını kaydırmak,
      // hafif eğik taranmış sayfalarda grupların birbirine akmasına yol açar.
      anchor = line.centerY;
    }
  }
  rows.add(current);

  return [
    for (final row in rows)
      (row..sort((a, b) => a.left.compareTo(b.left)))
          .map((l) => l.text.trim())
          .join(' '),
  ].join('\n');
}

double _medianHeight(List<OcrLine> lines) {
  final heights = [for (final l in lines) l.height]..sort();
  final mid = heights.length ~/ 2;
  final median = heights.length.isOdd
      ? heights[mid]
      : (heights[mid - 1] + heights[mid]) / 2;
  // Sıfır/negatif yükseklik (bozuk kutu) toleransı sıfırlamasın.
  return median > 0 ? median : 1;
}
