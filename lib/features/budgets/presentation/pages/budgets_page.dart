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
import 'package:cunehat/core/shared/widgets/row_action_sheet.dart';
import 'package:cunehat/core/error/error_handling.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';

import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/wallet_category_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/core/shared/layout/system_bar_insets.dart';

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
            _BudgetsBody(walletId: walletId),
          ],
        ),
        floatingActionButton: _AddBudgetButton(walletId: walletId),
      ),
    );
  }
}

class _BudgetsBody extends StatefulWidget {
  /// Bütçelerin ait olduğu cüzdan; düzenleme formu kategori kapsamını
  /// buradan alır.
  final String walletId;

  const _BudgetsBody({required this.walletId});

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
    //
    // Bu harita KÜRESEL kalır (cüzdana daraltılmaz): bir bütçe, kategorisi bu
    // cüzdanda sonradan gizlense de listede durur ve adının çözülmesi gerekir.
    // Daraltılsaydı o satır ham UUID gösterirdi.
    final List<CategoryEntity> cats;
    try {
      cats = await getIt<CategoryRepository>().getCategories(true);
    } catch (e, st) {
      // Kategori deposu `Either` DEĞİL, EXCEPTION fırlatır. Önceki harita
      // korunur: geçici bir okuma hatası çalışan etiketleri silmemeli.
      reportError('Bütçeler · kategori adları', e, st);
      return;
    }
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
            // FAB (56dp) listenin son kartının üstüne biniyordu.
            padding: const EdgeInsets.all(16.0)
                .plusSystemBottom(context)
                .plusFabClearance(),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _BudgetSummaryCard(budgets: state.budgets),
                const SizedBox(height: 16),
                ...state.budgets.map((budget) => _BudgetListItem(
                      budget: budget,
                      categoryLabels: _labels,
                      walletId: widget.walletId,
                    )),
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
  final String walletId;

  const _BudgetListItem({
    required this.budget,
    required this.walletId,
    this.categoryLabels = const {},
  });

  /// Karta (ya da limit satırına) dokununca: bu bütçenin limitini düzenle.
  ///
  /// Eskiden karta dokunmak BOŞTU. Limiti değiştirmenin tek yolu "+" ile
  /// yeni bütçe formunu açıp AYNI kategoriyi yeniden seçmekti — form o zaman
  /// sessizce "Güncelle"ye dönüyordu; bunu bilen kullanıcı azdı.
  Future<void> _delete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: context.l10n.budgetDeleteConfirmTitle,
      message: context.l10n.budgetDeleteConfirmMessage(context
          .categoryLabelForTag(budget.categoryId, labels: categoryLabels)),
      confirmText: context.l10n.sil,
    );
    if (!confirmed || !context.mounted) return;
    context.read<BudgetsBloc>().add(DeleteBudgetEvent(budget.categoryId));
  }

  Future<void> _showActions(
    BuildContext context, {
    required IconData icon,
    required Color accent,
  }) async {
    final action = await RowActionSheet.show<RowEditDelete>(
      context,
      title: context.categoryLabelForTag(budget.categoryId,
          labels: categoryLabels),
      icon: icon,
      accent: accent,
      actions: editDeleteActions(context),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case RowEditDelete.edit:
        _edit(context);
      case RowEditDelete.delete:
        await _delete(context);
    }
  }

  void _edit(BuildContext context) => _showBudgetForm(
        context,
        walletId: walletId,
        editing: budget,
        editingLabel: context.categoryLabelForTag(budget.categoryId,
            labels: categoryLabels),
      );

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
      key: ValueKey('budget-card-${budget.categoryId}'),
      accent: statusColor,
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _edit(context),
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
              // Satır eylemleri uygulamanın her yerinde aynı yerde ve aynı
              // biçimde: ⋮ → eylem sayfası (bkz. RowActionSheet). Eskiden
              // burada çıplak bir çöp kutusu vardı.
              RowMenuButton(
                key: ValueKey('budget-menu-${budget.categoryId}'),
                onPressed: () => _showActions(context,
                    icon: statusIcon, accent: statusColor),
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
              // Düzenlenebilir olduğunu gösteren işaret, düzenlenen değerin
              // yanında: kartın tamamı da aynı formu açar.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.limitAppformattersCurrencyFormat(formatMoney(
                        budget.limitAmount,
                        currency: context.activeWalletCurrency)),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit_outlined,
                      size: 14, color: scheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddBudgetButton extends StatelessWidget {
  final String walletId;

  const _AddBudgetButton({required this.walletId});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showBudgetForm(context, walletId: walletId),
      child: const Icon(Icons.add),
    );
  }
}

/// Bütçe formunu alt sayfa olarak açar: yeni bütçe, ya da [editing] verilirse
/// o bütçenin limiti.
///
/// Eskiden ham bir `AlertDialog`'du; uygulamanın diğer bütün formları alt
/// sayfa. Alt sayfa klavyeyle birlikte yükselir ve tek elle erişilir.
void _showBudgetForm(
  BuildContext context, {
  required String walletId,
  BudgetEntity? editing,
  String? editingLabel,
}) {
  final bloc = context.read<BudgetsBloc>();
  final state = bloc.state;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _BudgetFormSheet(
      bloc: bloc,
      walletId: walletId,
      existingBudgets: state is BudgetsLoaded ? state.budgets : const [],
      editing: editing,
      editingLabel: editingLabel,
    ),
  );
}

class _BudgetFormSheet extends StatefulWidget {
  final BudgetsBloc bloc;

  /// Bütçe zaten cüzdan bazlı (`walletId::categoryId`); kategori seçeneği de
  /// o cüzdanda görünür kalemlerle sınırlanır.
  final String walletId;
  final List<BudgetEntity> existingBudgets;

  /// Düzenlenen bütçe. Verilirse kategori KİLİTLİDİR (bütçenin kimliği odur;
  /// başka kategoriye taşımak = sil + yeniden kur) ve yalnız limit değişir.
  final BudgetEntity? editing;

  /// [editing]'in görünen kategori adı.
  final String? editingLabel;

  const _BudgetFormSheet({
    required this.bloc,
    required this.walletId,
    required this.existingBudgets,
    this.editing,
    this.editingLabel,
  });

  @override
  State<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<_BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();

  /// Entity olarak tutulur: dropdown'un DEĞERİ `id` (bütçe anahtarı,
  /// `tag` ile eşleşmek zorunda), ETİKETİ ise çözümlenmiş görünen ad.
  List<CategoryEntity> _categories = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      // Düzenleme: kategori belli, liste yüklenmez.
      _selectedCategory = editing.categoryId;
      _limitController.text = formatAmountForInput(editing.limitAmount);
    } else {
      _loadCategories();
    }
  }

  Future<void> _loadCategories() async {
    // Serbest metin yerine gerçek gider kategorileri: bütçenin categoryId'si
    // işlem tag'iyle birebir eşleşmezse harcama hiç birikmez.
    final List<CategoryEntity> categories;
    try {
      categories = await getIt<WalletCategoryService>().categoriesFor(
        walletId: widget.walletId,
        isExpense: true,
      );
    } catch (e, st) {
      // Kategori deposu `Either` DEĞİL, EXCEPTION fırlatır. Yakalanmadığında
      // seçenek listesi sessizce boş kalıyor, kullanıcı hiç kategorisi
      // olmadığını sanıyordu.
      reportError('Bütçe ekleme · kategoriler', e, st);
      if (!mounted) return;
      AppMessenger.error(context.l10n.kategorilerYuklenemedi('$e'));
      return;
    }
    if (!mounted) return;
    setState(() => _categories = categories);
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.editing != null;

  bool get _isUpdate =>
      _isEdit ||
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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + sheetBottomInset(context)),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? l10n.butceyiDuzenle : l10n.yeniButceEkle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (_isEdit)
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.labelKategori,
                    border: const OutlineInputBorder(),
                    enabled: false,
                  ),
                  child: Text(widget.editingLabel ?? ''),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: l10n.labelKategori,
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
                  validator: (value) =>
                      value == null ? l10n.kategoriSecmeUyarisi : null,
                ),
              if (!_isEdit && _isUpdate)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.buKategorininButcesiVar,
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('budget-limit-field'),
                controller: _limitController,
                // Düzenlemede değişecek tek şey limit.
                autofocus: _isEdit,
                decoration: InputDecoration(
                  labelText: l10n.labelAylikLimit,
                  border: const OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [AmountInputFormatter()],
                validator: (value) => validateAmountInput(value ?? ''),
                onFieldSubmitted: (_) => _save(),
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
                      onPressed: _save,
                      child: Text(_isUpdate ? l10n.guncelle : l10n.kaydet),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
