import 'dart:io';

import 'package:cunehat/config/theme/app_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tasarım jetonlarının CIRCIRI.
///
/// `lib/` içinde satır içi yazılmış ölçek dışı değerleri sayar ve sayıyı
/// aşağıdaki tabana kilitler. Amaç bugünkü borcu bir günde ödemek değil,
/// borcun BÜYÜMESİNİ durdurmak: yüzeyler tek tek temaya taşınırken yeni
/// yazılan kod eski alışkanlığı geri getirmesin.
///
/// Test iki yönde de kırılır:
/// - sayı ARTTIYSA: yeni bir satır içi değer girmiş → tema rolü / jeton kullan
///   (`Theme.of(context).textTheme`, `colorScheme`, `MoneyColors`, `AppRadius`).
/// - sayı AZALDIYSA: bir yüzey taşınmış → tabanı yeni sayıya İNDİR. Taban
///   gevşek bırakılırsa cırcır geri kayar.
///
/// Üretilen dosyalar (`*.g.dart`, çeviri sınıfları, DI yapılandırması) sayılmaz.
void main() {
  // Tabanlar — 13 Eki 2026. Başlangıç: palet 282 · fontSize 252 · yarıçap 167
  // · kalın 119. Yeni kullanıcının yolundaki yüzeyler taşındıkça indi.
  const rawPaletteBaseline = 281;
  const offScaleFontSizeBaseline = 207;
  const offScaleRadiusBaseline = 141;
  const heavyWeightBaseline = 98;

  final sources = _dartSources();

  test('ham Material paleti (Colors.green, Colors.red…) artmaz', () {
    final hits = _count(
      sources,
      RegExp(
        r'Colors\.(red|green|blue|amber|orange|purple|teal|pink|indigo|cyan|'
        r'grey|yellow|lime|brown|deepOrange|deepPurple|lightBlue|lightGreen|'
        r'blueGrey)(Accent)?\b',
      ),
    );
    _expectBaseline(
      hits,
      rawPaletteBaseline,
      what: 'ham Material rengi',
      instead: 'MoneyColors / AppGradients / colorScheme',
    );
  });

  test('ölçek dışı yazı boyutu artmaz', () {
    final hits = _countWhere(
      sources,
      RegExp(r'fontSize:\s*([0-9]+(?:\.[0-9]+)?)\b'),
      (m) => !AppType.sizes.contains(double.parse(m.group(1)!)),
    );
    _expectBaseline(
      hits,
      offScaleFontSizeBaseline,
      what: 'ölçek dışı fontSize (ölçek: ${AppType.sizes.join(' · ')})',
      instead: 'Theme.of(context).textTheme rolü',
    );
  });

  test('ölçek dışı köşe yarıçapı artmaz', () {
    const scale = [
      AppRadius.control,
      AppRadius.card,
      AppRadius.sheet,
      AppRadius.pill,
    ];
    final hits = _countWhere(
      sources,
      RegExp(r'BorderRadius\.circular\(\s*([0-9]+(?:\.[0-9]+)?)\s*\)'),
      (m) {
        final value = double.parse(m.group(1)!);
        // 4 ve altı köşe değil çizgi ucudur (ilerleme çubuğu, tutamaç).
        return value > 4 && !scale.contains(value);
      },
    );
    _expectBaseline(
      hits,
      offScaleRadiusBaseline,
      what: 'ölçek dışı BorderRadius.circular (ölçek: ${scale.join(' · ')})',
      instead: 'AppRadius',
    );
  });

  test('aşırı kalın yazı (w800 / w900) artmaz', () {
    final hits = _count(sources, RegExp(r'FontWeight\.w(800|900)\b'));
    _expectBaseline(
      hits,
      heavyWeightBaseline,
      what: 'FontWeight.w800 / w900',
      instead: 'AppType.strong (w700)',
    );
  });
}

void _expectBaseline(
  int hits,
  int baseline, {
  required String what,
  required String instead,
}) {
  expect(
    hits,
    lessThanOrEqualTo(baseline),
    reason: '$what ARTTI: $hits (taban $baseline). Yerine: $instead.',
  );
  expect(
    hits,
    greaterThanOrEqualTo(baseline),
    reason: '$what AZALDI: $hits (taban $baseline). '
        'Tabanı $hits yap ki cırcır geri kaymasın.',
  );
}

List<String> _dartSources() {
  final root = Directory('lib');
  return [
    for (final entity in root.listSync(recursive: true))
      if (entity is File && _isHandWritten(entity.path))
        entity.readAsStringSync(),
  ];
}

bool _isHandWritten(String path) {
  final p = path.replaceAll(r'\', '/');
  if (!p.endsWith('.dart')) return false;
  if (p.endsWith('.g.dart') || p.endsWith('.config.dart')) return false;
  if (p.contains('/l10n/app_localizations')) return false;
  return true;
}

int _count(List<String> sources, RegExp pattern) =>
    sources.fold(0, (sum, s) => sum + pattern.allMatches(s).length);

int _countWhere(
  List<String> sources,
  RegExp pattern,
  bool Function(RegExpMatch) test,
) =>
    sources.fold(0, (sum, s) => sum + pattern.allMatches(s).where(test).length);
