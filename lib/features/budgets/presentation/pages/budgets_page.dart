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

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<BudgetsBloc>()..add(LoadBudgetsEvent()),
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
    // Burada harcanan miktarı işlem deposundan çekip hesaplamak gerekir.
    // Şimdilik sadece bütçe limitini gösteriyoruz.
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(budget.categoryId), // Kategori ID aynı zamanda isim.
        subtitle: Text(
            'Aylık Limit: ${AppFormatters.currency.format(budget.limitAmount)}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            context
                .read<BudgetsBloc>()
                .add(DeleteBudgetEvent(budget.categoryId));
          },
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
        _showAddBudgetDialog(context);
      },
      child: const Icon(Icons.add),
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    final bloc = context.read<BudgetsBloc>();
    String categoryName = '';
    double limit = 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Yeni Bütçe Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Kategori Adı'),
                onChanged: (val) => categoryName = val,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Aylık Limit'),
                keyboardType: TextInputType.number,
                onChanged: (val) => limit = double.tryParse(val) ?? 0,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                if (categoryName.isNotEmpty && limit > 0) {
                  bloc.add(SaveBudgetEvent(BudgetEntity(
                    categoryId: categoryName,
                    limitAmount: limit,
                  )));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }
}
