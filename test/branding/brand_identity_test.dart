import 'dart:io';

import 'package:cunehat/core/services/google_drive_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Görünen marka adını, eski adı taşıyan KALICI kimliklerden ayırır.
///
/// Neden var: uygulamanın adı 16 Eylül 2026'da ÇuNehat → ÇuHat oldu. Görünen
/// ad (launcher etiketi, l10n, gizlilik politikası) serbestçe değişebilir;
/// eski adı taşıyan bazı kimlikler ise kullanıcı verisine bağlıdır ve
/// DEĞİŞMEZ:
/// - Drive yedek öneki: liste ve budama sorgusu `name contains` ile çalışır;
///   önek değişirse kullanıcının Drive'daki yedekleri görünmez olur.
/// - Bildirim kanal kimlikleri: kimlik değişirse Android yeni kanal açar,
///   kullanıcının sessize alma/önem ayarları kaybolur.
/// - `applicationId`: değişirse Play'de BAŞKA bir uygulama olur.
///
/// Test iki yönlü hatayı yakalar: eski adın görünen bir metinde kalması ve
/// "marka temizliği" adına kalıcı bir kimliğin değiştirilmesi. Önceki geçişte
/// (C → Ç, 26 Ağu 2026) toplu bul-değiştir rehberdeki gizlilik politikası
/// URL'ini bozmuştu — ad değişikliği bir metin değişikliği değildir.
void main() {
  const brand = 'ÇuHat';
  final oldName = RegExp('nehat', caseSensitive: false);

  /// Eski adı BİLEREK taşıyan kalıcı kimlikler; görünen ad değildir.
  const persistentTokens = [
    'package:cunehat/', // Dart paket adı
    'dev.halilibrahim.cunehat', // applicationId, MethodChannel adları
    'CuNehatApp', // sınıf adı
    'cunehat_app.dart',
    'cunehat_backup', // yedek dosya adı + Drive sorgu öneki
    'cunehat-backup-boundary', // multipart sınırı
    'cunehat_critical', // bildirim kanal kimlikleri
    'cunehat_recurring',
    'cunehat_motivational',
  ];

  List<String> remnants(File file, {List<String> allowed = const []}) {
    final hits = <String>[];
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      for (final token in [...persistentTokens, ...allowed]) {
        line = line.replaceAll(token, '');
      }
      if (oldName.hasMatch(line)) {
        hits.add('${file.path}:${i + 1}: ${lines[i].trim()}');
      }
    }
    return hits;
  }

  group('eski ad görünen hiçbir yerde kalmadı', () {
    test('lib/ (kod, l10n ARB ve üretilmiş l10n)', () {
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart') || f.path.endsWith('.arb'));
      final hits = [for (final f in files) ...remnants(f)];
      expect(hits, isEmpty, reason: hits.join('\n'));
    });

    test('Android manifestleri', () {
      final hits = [
        for (final flavor in const ['main', 'debug', 'profile'])
          ...remnants(File('android/app/src/$flavor/AndroidManifest.xml')),
      ];
      expect(hits, isEmpty, reason: hits.join('\n'));
    });

    test('Pages: site kökü ve gizlilik politikası', () {
      final hits = [
        ...remnants(File('docs/index.html')),
        // Politika geçiş döneminde eski adı da anar: Play, mağaza girişindeki
        // uygulama adının politikada geçmesini istiyor ve yeni mağaza adı
        // incelemeden geçene kadar eski ad yayında kalıyor.
        ...remnants(
          File('docs/privacy-policy.html'),
          allowed: const ['formerly ÇuNehat', 'önceki adıyla ÇuNehat'],
        ),
      ];
      expect(hits, isEmpty, reason: hits.join('\n'));
    });
  });

  group('görünen ad yeni markayı taşıyor', () {
    String manifest(String flavor) =>
        File('android/app/src/$flavor/AndroidManifest.xml').readAsStringSync();

    test('launcher etiketi', () {
      expect(manifest('main'), contains('android:label="$brand"'));
      expect(manifest('debug'), contains('android:label="$brand DEV"'));
      expect(manifest('profile'), contains('android:label="$brand DEV"'));
    });

    test('son uygulamalar ekranındaki başlık', () {
      expect(File('lib/core/widgets/cunehat_app.dart').readAsStringSync(),
          contains('title: "$brand"'));
    });

    test('tanıtım görseli üreteci', () {
      expect(File('tools/make_feature_graphic.py').readAsStringSync(),
          contains('WORDMARK = "$brand"'));
    });
  });

  group('kalıcı kimlikler marka değişse de DEĞİŞMEZ', () {
    test('Drive yedek öneki', () {
      expect(GoogleDriveBackupService.backupNamePrefix, 'cunehat_backup',
          reason: 'Drive listesi `name contains` ile sorgulanıyor; önek '
              'değişirse kullanıcıların mevcut yedekleri görünmez olur');
    });

    test('bildirim kanal kimlikleri', () {
      final service = File('lib/core/notifications/notification_service.dart')
          .readAsStringSync();
      for (final id in const [
        'cunehat_critical',
        'cunehat_recurring',
        'cunehat_motivational',
      ]) {
        expect(service, contains("id: '$id'"),
            reason: '$id değişirse Android yeni kanal açar; kullanıcının '
                'kanal ayarları kaybolur, eski kanal ayarlarda öksüz kalır');
      }
    });

    test('applicationId', () {
      expect(File('android/app/build.gradle.kts').readAsStringSync(),
          contains('applicationId = "dev.halilibrahim.cunehat"'),
          reason: "applicationId değişirse Play'de başka bir uygulama olur");
    });
  });
}
