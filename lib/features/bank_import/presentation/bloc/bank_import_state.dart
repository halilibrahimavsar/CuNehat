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

/// Taslaklar hazır: inceleme (liste ya da stepper) + toplu ekleme.
class BankImportReview extends BankImportState {
  final List<ImportDraft> drafts;
  final List<CategoryEntity> expenseCategories;
  final List<CategoryEntity> incomeCategories;
  final int skippedRows;

  const BankImportReview({
    required this.drafts,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.skippedRows,
  });

  int get selectedCount => drafts.where((d) => d.selected).length;
  int get duplicateCount => drafts.where((d) => d.isDuplicate).length;

  BankImportReview copyWith({List<ImportDraft>? drafts}) => BankImportReview(
        drafts: drafts ?? this.drafts,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
        skippedRows: skippedRows,
      );
}

/// Toplu yazım ilerlemesi.
class BankImportCommitting extends BankImportState {
  final int done;
  final int total;
  const BankImportCommitting({required this.done, required this.total});
}

/// Bitti: eklenen + atlanan (seçilmeyen) sayıları.
class BankImportDone extends BankImportState {
  final int added;
  final int skipped;
  const BankImportDone({required this.added, required this.skipped});
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
