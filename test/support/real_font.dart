import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testlerde GERÇEK Roboto'yu yükler.
///
/// **Neden gerekli:** `flutter test` varsayılan olarak her glife aynı kutuyu
/// veren bir yer tutucu font kullanır ve bu font gerçek Roboto'dan belirgin
/// biçimde GENİŞTİR. Bu projede aynı tuzağa birden çok kez düşüldü: taşma
/// ölçen testler var olmayan taşmalar raporluyor ya da gerçek taşmaları
/// kaçırıyordu. Ölçülen örnek — "Kategori Dağılımı" + mod seçici satırı test
/// fontuyla 91px taşıyor görünüyordu, gerçek Roboto ile 59,6px BOŞLUKLA
/// sığıyor.
///
/// Yalnız GENİŞLİK/taşma iddiası kuran testler bunu çağırmalı; ötekiler
/// varsayılan fontla daha hızlı çalışır.
///
/// Font, çalışan Flutter SDK'sının kendi `material_fonts` önbelleğinden
/// okunur (yol makineye gömülmez): `dart` çalıştırılabiliri
/// `<flutter>/bin/cache/dart-sdk/bin/` altındadır.
Future<void> loadRealRoboto() async {
  final dir = _materialFontsDir();
  if (dir == null) {
    markTestSkipped('Roboto bulunamadı: SDK font önbelleği yok');
    return;
  }

  for (final name in const [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]) {
    final file = File('${dir.path}/$name');
    if (!file.existsSync()) continue;
    final bytes = file.readAsBytesSync();
    // FontLoader aynı aileye birden çok ağırlık ekleyebilir.
    await (FontLoader('Roboto')
          ..addFont(Future.value(ByteData.view(bytes.buffer))))
        .load();
  }
}

Directory? _materialFontsDir() {
  var dir = File(Platform.resolvedExecutable).parent;
  // .../bin/cache/dart-sdk/bin → .../bin/cache
  for (var i = 0; i < 6 && dir.path != dir.parent.path; i++) {
    final candidate = Directory('${dir.path}/artifacts/material_fonts');
    if (candidate.existsSync()) return candidate;
    dir = dir.parent;
  }
  return null;
}

/// Gerçek Roboto ile ölçen testlerin kullanacağı tema.
///
/// `fontFamily` açıkça verilir: yüklenen font "Roboto" ailesine kaydedilir
/// ama testte varsayılan aile o değildir.
const String kRealFontFamily = 'Roboto';
