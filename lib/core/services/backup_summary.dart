import 'package:flutter/foundation.dart';

/// Bir yedeğin — ya da cihazdaki mevcut verinin — HİÇBİR ŞEY YAZMADAN
/// çıkarılmış özeti.
///
/// Varlık sebebi: `drive.appdata` yedeği kullanıcıdan gizler (Drive arayüzünde
/// görünmez), yani geri yüklemeden önce içinde ne olduğuna bakmanın başka yolu
/// yok. Tek yol "üzerine geri yükle ve gör" idi, ki o da yıkıcı. Bu özet
/// önizleme ekranını ve otomatik yedeğin "boş veriyle ezme" kapısını besler.
@immutable
class BackupWalletSummary {
  final String name;
  final String currency;
  final double balance;

  const BackupWalletSummary({
    required this.name,
    required this.currency,
    required this.balance,
  });
}

@immutable
class BackupSummary {
  /// Yedeğin şema sürümü. Cihaz özetinde her zaman geçerli sürümdür.
  final int schemaVersion;

  /// Yedeğin alındığı an (`timestamp` alanı). Cihaz özetinde null.
  final DateTime? createdAt;

  final int walletCount;
  final int transactionCount;
  final int investmentCount;
  final int debtCount;
  final int receivableCount;
  final int budgetCount;
  final int recurringCount;

  /// Yedekteki kategori SAYISI. (v7 öncesi burada dolu SharedPreferences
  /// anahtarlarının sayısı — en fazla 4 — duruyordu; kullanıcıya hiçbir
  /// şey söylemeyen bir sayıydı.)
  final int categoryCount;

  final List<BackupWalletSummary> wallets;

  final DateTime? firstTransactionDate;
  final DateTime? lastTransactionDate;

  final double totalIncome;
  final double totalExpense;

  /// Fiş görseli iliştirilmiş işlem sayısı. Görsel binary'si yedeğe GİRMEZ
  /// (yalnız dosya adı taşınır), bu yüzden başka bir cihaza geri yüklemede
  /// bu kadar işlemin eki bulunamayacak — önizleme bunu açıkça uyarır.
  final int transactionsWithReceipt;

  const BackupSummary({
    required this.schemaVersion,
    required this.createdAt,
    required this.walletCount,
    required this.transactionCount,
    required this.investmentCount,
    required this.debtCount,
    required this.receivableCount,
    required this.budgetCount,
    required this.recurringCount,
    required this.categoryCount,
    required this.wallets,
    required this.firstTransactionDate,
    required this.lastTransactionDate,
    required this.totalIncome,
    required this.totalExpense,
    required this.transactionsWithReceipt,
  });

  /// Kategori tercihleri sayılmaz: onlar varsayılanların üzerine yazılan
  /// tercihler, "kayıt" değil. Boşluk kararı defter kayıtlarına bakar.
  int get recordCount =>
      walletCount +
      transactionCount +
      investmentCount +
      debtCount +
      receivableCount +
      budgetCount +
      recurringCount;

  bool get isEmpty => recordCount == 0;
}

enum BackupInspectionStatus {
  ok,

  /// Şema sürümü bu sürümle eşleşmiyor → geri yüklenemez. Ayrı bir durum
  /// olması şart: kullanıcıya "yedek bozuk" demek yalan olurdu.
  versionMismatch,

  /// JSON parse edilemedi / beklenen alanlar yok (yarım yükleme, 0 baytlı
  /// dosya, elle düzenlenmiş dosya).
  corrupt,
}

@immutable
class BackupInspection {
  final BackupInspectionStatus status;
  final BackupSummary? summary;

  /// `versionMismatch` durumunda dosyadan okunan sürüm (bir int olmayabilir).
  final Object? foundVersion;
  final int expectedVersion;
  final Object? error;

  const BackupInspection._({
    required this.status,
    required this.expectedVersion,
    this.summary,
    this.foundVersion,
    this.error,
  });

  const BackupInspection.ok(BackupSummary summary, int expectedVersion)
      : this._(
          status: BackupInspectionStatus.ok,
          expectedVersion: expectedVersion,
          summary: summary,
        );

  const BackupInspection.versionMismatch(
    Object? foundVersion,
    int expectedVersion,
  ) : this._(
          status: BackupInspectionStatus.versionMismatch,
          expectedVersion: expectedVersion,
          foundVersion: foundVersion,
        );

  const BackupInspection.corrupt(Object? error, int expectedVersion)
      : this._(
          status: BackupInspectionStatus.corrupt,
          expectedVersion: expectedVersion,
          error: error,
        );

  bool get isRestorable => status == BackupInspectionStatus.ok;
}

/// Şema sürümü kapısının fırlattığı tip. `FormatException` ile aynı yerden
/// yakalanırsa "bozuk dosya" ile karışır; sürüm uyuşmazlığı ayrı bir olgudur
/// (dosya sapasağlam, sadece bu sürüm onu okumuyor).
class BackupVersionMismatch implements Exception {
  final Object? found;
  final int expected;

  const BackupVersionMismatch(this.found, this.expected);

  @override
  String toString() =>
      'BackupVersionMismatch(found: $found, expected: $expected)';
}
