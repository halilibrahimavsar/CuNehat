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

  group('v10 → v11 (işlemlere kuplaj bağı ve köken)', () {
    Map<String, dynamic> v10Backup() => {
          'version': 10,
          'timestamp': '2026-09-20T10:00:00.000',
          'wallets': [
            {'id': 'w1', 'name': 'Nakit', 'categoryIds': null},
          ],
          'transactions': [
            {'id': 't1', 'tag': 'cat-1', 'isSystem': false},
            {'id': 't2', 'tag': 'Borç Ödemesi', 'isSystem': true},
          ],
          'users': <String, dynamic>{},
        };

    test('sürüm damgası 11 olur', () {
      expect(migrateBackup(v10Backup(), targetVersion: 11)['version'], 11);
    });

    test('her işleme üç alan AÇIKÇA null yazılır ("bilinmiyor")', () {
      // Eski kuplaj hareketinin sahibi bilinmiyordu; benimseme yoktu; kaydın
      // kökeni saklanmıyordu. `null` tam olarak bunu söyler.
      final result = migrateBackup(v10Backup(), targetVersion: 11);
      final txs = (result['transactions'] as List).cast<Map<String, dynamic>>();
      expect(txs, hasLength(2));
      for (final t in txs) {
        for (final key in ['linkedRecordId', 'adoptedFromTag', 'origin']) {
          expect(t.containsKey(key), isTrue, reason: key);
          expect(t[key], isNull, reason: key);
        }
      }
      // Diğer alanlar korunur (sistem işareti dahil).
      expect(txs.map((t) => t['isSystem']), [false, true]);
    });

    test('işlem dışındaki bölümlere DOKUNULMAZ', () {
      final source = v10Backup();
      final result = migrateBackup(source, targetVersion: 11);
      expect(result['wallets'], source['wallets']);
      expect(result['timestamp'], source['timestamp']);
    });

    test('dönüşüm SAFTIR: girdi değişmez', () {
      final source = v10Backup();
      migrateBackup(source, targetVersion: 11);
      expect(source['version'], 10);
      expect((source['transactions'] as List).first,
          isNot(contains('linkedRecordId')));
    });

    test('işlem listesi yoksa çökmez', () {
      final result = migrateBackup(
        {'version': 10, 'users': <String, dynamic>{}},
        targetVersion: 11,
      );
      expect(result['transactions'], isEmpty);
    });

    test('v9 yedeği iki adımda (9→10→11) yükselir', () {
      final result = migrateBackup(v9Backup(), targetVersion: 11);
      expect(result['version'], 11);
      expect(
          (result['wallets'] as List).first, containsPair('categoryIds', null));
      expect(
          (result['transactions'] as List).first, containsPair('origin', null));
    });
  });

  group('v11 → v12 (cüzdanlara kredi kartı bilgisi)', () {
    Map<String, dynamic> v11Backup() => {
          'version': 11,
          'timestamp': '2026-09-23T10:00:00.000',
          'wallets': [
            {'id': 'w1', 'name': 'Nakit', 'categoryIds': null},
            {'id': 'w2', 'name': 'Bonus Kart', 'categoryIds': <String>[]},
          ],
          'transactions': [
            {'id': 't1', 'tag': 'cat-1', 'origin': 'manual'},
          ],
          'users': <String, dynamic>{},
        };

    test('sürüm damgası 12 olur', () {
      expect(migrateBackup(v11Backup(), targetVersion: 12)['version'], 12);
    });

    test('her cüzdana creditCard AÇIKÇA null yazılır (düz cüzdan)', () {
      // v11'de kart kavramı yoktu: her cüzdan düz cüzdandı. Elle açılmış
      // "kart" cüzdanı da düz kalır; kullanıcı sonradan çevirebilir.
      final result = migrateBackup(v11Backup(), targetVersion: 12);
      final wallets = (result['wallets'] as List).cast<Map<String, dynamic>>();
      expect(wallets, hasLength(2));
      for (final w in wallets) {
        expect(w.containsKey('creditCard'), isTrue);
        expect(w['creditCard'], isNull);
      }
      expect(wallets.map((w) => w['name']), ['Nakit', 'Bonus Kart']);
      expect(wallets.last['categoryIds'], isEmpty);
    });

    test('cüzdan dışındaki bölümlere DOKUNULMAZ; dönüşüm SAFTIR', () {
      final source = v11Backup();
      final result = migrateBackup(source, targetVersion: 12);
      expect(result['transactions'], source['transactions']);
      expect(source['version'], 11);
      expect((source['wallets'] as List).first, isNot(contains('creditCard')));
    });

    test('v9 yedeği üç adımda (9→10→11→12) yükselir', () {
      final result = migrateBackup(v9Backup(), targetVersion: 12);
      expect(result['version'], 12);
      final wallet = (result['wallets'] as List).first as Map;
      expect(wallet, containsPair('categoryIds', null));
      expect(wallet, containsPair('creditCard', null));
      expect(
          (result['transactions'] as List).first, containsPair('origin', null));
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
