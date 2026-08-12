import 'dart:async';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_event.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_state.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';

import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AppAuthBloc>().state;
    final userId = authState is AppAuthenticated ? authState.user.uid : '';

    final walletState = context.read<WalletBloc>().state;
    final walletId =
        walletState is WalletLoadedSt && walletState.wallets.isNotEmpty
            ? (walletState.activeWallet?.id ?? walletState.wallets.first.id!)
            : '';

    final scheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (context) => getIt<BudgetsBloc>()
        ..add(LoadBudgetsEvent(userId: userId, walletId: walletId)),
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: scheme.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  context.l10n.butcePlanlama,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [scheme.primary, scheme.secondary],
                    ),
                  ),
                ),
              ),
            ),
            const _BudgetsBody(),
          ],
        ),
        floatingActionButton: _AddBudgetButton(),
      ),
    );
  }
}

class _BudgetsBody extends StatefulWidget {
  const _BudgetsBody();

  @override
  State<_BudgetsBody> createState() => _BudgetsBodyState();
}

class _BudgetsBodyState extends State<_BudgetsBody> {
  /// `categoryId` → görünen ad. Bütçe anahtarı hep kategori id'sidir
  /// (`tag` ile eşleşmek zorunda); bu harita yalnız başlık basmak içindir.
  Map<String, String> _labels = {};

  StreamSubscription<void>? _categoriesSub;

  @override
  void initState() {
    super.initState();
    _loadLabels();
    _categoriesSub =
        getIt<CategoriesChangedNotifier>().stream.listen((_) => _loadLabels());
  }

  @override
  void dispose() {
    _categoriesSub?.cancel();
    super.dispose();
  }

  /// Kategori ikon+ad indeksini yükler ve kategoriler değiştikçe TAZELER.
  ///
  /// Harita eskiden yalnız initState'te kuruluyordu: sayfa route yığınında
  /// dururken yapılan bir yeniden adlandırma ancak sayfa yeniden kurulduğunda
  /// görünüyordu.
  Future<void> _loadLabels() async {
    // Bütçeler yalnız gider kategorilerine kurulur.
    final cats = await getIt<CategoryRepository>().getCategories(true);
    if (!mounted) return;
    setState(() => _labels = buildCategoryLabelMap(cats));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetsBloc, BudgetsState>(
      builder: (context, state) {
        if (state is BudgetsLoading) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (state is BudgetsError) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
                child: Text(context.l10n
                    .hataStateFailureMessage(state.failure.message))),
          );
        } else if (state is BudgetsLoaded) {
          if (state.budgets.isEmpty) {
            return const _EmptyBudgets();
          }
          return SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _BudgetSummaryCard(budgets: state.budgets),
                const SizedBox(height: 16),
                ...state.budgets.map((budget) =>
                    _BudgetListItem(budget: budget, categoryLabels: _labels)),
              ]),
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }
}

class _EmptyBudgets extends StatelessWidget {
  const _EmptyBudgets();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.savings_outlined, size: 48, color: scheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.henuzButceYok,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.kategorilerinizeAylikHarcamaLimiti,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tüm bütçelerin toplam görünümü (toplam limit, harcanan, aşılan sayısı).
class _BudgetSummaryCard extends StatelessWidget {
  final List<BudgetEntity> budgets;

  const _BudgetSummaryCard({required this.budgets});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final totalLimit = budgets.fold(0.0, (sum, b) => sum + b.limitAmount);
    final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spentAmount);
    final exceededCount = budgets.where((b) => b.isExceeded).length;
    final filledCount = budgets.where((b) => b.isFilled).length;
    final overallProgress =
        totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;

    final Color statusColor;
    final String statusText;
    if (exceededCount > 0) {
      statusColor = Colors.red;
      statusText = context.l10n.budgetStatusExceededCount(exceededCount);
    } else if (filledCount > 0) {
      statusColor = Colors.orange;
      statusText = context.l10n.budgetStatusFilledCount(filledCount);
    } else {
      statusColor = Colors.green;
      statusText = context.l10n.budgetStatusUnderControl;
    }

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.bUAyToplamHarcama,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatMoney(totalSpent, currency: context.activeWalletCurrency),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.toplamLimitAppformattersCurrency(formatMoney(
                totalLimit,
                currency: context.activeWalletCurrency)),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: overallProgress,
              backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
              color: statusColor,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetListItem extends StatelessWidget {
  /// `categoryId` → görünen ad; boşsa id l10n'a düşer.
  final Map<String, String> categoryLabels;

  final BudgetEntity budget;

  const _BudgetListItem({
    required this.budget,
    this.categoryLabels = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Color statusColor;
    final IconData statusIcon;
    if (budget.isExceeded) {
      statusColor = Colors.red;
      statusIcon = Icons.warning_amber_rounded;
    } else if (budget.isFilled) {
      statusColor = Colors.orange;
      statusIcon = Icons.error_outline;
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
    }

    // Yüzde etiketi rozet rengiyle çelişmemeli: yuvarlama yüzünden %99,6
    // (yeşil), %100 (turuncu) ve %100,4 (kırmızı) üçü de "100" yazıyordu.
    // Etiket, durumun eşiklerine sabitlenir.
    final rawPercent = budget.limitAmount > 0
        ? (budget.spentAmount / budget.limitAmount * 100).round()
        : 0;
    final int percentValue;
    if (budget.isFilled) {
      percentValue = 100;
    } else if (budget.isExceeded) {
      percentValue = rawPercent <= 100 ? 101 : rawPercent;
    } else {
      percentValue = rawPercent >= 100 ? 99 : rawPercent;
    }
    final percent = '$percentValue';

    return AppCard(
      accent: statusColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.categoryLabelForTag(budget.categoryId,
                      labels: categoryLabels),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  context.l10n.percent(percent),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                icon:
                    Icon(Icons.delete_outline, color: scheme.onSurfaceVariant),
                onPressed: () async {
                  final confirmed = await ConfirmDialog.show(
                    context,
                    title: context.l10n.budgetDeleteConfirmTitle,
                    message: context.l10n.budgetDeleteConfirmMessage(
                        context.categoryLabelForTag(budget.categoryId,
                            labels: categoryLabels)),
                    confirmText: context.l10n.sil,
                  );
                  if (!confirmed || !context.mounted) return;
                  context
                      .read<BudgetsBloc>()
                      .add(DeleteBudgetEvent(budget.categoryId));
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: budget.progress,
              backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
              color: statusColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.harcananAppformattersCurrencyFormat(formatMoney(
                    budget.spentAmount,
                    currency: context.activeWalletCurrency)),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: budget.isExceeded
                      ? Colors.red
                      : (budget.isFilled ? Colors.orange : scheme.onSurface),
                  fontWeight: (budget.isExceeded || budget.isFilled)
                      ? FontWeight.bold
                      : FontWeight.w600,
                ),
              ),
              Text(
                context.l10n.limitAppformattersCurrencyFormat(formatMoney(
                    budget.limitAmount,
                    currency: context.activeWalletCurrency)),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddBudgetButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        final bloc = context.read<BudgetsBloc>();
        final state = bloc.state;
        showDialog(
          context: context,
          builder: (ctx) => _AddBudgetDialog(
            bloc: bloc,
            existingBudgets: state is BudgetsLoaded ? state.budgets : const [],
          ),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}

class _AddBudgetDialog extends StatefulWidget {
  final BudgetsBloc bloc;
  final List<BudgetEntity> existingBudgets;
  const _AddBudgetDialog({required this.bloc, required this.existingBudgets});

  @override
  State<_AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<_AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();

  /// Entity olarak tutulur: dropdown'un DEĞERİ `id` (bütçe anahtarı,
  /// `tag` ile eşleşmek zorunda), ETİKETİ ise çözümlenmiş görünen ad.
  List<CategoryEntity> _categories = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    // Serbest metin yerine gerçek gider kategorileri: bütçenin categoryId'si
    // işlem tag'iyle birebir eşleşmezse harcama hiç birikmez.
    final categories = await getIt<CategoryRepository>().getCategories(true);
    if (!mounted) return;
    setState(() => _categories = categories);
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  bool get _isUpdate =>
      widget.existingBudgets.any((b) => b.categoryId == _selectedCategory);

  /// TEK SEVİYE KİLİDİ: bir kategoriye bütçe konduysa atasına ya da
  /// çocuklarına konamaz.
  ///
  /// Ana kategori bütçesi çocuklarının harcamasını zaten sayıyor; ikisine
  /// birden limit koymak "hangi seviye aşıldı?" sorusunu belirsizleştirir ve
  /// bütçe uyarı monitörünün tek-kategori mantığını bozardı. Kilit sebebini
  /// döner, engel yoksa `null`.
  String? _lockReasonFor(CategoryEntity category) {
    // Kategorinin KENDİ bütçesi engel değil — o güncellemedir.
    if (widget.existingBudgets.any((b) => b.categoryId == category.id)) {
      return null;
    }

    final parentId = category.parentId;
    if (parentId != null &&
        widget.existingBudgets.any((b) => b.categoryId == parentId)) {
      final parent = _categories.where((c) => c.id == parentId).firstOrNull;
      return context.l10n.butceUstKategorideVar(parent?.name ?? '');
    }

    final hasBudgetedChild = _categories.any((c) =>
        c.parentId == category.id &&
        widget.existingBudgets.any((b) => b.categoryId == c.id));
    if (hasBudgetedChild) return context.l10n.butceAltKategorideVar;

    return null;
  }

  Widget _categoryItem(CategoryEntity category) {
    final lockReason = _lockReasonFor(category);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(left: category.isRoot ? 0 : 16),
      child: Row(
        children: [
          if (!category.isRoot)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.subdirectory_arrow_right,
                  size: 14, color: cs.onSurfaceVariant),
            ),
          Flexible(
            child: Text(
              category.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: lockReason != null ? cs.onSurfaceVariant : null,
              ),
            ),
          ),
          if (lockReason != null) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '· $lockReason',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onCategorySelected(String? value) {
    setState(() => _selectedCategory = value);
    // Mevcut bütçesi olan kategori seçilirse limiti öne doldur (güncelleme).
    final existing =
        widget.existingBudgets.where((b) => b.categoryId == value).toList();
    if (existing.isNotEmpty) {
      _limitController.text = formatAmountForInput(existing.first.limitAmount);
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final limit = parseMoneyInput(_limitController.text) ?? 0;

      if (_selectedCategory != null && limit > 0) {
        widget.bloc.add(SaveBudgetEvent(BudgetEntity(
          categoryId: _selectedCategory!,
          limitAmount: limit,
        )));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.yeniButceEkle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: context.l10n.labelKategori,
                border: const OutlineInputBorder(),
              ),
              isExpanded: true,
              items: [
                for (final c in _categories)
                  DropdownMenuItem(
                    value: c.id,
                    enabled: _lockReasonFor(c) == null,
                    child: _categoryItem(c),
                  ),
              ],
              onChanged: _onCategorySelected,
              validator: (value) => value == null ? 'Bir kategori seçin' : null,
            ),
            if (_isUpdate)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.l10n.buKategorininButcesiVar,
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _limitController,
              decoration: InputDecoration(
                labelText: context.l10n.labelAylikLimit,
                border: const OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AmountInputFormatter()],
              validator: (value) => validateAmountInput(value ?? ''),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.iptal),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_isUpdate ? 'Güncelle' : 'Kaydet'),
        ),
      ],
    );
  }
}
