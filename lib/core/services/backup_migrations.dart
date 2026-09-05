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
