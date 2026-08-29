import 'package:cunehat/core/utils/money_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/text_search.dart';
import 'package:cunehat/features/bank_import/data/balance_reconciler.dart';
import 'package:cunehat/features/bank_import/data/description_grouper.dart';
import 'package:cunehat/features/bank_import/data/statement_verification.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/bank_import/presentation/import_category_labels.dart';
import 'package:cunehat/features/bank_import/presentation/widgets/similar_group_sheet.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_picker_sheet.dart';

/// İnceleme listesinde hangi taslakların gösterileceği.
enum _ReviewFilter { all, uncategorized, duplicates }

/// Kategori seçiminin sonucu: seçilen kategori + hangi türe ait olduğu. Toplu
/// atamada tür de gerekir; kategori yalnız KENDİ türündeki satırlara uygulanır
/// (gider kategorisi gelir satırına yazılamaz).
typedef _PickedCategory = ({String id, bool isExpense});

/// Taslakları inceleme: liste (varsayılan) + tek-tek stepper. Toplu ekleme.
///
/// Liste 80+ satıra kadar çıkabildiği için (gerçek bir Garanti ekstresinde 85)
/// arama + filtre şart: "kategorisiz" olanlara doğrudan gitmek, tekrarları
/// gözden geçirmek elle kaydırmadan mümkün olmalı. Aynı nedenle tam ekran
/// kipi var: özet/uyarı kartı ve AppBar gizlenince ekrana ~4 satır daha sığar.
class BankImportReviewView extends StatefulWidget {
  final BankImportReview state;

  /// Tam ekran (yalnız liste) kipi. Durum sayfada tutulur, çünkü AppBar'ı
  /// gizleyen `Scaffold` orada.
  final bool fullscreen;
  final VoidCallback onToggleFullscreen;

  const BankImportReviewView({
    super.key,
    required this.state,
    required this.onToggleFullscreen,
    this.fullscreen = false,
  });

  @override
  State<BankImportReviewView> createState() => _BankImportReviewViewState();
}

class _BankImportReviewViewState extends State<BankImportReviewView> {
  bool _stepper = false;
  int _step = 0;
  _ReviewFilter _filter = _ReviewFilter.all;
  String _query = '';
  final _searchController = TextEditingController();

  BankImportCubit get _cubit => context.read<BankImportCubit>();
  BankImportReview get _s => widget.state;

  String get _currency => _s.walletCurrency ?? kDefaultCurrency;
  String _money(double v) => formatMoney(v, currency: _currency);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Seçili filtrenin karşılığı kalmadıysa (ör. kullanıcı son kategorisiz
  /// satırı da kategorize etti) sessizce "tümü"ne döner; aksi halde ekran
  /// boşalır ve kullanıcı neden hiçbir şey göremediğini anlamaz.
  _ReviewFilter get _effectiveFilter => switch (_filter) {
        _ReviewFilter.uncategorized when _s.uncategorizedCount == 0 =>
          _ReviewFilter.all,
        _ReviewFilter.duplicates when _s.duplicateCount == 0 =>
          _ReviewFilter.all,
        _ => _filter,
      };

  /// Görünür taslaklar; cubit mutasyonları İNDEKS tabanlı olduğu için gerçek
  /// (filtrelenmemiş) indeks satırla birlikte taşınır — aksi halde filtreliyken
  /// yapılan her düzenleme başka bir satıra uygulanırdı.
  ///
  /// Arama `toLowerCase()` DEĞİL [matchesFolded] ile yapılır: Dart noktasız
  /// `I`'yı `i`'ye çevirir, `ı`'ya değil. Ekstre açıklamaları BÜYÜK HARF
  /// olduğu için "IŞIK ELEKTRİK" satırı `işik...` diye küçülüyor ve
  /// kullanıcının doğal yazımı olan "ışık" onu hiç bulamıyordu.
  List<(int, ImportDraft)> get _visible {
    final q = _query;
    final filter = _effectiveFilter;
    final out = <(int, ImportDraft)>[];
    for (var i = 0; i < _s.drafts.length; i++) {
      final d = _s.drafts[i];
      final passesFilter = switch (filter) {
        _ReviewFilter.all => true,
        _ReviewFilter.uncategorized => d.categoryId == null,
        _ReviewFilter.duplicates => d.isDuplicate,
      };
      if (!passesFilter) continue;
      if (!matchesFolded(d.description, q)) continue;
      out.add((i, d));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (_s.drafts.isEmpty) {
      return Center(child: Text(context.l10n.bankImportNoRows));
    }
    final body = _stepper ? _buildStepper(context) : _buildList(context);
    return PopScope(
      // Tam ekranda geri hareketi önce KİPTEN çıkar: AppBar gizli olduğu için
      // ekranda başka çıkış yolu yok ve kullanıcı istemeden akıştan düşerdi.
      canPop: !widget.fullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onToggleFullscreen();
      },
      // AppBar gizliyken üst çentik/durum çubuğu alanını Scaffold tüketmez.
      child: widget.fullscreen ? SafeArea(bottom: false, child: body) : body,
    );
  }

  List<CategoryEntity> _catsFor(bool income) =>
      income ? _s.incomeCategories : _s.expenseCategories;

  ({List<CategoryEntity> expense, List<CategoryEntity> income})? _labelKey;
  Map<String, String> _labelCache = const {};

  /// `id → gösterilecek kategori adı`; alt kategori adı tür içinde tekil
  /// değilse ana kategorisiyle birlikte ("Fatura › Su"). Bkz.
  /// [buildImportCategoryLabels].
  ///
  /// Liste kimliğine göre önbelleklenir: kategoriler yalnız inceleme sırasında
  /// yeni kategori kurulunca değişiyor, her satır için yeniden kurmak 85
  /// satırlık bir ekstrede her karede boşuna iş demek.
  Map<String, String> get _categoryLabels {
    if (_labelKey?.expense != _s.expenseCategories ||
        _labelKey?.income != _s.incomeCategories) {
      _labelKey = (expense: _s.expenseCategories, income: _s.incomeCategories);
      _labelCache = {
        ...buildImportCategoryLabels(_s.expenseCategories),
        ...buildImportCategoryLabels(_s.incomeCategories),
      };
    }
    return _labelCache;
  }

  CategoryEntity? _categoryById(List<CategoryEntity> cats, String? id) {
    if (id == null) return null;
    for (final c in cats) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ---------------------------------------------------------------- List mode

  Widget _buildList(BuildContext context) {
    final visible = _visible;
    return Column(
      children: [
        if (!widget.fullscreen) _statusCard(context),
        _toolbar(context),
        Expanded(
          child: visible.isEmpty
              ? Center(child: Text(context.l10n.bankImportNoMatch))
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, k) {
                    final (index, draft) = visible[k];
                    return _row(context, index, draft);
                  },
                ),
        ),
        _bottomBar(context),
      ],
    );
  }

  // ------------------------------------------------------------- Status card

  /// Özet + uyarılar TEK kartta. Eskiden üst üste üç tam genişlik şerit
  /// (genel uyarı, mutabakat, para birimi) vardı ve listeye yer kalmıyordu;
  /// olumlu bilgi (bakiye doğrulandı) artık çip olarak, uyarılar tek blokta.
  ///
  /// Tam ekran kipinde listeden çıkar ama KAYBOLMAZ: taşma menüsünden aynı
  /// kart bir sayfa olarak açılır (bkz. [_showSummarySheet]).
  Widget _statusCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final warnings = _warnings(context);

    return Container(
      width: double.infinity,
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _stat(context, '${_s.drafts.length}',
                  context.l10n.bankImportStatRows, cs.primary),
              if (_s.duplicateCount > 0)
                _stat(context, '${_s.duplicateCount}',
                    context.l10n.bankImportStatDuplicates, AppGradients.debt),
              if (_s.uncategorizedCount > 0)
                _stat(context, '${_s.uncategorizedCount}',
                    context.l10n.bankImportStatUncategorized, cs.error),
              if (_s.skippedRows > 0)
                _stat(context, '${_s.skippedRows}',
                    context.l10n.bankImportStatSkipped, cs.onSurfaceVariant),
              if (_s.verification.status ==
                      StatementVerificationStatus.unavailable &&
                  _s.reconciliation?.status == ReconcileStatus.matched)
                _chip(context, Icons.verified_rounded,
                    context.l10n.bankImportRoleBalance, Colors.green),
            ],
          ),
          if (_s.verification.status !=
              StatementVerificationStatus.unavailable) ...[
            const SizedBox(height: 10),
            _verificationBanner(context),
          ],
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final w in warnings)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(w.icon, size: 16, color: w.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(w.message,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Tam ekran kipinde gizlenen özet/uyarı kartını sayfa olarak gösterir.
  void _showSummarySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.8,
          ),
          child: SingleChildScrollView(child: _statusCard(context)),
        ),
      ),
    );
  }

  /// Ekstrenin KENDİ verileriyle yapılan aritmetik doğrulamanın sonucu.
  ///
  /// Buradaki iddia "muhtemelen doğru okuduk" değil, kanıtlanabilir bir
  /// eşitliktir: bakiye zinciri her satırın tutar+işaretini, beyan edilen
  /// kayıt sayısı hiçbir satırın kaçmadığını, devreden/kapanış bakiyesi ve
  /// Borç/Alacak toplamları da bütünü doğrular. Kontrollerin dökümü
  /// gösterilir ki kullanıcı neye güvendiğini görebilsin.
  Widget _verificationBanner(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = _s.verification;
    final ok = v.status == StatementVerificationStatus.verified;
    final color = ok ? Colors.green : cs.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(ok ? Icons.verified_rounded : Icons.error_outline_rounded,
                  size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ok
                      ? context.l10n.bankImportVerified
                      : context.l10n.bankImportVerifyFailed,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            ok
                ? context.l10n.bankImportVerifiedHint
                : context.l10n.bankImportVerifyFailedHint,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 6),
          for (final c in v.checks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                children: [
                  Icon(
                    c.passed ? Icons.check_rounded : Icons.close_rounded,
                    size: 13,
                    color: c.passed ? Colors.green : cs.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_checkLabel(context, c.kind)}: ${c.detail}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _checkLabel(BuildContext context, StatementCheckKind kind) =>
      switch (kind) {
        StatementCheckKind.balanceChain =>
          context.l10n.bankImportCheckBalanceChain,
        StatementCheckKind.recordCount =>
          context.l10n.bankImportCheckRecordCount,
        StatementCheckKind.openingBalance =>
          context.l10n.bankImportCheckOpeningBalance,
        StatementCheckKind.closingBalance =>
          context.l10n.bankImportCheckClosingBalance,
        StatementCheckKind.totals => context.l10n.bankImportCheckTotals,
      };

  /// Gösterilecek uyarılar: genel "otomatik algılandı" uyarısı HER ZAMAN
  /// (kullanıcı talebi), bakiye tutmazsa ve para birimi uyuşmazsa ek olarak.
  List<_Warning> _warnings(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rec = _s.reconciliation;
    return [
      _Warning(Icons.warning_amber_rounded,
          context.l10n.bankImportReviewWarning, Colors.orange),
      // OCR yolu diğerlerinden belirgin biçimde hatalı: en üstte, kırmızıyla.
      if (_s.fromOcr)
        _Warning(Icons.image_search_rounded, context.l10n.bankImportOcrWarning,
            cs.error),
      if (rec != null && rec.status == ReconcileStatus.mismatch)
        _Warning(
          Icons.error_outline_rounded,
          context.l10n.bankImportReconcileMismatch(rec.mismatchCount),
          cs.error,
        ),
      if (_s.foreignCurrency case final foreign?)
        _Warning(
          Icons.currency_exchange_rounded,
          context.l10n.bankImportCurrencyMismatch(
              currencySymbol(foreign), currencySymbol(_currency)),
          cs.error,
        ),
      // Kaynak dosyanın kendisi şüpheliyse (kırpık .xls / çözülemeyen hücre)
      // bunu ayrıştırma uyarılarından AYRI söyle: burada sorun bizim
      // yorumumuz değil, elimizdeki verinin eksikliği.
      if (_s.sourceTruncated)
        _Warning(Icons.broken_image_outlined,
            context.l10n.bankImportSourceTruncated, cs.error),
      if (_s.sourceUnresolvedCells > 0)
        _Warning(
          Icons.help_outline_rounded,
          context.l10n.bankImportSourceUnresolved(_s.sourceUnresolvedCells),
          cs.error,
        ),
    ];
  }

  Widget _stat(BuildContext context, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          // Satır içinde (tekrar rozeti) yer daralabiliyor: etiket taşmak
          // yerine kısalsın.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- Toolbar

  Widget _toolbar(BuildContext context) {
    final visibleCount = _visible.length;
    final filtered = _effectiveFilter != _ReviewFilter.all || _query.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            // Sorgu tuş başına BİR kez katlanır, aday satır başına değil.
            onChanged: (v) => setState(() => _query = foldTr(v)),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              hintText: context.l10n.bankImportSearchHint,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() {
                        _query = '';
                        _searchController.clear();
                      }),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(context, _ReviewFilter.all,
                    context.l10n.bankImportFilterAll),
                const SizedBox(width: 6),
                if (_s.uncategorizedCount > 0)
                  _filterChip(context, _ReviewFilter.uncategorized,
                      '${context.l10n.bankImportFilterUncategorized} (${_s.uncategorizedCount})'),
                if (_s.uncategorizedCount > 0) const SizedBox(width: 6),
                if (_s.duplicateCount > 0)
                  _filterChip(context, _ReviewFilter.duplicates,
                      '${context.l10n.bankImportFilterDuplicates} (${_s.duplicateCount})'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  filtered
                      ? context.l10n
                          .bankImportShownOf(visibleCount, _s.drafts.length)
                      : context.l10n.bankImportSelectedOf(
                          _s.selectedCount, _s.drafts.length),
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: context.l10n.bankImportSelectAll,
                icon: const Icon(Icons.done_all_rounded, size: 20),
                onPressed: () => _cubit.setAllSelected(true),
              ),
              IconButton(
                tooltip: context.l10n.bankImportDeselectAll,
                icon: const Icon(Icons.remove_done_rounded, size: 20),
                onPressed: () => _cubit.setAllSelected(false),
              ),
              IconButton(
                tooltip: widget.fullscreen
                    ? context.l10n.bankImportExitFullscreen
                    : context.l10n.bankImportFullscreen,
                icon: Icon(
                    widget.fullscreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    size: 20),
                onPressed: widget.onToggleFullscreen,
              ),
              _overflowMenu(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, _ReviewFilter value, String label) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _effectiveFilter == value,
      visualDensity: VisualDensity.compact,
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  /// Seyrek kullanılan işlemler tek taşma menüsünde: eylem satırına dördüncü
  /// bir simge daha sığmıyor (dar telefonda taşıyordu).
  Widget _overflowMenu(BuildContext context) {
    final visible = _visible;
    final blank = [
      for (final (index, draft) in visible)
        if (draft.categoryId == null) index,
    ];
    final all = [for (final (index, _) in visible) index];

    return PopupMenuButton<void>(
      tooltip: context.l10n.bankImportMoreActions,
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      itemBuilder: (ctx) => [
        // Toplu atamanın kapsamı artık eylemin ADINDA. Tek bir "görünen
        // satırlara ata" eylemi vardı ve varsayılan süzgeç "tümü" olduğu için
        // kullanıcının ELLE seçtiği kategorilerin üzerine de yazıyordu:
        // "kalan boşları doldur" diye dokunulan düğme bütün listeyi tek
        // kategoriye çeviriyordu. Boşları doldurmak ile üzerine yazmak artık
        // iki ayrı eylem; ikincisi sayısıyla birlikte açıkça söylüyor.
        if (blank.isNotEmpty)
          _menuItem(
            icon: Icons.label_outline_rounded,
            label: context.l10n.bankImportAssignUncategorized(blank.length),
            onTap: () => _assignCategoryTo(blank),
          ),
        if (all.length > blank.length)
          _menuItem(
            icon: Icons.edit_note_rounded,
            label: context.l10n.bankImportAssignOverwrite(all.length),
            onTap: () => _assignCategoryTo(all),
          ),
        if (_s.drafts.length >= kMinGroupSize)
          _menuItem(
            icon: Icons.workspaces_outline,
            label: context.l10n.bankImportGroupSimilar,
            onTap: () => showSimilarGroupSheet(context),
          ),
        _menuItem(
          icon: Icons.view_agenda_outlined,
          label: context.l10n.bankImportStepperMode,
          onTap: () => setState(() {
            _stepper = true;
            _step = 0;
          }),
        ),
        if (widget.fullscreen)
          _menuItem(
            icon: Icons.info_outline_rounded,
            label: context.l10n.bankImportSummarySheet,
            onTap: () => _showSummarySheet(context),
          ),
        _menuItem(
          icon: Icons.trending_down_rounded,
          label:
              '${context.l10n.bankImportBatchTypeLabel} ${context.l10n.bankImportSetAllExpense}',
          onTap: () => _cubit.setAllType(TransactionTypeModel.expense),
        ),
        _menuItem(
          icon: Icons.trending_up_rounded,
          label:
              '${context.l10n.bankImportBatchTypeLabel} ${context.l10n.bankImportSetAllIncome}',
          onTap: () => _cubit.setAllType(TransactionTypeModel.income),
        ),
      ],
    );
  }

  /// Menü satırı. Etiket `Flexible`: çeviriler ve "{n} satır" gibi değişken
  /// parçalar menü genişliğini taşırabiliyor (ölçüldü), taşma yerine sarsın.
  PopupMenuItem<void> _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return PopupMenuItem<void>(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(child: Text(label)),
      ]),
    );
  }

  // -------------------------------------------------------- Category picking

  /// Kategori seçim sayfasını açar; iptalde `null`.
  ///
  /// Sayfanın içinden YENİ kategori de kurulabilir: ekstredeki bir harcama
  /// mevcut kategorilerin hiçbirine uymadığında akıştan çıkıp ayarlara gitmek
  /// gerekmemeli (öneri adımı yalnız BİLİNEN grupları önerir, kullanıcının
  /// kendi kategorisini değil).
  /// Seçici PAYLAŞILAN yüzeydir (`CategoryPickerSheet`): ağaç mantığı burada
  /// ikinci kez yazılsaydı işlem formuyla ekstre incelemesi zamanla ayrışırdı.
  Future<_PickedCategory?> _pickCategory(
    BuildContext context, {
    required bool allowTypeSwitch,
    required bool initialIsExpense,
    String? currentId,
  }) async {
    final picked = await showCategoryPickerSheet(
      context: context,
      isExpense: initialIsExpense,
      currentId: currentId,
      allowTypeSwitch: allowTypeSwitch,
      onCreated: _cubit.registerCreatedCategory,
    );
    if (picked == null) return null;
    return (id: picked.id, isExpense: picked.isExpense);
  }

  Future<void> _pickCategoryForRow(
      BuildContext context, int i, ImportDraft d) async {
    final picked = await _pickCategory(
      context,
      allowTypeSwitch: false,
      initialIsExpense: !d.isIncome,
      currentId: d.categoryId,
    );
    if (picked == null || !mounted) return;
    _cubit.setDraftCategory(i, picked.id);
    _offerSimilar(i, picked.id);
  }

  /// Bu satıra benzeyen KATEGORİSİZ satırlar varsa tek dokunuşla hepsine
  /// uygulamayı önerir.
  ///
  /// Öneri, kullanıcı zaten doğru kararı verdiği anda gelir: aynı üye
  /// işyerinin 12 satırını tek tek gezmek yerine ilkini seçip "hepsine uygula"
  /// demek yeter. Eylem basıldığında hedefler YENİDEN süzülür — arada elle
  /// kategori verilmiş bir satırın üzerine yazmaz.
  void _offerSimilar(int index, String categoryId) {
    final state = _cubit.state;
    if (state is! BankImportReview) return;
    final similar = [
      for (final i in similarDraftIndexes(state.drafts, index))
        if (state.drafts[i].categoryId == null) i,
    ];
    if (similar.isEmpty) return;

    AppMessenger.info(
      context.l10n.bankImportApplyToSimilar(
        similar.length,
        _sampleDescription(state.drafts, similar),
      ),
      action: AppMessageAction(
        label: context.l10n.bankImportApplyToSimilarAction,
        onPressed: () {
          final fresh = _cubit.state;
          if (fresh is! BankImportReview) return;
          final targets = [
            for (final i in similar)
              if (fresh.drafts[i].categoryId == null) i,
          ];
          if (targets.isNotEmpty) {
            _cubit.applyCategoryToIndexes(targets, categoryId);
          }
        },
      ),
    );
  }

  /// Önerinin ETKİLEYECEĞİ satırlardan bir örnek.
  ///
  /// Kritik: kümeleme ortak ÖN EKE bakıyor ve ön ek her zaman marka olmuyor.
  /// Ölçüldü — "TURK HAVA YOLLARI" ile "TURK EKONOMI BANKASI" tek grupta
  /// birleşiyor, tıpkı "ŞOK Üsküdar" + "ŞOK Kadıköy" gibi; ikisi yapısal
  /// olarak AYNI ve hiçbir eşik birini kesip diğerini bırakamıyor
  /// (bkz. `description_grouper.dart` "BİLİNEN SINIR").
  ///
  /// Bu yüzden öneri sayı ile yetinmez: kullanıcı neye dokunacağını görmeden
  /// "hepsine uygula" dememeli. Grup sayfası zaten örnek gösteriyordu; tek
  /// dokunuşluk bu kısayol göstermiyordu.
  static String _sampleDescription(
      List<ImportDraft> drafts, List<int> indexes) {
    final first = drafts[indexes.first].description.trim();
    final shown = first.length <= 40 ? first : '${first.substring(0, 39)}…';
    return indexes.length > 1 ? '$shown …' : shown;
  }

  /// [targets] indekslerine toplu kategori uygular. Kapsamı ÇAĞIRAN belirler
  /// (yalnız kategorisiz olanlar / görünenlerin tamamı); bu fonksiyon verilen
  /// kümenin dışına asla çıkmaz.
  ///
  /// Kategori kendi türündeki satırlara uygulanır; karışık listede seçilmeyen
  /// tür olduğu gibi kalır. Hiç eşleşen satır kalmazsa sessizce dönmek yerine
  /// söylenir — eskiden gider kategorisi seçilen gelir listesinde düğme hiçbir
  /// şey yapmıyor gibi görünüyordu.
  ///
  /// `context` bilerek parametre DEĞİL: seçim sayfası beklenirken sayfa
  /// kapanmış olabilir, `mounted` ancak State'in kendi context'ini korur.
  Future<void> _assignCategoryTo(List<int> targets) async {
    if (targets.isEmpty) return;
    final rows = [for (final i in targets) (i, _s.drafts[i])];
    final hasExpense = rows.any((r) => !r.$2.isIncome);
    final hasIncome = rows.any((r) => r.$2.isIncome);

    final picked = await _pickCategory(
      context,
      allowTypeSwitch: hasExpense && hasIncome,
      initialIsExpense: hasExpense,
    );
    if (picked == null || !mounted) return;

    final matching = [
      for (final (index, draft) in rows)
        if (draft.isIncome != picked.isExpense) index,
    ];
    if (matching.isEmpty) {
      AppMessenger.warning(context.l10n.bankImportAssignTypeMismatch);
      return;
    }
    _cubit.applyCategoryToIndexes(matching, picked.id);

    AppMessenger.success(context.l10n.bankImportAssignVisibleDone(
      matching.length,
      _categoryLabels[picked.id] ?? picked.id,
    ));
  }

  // --------------------------------------------------------------------- Row

  Widget _row(BuildContext context, int i, ImportDraft d) {
    final cs = Theme.of(context).colorScheme;
    final accent = d.isIncome ? AppGradients.savings : AppGradients.debt;
    return Opacity(
      opacity: d.selected ? 1 : 0.45,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: d.selected,
              visualDensity: VisualDensity.compact,
              onChanged: (_) => _cubit.toggleDraft(i),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              _editDescriptionDialog(context, i, d.description),
                          borderRadius: BorderRadius.circular(4),
                          child: Text(
                            d.description.isEmpty ? '—' : d.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _editAmountDialog(context, i, d.amount),
                        borderRadius: BorderRadius.circular(4),
                        child: Text(
                          '${d.isIncome ? '+' : '−'}${_money(d.amount)}',
                          style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(AppFormatters.dateShort.format(d.date),
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                      if (d.isDuplicate) ...[
                        const SizedBox(width: 8),
                        // Rozet de esner: tarih + rozet + kategori + tür
                        // simgesi dar telefonda satırı taşırıyordu (ölçüldü).
                        Flexible(
                          child: _chip(
                              context,
                              Icons.copy_all_rounded,
                              context.l10n.bankImportDuplicate,
                              AppGradients.debt),
                        ),
                      ],
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _categoryControl(context, i, d),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: d.isIncome
                            ? context.l10n.detailLabelGelir
                            : context.l10n.detailLabelGider,
                        icon: Icon(
                            d.isIncome
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: accent,
                            size: 20),
                        onPressed: () => _cubit.setDraftType(
                            i,
                            d.isIncome
                                ? TransactionTypeModel.expense
                                : TransactionTypeModel.income),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Satırın kategori düğmesi. Açılır liste (Dropdown) yerine sayfa açar:
  /// listeye "yeni kategori" girişi eklenebilsin ve 20+ kategori dar satırda
  /// okunabilsin diye.
  ///
  /// Tahmin edilemeyen taslaklar `categoryId: null` gelir (bkz. cubit); boş
  /// görünmek yerine kırmızı bir "Kategori seç" çağrısı basılır — kategorisiz
  /// satır zaten eklenemez.
  Widget _categoryControl(BuildContext context, int i, ImportDraft d) {
    final cs = Theme.of(context).colorScheme;
    final cat = _categoryById(_catsFor(d.isIncome), d.categoryId);
    final missing = cat == null;
    return InkWell(
      onTap: () => _pickCategoryForRow(context, i, d),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              missing
                  ? Icons.error_outline_rounded
                  : AppIcons.getIconData(cat.iconName),
              size: 14,
              color: missing ? cs.error : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                missing
                    ? context.l10n.bankImportPickCategoryHint
                    : (_categoryLabels[cat.id] ?? cat.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: missing ? cs.error : cs.onSurface,
                  fontWeight: missing ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded,
                size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final blocked = _s.selectedUncategorizedCount;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (blocked > 0) _uncategorizedBanner(context, blocked),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _s.canCommit ? () => _cubit.commit() : null,
              icon: const Icon(Icons.playlist_add_check_rounded),
              label: Text(context.l10n.bankImportAdd(_s.selectedCount)),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ],
      ),
    );
  }

  /// Seçili ama kategorisiz satır varsa ekleme kapalıdır: kategorisiz hareket
  /// deftere boş etiketle yazılır ve bütçe/raporda hiçbir kategoriye sayılmaz
  /// (elle girişte de kategori zorunlu). Şerit doğrudan o satırlara götürür.
  Widget _uncategorizedBanner(BuildContext context, int count) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() {
          _stepper = false;
          _filter = _ReviewFilter.uncategorized;
        }),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, size: 16, color: cs.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.bankImportUncategorizedBlocked(count),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.bankImportShowUncategorized,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: cs.error),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- Stepper mode

  Widget _buildStepper(BuildContext context) {
    final total = _s.drafts.length;
    final d = _s.drafts[_step];
    final accent = d.isIncome ? AppGradients.savings : AppGradients.debt;

    return Column(
      children: [
        LinearProgressIndicator(value: (_step + 1) / total),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${_step + 1} / $total'),
              const Spacer(),
              // Tam ekranda AppBar yok: kipten çıkış burada da bulunmalı,
              // yoksa stepper'a geçen kullanıcı için tek yol geri hareketi
              // kalıyor.
              if (widget.fullscreen)
                IconButton(
                  tooltip: context.l10n.bankImportExitFullscreen,
                  icon: const Icon(Icons.fullscreen_exit_rounded, size: 20),
                  onPressed: widget.onToggleFullscreen,
                ),
              TextButton.icon(
                onPressed: () => setState(() => _stepper = false),
                icon: const Icon(Icons.list_rounded, size: 18),
                label: Text(context.l10n.bankImportFilterAll),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppFormatters.dateLong.format(d.date)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () =>
                        _editDescriptionDialog(context, _step, d.description),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              d.description.isEmpty ? '—' : d.description,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.edit_outlined,
                              size: 16,
                              color: Theme.of(context).colorScheme.outline),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _editAmountDialog(context, _step, d.amount),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${d.isIncome ? '+' : '−'}${_money(d.amount)}',
                            style: TextStyle(
                                color: accent,
                                fontSize: 28,
                                fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.edit_outlined,
                              size: 20, color: accent.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Dokunma kolu [_categoryControl]'ün kendisinde; burada
                  // yalnız daha görünür bir çerçeveye alınıyor (iç içe iki
                  // tıklama alanı kurulmaz).
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      child: _categoryControl(context, _step, d),
                    ),
                  ),
                  if (d.isDuplicate) ...[
                    const SizedBox(height: 8),
                    Text(context.l10n.bankImportDuplicate,
                        style: TextStyle(color: AppGradients.debt)),
                  ],
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _stepDecide(false),
                      child: Text(context.l10n.bankImportStepSkip),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      // Kategorisiz satır eklenemez (bkz. [_uncategorizedBanner]).
                      onPressed:
                          d.categoryId == null ? null : () => _stepDecide(true),
                      child: Text(context.l10n.bankImportStepAdd),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(context.l10n.bankImportStepAddRest),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.l10n.bankImportStepCancelAll),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _stepDecide(bool add) {
    _cubit.setDraftSelected(_step, add);
    if (_step >= _s.drafts.length - 1) {
      _finish();
    } else {
      setState(() => _step++);
    }
  }

  /// Toplu yazımı başlatır. Seçililer arasında kategorisiz satır kalmışsa
  /// (stepper yalnız gezilen satırları etkiler) yazmaz; listeye dönüp o
  /// satırları gösterir.
  ///
  /// Durum cubit'ten TAZE okunur: `widget.state` bu karede hâlâ mutasyon
  /// öncesini taşıyor olabilir.
  void _finish() {
    final s = _cubit.state;
    if (s is BankImportReview && !s.canCommit && s.selectedCount > 0) {
      setState(() {
        _stepper = false;
        _filter = _ReviewFilter.uncategorized;
      });
      AppMessenger.warning(context.l10n.bankImportStepNeedsCategory);
      return;
    }
    _cubit.commit();
  }

  Future<void> _editDescriptionDialog(
      BuildContext context, int i, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.bankImportEditDescTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration:
              InputDecoration(labelText: ctx.l10n.bankImportEditDescLabel),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.iptal)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(ctx.l10n.kaydet)),
        ],
      ),
    );
    if (result != null) {
      _cubit.setDraftDescription(i, result);
    }
  }

  Future<void> _editAmountDialog(
      BuildContext context, int i, double current) async {
    final controller =
        TextEditingController(text: formatAmountForInput(current));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.bankImportEditAmountTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: ctx.l10n.bankImportEditAmountLabel,
            // Hedef cüzdanın birimi; sabit '₺' USD/EUR cüzdanda yanlıştı.
            suffixText: currencySymbol(_currency),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.iptal)),
          FilledButton(
            onPressed: () {
              final val = parseMoneyInput(controller.text);
              if (val != null && val > 0) {
                Navigator.pop(ctx, val);
              }
            },
            child: Text(ctx.l10n.kaydet),
          ),
        ],
      ),
    );
    if (result != null) {
      _cubit.setDraftAmount(i, result);
    }
  }
}

/// İnceleme ekranında gösterilen tek bir uyarı satırı.
class _Warning {
  final IconData icon;
  final String message;
  final Color color;
  const _Warning(this.icon, this.message, this.color);
}
