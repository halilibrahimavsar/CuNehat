// ignore_for_file: deprecated_member_use

import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:cunehat/repository/models/wallet_model.dart';
import 'package:cunehat/repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CompareView extends StatelessWidget {
  final Map<DateTime, List<Income>> incomeData;
  final Map<DateTime, List<Expense>> expenseData;

  CompareView({
    super.key,
    required this.incomeData,
    required this.expenseData,
  });

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<DataRepository>();
    final pendingCount = repository.getPendingSyncCount();

    // ✅ DÜZELTME: Aktif cüzdanı al
    return FutureBuilder<Wallet?>(
      future: repository.getActiveWallet(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Hata: ${snapshot.error}'),
              ],
            ),
          );
        }

        // No wallet found (should not happen in normal flow)
        final activeWallet = snapshot.data;
        if (activeWallet == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wallet, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('Aktif cüzdan bulunamadı'),
              ],
            ),
          );
        }

        // ✅ DÜZELTME: Aktif cüzdanın bakiyesini kullan
        final currentBalance = activeWallet.balance;
        final combinedList = _createCombinedList();

        return Container(
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
            child: Column(
              children: [
                // ✅ DÜZELTME: Cüzdan bilgisiyle birlikte bakiye göster
                _buildBalanceHeader(
                  context,
                  currentBalance,
                  pendingCount,
                  activeWallet,
                ),

                // İŞLEM LİSTESİ
                Expanded(
                  child: combinedList.isEmpty
                      ? _buildEmptyState()
                      : _buildTransactionList(combinedList, currentBalance),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ DÜZELTME: Wallet parametresi eklendi
  Widget _buildBalanceHeader(
    BuildContext context,
    double balance,
    int pendingCount,
    Wallet wallet, // ➕ YENİ PARAMETRE
  ) {
    final formatCurrency = NumberFormat.currency(symbol: "₺", decimalDigits: 2);
    // final walletColor = WalletColors.hexToColor(wallet.colorHex);

    return ValueListenableBuilder<bool>(
      valueListenable: _isBalanceVisible,
      builder: (context, isVisible, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: balance >= 0
                  ? [Colors.green.shade400, Colors.green.shade600]
                  : [Colors.red.shade400, Colors.red.shade600],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ➕ YENİ: Aktif Cüzdan Bilgisi
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      WalletIcons.getIcon(wallet.iconName),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (wallet.isActive)
                          Text(
                            'Varsayılan Cüzdan',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (pendingCount > 0)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.sync,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$pendingCount bekliyor",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // GÖZ BUTONU
                      IconButton(
                        onPressed: () {
                          _isBalanceVisible.value = !_isBalanceVisible.value;
                        },
                        icon: Icon(
                          isVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white70,
                          size: 26,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // BAKİYE GÖSTERGE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Mevcut Bakiye",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isVisible ? formatCurrency.format(balance) : "••••••",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    balance >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: Colors.white70,
                    size: 32,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // DURUM BİLGİSİ
              Row(
                children: [
                  Icon(
                    balance >= 0 ? Icons.check_circle : Icons.warning,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    balance >= 0 ? "Pozitif Bakiye" : "Negatif Bakiye",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  if (!isVisible)
                    Text(
                      "Bakiye gizli",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Balance görünürlük state'i
  final ValueNotifier<bool> _isBalanceVisible = ValueNotifier<bool>(true);

  List<CombinedTransaction> _createCombinedList() {
    final List<CombinedTransaction> combinedList = [];

    incomeData.values.expand((list) => list).forEach((income) {
      combinedList.add(CombinedTransaction(date: income.date, item: income));
    });

    expenseData.values.expand((list) => list).forEach((expense) {
      combinedList.add(CombinedTransaction(date: expense.date, item: expense));
    });

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

  Widget _buildTransactionList(
      List<CombinedTransaction> combinedList, double initialBalance) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isBalanceVisible,
      builder: (context, isBalanceVisible, child) {
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
                  Icon(Icons.history, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    "Son İşlemler",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  // Her işlem için o anki bakiyeyi hesapla
                  double balanceAtThisPoint = initialBalance;

                  // Bu işleme kadar olan tüm işlemleri tersine uygula
                  for (int i = 0; i < index; i++) {
                    final transaction = combinedList[i];
                    if (transaction.item is Income) {
                      balanceAtThisPoint -= (transaction.item as Income).amount;
                    } else if (transaction.item is Expense) {
                      balanceAtThisPoint +=
                          (transaction.item as Expense).amount;
                    }
                  }

                  return _buildTransactionItem(
                    combinedList[index],
                    index,
                    balanceAtThisPoint,
                    AppFormatters.currency,
                    isBalanceVisible: isBalanceVisible,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(
    CombinedTransaction transaction,
    int index,
    double balanceAfter,
    NumberFormat formatCurrency, {
    required bool isBalanceVisible,
  }) {
    final item = transaction.item;
    final isIncome = item is Income;
    final amount = isIncome ? (item).amount : (item as Expense).amount;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
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
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                      AppFormatters.dateLong.format(item.date),
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
                      isBalanceVisible
                          ? "${isIncome ? '+' : '-'}${amount.toStringAsFixed(2)} ₺"
                          : "••••",
                      style: TextStyle(
                        color: isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
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
              // İŞLEM SONRASI BAKİYE
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: balanceAfter >= 0
                      ? Colors.green.withOpacity(0.05)
                      : Colors.red.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "İşlem sonrası bakiye:",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      isBalanceVisible
                          ? formatCurrency.format(balanceAfter)
                          : "••••••",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isBalanceVisible
                            ? (balanceAfter >= 0
                                ? Colors.green[700]
                                : Colors.red[700])
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
