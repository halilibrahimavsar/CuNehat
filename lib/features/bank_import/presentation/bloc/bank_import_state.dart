import 'package:cunehat/features/bank_import/data/balance_reconciler.dart';
import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/domain/column_mapping.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';

/// Banka ekstresi içe aktarma akış durumları. Bilerek Equatable DEĞİL: inceleme
/// mutasyonlarında her yeni örnek yeniden çizim tetiklemeli.
sealed class BankImportState {
  const BankImportState();
}

/// Başlangıç: hedef cüzdan + format seçimi + dosya seç.
class BankImportInitial extends BankImportState {
  const BankImportInitial();
}

/// Dosya okunuyor/ayrıştırılıyor.
class BankImportParsing extends BankImportState {
  const BankImportParsing();
}

/// CSV/Excel: kolon eşleme adımı (kullanıcı sütun→alan eşlemesini onaylar).
class BankImportMapping extends BankImportState {
  final RawTable table;
  final ColumnMapping mapping;
  const BankImportMapping({required this.table, required this.mapping});
}

/// Ayrıştırılan taslaklarda bilinen ama kullanıcının o türdeki kategori
/// listesinde karşılığı olmayan gruplar bulundu: incelemeden ÖNCE kullanıcıya
/// onaylatılır. Onaylanmayanlar oluşturulmaz; ilgili taslaklar yine mevcut
/// varsayılana (türün ilk kategorisi) düşer — bu adım tamamen isteğe bağlıdır.
class BankImportCategorySuggestion extends BankImportState {
  final List<CategorySuggestion> suggestions;
  final List<ImportDraft> rawDrafts;
  final int skippedRows;
  const BankImportCategorySuggestion({
    required this.suggestions,
    required this.rawDrafts,
    required this.skippedRows,
  });
}

/// Taslaklar hazır: inceleme (liste ya da stepper) + toplu ekleme.
class BankImportReview extends BankImportState {
  final List<ImportDraft> drafts;
  final List<CategoryEntity> expenseCategories;
  final List<CategoryEntity> incomeCategories;
  final int skippedRows;

  /// Bakiye sütunuyla mutabakat sonucu (CSV/Excel yolunda). PDF/başlıksız
  /// yolda `null`. `matched` → işaretler bakiyeden türetildi (güven yüksek);
  /// `mismatch` → bakiye var ama tutmadı, kullanıcı kontrol etmeli.
  final BalanceReconciliation? reconciliation;

  /// Ekstrede sezilen para birimi hedef cüzdanınkinden farklıysa dolu gelir
  /// (uyarı için); aksi halde `null`. [walletCurrency] mesajda göstermek için.
  final String? foreignCurrency;
  final String? walletCurrency;

  const BankImportReview({
    required this.drafts,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.skippedRows,
    this.reconciliation,
    this.foreignCurrency,
    this.walletCurrency,
  });

  int get selectedCount => drafts.where((d) => d.selected).length;
  int get duplicateCount => drafts.where((d) => d.isDuplicate).length;

  /// Kategori tahmin edilemediği için boş kalan (kullanıcının elle
  /// seçmesi gereken) taslak sayısı — bkz. `CategoryGuesser.guess`: yanlış
  /// bir varsayılana (ör. hep ilk kategoriye) sessizce düşmek yerine
  /// tahmin yoksa `categoryId` bilerek `null` bırakılır.
  int get uncategorizedCount =>
      drafts.where((d) => d.categoryId == null).length;

  BankImportReview copyWith({List<ImportDraft>? drafts}) => BankImportReview(
        drafts: drafts ?? this.drafts,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
        skippedRows: skippedRows,
        reconciliation: reconciliation,
        foreignCurrency: foreignCurrency,
        walletCurrency: walletCurrency,
      );
}

/// Toplu yazım ilerlemesi.
class BankImportCommitting extends BankImportState {
  final int done;
  final int total;
  const BankImportCommitting({required this.done, required this.total});
}

/// Bitti: eklenen + atlanan (seçilmeyen) sayıları. [walletId]/[userId], hedef
/// cüzdanı bulmak/aktif yapmak için. [balance], `syncBalance` sonrası defterden
/// TAZE okunan bakiye — UI'nin box-watch debounce'una (WalletBloc'un ~150ms
/// gecikmeli akışına) bağımlı kalıp anlık bayat bakiye göstermemesi için
/// durumda taşınır. [hasPastMonthRows], eklenen hareketlerin bir kısmı içinde
/// bulunulan ay dışında (liste varsayılanı mevcut ay) → kullanıcıyı uyar.
class BankImportDone extends BankImportState {
  final int added;
  final int skipped;
  final String walletId;
  final String userId;
  final double balance;
  final bool hasPastMonthRows;
  const BankImportDone({
    required this.added,
    required this.skipped,
    required this.walletId,
    required this.userId,
    required this.balance,
    required this.hasPastMonthRows,
  });
}

class BankImportError extends BankImportState {
  final String message;
  const BankImportError(this.message);
}

/// PDF metni çıkarıldı ama hareket satırı tanınamadı: ham metin tanılama için
/// gösterilir (kullanıcı paylaşınca ayrıştırıcı o düzene uyarlanabilir).
class BankImportRawText extends BankImportState {
  final String rawText;
  const BankImportRawText(this.rawText);
}
