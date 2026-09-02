import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/detailed_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Verilen işlem listesini gösteren sade alt sayfa.
///
/// **Grubun kimliği, üye KAYIT KİMLİKLERİDİR.** "En çok harcanan yer"
/// grubunun kategori karşılığı yok (kümeleme metin benzerliğinden geliyor),
/// bu yüzden liste bloc her değiştiğinde yeniden KÜMELENMEZ: bir işlem
/// silinince trie yeniden kurulsa gruplar birleşip ayrılabilir ve açık liste
/// sessizce başka bir kaleme kayardı. Bunun yerine açılışta yakalanan kimlik
/// kümesi sabit kalır, satırların İÇERİĞİ defterden tazelenir.
///
/// Sonuç: silinen üye listeden düşer, düzenlenen üye yeni hâliyle görünür,
/// başlıktaki toplam ikisini de izler. Karşılığında, sayfa açıkken eklenen
/// yeni bir işlem gruba KATILMAZ — grup yeniden kümelenmediği için. Sayfa
/// kapanıp yeniden açıldığında kart zaten güncel gruplarla çizilir.
///
/// Eskiden liste tamamen SABİTTİ: cihazda silinen bir işlem bakiyeyi ve
/// arkadaki raporu güncelliyor ama bu sayfada duruyordu.
class ReportTransactionListSheet extends StatelessWidget {
  final String title;

  /// Sayfa açılırken yakalanan üyeler; kimlik kaynağı budur.
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
    // Modal route sayfanın provider'ının altında değil, Overlay'de kardeşi
    // olarak açılır → bloc elle taşınmalı. Taşınmazsa `context.read` uygulama
    // seviyesindeki BAŞKA bir örneği bulur: sayfa içindeki silme/düzenleme
    // raporun bloc'unu hiç görmez.
    final transactionBloc = context.read<TransactionBloc>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: transactionBloc,
        child: ReportTransactionListSheet(
          title: title,
          transactions: transactions,
          isExpense: isExpense,
          categoryIcons: categoryIcons,
          categoryLabels: categoryLabels,
        ),
      ),
    );
  }

  /// Açılıştaki üyeleri defterin güncel hâliyle eşler.
  ///
  /// Sıra korunur (grup zaten sıralı geldi). Kimliği olmayan kayıt defterde
  /// aranamaz; olduğu gibi bırakılır.
  List<TransactionEntity> _liveMembers(List<TransactionEntity> ledger) {
    final byId = <String, TransactionEntity>{
      for (final t in ledger)
        if (t.id != null) t.id!: t,
    };
    return [
      for (final snapshot in transactions)
        if (snapshot.id == null)
          snapshot
        else if (byId[snapshot.id!] case final live?)
          live,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) =>
          _buildSheet(context, _liveMembers(state.currentTransactions)),
    );
  }

  Widget _buildSheet(
      BuildContext context, List<TransactionEntity> transactions) {
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
