import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cihaz kenarlarını (durum çubuğu / gezinme çubuğu) taklit eden ölçüm aracı.
///
/// **Neden var.** `targetSdk 36` ile Android artık edge-to-edge'i ZORUNLU
/// kılıyor: uygulama her zaman durum çubuğunun ve gezinme çubuğunun ALTINA
/// çiziyor. Varsayılan test yüzeyinin `padding`'i ise SIFIR — yani testler
/// tam da bu hatayı göremeyecek şekilde koşuyor. Bu aracın tek işi o payları
/// geri koyup "hangi piksel çubuğun altında kaldı"yı ÖLÇMEK.
class DeviceInsets {
  /// Pixel sınıfı bir telefon: 48dp durum çubuğu, 48dp 3 tuşlu gezinme çubuğu.
  static const buttonNav = EdgeInsets.only(top: 48, bottom: 48);

  /// Jest gezinmesi: ince tutamak.
  static const gestureNav = EdgeInsets.only(top: 48, bottom: 24);
}

/// Güvenli olmayan bölgeye taşan tek bir öğe.
class UnsafeHit {
  UnsafeHit({
    required this.label,
    required this.rect,
    required this.edge,
    required this.overlap,
  });

  final String label;
  final Rect rect;

  /// 'top' ya da 'bottom'.
  final String edge;

  /// Kaç dp çubuğun altında kaldı.
  final double overlap;

  @override
  String toString() =>
      '$edge ${overlap.toStringAsFixed(1)}dp  $label  ${_r(rect)}';

  static String _r(Rect r) =>
      '(${r.left.toStringAsFixed(0)},${r.top.toStringAsFixed(0)})'
      '-(${r.right.toStringAsFixed(0)},${r.bottom.toStringAsFixed(0)})';
}

/// Ekranda GÖRÜNEN öğeleri (yazı, ikon, anahtar, düğme yüzeyi) tarar ve
/// bunlardan güvenli olmayan şeride giren varsa döner.
///
/// Yalnız görünür bir şey çizen öğeler sayılır: kaydırıcıların, `Container`
/// kabuklarının ya da tam ekran zeminlerin çubuğun altına uzanması NORMALDİR
/// (zaten istenen budur) — hata, OKUNACAK ya da DOKUNULACAK bir şeyin oraya
/// düşmesidir.
List<UnsafeHit> probeUnsafe(
  WidgetTester tester, {
  required EdgeInsets insets,
  required Size screen,
  double tolerance = 0.5,
}) {
  final hits = <UnsafeHit>[];
  // Üst çubuğun (AppBar/SliverAppBar) örttüğü şerit güvenlidir: içeriğin
  // onun ALTINDAN kayması istenen davranıştır, hata değil.
  final topLimit = statusBarIsCovered(tester, insets.top) ? 0.0 : insets.top;
  final bottomLimit = screen.height - insets.bottom;

  void consider(Element element, String label) {
    final ro = element.renderObject;
    if (ro is! RenderBox || !ro.hasSize || !ro.attached) return;
    if (ro.size.isEmpty) return;
    final Offset origin;
    try {
      origin = ro.localToGlobal(Offset.zero);
    } catch (_) {
      return;
    }
    final rect = origin & ro.size;
    // Ekran dışına kaydırılmış (henüz görünmeyen) içerik sayılmaz.
    if (rect.bottom <= 0 || rect.top >= screen.height) return;

    final topOverlap = topLimit - rect.top;
    // topLimit == 0 → durum çubuğunu üst çubuk örtüyor; y<0'daki içerik
    // kaydırma sonucu kırpılmıştır, hata değil.
    if (topLimit > 0 && topOverlap > tolerance && rect.top < topLimit) {
      hits.add(UnsafeHit(
        label: label,
        rect: rect,
        edge: 'top',
        overlap: topOverlap.clamp(0, ro.size.height),
      ));
      return;
    }
    final bottomOverlap = rect.bottom - bottomLimit;
    if (bottomOverlap > tolerance && rect.bottom > bottomLimit) {
      hits.add(UnsafeHit(
        label: label,
        rect: rect,
        edge: 'bottom',
        overlap: bottomOverlap.clamp(0, ro.size.height),
      ));
    }
  }

  for (final element in find.byType(Text).evaluate()) {
    final w = element.widget as Text;
    consider(element, 'Text("${_short(w.data ?? w.textSpan?.toPlainText())}")');
  }
  for (final element in find.byType(Icon).evaluate()) {
    final w = element.widget as Icon;
    consider(element, 'Icon(${w.icon?.codePoint})');
  }
  for (final t in const <Type>[
    Switch,
    Checkbox,
    Radio,
    Slider,
    TextField,
    FloatingActionButton,
    AppCard,
    Card,
    ElevatedButton,
    FilledButton,
    OutlinedButton,
    TextButton,
  ]) {
    for (final element in find.byType(t).evaluate()) {
      consider(element, '$t');
    }
  }
  return hits;
}

/// Durum çubuğu şeridini opak bir üst çubuk örtüyor mu?
///
/// `AppBar` (SliverAppBar da onu kurar) `primary` iken kendi içinde
/// `SafeArea` uygular ve zemini durum çubuğunun altına kadar boyar. Böyle bir
/// çubuk varsa üst kenar ZATEN güvenlidir.
bool statusBarIsCovered(WidgetTester tester, double statusBarHeight) {
  if (statusBarHeight <= 0) return true;
  for (final element in find.byType(AppBar).evaluate()) {
    final ro = element.renderObject;
    if (ro is! RenderBox || !ro.hasSize || !ro.attached) continue;
    final rect = ro.localToGlobal(Offset.zero) & ro.size;
    if (rect.top <= 0.5 && rect.bottom >= statusBarHeight - 0.5) return true;
  }
  return false;
}

/// Sayfanın en altta çizdiği görünür içeriğin alt kenarı (dp).
///
/// "Taşma yok" iddiasının bir de zeminini görmek gerekiyor: içerik hiç o
/// kadar uzamıyorsa test yeşil kalır ama sayfa uzayınca hata geri döner.
double? lowestContentBottom(WidgetTester tester, Size screen) {
  double? lowest;
  void scan(Finder finder) {
    for (final element in finder.evaluate()) {
      final ro = element.renderObject;
      if (ro is! RenderBox || !ro.hasSize || !ro.attached) continue;
      if (ro.size.isEmpty) continue;
      final rect = ro.localToGlobal(Offset.zero) & ro.size;
      if (rect.top >= screen.height || rect.bottom <= 0) continue;
      if (lowest == null || rect.bottom > lowest!) lowest = rect.bottom;
    }
  }

  scan(find.byType(Text));
  scan(find.byType(Icon));
  scan(find.byType(AppCard));
  scan(find.byType(Card));
  return lowest;
}

String _short(String? s) {
  if (s == null) return '';
  final one = s.replaceAll('\n', ' ');
  return one.length <= 28 ? one : '${one.substring(0, 28)}…';
}

/// Ölçüm yüzeyini gerçek bir telefona benzetir.
Future<void> useDevice(
  WidgetTester tester, {
  Size size = const Size(411, 914),
  double dpr = 1.0,
}) async {
  tester.view.physicalSize = size * dpr;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
}

/// Verilen sayfayı cihaz paylarıyla sarar.
Widget withDeviceInsets(Widget child, EdgeInsets insets) {
  return Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: insets,
        viewPadding: insets,
      ),
      child: child,
    ),
  );
}

/// Bulguları okunur bir rapora çevirir.
String reportHits(String page, List<UnsafeHit> hits) {
  if (hits.isEmpty) return '✅ $page — temiz';
  final buf = StringBuffer('❌ $page — ${hits.length} taşma');
  for (final h in hits) {
    buf.write('\n     $h');
  }
  return buf.toString();
}
