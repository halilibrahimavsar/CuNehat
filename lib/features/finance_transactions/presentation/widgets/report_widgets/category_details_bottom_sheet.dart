import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/detailed_list_view.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bir kategori diliminin işlemlerini listeleyen detay sayfası.
///
/// TransactionBloc'u dinler: liste açıkken bir işlem silinir/eklenirse kırılım
/// [dataBuilder] üzerinden yeniden hesaplanır.
class CategoryDetailsBottomSheet extends StatelessWidget {
  final CategoryData initialCategory;
  final bool isExpense;

  /// true = bar grafikten açıldı (tam liste), false = pastadan açıldı
  /// (küçük kategoriler "Diğer"de toplanmış liste).
  final bool useFullData;
  final Map<String, IconData> categoryIcons;
  final ReportCategoryDataBuilder dataBuilder;

  /// `tag` → görünen ad; kırılım anahtarı hep tag kalır (bkz. chart card).
  final Map<String, String> categoryLabels;

  const CategoryDetailsBottomSheet({
    super.key,
    required this.initialCategory,
    required this.isExpense,
    required this.useFullData,
    required this.categoryIcons,
    required this.dataBuilder,
    this.categoryLabels = const {},
  });

  static void show({
    required BuildContext context,
    required CategoryData initialCategory,
    required bool isExpense,
    required bool useFullData,
    required Map<String, IconData> categoryIcons,
    required ReportCategoryDataBuilder dataBuilder,
    Map<String, String> categoryLabels = const {},
  }) {
    // Modal route sayfanın provider'ının altında değil, Overlay'de kardeşi
    // olarak açılır → bloc elle taşınmalı.
    final transactionBloc = context.read<TransactionBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocProvider.value(
          value: transactionBloc,
          child: CategoryDetailsBottomSheet(
            initialCategory: initialCategory,
            isExpense: isExpense,
            useFullData: useFullData,
            categoryIcons: categoryIcons,
            dataBuilder: dataBuilder,
            categoryLabels: categoryLabels,
          ),
        );
      },
    );
  }

  String _formatCurrency(BuildContext context, double value) =>
      formatMoney(value, currency: context.activeWalletCurrency);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final filteredTransactions =
            dataBuilder.filterByRange(state.currentTransactions);
        final fullList =
            dataBuilder.buildFull(filteredTransactions, isExpense: isExpense);
        final categoryDataList =
            useFullData ? fullList : dataBuilder.buildPie(fullList);

        final updatedCategory = categoryDataList.firstWhere(
          (c) =>
              c.name == initialCategory.name &&
              c.isOther == initialCategory.isOther,
          orElse: () => CategoryData(
            initialCategory.name,
            0,
            const [],
            initialCategory.color,
            isOther: initialCategory.isOther,
          ),
        );

        final budgetInfo = isExpense
            ? dataBuilder.budgetProgressFor(
                updatedCategory.name, updatedCategory.totalAmount)
            : null;

        final transactionsWithBalance = updatedCategory.transactions
            .map((t) => TransactionWithBalance(transaction: t, balanceAfter: 0))
            .toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Sayfa başlığı: kategori rengi, adı, dönem toplamı
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: updatedCategory.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            updatedCategory.labelIn(context, categoryLabels),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _formatCurrency(context, updatedCategory.totalAmount),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isExpense ? Colors.redAccent : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (budgetInfo != null) ...[
                      const SizedBox(height: 12),
                      _buildBudgetIndicator(context, theme, budgetInfo),
                    ],
                  ],
                ),
              ),
              // Kategorinin dönem içindeki işlemleri
              Expanded(
                child: transactionsWithBalance.isEmpty
                    ? Center(
                        child: Text(
                          context.l10n.buKategoriyeAitIslem,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : DetailedListView(
                        transactions: transactionsWithBalance,
                        mode: isExpense
                            ? FinanceMode.expense
                            : FinanceMode.income,
                        categoryIcons: categoryIcons,
                        categoryLabels: categoryLabels,
                        showDayEndBalance: false,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudgetIndicator(
    BuildContext context,
    ThemeData theme,
    ({double progress, bool isExceeded, double limit}) budget,
  ) {
    final scheme = theme.colorScheme;
    final color = budget.isExceeded ? Colors.redAccent : Colors.green;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: budget.progress,
            minHeight: 6,
            backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '%${(budget.progress * 100).toStringAsFixed(0)} / ${_formatCurrency(context, budget.limit)}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
