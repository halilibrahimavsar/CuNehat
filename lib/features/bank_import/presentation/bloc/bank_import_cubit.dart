import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/bank_import/data/column_mapper.dart';
import 'package:cunehat/features/bank_import/data/draft_dedup.dart';
import 'package:cunehat/features/bank_import/data/pdf_statement_parser.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/domain/column_mapping.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/bank_import/domain/statement_format.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';

/// Banka ekstresi içe aktarma akışının durum makinesi.
///
/// pickAndParse → (CSV/Excel) kolon eşleme → applyMapping → dedup → inceleme →
/// commit (mevcut cüzdana toplu yazım: tek syncBalance + tek notify).
@injectable
class BankImportCubit extends Cubit<BankImportState> {
  final RawTableReader _reader;
  final ColumnMapper _mapper;
  final PdfStatementParser _pdfParser;
  final CategoryRepository _categoryRepo;
  final TransactionsRepository _txRepo;
  final WalletMetricsService _metrics;
  final TransactionsChangedNotifier _notifier;

  BankImportCubit(
    this._reader,
    this._mapper,
    this._pdfParser,
    this._categoryRepo,
    this._txRepo,
    this._metrics,
    this._notifier,
  ) : super(const BankImportInitial());

  String _userId = '';
  String _walletId = '';
  List<CategoryEntity> _expenseCats = const [];
  List<CategoryEntity> _incomeCats = const [];

  /// Son PDF içe aktarımının çıkarılan ham metni (tanılama/paylaşım için).
  String? _lastPdfRawText;
  String? get lastPdfRawText => _lastPdfRawText;

  /// Dosya seç + ayrıştır. CSV/Excel → kolon eşleme; PDF → doğrudan inceleme.
  Future<void> pickAndParse({
    required String userId,
    required String walletId,
    required StatementFormat format,
  }) async {
    _userId = userId;
    _walletId = walletId;

    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: format.extensions,
    );
    final path = picked?.files.single.path;
    if (path == null) {
      emit(const BankImportInitial());
      return;
    }

    emit(const BankImportParsing());
    try {
      _expenseCats = await _categoryRepo.getExpenseCategories();
      _incomeCats = await _categoryRepo.getIncomeCategories();

      // PDF'te kolon yapısı güvenilir değil → satır-sezgisel doğrudan taslak,
      // eşleme adımı atlanır, direkt incelemeye gider.
      if (format == StatementFormat.pdf) {
        final result = await _pdfParser.parse(path);
        _lastPdfRawText = result.rawText;
        if (result.drafts.isEmpty) {
          // Metin çıktı ama satır tanınamadı → ham metni tanılama için göster.
          emit(BankImportRawText(result.rawText));
          return;
        }
        await _toReview(result.drafts, result.skippedLines);
        return;
      }

      final table = switch (format) {
        StatementFormat.csv => await _reader.readCsv(path),
        StatementFormat.excel => await _reader.readExcel(path),
        StatementFormat.pdf => throw StateError('unreachable'),
      };
      if (table.isEmpty) {
        emit(const BankImportError('Dosya boş veya okunamadı.'));
        return;
      }
      emit(BankImportMapping(table: table, mapping: _mapper.guess(table)));
    } catch (e) {
      emit(BankImportError('Dosya okunamadı: $e'));
    }
  }

  /// Başa dön (hata sonrası tekrar dene / yeni dosya). Önceki PDF denemesinin
  /// ham metnini de temizler; aksi halde sonraki CSV/Excel akışında AppBar'daki
  /// "ham metni göster" düğmesi eski PDF'e ait metni göstermeye devam eder.
  void reset() {
    _lastPdfRawText = null;
    emit(const BankImportInitial());
  }

  void updateMapping(ColumnMapping mapping) {
    final s = state;
    if (s is BankImportMapping) {
      emit(BankImportMapping(table: s.table, mapping: mapping));
    }
  }

  /// Kolon eşlemesini uygula → varsayılan kategori ata → dedup → inceleme.
  Future<void> applyMapping() async {
    final s = state;
    if (s is! BankImportMapping) return;
    emit(const BankImportParsing());
    try {
      final result = _mapper.apply(s.table, s.mapping);
      await _toReview(result.drafts, result.skippedRows);
    } catch (e) {
      emit(BankImportError('Eşleme uygulanamadı: $e'));
    }
  }

  Future<void> _toReview(List<ImportDraft> raw, int skipped) async {
    final defExp = _expenseCats.isNotEmpty ? _expenseCats.first.id : null;
    final defInc = _incomeCats.isNotEmpty ? _incomeCats.first.id : null;

    var drafts = [
      for (final d in raw)
        d.copyWith(categoryId: d.isIncome ? defInc : defExp),
    ];

    if (drafts.isNotEmpty) {
      final dates = drafts.map((d) => d.date).toList()..sort();
      final existing = await _txRepo.getTransactions(
        userId: _userId,
        walletId: _walletId,
        startDate: dates.first,
        endDate: dates.last,
      );
      existing.fold(
        (_) {}, // sorgu hatası: dedup atlanır, hepsi seçili gelir
        (list) => drafts = markDuplicateDrafts(drafts, list),
      );
    }

    emit(BankImportReview(
      drafts: drafts,
      expenseCategories: _expenseCats,
      incomeCategories: _incomeCats,
      skippedRows: skipped,
    ));
  }

  // --- inceleme mutasyonları ---

  void toggleDraft(int i) => _mutate(
        (d) => [for (var k = 0; k < d.length; k++) k == i ? d[k].copyWith(selected: !d[k].selected) : d[k]],
      );

  void setDraftCategory(int i, String categoryId) => _mutate(
        (d) => [for (var k = 0; k < d.length; k++) k == i ? d[k].copyWith(categoryId: categoryId) : d[k]],
      );

  void setDraftAmount(int i, double amount) => _mutate(
        (d) => [for (var k = 0; k < d.length; k++) k == i ? d[k].copyWith(amount: amount) : d[k]],
      );

  void setDraftDescription(int i, String description) => _mutate(
        (d) => [for (var k = 0; k < d.length; k++) k == i ? d[k].copyWith(description: description) : d[k]],
      );

  void setDraftType(int i, TransactionTypeModel type) => _mutate((d) {
        final defExp = _expenseCats.isNotEmpty ? _expenseCats.first.id : null;
        final defInc = _incomeCats.isNotEmpty ? _incomeCats.first.id : null;
        return [
          for (var k = 0; k < d.length; k++)
            if (k == i)
              d[k].copyWith(
                type: type,
                categoryId: type == TransactionTypeModel.income ? defInc : defExp,
              )
            else
              d[k],
        ];
      });

  void setAllSelected(bool value) =>
      _mutate((d) => [for (final x in d) x.copyWith(selected: value)]);

  void setDraftSelected(int i, bool value) => _mutate(
        (d) => [for (var k = 0; k < d.length; k++) k == i ? d[k].copyWith(selected: value) : d[k]],
      );

  /// Bir türdeki (gider/gelir) tüm taslaklara toplu kategori uygular.
  void applyBatchCategory({required bool forExpense, required String categoryId}) =>
      _mutate((d) => [
            for (final x in d)
              if (x.isIncome != forExpense) x.copyWith(categoryId: categoryId) else x,
          ]);

  void _mutate(List<ImportDraft> Function(List<ImportDraft>) f) {
    final s = state;
    if (s is BankImportReview) emit(s.copyWith(drafts: f(s.drafts)));
  }

  /// Seçili taslakları mevcut cüzdana yazar. Para zinciri: döngü sonunda TEK
  /// syncBalance + TEK notify (O(N²) ve bildirim fırtınası önlenir).
  Future<void> commit() async {
    final s = state;
    if (s is! BankImportReview) return;
    final selected = s.drafts.where((d) => d.selected).toList();
    if (selected.isEmpty) {
      emit(const BankImportDone(added: 0, skipped: 0));
      return;
    }

    emit(BankImportCommitting(done: 0, total: selected.length));
    var added = 0;
    for (var i = 0; i < selected.length; i++) {
      final entity = selected[i].toEntity(
        id: UidGenerator.generateV7(),
        userId: _userId,
        walletId: _walletId,
      );
      final res = await _txRepo.addTransaction(entity);
      res.fold((_) {}, (_) => added++);
      if (i % 10 == 0 || i == selected.length - 1) {
        emit(BankImportCommitting(done: i + 1, total: selected.length));
      }
    }

    await _metrics.syncBalance(_walletId);
    _notifier.notify(userId: _userId, walletId: _walletId);

    emit(BankImportDone(added: added, skipped: s.drafts.length - added));
  }
}
