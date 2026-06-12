import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_event.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_state.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';

import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AppAuthBloc>().state;
    final userId = authState is AppAuthenticated ? authState.user.uid : '';
    
    final walletState = context.read<WalletBloc>().state;
    final walletId = walletState is WalletLoadedSt && walletState.wallets.isNotEmpty 
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
                icon:
                    const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Bütçe Planlama',
                  style: TextStyle(
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

class _BudgetsBody extends StatelessWidget {
  const _BudgetsBody();

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
            child: Center(child: Text('Hata: ${state.failure.message}')),
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
                ...state.budgets
                    .map((budget) => _BudgetListItem(budget: budget)),
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
              child: Icon(Icons.savings_outlined,
                  size: 48, color: scheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz bütçe yok',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Kategorilerinize aylık harcama limiti koyun,\nharcamalarınızı buradan takip edin.',
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
    final overallProgress =
        totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;
    final statusColor = exceededCount > 0 ? Colors.red : Colors.green;

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
                'BU AY TOPLAM HARCAMA',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  exceededCount > 0
                      ? '$exceededCount bütçe aşıldı'
                      : 'Kontrol altında',
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
              AppFormatters.currency.format(totalSpent),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toplam limit: ${AppFormatters.currency.format(totalLimit)}',
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
  final BudgetEntity budget;

  const _BudgetListItem({required this.budget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusColor = budget.isExceeded ? Colors.red : Colors.green;
    final percent = (budget.progress * 100).toStringAsFixed(0);

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
                  budget.isExceeded
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  budget.categoryId,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '%$percent',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: scheme.onSurfaceVariant),
                onPressed: () {
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
                'Harcanan: ${AppFormatters.currency.format(budget.spentAmount)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: budget.isExceeded ? Colors.red : scheme.onSurface,
                  fontWeight:
                      budget.isExceeded ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              Text(
                'Limit: ${AppFormatters.currency.format(budget.limitAmount)}',
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
            existingBudgets:
                state is BudgetsLoaded ? state.budgets : const [],
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

  List<String> _categories = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    // Serbest metin yerine gerçek gider kategorileri: bütçenin categoryId'si
    // işlem tag'iyle birebir eşleşmezse harcama hiç birikmez.
    final categories =
        await getIt<CategoryRepository>().getCategories(true);
    if (!mounted) return;
    setState(() => _categories = categories.map((c) => c.id).toList());
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  bool get _isUpdate =>
      widget.existingBudgets.any((b) => b.categoryId == _selectedCategory);

  void _onCategorySelected(String? value) {
    setState(() => _selectedCategory = value);
    // Mevcut bütçesi olan kategori seçilirse limiti öne doldur (güncelleme).
    final existing =
        widget.existingBudgets.where((b) => b.categoryId == value).toList();
    if (existing.isNotEmpty) {
      _limitController.text = existing.first.limitAmount.toString();
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final limitStr = _limitController.text.trim().replaceAll(',', '.');
      final limit = double.tryParse(limitStr) ?? 0;

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
      title: const Text('Yeni Bütçe Ekle'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: _onCategorySelected,
              validator: (value) =>
                  value == null ? 'Bir kategori seçin' : null,
            ),
            if (_isUpdate)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Bu kategorinin bütçesi var; limit güncellenecek.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _limitController,
              decoration: const InputDecoration(
                labelText: 'Aylık Limit',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tutar boş olamaz';
                }
                final parsedStr = value.replaceAll(',', '.');
                final parsed = double.tryParse(parsedStr);
                if (parsed == null || parsed <= 0) {
                  return 'Geçerli bir tutar girin';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_isUpdate ? 'Güncelle' : 'Kaydet'),
        ),
      ],
    );
  }
}
