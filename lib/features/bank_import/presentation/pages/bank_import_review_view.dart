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

/// Taslakları inceleme: liste (varsayılan) + tek-tek stepper. Toplu ekleme.
class BankImportReviewView extends StatefulWidget {
  final BankImportReview state;
  const BankImportReviewView({super.key, required this.state});

  @override
  State<BankImportReviewView> createState() => _BankImportReviewViewState();
}

class _BankImportReviewViewState extends State<BankImportReviewView> {
  bool _stepper = false;
  int _step = 0;

  BankImportCubit get _cubit => context.read<BankImportCubit>();
  BankImportReview get _s => widget.state;

  @override
  Widget build(BuildContext context) {
    if (_s.drafts.isEmpty) {
      return Center(child: Text(context.l10n.bankImportNoRows));
    }
    return Column(
      children: [
        _warningBanner(context),
        _reconcileBanner(context),
        _currencyBanner(context),
        Expanded(
            child: _stepper ? _buildStepper(context) : _buildList(context)),
      ],
    );
  }

  /// Ekstre para birimi hedef cüzdanınkinden farklıysa uyarır (tutarlar
  /// dönüştürülmez). Yoksa hiçbir şey.
  Widget _currencyBanner(BuildContext context) {
    final foreign = _s.foreignCurrency;
    final wallet = _s.walletCurrency;
    if (foreign == null || wallet == null) return const SizedBox.shrink();
    final color = Theme.of(context).colorScheme.error;
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.currency_exchange_rounded, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.bankImportCurrencyMismatch(
                currencySymbol(foreign),
                currencySymbol(wallet),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Bakiye sütunuyla mutabakat sonucunu gösterir: `matched` → yeşil güven
  /// şeridi (işaretler bakiyeden doğrulandı); `mismatch` → kırmızı uyarı
  /// (bakiye tutmadı, kullanıcı işaretleri kontrol etmeli). Yoksa hiçbir şey.
  Widget _reconcileBanner(BuildContext context) {
    final rec = _s.reconciliation;
    if (rec == null || rec.status == ReconcileStatus.notAvailable) {
      return const SizedBox.shrink();
    }
    final matched = rec.status == ReconcileStatus.matched;
    final color = matched ? Colors.green : Theme.of(context).colorScheme.error;
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(matched ? Icons.verified_rounded : Icons.error_outline_rounded,
              size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              matched
                  ? context.l10n.bankImportReconcileMatched
                  : context.l10n.bankImportReconcileMismatch(rec.mismatchCount),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Otomatik algılamanın hatalı olabileceğini hatırlatan kalıcı uyarı şeridi
  /// (bkz. kullanıcı talebi: onaydan önce açık bir uyarı gösterilmesi).
  Widget _warningBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.withValues(alpha: 0.14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.bankImportReviewWarning,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  List<CategoryEntity> _catsFor(bool income) =>
      income ? _s.incomeCategories : _s.expenseCategories;

  // ---------------------------------------------------------------- List mode

  Widget _buildList(BuildContext context) {
    return Column(
      children: [
        _summaryBar(context),
        _batchCategoryBar(context),
        _batchTypeBar(context),
        Expanded(
          child: ListView.separated(
            itemCount: _s.drafts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _row(context, i),
          ),
        ),
        _bottomBar(context),
      ],
    );
  }

  Widget _summaryBar(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.bankImportSummary(_s.drafts.length,
                  _s.duplicateCount, _s.skippedRows, _s.uncategorizedCount),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _cubit.setAllSelected(true),
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: Text(context.l10n.bankImportSelectAll),
                ),
                TextButton.icon(
                  onPressed: () => _cubit.setAllSelected(false),
                  icon: const Icon(Icons.remove_done_rounded, size: 18),
                  label: Text(context.l10n.bankImportDeselectAll),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _stepper = true;
                    _step = 0;
                  }),
                  icon: const Icon(Icons.view_agenda_outlined, size: 18),
                  label: Text(context.l10n.bankImportStepperMode),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Toplu varsayılan kategori: bir türdeki tüm taslaklara tek dokunuşla uygular.
  Widget _batchCategoryBar(BuildContext context) {
    final hasExpense = _s.drafts.any((d) => !d.isIncome);
    final hasIncome = _s.drafts.any((d) => d.isIncome);
    if (!hasExpense && !hasIncome) return const SizedBox.shrink();

    String? currentFor(bool income) => _s.drafts
        .firstWhere((d) => d.isIncome == income, orElse: () => _s.drafts.first)
        .categoryId;

    Widget picker(bool income, String label) {
      final cats = _catsFor(income);
      if (cats.isEmpty) return const SizedBox.shrink();
      final value = cats.any((c) => c.id == currentFor(income))
          ? currentFor(income)
          : null;
      return Expanded(
        child: Row(
          children: [
            Text('$label ', style: const TextStyle(fontSize: 12)),
            Expanded(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                isDense: true,
                style: Theme.of(context).textTheme.bodySmall,
                items: [
                  for (final c in cats)
                    DropdownMenuItem(value: c.id, child: Text(c.id)),
                ],
                onChanged: (v) => v == null
                    ? null
                    : _cubit.applyBatchCategory(
                        forExpense: !income, categoryId: v),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          if (hasExpense)
            picker(false, context.l10n.bankImportDefaultExpenseCat),
          if (hasExpense && hasIncome) const SizedBox(width: 12),
          if (hasIncome) picker(true, context.l10n.bankImportDefaultIncomeCat),
        ],
      ),
    );
  }

  /// Toplu tür: tek dokunuşla tüm satırları gider ya da gelir yapar. Tek
  /// pozitif "Tutar" sütunlu (işaretsiz) ekstrelerde tüm satırlar yanlış yöne
  /// düşerse (ör. hepsi gelir) hızlı düzeltme için.
  Widget _batchTypeBar(BuildContext context) {
    ButtonStyle style() => OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Text(context.l10n.bankImportBatchTypeLabel,
              style: const TextStyle(fontSize: 12)),
          OutlinedButton.icon(
            onPressed: () => _cubit.setAllType(TransactionTypeModel.expense),
            icon: const Icon(Icons.trending_down_rounded, size: 16),
            label: Text(context.l10n.bankImportSetAllExpense),
            style: style(),
          ),
          OutlinedButton.icon(
            onPressed: () => _cubit.setAllType(TransactionTypeModel.income),
            icon: const Icon(Icons.trending_up_rounded, size: 16),
            label: Text(context.l10n.bankImportSetAllIncome),
            style: style(),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, int i) {
    final d = _s.drafts[i];
    final accent = d.isIncome ? AppGradients.savings : AppGradients.debt;
    return Opacity(
      opacity: d.selected ? 1 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: d.selected,
              onChanged: (_) => _cubit.toggleDraft(i),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              _editDescriptionDialog(context, i, d.description),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    d.description.isEmpty ? '—' : d.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.edit_outlined,
                                    size: 12,
                                    color:
                                        Theme.of(context).colorScheme.outline),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _editAmountDialog(context, i, d.amount),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                '${d.isIncome ? '+' : '-'}${formatAmountForInput(d.amount)}',
                                style: TextStyle(
                                    color: accent, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.edit_outlined,
                                  size: 12,
                                  color: accent.withValues(alpha: 0.7)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(AppFormatters.dateShort.format(d.date),
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 10),
                      if (d.isDuplicate)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppGradients.debt.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(context.l10n.bankImportDuplicate,
                              style: TextStyle(
                                  fontSize: 10, color: AppGradients.debt)),
                        ),
                      const Spacer(),
                      _categoryDropdown(context, i, d),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
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
      style: Theme.of(context).textTheme.bodySmall,
      // Tahmin edilemeyen taslaklar `categoryId: null` gelir (bkz. cubit);
      // boş dropdown yerine açık bir "seç" ipucu göster, aksi halde satır
      // kategorisi varmış gibi yanlışlıkla boş görünür.
      hint: Text(
        context.l10n.bankImportPickCategoryHint,
        style: TextStyle(color: cs.error, fontSize: 12),
      ),
      items: [
        for (final c in cats) DropdownMenuItem(value: c.id, child: Text(c.id)),
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
          child: Text('${_step + 1} / $total'),
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
                            '${d.isIncome ? '+' : '-'}${formatAmountForInput(d.amount)}',
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
        title: const Text('Açıklamayı Düzenle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Açıklama'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Kaydet')),
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
        title: const Text('Tutarı Düzenle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration:
              const InputDecoration(labelText: 'Tutar', suffixText: '₺'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              final val = parseMoneyInput(controller.text);
              if (val != null && val > 0) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (result != null) {
      _cubit.setDraftAmount(i, result);
    }
  }
}
