import 'package:cunehat/core/services/backup_migrations.dart';
import 'package:cunehat/core/services/backup_summary.dart';
import 'package:cunehat/core/services/data_serialization_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Yedek yükseltme zincirinin testleri.
///
/// Bu zincir kapalı test yayındayken doğdu (bkz. `CLAUDE.md`): testerların
/// Drive'ında v9 yedekleri duruyor. Sürüm kapısı eskiden SIKI EŞİTLİKTİ, yani
/// `schemaVersion` artar artmaz o yedekler geri yüklenemez hale gelirdi —
/// "yedeğim vardı" diyen kullanıcı verisini kurtaramazdı. Buradaki testler tam
/// olarak bunu engelliyor.
void main() {
  Map<String, dynamic> v9Backup({List<Map<String, dynamic>>? wallets}) => {
        'version': 9,
        'timestamp': '2026-09-01T10:00:00.000',
        'wallets': wallets ??
            [
              {'id': 'w1', 'name': 'Nakit'},
              {'id': 'w2', 'name': 'İş'},
            ],
        'transactions': [
          {'id': 't1', 'tag': 'cat-1'},
        ],
        'categories': [
          {'id': 'cat-1', 'name': 'Market'},
        ],
        'users': <String, dynamic>{},
      };

  group('migrateBackup', () {
    test('güncel sürüm olduğu gibi geçer', () {
      final current = {'version': DataSerializationService.schemaVersion};
      expect(
        migrateBackup(current,
            targetVersion: DataSerializationService.schemaVersion),
        current,
      );
    });

    test('v9 → v10: sürüm damgası yükselir', () {
      final result = migrateBackup(v9Backup(), targetVersion: 10);
      expect(result['version'], 10);
    });

    test('v9 → v10: her cüzdan KÜRASYONSUZ gelir (categoryIds null)', () {
      // v9'da kategoriler cüzdandan bağımsızdı: her cüzdan hepsini görüyordu.
      // `null` tam olarak bu anlama gelir; başka bir değer (ör. boş liste)
      // eski yedekten dönen kullanıcının bütün kategorilerini kaybetmesi
      // demek olurdu.
      final result = migrateBackup(v9Backup(), targetVersion: 10);

      final wallets = (result['wallets'] as List).cast<Map<String, dynamic>>();
      expect(wallets, hasLength(2));
      for (final w in wallets) {
        expect(w.containsKey('categoryIds'), isTrue);
        expect(w['categoryIds'], isNull);
      }
      // Diğer alanlar korunur.
      expect(wallets.map((w) => w['name']), ['Nakit', 'İş']);
    });

    test('v9 → v10: cüzdan dışındaki bölümlere DOKUNULMAZ', () {
      final source = v9Backup();
      final result = migrateBackup(source, targetVersion: 10);

      expect(result['transactions'], source['transactions']);
      expect(result['categories'], source['categories']);
      expect(result['timestamp'], source['timestamp']);
    });

    test('dönüşüm SAFTIR: girdi haritası değişmez', () {
      final source = v9Backup();
      migrateBackup(source, targetVersion: 10);

      expect(source['version'], 9);
      expect(
        (source['wallets'] as List).first,
        isNot(contains('categoryIds')),
      );
    });

    test('cüzdan listesi yoksa çökmez', () {
      final result = migrateBackup(
        {'version': 9, 'users': <String, dynamic>{}},
        targetVersion: 10,
      );
      expect(result['version'], 10);
      expect(result['wallets'], isEmpty);
    });

    group('reddedilenler', () {
      test('desteklenenden ESKİ sürüm', () {
        expect(
          () => migrateBackup({'version': 8}, targetVersion: 10),
          throwsA(isA<BackupVersionMismatch>()
              .having((e) => e.found, 'found', 8)
              .having((e) => e.expected, 'expected', 10)),
        );
      });

      test('hedeften YENİ sürüm (ileri uyumluluk yok)', () {
        expect(
          () => migrateBackup({'version': 11}, targetVersion: 10),
          throwsA(isA<BackupVersionMismatch>()),
        );
      });

      test('sürüm alanı yok', () {
        expect(
          () => migrateBackup(<String, dynamic>{}, targetVersion: 10),
          throwsA(isA<BackupVersionMismatch>()),
        );
      });

      test('sürüm sayı değil', () {
        expect(
          () => migrateBackup({'version': '9'}, targetVersion: 10),
          throwsA(isA<BackupVersionMismatch>()),
        );
      });
    });
  });

  group('zincir bütünlüğü', () {
    test('desteklenen en eskiden güncele kadar HER adım tanımlı', () {
      // Zincirde bir boşluk kalırsa (ör. v11 eklenip 10→11 yazılmazsa) o
      // sürümden itibaren tüm eski yedekler sessizce reddedilmeye başlar.
      // Bu test, `schemaVersion` artıran kişiyi migrasyon yazmaya zorlar.
      for (var v = oldestSupportedBackupVersion;
          v < DataSerializationService.schemaVersion;
          v++) {
        expect(
          backupMigrations[v],
          isNotNull,
          reason: 'v$v → v${v + 1} dönüşümü eksik',
        );
      }
    });

    test('güncel sürüm için adım GEREKMEZ', () {
      expect(backupMigrations[DataSerializationService.schemaVersion], isNull);
    });
  });
}
