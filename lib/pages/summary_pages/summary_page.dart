import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart';
import 'package:cunehat/pages/wallet_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// TODO: burada anapara eklenmeli ve her bir giriş çıkışta anapara değişmeli(anaparadan gider ve gelir eklenip cıkarılmalı). Ve tam ekran olması gerekli

class CompareView extends StatelessWidget {
  final Map<DateTime, List<Income>> incomeData;
  final Map<DateTime, List<Expense>> expenseData;

  const CompareView({
    super.key,
    required this.incomeData,
    required this.expenseData,
  });

  @override
  Widget build(BuildContext context) {
    final combinedList = _createCombinedList();

    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!.withOpacity(0.8),
            Colors.purple[50]!.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: combinedList.isEmpty
            ? _buildEmptyState()
            : _buildTransactionList(combinedList),
      ),
    );
  }

  List<CombinedTransaction> _createCombinedList() {
    final List<CombinedTransaction> combinedList = [];

    // Gelirleri ekle
    incomeData.values.expand((list) => list).forEach((income) {
      combinedList.add(CombinedTransaction(date: income.date, item: income));
    });

    // Giderleri ekle
    expenseData.values.expand((list) => list).forEach((expense) {
      combinedList.add(CombinedTransaction(date: expense.date, item: expense));
    });

    // Tarihe göre sırala (en yeni en üstte)
    combinedList.sort((a, b) => b.date.compareTo(a.date));

    return combinedList;
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.account_balance_wallet_outlined,
          size: 64,
          color: Colors.blue[300]!.withOpacity(0.6),
        ),
        const SizedBox(height: 16),
        Text(
          "Henüz işlem bulunmuyor",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Gelir veya gider ekleyerek başlayın",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList(List<CombinedTransaction> combinedList) {
    return Column(
      children: [
        // Başlık
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!.withOpacity(0.5)),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.compare_arrows, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                "İşlem Karşılaştırması",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${combinedList.length} işlem",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
        ),

        // İşlem Listesi
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: combinedList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _buildTransactionItem(combinedList[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(CombinedTransaction transaction, int index) {
    final item = transaction.item;
    final isIncome = item is Income;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, 0, 0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isIncome
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isIncome
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                color: isIncome ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMMMEd('tr_TR').format(item.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${isIncome ? '+' : '-'}${item.amount.toStringAsFixed(2)} ₺",
                  style: TextStyle(
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isIncome
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isIncome ? "Gelir" : "Gider",
                    style: TextStyle(
                      fontSize: 10,
                      color: isIncome ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CombinedTransaction {
  final DateTime date;
  final dynamic item;

  CombinedTransaction({required this.date, required this.item});
}
