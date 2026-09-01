import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/detailed_list_view.dart';
import 'package:flutter/material.dart';

/// Verilen işlem listesini gösteren sade alt sayfa.
///
/// [CategoryDetailsBottomSheet]'ten farkı: liste SABİTTİR, bloc değiştikçe
/// yeniden hesaplanmaz. Çünkü "en çok harcanan yer" grubunun kategori
/// karşılığı yok — kümeleme metin benzerliğinden geliyor, yeniden
/// hesaplanacak bir kırılım kimliği bulunmuyor. Kategori sayfası bu yüzden
/// kullanılamaz; ona kimlik uydurmak, silinen bir işlemden sonra listenin
/// sessizce başka bir gruba kaymasına yol açardı.
class ReportTransactionListSheet extends StatelessWidget {
  final String title;
  final List<TransactionEntity> transactions;
  final bool isExpense;
  final Map<String, IconData> categoryIcons;
  final Map<String, String> categoryLabels;

  const ReportTransactionListSheet({
    super.key,
    required this.title,
    required this.transactions,
    required this.isExpense,
    this.categoryIcons = const {},
    this.categoryLabels = const {},
  });

  static void show({
    required BuildContext context,
    required String title,
    required List<TransactionEntity> transactions,
    required bool isExpense,
    Map<String, IconData> categoryIcons = const {},
    Map<String, String> categoryLabels = const {},
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportTransactionListSheet(
        title: title,
        transactions: transactions,
        isExpense: isExpense,
        categoryIcons: categoryIcons,
        categoryLabels: categoryLabels,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final money = MoneyWriter.of(context);
    final total = transactions.fold<double>(0, (sum, t) => sum + t.amount);

    final withBalance = [
      for (final t in transactions)
        TransactionWithBalance(transaction: t, balanceAfter: 0),
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      money(total),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isExpense ? Colors.redAccent : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: withBalance.isEmpty
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
                    transactions: withBalance,
                    mode: isExpense ? FinanceMode.expense : FinanceMode.income,
                    categoryIcons: categoryIcons,
                    categoryLabels: categoryLabels,
                    showDayEndBalance: false,
                  ),
          ),
        ],
      ),
    );
  }
}
