import 'dart:math' as math;

/// Oran çubuğunun çizim genişliği.
///
/// En küçük kalem bile görünür kalsın diye [minVisible] tabanı uygulanır; ama
/// taban mevcut genişliği AŞAMAZ. Eskiden doğrudan
/// `clamp(minVisible, maxWidth)` yazılıyordu: dar bir yerleşimde
/// (`maxWidth < minVisible`) alt sınır üst sınırı geçtiği için `clamp`
/// ArgumentError fırlatıyordu. Hata build sırasında doğduğundan kartın tamamı
/// hata görünümüne düşerdi.
double visibleBarWidth({
  required double maxWidth,
  required double fraction,
  double minVisible = 4.0,
}) =>
    (maxWidth * fraction).clamp(math.min(minVisible, maxWidth), maxWidth);
