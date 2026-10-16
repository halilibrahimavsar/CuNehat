/// Yedek şeması yükseltme zinciri — vN → vN+1, **ham JSON map üzerinde**.
///
/// Neden burada ve neden ham map: modellerin `fromJson`'ları TEK (güncel)
/// biçimi tanımaya devam etmeli. Her modele "bu alan v7'den önce yoktu"
/// dallanması eklemek, sürüm bilgisini onlarca dosyaya dağıtır ve birkaç
/// sürüm sonra hangi dalın hangi yedeği taşıdığı ölçülemez hale gelir.
/// Dönüşüm ayrıştırmadan ÖNCE, tek yerde çalışır.
///
/// **Zincir kuralı:** her adım TAM BİR sürüm atlar (9 → 10), kendi
/// `version` damgasını yazar ve saf olmalıdır (girdiyi değiştirmez, yeni map
/// döner). Böylece v7'lik bir yedek ileride 7→8→9→10 sırasıyla yükselir ve
/// her adım tek başına test edilebilir.
///
/// Bu dosya, kapalı test yayındayken (bkz. `CLAUDE.md`) `schemaVersion`'ın ilk
/// kez artırılmasıyla doğdu: v9 yedekleri testerların Drive'ında duruyor ve
/// sürüm kapısı sıkı eşitlik olduğu için migrasyon olmadan geri
/// yüklenemezlerdi.
library;

import 'package:cunehat/core/services/backup_summary.dart';

/// Bir sürümü bir sonrakine taşıyan saf dönüşüm.
typedef BackupMigration = Map<String, dynamic> Function(Map<String, dynamic>);

/// Zincirin başlayabileceği en eski sürüm.
///
/// v9'dan öncesi bilerek desteklenmiyor: o yedekler sürüm kapısı sıkı eşitken
/// zaten reddediliyordu, yani sahada geri yüklenebilir tek bir örneği yok.
/// Yazılmayan dönüşümün test edilebilir vakası da olmazdı.
const int oldestSupportedBackupVersion = 9;

/// `sürüm → o sürümü bir sonrakine taşıyan adım`.
const Map<int, BackupMigration> backupMigrations = {
  9: _v9ToV10,
  10: _v10ToV11,
  11: _v11ToV12,
  12: _v12ToV13,
  13: _v13ToV14,
  14: _v14ToV15,
  15: _v15ToV16,
  16: _v16ToV17,
};

/// [raw]'ı [targetVersion]'a yükseltir.
///
/// Zaten hedef sürümdeyse OLDUĞU GİBİ döner. Sürüm okunamıyorsa, hedeften
/// yeniyse, desteklenen en eskiden eskiyse ya da zincirde bir adım eksikse
/// [BackupVersionMismatch] fırlatır — "sessizce yanlış yorumlama, gürültülü
/// hatadan kötüdür" kuralı sürüyor.
Map<String, dynamic> migrateBackup(
  Map<String, dynamic> raw, {
  required int targetVersion,
}) {
  final found = raw['version'];
  if (found is! int ||
      found > targetVersion ||
      found < oldestSupportedBackupVersion) {
    throw BackupVersionMismatch(found, targetVersion);
  }

  var current = raw;
  for (var v = found; v < targetVersion; v++) {
    final step = backupMigrations[v];
    if (step == null) throw BackupVersionMismatch(found, targetVersion);
    current = step(current);
  }
  return current;
}

/// v9 → v10: cüzdanlara `categoryIds` (bu cüzdanda görünür kategoriler).
///
/// v9'da kategoriler küresel ve cüzdandan bağımsızdı; her cüzdan hepsini
/// görüyordu. `null` tam olarak bunu ifade eder ("kürasyon yapılmamış"), bu
/// yüzden eski yedekten dönen cüzdanlar bugünkü davranışlarını sürdürür —
/// kimse kategori kaybetmez.
///
/// Alan AÇIKÇA yazılıyor (yokluğu da `null` okunurdu): dönüşümün ne yaptığı
/// veriye bakınca görünsün ve testi tam olarak bunu ölçsün.
Map<String, dynamic> _v9ToV10(Map<String, dynamic> raw) {
  final wallets = (raw['wallets'] as List?) ?? const [];
  return {
    ...raw,
    'version': 10,
    'wallets': [
      for (final w in wallets)
        {...Map<String, dynamic>.from(w as Map), 'categoryIds': null},
    ],
  };
}

/// v10 → v11: işlemlere kuplaj bağı ve köken — `linkedRecordId`,
/// `adoptedFromTag`, `origin` (üçü de nullable).
///
/// v10'da bir kuplaj hareketinin sahibi hiç yazılmıyordu, benimseme kavramı
/// yoktu ve kaydın elle mi ekstreden mi geldiği saklanmıyordu. `null` tam
/// olarak bunu söyler ("bilinmiyor"): eski kuplaj hareketleri eskisi gibi
/// davranır (sahibinden yönetilir), eski düz kayıtlarda tekrar tespiti
/// başlığın yazımına bakan eski sezgiye düşer.
///
/// Alanlar AÇIKÇA yazılıyor (yokluğu da `null` okunurdu): dönüşümün ne
/// yaptığı veriye bakınca görünsün ve testi tam olarak bunu ölçsün.
Map<String, dynamic> _v10ToV11(Map<String, dynamic> raw) {
  final transactions = (raw['transactions'] as List?) ?? const [];
  return {
    ...raw,
    'version': 11,
    'transactions': [
      for (final t in transactions)
        {
          ...Map<String, dynamic>.from(t as Map),
          'linkedRecordId': null,
          'adoptedFromTag': null,
          'origin': null,
        },
    ],
  };
}

/// v11 → v12: cüzdanlara `creditCard` (kredi kartı bilgileri).
///
/// v11'de kredi kartı kavramı yoktu: her cüzdan düz cüzdandı. `null` tam
/// olarak bunu söyler; eski yedekten dönen cüzdanlar düz cüzdan kalır (elle
/// açılmış kart cüzdanları sonradan "Kredi kartına çevir" ile çevrilebilir).
///
/// Alan AÇIKÇA yazılıyor (yokluğu da `null` okunurdu): dönüşümün ne yaptığı
/// veriye bakınca görünsün ve testi tam olarak bunu ölçsün.
Map<String, dynamic> _v11ToV12(Map<String, dynamic> raw) {
  final wallets = (raw['wallets'] as List?) ?? const [];
  return {
    ...raw,
    'version': 12,
    'wallets': [
      for (final w in wallets)
        {...Map<String, dynamic>.from(w as Map), 'creditCard': null},
    ],
  };
}

/// v12 → v13: işlemlere `importBatchId` (kaydı yazan ekstre içe aktarımı).
///
/// v12'de içe aktarım partisi saklanmıyordu: bir içe aktarım ancak bitiş
/// ekranındayken geri alınabiliyordu. `null` tam olarak bunu söyler ("hangi
/// partiden geldiği bilinmiyor"); eski yedekten dönen kayıtlar "Son içe
/// aktarımlar" listesinde görünmez, başka hiçbir davranışları değişmez.
///
/// Alan AÇIKÇA yazılıyor (yokluğu da `null` okunurdu): dönüşümün ne yaptığı
/// veriye bakınca görünsün ve testi tam olarak bunu ölçsün.
Map<String, dynamic> _v12ToV13(Map<String, dynamic> raw) {
  final transactions = (raw['transactions'] as List?) ?? const [];
  return {
    ...raw,
    'version': 13,
    'transactions': [
      for (final t in transactions)
        {...Map<String, dynamic>.from(t as Map), 'importBatchId': null},
    ],
  };
}

/// v13 → v14: yatırım türüne `cash` (birikim nakit kasası) eklendi.
///
/// Veri DÖNÜŞMEZ: v13 yedeğinde bu tür yoktur, var olan kayıtlar aynen
/// okunur. Sürüm yine artırıldı, çünkü yeni türü taşıyan bir yedek eski
/// sürümde `InvestmentType` ayrıştırmasında patlardı; artık eski sürüm onu
/// `BackupVersionMismatch` ile düzgünce reddeder.
Map<String, dynamic> _v13ToV14(Map<String, dynamic> raw) => {
      ...raw,
      'version': 14,
    };

/// v14 → v15: işlemlere taksit grubu (`installmentGroupId`, `installmentNo`,
/// `installmentCount`).
///
/// v14'te kartla taksitli alışverişin aylık satırları birbirine bağlı
/// değildi ("(2/6)" yalnız başlıkta). `null` tam olarak bunu söyler: eski
/// taksitler bağsız kalır, başlıktan TAHMİN edilip bağlanmaz (kullanıcının
/// başlığı düzenlemiş olabileceği satırı yanlış gruba bağlamak, bağsız
/// bırakmaktan kötüdür).
///
/// Alanlar AÇIKÇA yazılıyor (bkz. `_v12ToV13`).
Map<String, dynamic> _v14ToV15(Map<String, dynamic> raw) {
  final transactions = (raw['transactions'] as List?) ?? const [];
  return {
    ...raw,
    'version': 15,
    'transactions': [
      for (final t in transactions)
        {
          ...Map<String, dynamic>.from(t as Map),
          'installmentGroupId': null,
          'installmentNo': null,
          'installmentCount': null,
        },
    ],
  };
}

/// v15 → v16: kredi kartına `dueOffsetDays`, `monthlyInterestRate`,
/// `lateInterestRate`; yatırımlara `isPrimary` (ana kasa).
///
/// v15'te son ödeme yalnız sabit bir takvim günüydü, kartın faiz oranı
/// saklanmıyordu ve "ana kasa" kavramı yoktu. Kart alanlarında `null`
/// ("ayarlanmamış") ve yatırımlarda `false` tam olarak bunu söyler: eski
/// yedekten dönen kart bugünkü gibi davranır, hiçbir kasa işaretli gelmez
/// (varsayılan kaynak eskisi gibi en dolu kasadır).
///
/// Kartı OLMAYAN cüzdanın `creditCard`'ı `null` kalır. Alanlar AÇIKÇA
/// yazılıyor (bkz. `_v12ToV13`).
Map<String, dynamic> _v15ToV16(Map<String, dynamic> raw) {
  final wallets = (raw['wallets'] as List?) ?? const [];
  final investments = (raw['investments'] as List?) ?? const [];
  return {
    ...raw,
    'version': 16,
    'wallets': [
      for (final w in wallets)
        () {
          final wallet = Map<String, dynamic>.from(w as Map);
          final card = wallet['creditCard'];
          if (card == null) return wallet;
          return {
            ...wallet,
            'creditCard': {
              ...Map<String, dynamic>.from(card as Map),
              'dueOffsetDays': null,
              'monthlyInterestRate': null,
              'lateInterestRate': null,
            },
          };
        }(),
    ],
    'investments': [
      for (final i in investments)
        {...Map<String, dynamic>.from(i as Map), 'isPrimary': false},
    ],
  };
}

/// v16 → v17: tek seferlik (tarih aralıklı) bütçeler — yeni `tempBudgets`
/// dizisi.
///
/// v16'da bu kavram yoktu; boş dizi tam olarak bunu söyler. Aylık bütçelere
/// (`budgets`) dokunulmaz: geçici bütçe ayrı bir kayıt, aylık bütçenin
/// "yalnız bu ay" sürümü değil. Dizi AÇIKÇA yazılıyor (bkz. `_v12ToV13`).
Map<String, dynamic> _v16ToV17(Map<String, dynamic> raw) {
  return {
    ...raw,
    'version': 17,
    'tempBudgets': const <dynamic>[],
  };
}
