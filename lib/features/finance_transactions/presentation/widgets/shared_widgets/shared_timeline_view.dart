import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:flutter/material.dart';

class SharedTimelineView extends StatefulWidget {
  final List<TransactionWithBalance> transactions;
  final FinanceMode mode;
  final bool showBalanceAfter;

  const SharedTimelineView({
    super.key,
    required this.transactions,
    this.mode = FinanceMode.compare,
    this.showBalanceAfter = true,
  });

  @override
  State<SharedTimelineView> createState() => _SharedTimelineViewState();
}

class _SharedTimelineViewState extends State<SharedTimelineView> {
  final Map<DateTime, bool> _expandedStates = {};

  @override
  Widget build(BuildContext context) {
    // Veri İşleme (Mevcut mantık korundu)
    final filteredTransactions = widget.mode == FinanceMode.compare
        ? widget.transactions
        : widget.transactions
            .where((item) => widget.mode == FinanceMode.income
                ? item.transaction.isIncome
                : item.transaction.isExpense)
            .toList();

    final grouped = <DateTime, List<TransactionWithBalance>>{};
    for (var item in filteredTransactions) {
      final date = DateTime(
        item.transaction.date.year,
        item.transaction.date.month,
        item.transaction.date.day,
      );
      grouped.putIfAbsent(date, () => []).add(item);
    }
    // Başlangıçta hepsi kapalı olsun
    for (var date in grouped.keys) {
      _expandedStates.putIfAbsent(date, () => false);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final items = grouped[date]!;
        final isExpanded = _expandedStates[date] ?? true;

        return Stack(
          children: [
            // 1. ADIM: Dinamik Sol Çizgi (Overflow yapmaz çünkü Stack içinde)
            Positioned(
              left: 15,
              top: 40,
              bottom: 0,
              child: Container(
                width: 2,
                color: index == sortedDates.length - 1
                    ? Colors.transparent // Son elemanın alt çizgisi yok
                    : widget.mode.primaryColor.withValues(alpha: 0.2),
              ),
            ),

            // 2. ADIM: Ana İçerik
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarih ve Node Satırı
                _buildDateHeaderRow(date, items, isExpanded),

                // İşlemler Listesi
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return SizeTransition(
                      sizeFactor: animation,
                      axisAlignment: -1, // Yukarıdan aşağıya pürüzsüz açılış
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: isExpanded
                      ? Padding(
                          key: ValueKey('list_$date'),
                          padding: const EdgeInsets.only(
                              left: 42, top: 4, bottom: 20),
                          child: Column(
                            children: items
                                .map((item) => _buildTransactionNode(item))
                                .toList(),
                          ),
                        )
                      : const SizedBox(key: ValueKey('empty'), height: 16),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Tarih Başlığı ve Yuvarlak Node (Düğüm) bir arada
  Widget _buildDateHeaderRow(
      DateTime date, List<TransactionWithBalance> items, bool isExpanded) {
    final dailyIncome = items
        .where((e) => e.transaction.isIncome)
        .fold(0.0, (sum, e) => sum + e.transaction.amount);
    final dailyExpense = items
        .where((e) => e.transaction.isExpense)
        .fold(0.0, (sum, e) => sum + e.transaction.amount);
    final dailyNet = dailyIncome - dailyExpense;

    return GestureDetector(
      onTap: () => setState(() => _expandedStates[date] = !isExpanded),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Timeline Node (Yuvarlak)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: widget.mode.primaryColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: widget.mode.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                  )
                ],
              ),
              child: Center(
                child: Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.mode.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Başlık ve Özet
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppFormatters.dateLong.format(date),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  _buildDailySummary(dailyIncome, dailyExpense, dailyNet),
                ],
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummary(double income, double expense, double net) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(25)),
        color: Colors.blueGrey.shade50,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Günün raporu :",
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          Text(AppFormatters.currency.format(income),
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.green,
                  fontWeight: FontWeight.w600)),
          Text(AppFormatters.currency.format(expense),
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                  fontWeight: FontWeight.w600)),
          Text(AppFormatters.currency.format(net),
              style: TextStyle(
                  fontSize: 11,
                  color: net >= 0 ? Colors.blue : Colors.orange,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // İşlem Kartı (Node) - Görsel Tasarım
  Widget _buildTransactionNode(TransactionWithBalance item) {
    final t = item.transaction;
    final color = t.isIncome ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                t.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color)),
                    Text(t.tag,
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Text(
                '${t.isIncome ? '+' : '-'}${AppFormatters.currency.format(t.amount)}',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13, color: color),
              ),
            ],
          ),
          if (widget.showBalanceAfter) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'İşlem sonrası : ',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    AppFormatters.currency.format(item.balanceAfter),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          item.balanceAfter >= 0 ? Colors.blue : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
