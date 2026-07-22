import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/bank_import/data/balance_reconciler.dart';
import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/bank_import/data/column_mapper.dart';
import 'package:cunehat/features/bank_import/data/draft_dedup.dart';
import 'package:cunehat/features/bank_import/data/pdf_statement_parser.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/data/statement_currency_detector.dart';
import 'package:cunehat/features/bank_import/domain/column_mapping.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/bank_import/domain/statement_format.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
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
  final CategoryGuesser _guesser;
  final CategoryRepository _categoryRepo;
  final TransactionsRepository _txRepo;
  final WalletMetricsService _metrics;
  final TransactionsChangedNotifier _notifier;

  BankImportCubit(
    this._reader,
    this._mapper,
    this._pdfParser,
    this._guesser,
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

  /// Son CSV/Excel eşlemesinin bakiye-mutabakat sonucu; inceleme durumuna
  /// taşınır. PDF/başlıksız yolda `null` kalır.
  BalanceReconciliation? _reconciliation;

  /// Ekstrede sezilen baskın para birimi (₺/$/€ ya da kod). Cüzdan biriminden
  /// farklıysa inceleme ekranında uyarı gösterilir; sinyal yoksa `null`.
  String? _statementCurrency;

  /// Son `commit`te GERÇEKTEN yazılan işlem id'leri; `_Done`'daki "Geri al"
  /// bu partiyi (yalnız az önce eklenenleri) siler. Oturum-içi (Hive alanı yok).
  List<String> _lastImportedIds = const [];

  /// Dosya seç + biçimi uzantısından otomatik algıla + ayrıştır.
  /// CSV/Excel → kolon eşleme; PDF → doğrudan inceleme.
  Future<void> pickAndParse({
    required String userId,
    required String walletId,
  }) async {
    _userId = userId;
    _walletId = walletId;
    _reconciliation = null;
    _statementCurrency = null;

    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: StatementFormat.allExtensions,
    );
    final path = picked?.files.single.path;
    if (path == null) {
      emit(const BankImportInitial());
      return;
    }

    final format = StatementFormat.fromExtension(path);
    if (format == null) {
      emit(BankImportError('Desteklenmeyen dosya türü: $path'));
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
        _statementCurrency = detectDominantCurrency(result.rawText);
        if (result.drafts.isEmpty) {
          // Metin çıktı ama satır tanınamadı → ham metni tanılama için göster.
          emit(BankImportRawText(result.rawText));
          return;
        }
        await _afterParse(result.drafts, result.skippedLines);
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
      // Aynı bankadan tekrar içe aktarımda kolonları yeniden eşlemeye gerek
      // kalmasın: son onaylanan eşleme sütun sayısı uyuyorsa başlangıç olur.
      final saved = await _loadSavedMapping(table.columnCount);
      emit(BankImportMapping(
        table: table,
        mapping: saved ?? _mapper.guess(table),
      ));
    } catch (e) {
      emit(BankImportError('Dosya okunamadı: $e'));
    }
  }

  /// Başa dön (hata sonrası tekrar dene / yeni dosya). Önceki PDF denemesinin
  /// ham metnini de temizler; aksi halde sonraki CSV/Excel akışında AppBar'daki
  /// "ham metni göster" düğmesi eski PDF'e ait metni göstermeye devam eder.
  void reset() {
    _lastPdfRawText = null;
    _reconciliation = null;
    _statementCurrency = null;
    emit(const BankImportInitial());
  }

  void updateMapping(ColumnMapping mapping) {
    final s = state;
    if (s is BankImportMapping) {
      emit(BankImportMapping(table: s.table, mapping: mapping));
    }
  }

  static const _mappingPrefsKey = 'bank_import_last_mapping';

  /// Onaylanan eşlemeyi sütun sayısıyla birlikte saklar (best-effort).
  Future<void> _saveMapping(ColumnMapping m, int columnCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _mappingPrefsKey,
        jsonEncode({'columnCount': columnCount, 'mapping': m.toMap()}),
      );
    } catch (_) {
      // Kalıcılık best-effort; başarısızlık akışı bozmamalı.
    }
  }

  /// Kaydedilmiş eşlemeyi YALNIZ sütun sayısı bu tabloyla aynıysa döner (aynı
  /// banka düzeni sinyali); aksi halde `null` → otomatik tahmine düşülür.
  Future<ColumnMapping?> _loadSavedMapping(int columnCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_mappingPrefsKey);
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['columnCount'] != columnCount) return null;
      return ColumnMapping.fromMap(
          (data['mapping'] as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  /// Kolon eşlemesini uygula → varsayılan kategori ata → dedup → inceleme.
  Future<void> applyMapping() async {
    final s = state;
    if (s is! BankImportMapping) return;
    emit(const BankImportParsing());
    try {
      final result = _mapper.apply(s.table, s.mapping);
      _reconciliation = result.reconciliation;
      _statementCurrency = detectDominantCurrency(
        s.table.rows.map((r) => r.join(' ')).join('\n'),
      );
      // Kullanıcının onayladığı eşlemeyi hatırla (sonraki içe aktarım için).
      await _saveMapping(s.mapping, s.table.columnCount);
      await _afterParse(result.drafts, result.skippedRows);
    } catch (e) {
      emit(BankImportError('Eşleme uygulanamadı: $e'));
    }
  }

  /// Ayrıştırma bitti: bilinen ama kullanıcının listesinde karşılığı olmayan
  /// kategori grupları var mı bak. Varsa onay adımına dur; yoksa doğrudan
  /// incelemeye geç.
  Future<void> _afterParse(List<ImportDraft> raw, int skipped) async {
    final suggestions = _guesser.suggestNewCategories(
      drafts: raw,
      expenseCategories: _expenseCats,
      incomeCategories: _incomeCats,
    );
    if (suggestions.isEmpty) {
      await _toReview(raw, skipped);
      return;
    }
    emit(BankImportCategorySuggestion(
      suggestions: suggestions,
      rawDrafts: raw,
      skippedRows: skipped,
    ));
  }

  /// Kategori öneri adımının sonucu: [approvedNames] içindekiler yaratılır
  /// (kullanıcının o türdeki listesine eklenir), geri kalanı hiç
  /// oluşturulmaz. Ardından incelemeye geçilir (yeni yaratılanlar artık
  /// `_toReview`'daki `guess()` çağrısında bulunur).
  Future<void> resolveCategorySuggestions(Set<String> approvedNames) async {
    final s = state;
    if (s is! BankImportCategorySuggestion) return;

    for (final suggestion in s.suggestions) {
      if (!approvedNames.contains(suggestion.name)) continue;
      try {
        final category = CategoryEntity(
          id: suggestion.name,
          iconName: suggestion.iconName,
          isExpense: !suggestion.isIncome,
          sortOrder: DateTime.now().millisecondsSinceEpoch,
        );
        await _categoryRepo.addCategory(category);
        if (suggestion.isIncome) {
          _incomeCats = [..._incomeCats, category];
        } else {
          _expenseCats = [..._expenseCats, category];
        }
      } catch (_) {
        // Oluşturulamadıysa (ör. adı bu arada başka yerden eklendi) sessizce
        // atla; ilgili taslaklar yine varsayılana düşer, akış durmaz.
      }
    }

    await _toReview(s.rawDrafts, s.skippedRows);
  }

  Future<void> _toReview(List<ImportDraft> raw, int skipped) async {
    // Kullanıcının TÜM geçmişi tek sorguda çekilir: hem geçmişe dayalı kategori
    // tahmini (öğrenen) hem dedup için ortak kullanılır.
    var history = const <TransactionEntity>[];
    if (raw.isNotEmpty) {
      final res = await _txRepo.getTransactions(
        userId: _userId,
        walletId: _walletId,
      );
      res.fold((_) {}, (list) => history = list);
    }
    final historyIndex = _guesser.buildHistoryIndex(history);

    // Kategori tahmini: önce kullanıcının KENDİ geçmişinden ("bu markayı geçen
    // sefer X yapmıştım"), yoksa sabit anahtar-kelime sözlüğü. İkisi de yoksa
    // BİLEREK `null` kalır (türün ilk kategorisine düşülmez — eskiden işlemlerin
    // ~%80'i tesadüfen "Yemek" görünüp yanlış güven veriyordu). Eşleşmeyenler
    // inceleme ekranında elle seçilir (bkz. `BankImportReview.uncategorizedCount`).
    var drafts = [
      for (final d in raw)
        d.copyWith(
          categoryId: _guesser.guessFromHistory(
                description: d.description,
                isIncome: d.isIncome,
                index: historyIndex,
                candidates: d.isIncome ? _incomeCats : _expenseCats,
              ) ??
              _guesser.guess(
                description: d.description,
                isIncome: d.isIncome,
                candidates: d.isIncome ? _incomeCats : _expenseCats,
              ),
        ),
    ];

    if (drafts.isNotEmpty) {
      drafts = markDuplicateDrafts(drafts, history);
    }

    // Ekstre belirgin bir para birimi taşıyor ve bu hedef cüzdanınkinden
    // farklıysa uyar (ör. USD ekstresi TRY cüzdana). Yalnız sinyal varken oku.
    String? foreignCurrency;
    String? walletCurrency;
    if (_statementCurrency != null) {
      final wRes = await _metrics.walletRepository.getWalletById(_walletId);
      walletCurrency = wRes.fold((_) => null, (w) => w?.currency);
      if (walletCurrency != null && _statementCurrency != walletCurrency) {
        foreignCurrency = _statementCurrency;
      }
    }

    emit(BankImportReview(
      drafts: drafts,
      expenseCategories: _expenseCats,
      incomeCategories: _incomeCats,
      skippedRows: skipped,
      reconciliation: _reconciliation,
      foreignCurrency: foreignCurrency,
      walletCurrency: walletCurrency,
    ));
  }

  // --- inceleme mutasyonları ---

  void toggleDraft(int i) => _mutate(
        (d) => [
          for (var k = 0; k < d.length; k++)
            k == i ? d[k].copyWith(selected: !d[k].selected) : d[k]
        ],
      );

  void setDraftCategory(int i, String categoryId) => _mutate(
        (d) => [
          for (var k = 0; k < d.length; k++)
            k == i ? d[k].copyWith(categoryId: categoryId) : d[k]
        ],
      );

  void setDraftAmount(int i, double amount) => _mutate(
        (d) => [
          for (var k = 0; k < d.length; k++)
            k == i ? d[k].copyWith(amount: amount) : d[k]
        ],
      );

  void setDraftDescription(int i, String description) => _mutate(
        (d) => [
          for (var k = 0; k < d.length; k++)
            k == i ? d[k].copyWith(description: description) : d[k]
        ],
      );

  void setDraftType(int i, TransactionTypeModel type) => _mutate((d) {
        final defExp = _expenseCats.isNotEmpty ? _expenseCats.first.id : null;
        final defInc = _incomeCats.isNotEmpty ? _incomeCats.first.id : null;
        return [
          for (var k = 0; k < d.length; k++)
            if (k == i)
              d[k].copyWith(
                type: type,
                categoryId:
                    type == TransactionTypeModel.income ? defInc : defExp,
              )
            else
              d[k],
        ];
      });

  void setAllSelected(bool value) =>
      _mutate((d) => [for (final x in d) x.copyWith(selected: value)]);

  /// Tüm taslakları tek türe (gider/gelir) çevirir. Tek pozitif "Tutar"
  /// sütunlu (işaretsiz) ekstrelerde tüm satırlar yanlışlıkla aynı yöne
  /// (ör. hep gelir) düşerse kullanıcı tek dokunuşla düzeltebilsin diye.
  /// Kategori, `setDraftType` ile aynı biçimde yeni türün varsayılanına çekilir.
  void setAllType(TransactionTypeModel type) => _mutate((d) {
        final defExp = _expenseCats.isNotEmpty ? _expenseCats.first.id : null;
        final defInc = _incomeCats.isNotEmpty ? _incomeCats.first.id : null;
        return [
          for (final x in d)
            x.copyWith(
              type: type,
              categoryId: type == TransactionTypeModel.income ? defInc : defExp,
            ),
        ];
      });

  void setDraftSelected(int i, bool value) => _mutate(
        (d) => [
          for (var k = 0; k < d.length; k++)
            k == i ? d[k].copyWith(selected: value) : d[k]
        ],
      );

  /// Bir türdeki (gider/gelir) tüm taslaklara toplu kategori uygular.
  void applyBatchCategory(
          {required bool forExpense, required String categoryId}) =>
      _mutate((d) => [
            for (final x in d)
              if (x.isIncome != forExpense)
                x.copyWith(categoryId: categoryId)
              else
                x,
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
      emit(await _buildDone(
          added: 0, totalDrafts: s.drafts.length, committed: const []));
      return;
    }

    emit(BankImportCommitting(done: 0, total: selected.length));
    var added = 0;
    final importedIds = <String>[];
    for (var i = 0; i < selected.length; i++) {
      final id = UidGenerator.generateV7();
      final entity = selected[i].toEntity(
        id: id,
        userId: _userId,
        walletId: _walletId,
      );
      final res = await _txRepo.addTransaction(entity);
      res.fold((_) {}, (_) {
        added++;
        importedIds.add(id);
      });
      if (i % 10 == 0 || i == selected.length - 1) {
        emit(BankImportCommitting(done: i + 1, total: selected.length));
      }
    }
    _lastImportedIds = importedIds;

    await _metrics.syncBalance(_walletId);
    _notifier.notify(userId: _userId, walletId: _walletId);

    emit(await _buildDone(
      added: added,
      totalDrafts: s.drafts.length,
      committed: selected,
    ));
  }

  /// `_Done`'daki "Geri al": son içe aktarımda yazılan işlemleri (yalnız o
  /// partiyi) siler, bakiyeyi yeniden hesaplar, dinleyicileri bilgilendirir ve
  /// başa döner. İkinci çağrı no-op (id listesi boşalır). Oturum kapanınca
  /// (yeni dosya/`reset`) geri alma imkânı da doğal olarak biter.
  Future<void> undoImport() async {
    final ids = _lastImportedIds;
    if (ids.isEmpty) return;
    _lastImportedIds = const [];
    for (final id in ids) {
      await _txRepo.deleteTransaction(id);
    }
    await _metrics.syncBalance(_walletId);
    _notifier.notify(userId: _userId, walletId: _walletId);
    emit(const BankImportInitial());
  }

  /// Test tohumu: cubit'i doğrudan inceleme durumuna sokar (normalde dosya
  /// seçici + ayrıştırma gerektirir). `commit` gibi sonraki adımların testi için.
  @visibleForTesting
  void debugSeedReview({
    required String userId,
    required String walletId,
    required List<ImportDraft> drafts,
    List<CategoryEntity> expenseCategories = const [],
    List<CategoryEntity> incomeCategories = const [],
  }) {
    _userId = userId;
    _walletId = walletId;
    _expenseCats = expenseCategories;
    _incomeCats = incomeCategories;
    emit(BankImportReview(
      drafts: drafts,
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
      skippedRows: 0,
    ));
  }

  /// Bitiş durumunu kurar. Bakiyeyi `syncBalance` sonrası defterden TAZE okur
  /// (UI'nin WalletBloc'un ~150ms gecikmeli box-watch akışını beklemeden gerçek
  /// bakiyeyi göstermesi için) ve eklenen hareketlerin bir kısmı mevcut ay
  /// dışındaysa (liste varsayılanı mevcut ay) bayrağı ile bildirir.
  Future<BankImportDone> _buildDone({
    required int added,
    required int totalDrafts,
    required List<ImportDraft> committed,
  }) async {
    final walletRes = await _metrics.walletRepository.getWalletById(_walletId);
    final balance = walletRes.fold((_) => 0.0, (w) => w?.balance ?? 0.0);

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final hasOutOfMonthRows = committed.any(
      (d) => d.date.isBefore(monthStart) || d.date.isAfter(monthEnd),
    );

    return BankImportDone(
      added: added,
      skipped: totalDrafts - added,
      walletId: _walletId,
      userId: _userId,
      balance: balance,
      hasPastMonthRows: hasOutOfMonthRows,
    );
  }
}
