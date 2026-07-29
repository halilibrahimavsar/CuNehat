import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/features/bank_import/data/balance_reconciler.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';

/// İnceleme listesinde hangi taslakların gösterileceği.
enum _ReviewFilter { all, uncategorized, duplicates }

/// Taslakları inceleme: liste (varsayılan) + tek-tek stepper. Toplu ekleme.
///
/// Liste 80+ satıra kadar çıkabildiği için (gerçek bir Garanti ekstresinde 85)
/// arama + filtre şart: "kategorisiz" olanlara doğrudan gitmek, tekrarları
/// gözden geçirmek elle kaydırmadan mümkün olmalı.
class BankImportReviewView extends StatefulWidget {
  final BankImportReview state;
  const BankImportReviewView({super.key, required this.state});

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
  String _money(double v) => AppFormatters.currencyFor(_currency).format(v);

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
  List<(int, ImportDraft)> get _visible {
    final q = _query.trim().toLowerCase();
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
      if (q.isNotEmpty && !d.description.toLowerCase().contains(q)) continue;
      out.add((i, d));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (_s.drafts.isEmpty) {
      return Center(child: Text(context.l10n.bankImportNoRows));
    }
    return _stepper ? _buildStepper(context) : _buildList(context);
  }

  List<CategoryEntity> _catsFor(bool income) =>
      income ? _s.incomeCategories : _s.expenseCategories;

  // ---------------------------------------------------------------- List mode

  Widget _buildList(BuildContext context) {
    final visible = _visible;
    return Column(
      children: [
        _statusCard(context),
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
              if (_s.reconciliation?.status == ReconcileStatus.matched)
                _chip(context, Icons.verified_rounded,
                    context.l10n.bankImportRoleBalance, Colors.green),
            ],
          ),
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
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- Toolbar

  Widget _toolbar(BuildContext context) {
    final visibleCount = _visible.length;
    final filtered =
        _effectiveFilter != _ReviewFilter.all || _query.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
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
              Text(
                filtered
                    ? context.l10n
                        .bankImportShownOf(visibleCount, _s.drafts.length)
                    : context.l10n.bankImportSelectedOf(
                        _s.selectedCount, _s.drafts.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
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
                tooltip: context.l10n.bankImportStepperMode,
                icon: const Icon(Icons.view_agenda_outlined, size: 20),
                onPressed: () => setState(() {
                  _stepper = true;
                  _step = 0;
                }),
              ),
              _batchMenu(context),
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

  /// Toplu işlemler (tür çevirme + varsayılan kategori) artık ekranın üstünde
  /// iki ayrı çubuk yerine tek bir menüde: gerçek ekstrede nadiren gerekiyor
  /// ama gerektiğinde her satırı tek tek düzeltmekten kurtarıyor.
  Widget _batchMenu(BuildContext context) {
    final hasExpense = _s.drafts.any((d) => !d.isIncome);
    final hasIncome = _s.drafts.any((d) => d.isIncome);
    return PopupMenuButton<void>(
      tooltip: context.l10n.bankImportBatchTypeLabel,
      icon: const Icon(Icons.playlist_add_rounded, size: 20),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          onTap: () => _cubit.setAllType(TransactionTypeModel.expense),
          child: Row(children: [
            const Icon(Icons.trending_down_rounded, size: 18),
            const SizedBox(width: 8),
            Text(
                '${context.l10n.bankImportBatchTypeLabel} ${context.l10n.bankImportSetAllExpense}'),
          ]),
        ),
        PopupMenuItem(
          onTap: () => _cubit.setAllType(TransactionTypeModel.income),
          child: Row(children: [
            const Icon(Icons.trending_up_rounded, size: 18),
            const SizedBox(width: 8),
            Text(
                '${context.l10n.bankImportBatchTypeLabel} ${context.l10n.bankImportSetAllIncome}'),
          ]),
        ),
        if (hasExpense && _s.expenseCategories.isNotEmpty)
          PopupMenuItem(
            onTap: () => _pickBatchCategory(context, forExpense: true),
            child: Text(context.l10n.bankImportDefaultExpenseCat),
          ),
        if (hasIncome && _s.incomeCategories.isNotEmpty)
          PopupMenuItem(
            onTap: () => _pickBatchCategory(context, forExpense: false),
            child: Text(context.l10n.bankImportDefaultIncomeCat),
          ),
      ],
    );
  }

  Future<void> _pickBatchCategory(BuildContext context,
      {required bool forExpense}) async {
    final cats = _catsFor(!forExpense);
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in cats)
              ListTile(
                title: Text(context.categoryLabel(c)),
                onTap: () => Navigator.pop(ctx, c.id),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      _cubit.applyBatchCategory(forExpense: forExpense, categoryId: picked);
    }
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
                        _chip(
                            context,
                            Icons.copy_all_rounded,
                            context.l10n.bankImportDuplicate,
                            AppGradients.debt),
                      ],
                      const Spacer(),
                      _categoryDropdown(context, i, d),
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

  Widget _categoryDropdown(BuildContext context, int i, ImportDraft d) {
    final cats = _catsFor(d.isIncome);
    if (cats.isEmpty) return const SizedBox.shrink();
    final value = cats.any((c) => c.id == d.categoryId) ? d.categoryId : null;
    final cs = Theme.of(context).colorScheme;
    return DropdownButton<String>(
      value: value,
      isDense: true,
      underline: const SizedBox.shrink(),
      borderRadius: BorderRadius.circular(12),
      style: Theme.of(context).textTheme.bodySmall,
      // Tahmin edilemeyen taslaklar `categoryId: null` gelir (bkz. cubit);
      // boş dropdown yerine açık bir "seç" ipucu göster, aksi halde satır
      // kategorisi varmış gibi yanlışlıkla boş görünür.
      hint: Text(
        context.l10n.bankImportPickCategoryHint,
        style: TextStyle(color: cs.error, fontSize: 12),
      ),
      items: [
        for (final c in cats)
          DropdownMenuItem(value: c.id, child: Text(context.categoryLabel(c))),
      ],
      onChanged: (v) => v == null ? null : _cubit.setDraftCategory(i, v),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _s.selectedCount == 0 ? null : () => _cubit.commit(),
          icon: const Icon(Icons.playlist_add_check_rounded),
          label: Text(context.l10n.bankImportAdd(_s.selectedCount)),
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16)),
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
                  _categoryDropdown(context, _step, d),
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
                      onPressed: () => _stepDecide(true),
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
                      onPressed: () => _cubit.commit(),
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
      _cubit.commit();
    } else {
      setState(() => _step++);
    }
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
