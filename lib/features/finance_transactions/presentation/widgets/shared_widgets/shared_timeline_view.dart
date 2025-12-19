// ignore_for_file: deprecated_member_use

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/shared_widgets/dismissable_widget.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/shared_widgets/shared_transaction_card.dart';
import 'package:flutter/material.dart';

class SharedTimelineView extends StatelessWidget {
  final List<TransactionWithBalance> transactions;

  const SharedTimelineView({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final grouped = <DateTime, List<TransactionWithBalance>>{};
    for (var item in transactions) {
      final date = DateTime(
        item.transaction.date.year,
        item.transaction.date.month,
        item.transaction.date.day,
      );
      grouped.putIfAbsent(date, () => []).add(item);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final items = grouped[date]!;

        // --- GÜNLÜK RAPOR HESAPLAMA ---
        final dailyIncome = items
            .where((e) => e.transaction.isIncome)
            .fold(0.0, (sum, e) => sum + e.transaction.amount);
        final dailyExpense = items
            .where((e) => e.transaction.isExpense)
            .fold(0.0, (sum, e) => sum + e.transaction.amount);
        final dailyNet = dailyIncome - dailyExpense;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sol Taraftaki Timeline Hattı
              TimeLineDateView(
                  date: date,
                  isFirst: index == 0,
                  isLast: index == sortedDates.length - 1),

              // Sağ Taraftaki İçerik (Rapor + İşlemler)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 📊 GÜNLÜK MİNİ RAPOR PANELİ
                      _buildDailyReportCard(
                        dailyIncome,
                        dailyExpense,
                        dailyNet,
                      ),

                      const SizedBox(height: 12),

                      // İşlem Kartları
                      ...items.map((item) => DismissableWidget(
                          item: item,
                          child: SharedTransactionCard(
                            context: context,
                            item: item,
                          ))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyReportCard(double income, double expense, double net) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade100.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniStat(Icons.trending_up, Colors.green, income),
          _buildMiniStat(Icons.trending_down, Colors.red, expense),
          _buildMiniStat(Icons.account_balance,
              net >= 0 ? Colors.blue.shade700 : Colors.orange.shade700, net,
              isBold: true),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, Color color, double amount,
      {bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          '${amount.toStringAsFixed(0)} ₺',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class TimeLineDateView extends StatelessWidget {
  const TimeLineDateView({
    super.key,
    required this.date,
    required this.isFirst,
    required this.isLast,
  });

  final DateTime date;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          // Üst Çizgi (İlk eleman değilse)
          Container(
            width: 2,
            height: 10,
            color: isFirst ? Colors.transparent : Colors.blue.withOpacity(0.2),
          ),
          // Tarih Balonu
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  date.day.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  AppFormatters.dateShort.format(date), // örn: "Ara"
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Alt Çizgi (Sürekli Hat)
          Expanded(
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blue.withOpacity(0.5),
                    isLast ? Colors.transparent : Colors.blue.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
