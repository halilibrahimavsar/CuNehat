import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_event.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_state.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';

import 'package:cunehat/core/blocs/app_auth_bloc.dart';
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

    return BlocProvider(
      create: (context) => getIt<BudgetsBloc>()..add(LoadBudgetsEvent(userId: userId, walletId: walletId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bütçe Planlama'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.pop(),
          ),
        ),
        body: const _BudgetsBody(),
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
          return const Center(child: CircularProgressIndicator());
        } else if (state is BudgetsError) {
          return Center(child: Text('Hata: ${state.failure.message}'));
        } else if (state is BudgetsLoaded) {
          if (state.budgets.isEmpty) {
            return const Center(
              child: Text('Henüz bütçe planlaması yapmadınız.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: state.budgets.length,
            itemBuilder: (context, index) {
              final budget = state.budgets[index];
              return _BudgetListItem(budget: budget);
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _BudgetListItem extends StatelessWidget {
  final BudgetEntity budget;

  const _BudgetListItem({required this.budget});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    budget.categoryId,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    context
                        .read<BudgetsBloc>()
                        .add(DeleteBudgetEvent(budget.categoryId));
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Harcanan: ${AppFormatters.currency.format(budget.spentAmount)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: budget.isExceeded ? Colors.red : null,
                    fontWeight: budget.isExceeded ? FontWeight.bold : null,
                  ),
                ),
                Text(
                  'Limit: ${AppFormatters.currency.format(budget.limitAmount)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: budget.progress,
              backgroundColor: Colors.grey.shade200,
              color: budget.isExceeded ? Colors.red : Colors.green,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBudgetButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (ctx) => _AddBudgetDialog(bloc: context.read<BudgetsBloc>()),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}

class _AddBudgetDialog extends StatefulWidget {
  final BudgetsBloc bloc;
  const _AddBudgetDialog({required this.bloc});

  @override
  State<_AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<_AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _limitController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final categoryName = _categoryController.text.trim();
      final limitStr = _limitController.text.trim().replaceAll(',', '.');
      final limit = double.tryParse(limitStr) ?? 0;

      if (limit > 0) {
        widget.bloc.add(SaveBudgetEvent(BudgetEntity(
          categoryId: categoryName,
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
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Kategori Adı',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kategori adı boş olamaz';
                }
                return null;
              },
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
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
