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

  group('v12 → v13 (işlemlere içe aktarım partisi)', () {
    Map<String, dynamic> v12Backup() => {
          'version': 12,
          'timestamp': '2026-09-24T10:00:00.000',
          'wallets': [
            {
              'id': 'w1',
              'name': 'Nakit',
              'categoryIds': null,
              'creditCard': null
            },
          ],
          'transactions': [
            {'id': 't1', 'tag': 'cat-1', 'origin': 'import'},
            {'id': 't2', 'tag': 'cat-2', 'origin': 'manual'},
          ],
          'users': <String, dynamic>{},
        };

    test('sürüm damgası 13 olur', () {
      expect(migrateBackup(v12Backup(), targetVersion: 13)['version'], 13);
    });

    test('her işleme importBatchId AÇIKÇA null yazılır ("bilinmiyor")', () {
      // v12'de parti saklanmıyordu: eski içe aktarımlar "Son içe aktarımlar"
      // listesinde görünmez, başka hiçbir şeyleri değişmez.
      final result = migrateBackup(v12Backup(), targetVersion: 13);
      final txs = (result['transactions'] as List).cast<Map<String, dynamic>>();
      expect(txs, hasLength(2));
      for (final t in txs) {
        expect(t.containsKey('importBatchId'), isTrue);
        expect(t['importBatchId'], isNull);
      }
      expect(txs.map((t) => t['origin']), ['import', 'manual']);
    });

    test('işlem dışındaki bölümlere DOKUNULMAZ; dönüşüm SAFTIR', () {
      final source = v12Backup();
      final result = migrateBackup(source, targetVersion: 13);
      expect(result['wallets'], source['wallets']);
      expect(source['version'], 12);
      expect((source['transactions'] as List).first,
          isNot(contains('importBatchId')));
    });

    test('işlem listesi yoksa çökmez', () {
      final result = migrateBackup(
        {'version': 12, 'users': <String, dynamic>{}},
        targetVersion: 13,
      );
      expect(result['transactions'], isEmpty);
    });

    test('v9 yedeği dört adımda (9→10→11→12→13) yükselir', () {
      final result = migrateBackup(v9Backup(), targetVersion: 13);
      expect(result['version'], 13);
      final tx = (result['transactions'] as List).first as Map;
      expect(tx, containsPair('origin', null));
      expect(tx, containsPair('importBatchId', null));
    });
  });

  group('v13 → v14 (birikimde nakit kasası türü)', () {
    Map<String, dynamic> v13Backup() => {
          'version': 13,
          'timestamp': '2026-09-25T10:00:00.000',
          'investments': [
            {'id': 'i1', 'type': 'gold', 'amount': 100.0},
          ],
          'transactions': [
            {'id': 't1', 'importBatchId': null},
          ],
          'users': <String, dynamic>{},
        };

    test('yalnız sürüm damgası değişir (v13 kayıtlarında kasa yok)', () {
      final source = v13Backup();
      final result = migrateBackup(source, targetVersion: 14);
      expect(result['version'], 14);
      expect(result['investments'], source['investments']);
      expect(result['transactions'], source['transactions']);
      expect(source['version'], 13, reason: 'dönüşüm saf olmalı');
    });

    test('v9 yedeği beş adımda güncele yükselir', () {
      final result = migrateBackup(v9Backup(), targetVersion: 14);
      expect(result['version'], 14);
      final tx = (result['transactions'] as List).first as Map;
      expect(tx, containsPair('importBatchId', null));
    });
  });

  group('v14 → v15 (taksit grubu)', () {
    Map<String, dynamic> v14Backup() => {
          'version': 14,
          'timestamp': '2026-10-01T10:00:00.000',
          'transactions': [
            {'id': 't1', 'title': 'Laptop (1/6)', 'importBatchId': null},
            {'id': 't2', 'title': 'Market', 'importBatchId': 'b1'},
          ],
          'wallets': [
            {'id': 'w1'},
          ],
          'users': <String, dynamic>{},
        };

    test('her işleme üç alan AÇIKÇA null yazılır; başlıktan tahmin YOK', () {
      final result = migrateBackup(v14Backup(), targetVersion: 15);
      expect(result['version'], 15);
      final txs = (result['transactions'] as List).cast<Map<String, dynamic>>();
      for (final t in txs) {
        expect(t, containsPair('installmentGroupId', null));
        expect(t, containsPair('installmentNo', null));
        expect(t, containsPair('installmentCount', null));
      }
      expect(txs.map((t) => t['importBatchId']), [null, 'b1']);
    });

    test('dönüşüm SAFTIR; işlem dışına dokunulmaz', () {
      final source = v14Backup();
      final result = migrateBackup(source, targetVersion: 15);
      expect(result['wallets'], source['wallets']);
      expect(source['version'], 14);
      expect((source['transactions'] as List).first,
          isNot(contains('installmentGroupId')));
    });

    test('işlem listesi yoksa çökmez', () {
      final result = migrateBackup(
        {'version': 14, 'users': <String, dynamic>{}},
        targetVersion: 15,
      );
      expect(result['transactions'], isEmpty);
    });

    test('v9 yedeği altı adımda güncele yükselir', () {
      final result = migrateBackup(v9Backup(), targetVersion: 15);
      expect(result['version'], 15);
      final tx = (result['transactions'] as List).first as Map;
      expect(tx, containsPair('importBatchId', null));
      expect(tx, containsPair('installmentGroupId', null));
    });
  });

  group('v15 → v16 (kart: gün farkı + faiz; yatırım: ana kasa)', () {
    Map<String, dynamic> v15Backup() => {
          'version': 15,
          'timestamp': '2026-10-10T10:00:00.000',
          'wallets': [
            {'id': 'w1', 'name': 'Maaş', 'creditCard': null},
            {
              'id': 'card',
              'name': 'Bonus',
              'creditCard': {
                'bankName': 'QNB',
                'closingDay': 25,
                'dueDay': 5,
                'lastStatement': null,
              },
            },
          ],
          'investments': [
            {'id': 'pot', 'name': 'Acil durum', 'unbookedCost': 0},
            {'id': 'gold', 'name': 'Gram', 'unbookedCost': 120.5},
          ],
          'transactions': [
            {'id': 't1', 'installmentGroupId': null},
          ],
          'users': <String, dynamic>{},
        };

    test('kartın üç yeni alanı AÇIKÇA null yazılır; eski alanlar korunur', () {
      final result = migrateBackup(v15Backup(), targetVersion: 16);
      expect(result['version'], 16);

      final card = ((result['wallets'] as List)[1] as Map)['creditCard'] as Map;
      expect(card, containsPair('dueOffsetDays', null));
      expect(card, containsPair('monthlyInterestRate', null));
      expect(card, containsPair('lateInterestRate', null));
      expect(card['bankName'], 'QNB');
      expect(card['closingDay'], 25);
      expect(card['dueDay'], 5);
    });

    test('kartı OLMAYAN cüzdanın creditCard\'ı null KALIR (karta dönmez)', () {
      final result = migrateBackup(v15Backup(), targetVersion: 16);
      final plain = (result['wallets'] as List).first as Map;
      expect(plain.containsKey('creditCard'), isTrue);
      expect(plain['creditCard'], isNull);
      expect(plain['name'], 'Maaş');
    });

    test('her yatırıma isPrimary: false yazılır — hiçbir kasa işaretli gelmez',
        () {
      // `true` ya da tahmin (ör. "en dolu kasa ana kasadır") kullanıcının
      // hiç yapmadığı bir seçimi yedekten geri getirmek olurdu.
      final result = migrateBackup(v15Backup(), targetVersion: 16);
      final investments =
          (result['investments'] as List).cast<Map<String, dynamic>>();
      expect(investments, hasLength(2));
      for (final i in investments) {
        expect(i, containsPair('isPrimary', false));
      }
      expect(investments.map((i) => i['unbookedCost']), [0, 120.5]);
    });

    test('dönüşüm SAFTIR; işlemlere dokunulmaz', () {
      final source = v15Backup();
      final result = migrateBackup(source, targetVersion: 16);

      expect(result['transactions'], source['transactions']);
      expect(source['version'], 15);
      final sourceCard =
          ((source['wallets'] as List)[1] as Map)['creditCard'] as Map;
      expect(sourceCard.containsKey('dueOffsetDays'), isFalse);
      expect(
          (source['investments'] as List).first, isNot(contains('isPrimary')));
    });

    test('cüzdan ya da yatırım listesi yoksa çökmez', () {
      final result = migrateBackup(
        {'version': 15, 'users': <String, dynamic>{}},
        targetVersion: 16,
      );
      expect(result['wallets'], isEmpty);
      expect(result['investments'], isEmpty);
    });

    test('v9 yedeği YEDİ adımda güncele yükselir', () {
      final result = migrateBackup(
        v9Backup(),
        targetVersion: DataSerializationService.schemaVersion,
      );
      expect(result['version'], 16);
      final wallet = (result['wallets'] as List).first as Map;
      // v9'da kart kavramı yoktu: creditCard null, içine alan da yazılmaz.
      expect(wallet['creditCard'], isNull);
      final tx = (result['transactions'] as List).first as Map;
      expect(tx, containsPair('installmentGroupId', null));
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
