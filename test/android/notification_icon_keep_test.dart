import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Dart'tan STRING ile referans verilen Android kaynaklarının release
/// derlemesinde hayatta kalmasını güvenceye alır.
///
/// Neden var: `isShrinkResources = true` ile kaynak küçültücü, hangi
/// kaynağın kullanıldığını dex ve XML'lere bakarak çıkarır. Bildirim
/// ikonlarına tek referans Dart tarafındaki bir string
/// (`'@drawable/ic_notification'`) ve o string Flutter snapshot'ında
/// (`libapp.so`) yaşıyor — küçültücü orayı okuyamaz.
///
/// ÖLÇÜLDÜ (`v1.0.0+4` APK'sı): `ic_notification_large` release paketinde
/// yoktu. `ic_notification` yalnızca AndroidManifest'teki
/// `default_notification_icon` meta-data'sı sayesinde kalmıştı — yani KÜÇÜK
/// ikonun sağ kalması tesadüftü. Küçük ikon atılırsa `getIdentifier` 0 döner,
/// `setSmallIcon(0)` ile sistem bildirimi SESSİZCE düşürür: çökme yok, log
/// yok, bildirim yok. Bu test o tesadüfü sözleşmeye çevirir.
void main() {
  test('notification_service.dart\'taki her @drawable keep.xml\'de listeli',
      () {
    final service =
        File('lib/core/notifications/notification_service.dart').readAsStringSync();
    final keep = File('android/app/src/main/res/raw/keep.xml');

    expect(keep.existsSync(), isTrue,
        reason: 'keep.xml silinirse bildirim ikonları release\'te atılır');

    final keepContents = keep.readAsStringSync();
    final referenced = RegExp(r"@drawable/([A-Za-z0-9_]+)")
        .allMatches(service)
        .map((m) => m.group(1)!)
        .toSet();

    expect(referenced, isNotEmpty,
        reason: 'ikon adları değiştiyse bu testin regex\'i de güncellenmeli');

    for (final name in referenced) {
      expect(keepContents, contains('@drawable/$name'),
          reason: '$name Dart\'tan string ile çağrılıyor ama keep.xml\'de yok; '
              'release derlemesinde atılır ve bildirim sessizce görünmez olur');
    }
  });

  test('küçük ikon manifest\'te de çıpalı kalmalı', () {
    // İkinci bir çıpa: keep.xml yanlışlıkla silinse bile küçük ikon ayakta
    // kalsın. Bildirim büyük ikon olmadan gösterilir, küçük ikon olmadan
    // HİÇ gösterilmez.
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('default_notification_icon'));
    expect(manifest, contains('@drawable/ic_notification'));
  });
}
