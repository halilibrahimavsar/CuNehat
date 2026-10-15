import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// [file]'a görsel olarak çözülemeyen bayt yazar ve çözme hatasını görsel
/// önbelleğine önceden düşürür.
///
/// Dosya okuma ve çözme gerçek zaman uyumsuz iş; widget testinin sahte
/// saatinde `pump` onları bitirmez. Hata `runAsync` içinde üretilince aynı
/// dosyayı gösteren `Image.file` hatayı önbellekten eşzamanlı alır.
Future<void> writeUndecodableImage(WidgetTester tester, File file) async {
  file
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(List<int>.filled(64, 7));

  await tester.runAsync(() async {
    final decoded = Completer<bool>();
    final stream = FileImage(file).resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (image, _) {
        image.dispose();
        decoded.complete(true);
      },
      onError: (_, __) => decoded.complete(false),
    );
    stream.addListener(listener);
    final ok = await decoded.future;
    stream.removeListener(listener);
    if (ok) throw StateError('Bozuk sanılan bayt görsel olarak çözüldü');
  });
}

/// [finder] bulunana dek (en çok ~1 sn) gerçek zamana izin verip kare çizer.
///
/// [writeUndecodableImage] hatayı yalnız düz `FileImage` anahtarıyla önbelleğe
/// düşürür; `cacheWidth` verilen bir `Image.file` ise `ResizeImage` anahtarı
/// kullanır ve o önbelleği ıskalar — çözme widget'ın kendi yüklemesinde,
/// gerçek zamanda olur. Yükleme sahte bölgede başladığı için tek bir
/// `runAsync` beklemesi kilitlenir; gerçek zaman ve `pump` dönüşümlü verilir.
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
  }
}
