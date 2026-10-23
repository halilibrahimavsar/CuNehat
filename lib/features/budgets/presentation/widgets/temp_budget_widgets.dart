import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_tokens.dart';
import 'package:cunehat/config/theme/money_colors.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/error/error_handling.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/shared/focus.dart';
import 'package:cunehat/core/shared/layout/system_bar_insets.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/app_date_range_picker.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/core/shared/widgets/row_action_sheet.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';
import 'package:cunehat/features/budgets/domain/usecases/temp_budget_usecases.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_event.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/services/wallet_category_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_picker_sheet.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

/// "10 Kas – 20 Kas"; bu yıldan değilse yıllı ("28 Ara 2026 – 3 Oca 2027").
String tempBudgetRangeLabel(TempBudgetEntity b, {DateTime? today}) {
  final now = today ?? DateTime.now();
  final sameYear = b.startDate.year == now.year && b.endDate.year == now.year;
  final f = sameYear ? AppFormatters.dayMonth : AppFormatters.dayMonthYear;
  if (b.totalDays == 1) return f.format(b.startDate);
  return '${f.format(b.startDate)} – ${f.format(b.endDate)}';
}

/// Durumun rengi: yaklaşan nötr; süren ve biten bütçe iyi/kötü sinyaliyle
/// (limit doldu ya da aşıldı → "dikkat").
Color tempBudgetStatusColor(
    BuildContext context, TempBudgetEntity b, DateTime today) {
  if (b.statusOn(today) == TempBudgetStatus.upcoming) {
    return Theme.of(context).colorScheme.primary;
  }
  if (b.isExceeded || b.isFilled) return MoneyColors.bad;
  return MoneyColors.good;
}

/// Durum rozetinin metni: "5 gün kaldı" / "Yarın başlıyor" / "1.150 ₺ aştı".
String tempBudgetStatusText(
  AppLocalizations l10n,
  TempBudgetEntity b,
  DateTime today, {
  required String currency,
}) {
  switch (b.statusOn(today)) {
    case TempBudgetStatus.upcoming:
      return l10n.tempBudgetStartsIn(b.daysUntilStartOn(today));
    case TempBudgetStatus.active:
      return l10n.tempBudgetDaysLeft(b.remainingDaysOn(today));
    case TempBudgetStatus.finished:
      return tempBudgetResultText(l10n, b, currency: currency);
  }
}

/// Bitmiş bütçenin sonucu.
String tempBudgetResultText(
  AppLocalizations l10n,
  TempBudgetEntity b, {
  required String currency,
}) {
  if (b.isFilled) return l10n.tempBudgetResultExact;
  if (b.isExceeded) {
    return l10n
        .tempBudgetResultOver(formatMoney(-b.remaining, currency: currency));
  }
  return l10n
      .tempBudgetResultLeft(formatMoney(b.remaining, currency: currency));
}

/// Bütçeler sayfasındaki "Tek seferlik bütçeler" bölümü: sürenler ve
/// yaklaşanlar açık, bitenler daraltılmış bir alt başlıkta.
class TempBudgetSection extends StatelessWidget {
  final List<TempBudgetEntity> budgets;
  final Map<String, String> categoryLabels;
  final String walletId;

  /// Testler için sabit gün; verilmezse bugün.
  final DateTime? today;

  const TempBudgetSection({
    super.key,
    required this.budgets,
    required this.walletId,
    this.categoryLabels = const {},
    this.today,
  });

  @override
  Widget build(BuildContext context) {
    final now = today ?? DateTime.now();
    final open = [
      for (final b in budgets)
        if (b.statusOn(now) != TempBudgetStatus.finished) b,
    ];
    // Biten en yeni önce: geçen haftaki tatil, geçen yılki bayramdan önemli.
    final finished = [
      for (final b in budgets)
        if (b.statusOn(now) == TempBudgetStatus.finished) b,
    ]..sort((a, b) => b.endDate.compareTo(a.endDate));
    final theme = Theme.of(context);

    TempBudgetCard card(TempBudgetEntity b) => TempBudgetCard(
          budget: b,
          walletId: walletId,
          categoryLabels: categoryLabels,
          today: now,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10, top: 8),
          child: Text(
            context.l10n.tempBudgetSectionTitle,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: AppType.strong),
          ),
        ),
        ...open.map(card),
        if (finished.isNotEmpty)
          Theme(
            // ExpansionTile'ın varsayılan üst/alt çizgileri kart dilini bozar.
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: const ValueKey('temp-budget-finished'),
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              childrenPadding: EdgeInsets.zero,
              initiallyExpanded: open.isEmpty,
              title: Text(
                context.l10n.tempBudgetFinishedSection(finished.length),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              children: finished.map(card).toList(),
            ),
          ),
      ],
    );
  }
}

class TempBudgetCard extends StatelessWidget {
  final TempBudgetEntity budget;
  final String walletId;
  final Map<String, String> categoryLabels;
  final DateTime today;

  const TempBudgetCard({
    super.key,
    required this.budget,
    required this.walletId,
    required this.today,
    this.categoryLabels = const {},
  });

  Future<void> _delete(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmDialog.show(
      context,
      title: l10n.tempBudgetDeleteConfirmTitle,
      message: l10n.tempBudgetDeleteConfirmMessage(budget.name),
      confirmText: l10n.sil,
    );
    if (!confirmed || !context.mounted) return;
    final bloc = context.read<BudgetsBloc>();
    final original = budget;
    bloc.add(DeleteTempBudgetEvent(original.id));
    AppMessenger.success(
      l10n.tempBudgetDeleted(original.name),
      action: AppMessageAction(
        label: l10n.geriAl,
        onPressed: () {
          // Geri alma kayıt usecase'inden geçer (bkz. snackbar katmanı
          // notu): sayfa kapanmışsa bloc'a yazmak StateError fırlatırdı.
          if (!bloc.isClosed) {
            bloc.add(SaveTempBudgetEvent(original));
          } else {
            getIt<SaveTempBudgetUsecase>()(original);
          }
        },
      ),
    );
  }

  Future<void> _showActions(BuildContext context, Color accent) async {
    final action = await RowActionSheet.show<RowEditDelete>(
      context,
      title: budget.name,
      icon: Icons.event_note_rounded,
      accent: accent,
      actions: editDeleteActions(context),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case RowEditDelete.edit:
        showTempBudgetForm(context, walletId: walletId, editing: budget);
      case RowEditDelete.delete:
        await _delete(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currency = context.activeWalletCurrency;
    final status = budget.statusOn(today);
    final color = tempBudgetStatusColor(context, budget, today);

    final names = [
      for (final id in budget.categoryIds)
        context.categoryLabelForTag(id, labels: categoryLabels),
    ];
    const maxChips = 3;

    // Süren bütçede kalanın (planlılar düşülerek) güne bölünmüşü — Gelecek'in
    // "sığması için günde en çok" sayısıyla aynı; bitmişin sonucu rozette.
    final daily = status == TempBudgetStatus.active
        ? budget.dailyAllowanceOn(today)
        : null;
    final String? footnote = daily == null
        ? null
        : (budget.plannedAmount > 0.005
            ? l10n.tempBudgetDailyAfterPlanned(
                formatMoney(daily, currency: currency))
            : l10n.tempBudgetDailyAllowance(
                formatMoney(daily, currency: currency)));

    return AppCard(
      key: ValueKey('temp-budget-card-${budget.id}'),
      accent: color,
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () =>
          showTempBudgetForm(context, walletId: walletId, editing: budget),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.event_note_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      // İki satır: "Bayram alışveri…" — ad kartın kimliği.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    // Rozet adla aynı satırı paylaşınca 320dp'de ikisi de
                    // kesiliyordu ("Kapad…", "2 gün …"); tarihin yanında
                    // durur, sığmazsa alta iner, ad tüm genişliği alır.
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          tempBudgetRangeLabel(budget, today: today),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: AppRadius.controlAll,
                            border:
                                Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            tempBudgetStatusText(l10n, budget, today,
                                currency: currency),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: color,
                              fontWeight: AppType.strong,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              RowMenuButton(
                key: ValueKey('temp-budget-menu-${budget.id}'),
                onPressed: () => _showActions(context, color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final name in names.take(maxChips))
                _CategoryPill(label: name),
              if (names.length > maxChips)
                _CategoryPill(
                    label:
                        l10n.tempBudgetMoreCategories(names.length - maxChips)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: budget.progress,
              backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
              color: color,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.tempBudgetSpentOfLimit(
                    formatMoney(budget.spentAmount, currency: currency),
                    formatMoney(budget.limitAmount, currency: currency),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: budget.isExceeded
                        ? MoneyColors.expenseText(theme.brightness)
                        : scheme.onSurface,
                  ),
                ),
              ),
              if (footnote != null)
                Flexible(
                  child: Text(
                    footnote,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
          // Kart cüzdanında harcama ödeme gününe sayılır: tatilde kartla
          // yapılan harcama bu bütçede görünmeyebilir — nedeni kartta yazsın.
          if (context.walletById(walletId)?.isCreditCard ?? false) ...[
            const SizedBox(height: 6),
            Text(
              l10n.tempBudgetCardPaymentDayHint,
              key: ValueKey('temp-budget-card-hint-${budget.id}'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;

  const _CategoryPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: AppRadius.controlAll,
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

/// Tek seferlik bütçe formunu alt sayfa olarak açar; [editing] verilirse
/// o bütçeyi düzenler.
void showTempBudgetForm(
  BuildContext context, {
  required String walletId,
  TempBudgetEntity? editing,
}) {
  final bloc = context.read<BudgetsBloc>();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => TempBudgetFormSheet(
      walletId: walletId,
      editing: editing,
      onSave: (budget) => bloc.add(SaveTempBudgetEvent(budget)),
    ),
  );
}

class TempBudgetFormSheet extends StatefulWidget {
  final String walletId;
  final TempBudgetEntity? editing;
  final ValueChanged<TempBudgetEntity> onSave;

  /// Testler için kategori listesi; verilmezse cüzdanın gider kategorileri
  /// okunur.
  final List<CategoryEntity>? categories;

  const TempBudgetFormSheet({
    super.key,
    required this.walletId,
    required this.onSave,
    this.editing,
    this.categories,
  });

  @override
  State<TempBudgetFormSheet> createState() => _TempBudgetFormSheetState();
}

class _TempBudgetFormSheetState extends State<TempBudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();

  List<CategoryEntity> _categories = [];
  final List<String> _selected = [];
  DateTimeRange? _range;

  bool get _isEdit => widget.editing != null;

  bool get _onCard =>
      context.walletById(widget.walletId)?.isCreditCard ?? false;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _nameController.text = editing.name;
      _limitController.text = formatAmountForInput(editing.limitAmount);
      _selected.addAll(editing.categoryIds);
      _range = DateTimeRange(start: editing.startDate, end: editing.endDate);
    }
    final given = widget.categories;
    if (given != null) {
      _categories = given;
    } else {
      _loadCategories();
    }
  }

  Future<void> _loadCategories() async {
    final List<CategoryEntity> categories;
    try {
      categories = await getIt<WalletCategoryService>().categoriesFor(
        walletId: widget.walletId,
        isExpense: true,
      );
    } catch (e, st) {
      // Kategori deposu `Either` DEĞİL, EXCEPTION fırlatır (bkz. aylık form).
      reportError('Tek seferlik bütçe · kategoriler', e, st);
      if (!mounted) return;
      AppMessenger.error(context.l10n.kategorilerYuklenemedi('$e'));
      return;
    }
    if (!mounted) return;
    setState(() => _categories = categories);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  CategoryEntity? _byId(String id) =>
      _categories.where((c) => c.id == id).firstOrNull;

  String _nameOf(String id) => _byId(id)?.name ?? id;

  /// [id]'nin seçili bir ATASI var mı? Varsa onun kimliği.
  String? _selectedAncestorOf(String id) {
    var parent = _byId(id)?.parentId;
    final seen = <String>{};
    while (parent != null && seen.add(parent)) {
      if (_selected.contains(parent)) return parent;
      parent = _byId(parent)?.parentId;
    }
    return null;
  }

  /// Seçili atası olan kategori seçilemez: ana kategori alt kategorisini zaten
  /// sayıyor; ikisi birlikte "çift sayım" izlenimi verir (hesapta birleşim
  /// alındığı için tutar şişmez, ama seçim yanıltıcı olur).
  String? _lockReasonFor(CategoryEntity c) {
    final ancestor = _selectedAncestorOf(c.id);
    if (ancestor == null) return null;
    return context.l10n.tempBudgetCategoryCovered(_nameOf(ancestor));
  }

  Future<void> _addCategory(FormFieldState<List<String>> field) async {
    releaseInputFocus();
    final picked = await showCategoryPickerSheet(
      context: context,
      isExpense: true,
      walletId: widget.walletId,
      lockReasonFor: _lockReasonFor,
      onCreated: (_) => _loadCategories(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (!_categories.any((c) => c.id == picked.id)) {
        _categories = [..._categories, picked];
      }
      if (_selected.contains(picked.id) ||
          _selectedAncestorOf(picked.id) != null) {
        return;
      }
      // Yeni seçilen bir ATA ise, altında zaten seçili olanlar onun içinde
      // kalır; listeden düşer.
      _selected.removeWhere((id) {
        var parent = _byId(id)?.parentId;
        final seen = <String>{};
        while (parent != null && seen.add(parent)) {
          if (parent == picked.id) return true;
          parent = _byId(parent)?.parentId;
        }
        return false;
      });
      _selected.add(picked.id);
    });
    field.didChange(List.of(_selected));
  }

  Future<void> _pickRange(FormFieldState<DateTimeRange> field) async {
    final now = DateTime.now();
    final picked = await AppDateRangePicker.pick(
      context,
      initialDateRange: _range ??
          DateTimeRange(
            start: DateTime(now.year, now.month, now.day),
            end: DateTime(now.year, now.month, now.day + 6),
          ),
    );
    if (picked == null || !mounted) return;
    setState(() => _range = picked);
    field.didChange(picked);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final range = _range;
    final limit = parseMoneyInput(_limitController.text) ?? 0;
    if (range == null || limit <= 0 || _selected.isEmpty) return;
    final editing = widget.editing;
    final budget = TempBudgetEntity(
      id: editing?.id ?? const Uuid().v4(),
      walletId: editing?.walletId ?? widget.walletId,
      name: _nameController.text.trim(),
      limitAmount: limit,
      startDate: range.start,
      endDate: range.end,
      categoryIds: List.unmodifiable(_selected),
    );
    widget.onSave(budget);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rangeText = _range == null
        ? null
        : tempBudgetRangeLabel(TempBudgetEntity(
            id: '',
            name: '',
            limitAmount: 0,
            startDate: _range!.start,
            endDate: _range!.end,
            categoryIds: const [],
          ));

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + sheetBottomInset(context)),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? l10n.tempBudgetEditTitle : l10n.tempBudgetNewTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // Birincil eylem kaydırmanın DIŞINDA: uzun kategori listesi
            // "Kaydet"i ekranın altına itmesin (form alt sayfası kuralı).
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const ValueKey('temp-budget-name-field'),
                      controller: _nameController,
                      autofocus: !_isEdit,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l10n.tempBudgetNameLabel,
                        hintText: l10n.tempBudgetNameHint,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? l10n.tempBudgetNameRequired
                          : null,
                    ),
                    const SizedBox(height: 16),
                    FormField<DateTimeRange>(
                      initialValue: _range,
                      validator: (_) =>
                          _range == null ? l10n.tempBudgetRangeRequired : null,
                      builder: (field) => InkWell(
                        key: const ValueKey('temp-budget-range-field'),
                        onTap: () => _pickRange(field),
                        borderRadius: BorderRadius.circular(4),
                        child: InputDecorator(
                          isEmpty: rangeText == null,
                          decoration: InputDecoration(
                            labelText: l10n.tempBudgetRangeLabel,
                            border: const OutlineInputBorder(),
                            errorText: field.errorText,
                            suffixIcon: const Icon(Icons.date_range_rounded),
                          ),
                          child: rangeText == null ? null : Text(rangeText),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('temp-budget-limit-field'),
                      controller: _limitController,
                      decoration: InputDecoration(
                        labelText: l10n.tempBudgetLimitLabel,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [AmountInputFormatter()],
                      validator: (value) => validateAmountInput(value ?? ''),
                    ),
                    const SizedBox(height: 16),
                    FormField<List<String>>(
                      initialValue: List.of(_selected),
                      validator: (_) => _selected.isEmpty
                          ? l10n.tempBudgetCategoriesRequired
                          : null,
                      builder: (field) => InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.tempBudgetCategoriesLabel,
                          // Kart cüzdanında harcama ödeme gününe sayılır
                          // (aylık bütçe ve Rapor ile aynı kural): tatilde
                          // kartla yapılan harcama ödemesi aralığa düşerse
                          // sayılır. Kullanıcı bunu formda görsün.
                          helperText: _onCard
                              ? '${l10n.tempBudgetCategoriesHint} '
                                  '${l10n.tempBudgetCardPaymentDayHint}'
                              : l10n.tempBudgetCategoriesHint,
                          helperMaxLines: 3,
                          border: const OutlineInputBorder(),
                          errorText: field.errorText,
                        ),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final id in _selected)
                              InputChip(
                                key: ValueKey('temp-budget-cat-$id'),
                                label: Text(_nameOf(id)),
                                onDeleted: () {
                                  setState(() => _selected.remove(id));
                                  field.didChange(List.of(_selected));
                                },
                              ),
                            ActionChip(
                              key: const ValueKey('temp-budget-add-category'),
                              avatar: Icon(Icons.add_rounded,
                                  size: 18, color: scheme.primary),
                              label: Text(l10n.tempBudgetAddCategory),
                              onPressed: () => _addCategory(field),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.iptal),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('temp-budget-save'),
                    onPressed: _save,
                    child: Text(_isEdit ? l10n.guncelle : l10n.kaydet),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
