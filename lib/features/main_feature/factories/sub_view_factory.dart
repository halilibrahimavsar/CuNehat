import 'package:cunehat/features/debt_and_receivable/presentation/pages/debt_history_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_detail_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_pending_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_report_page.dart';
import 'package:cunehat/features/investments/presentation/pages/investment_detail_page.dart';
import 'package:flutter/material.dart';

/// Factory for creating sub views
///
/// Returns widgets based on index:
/// - Index 0: MainView (handled separately)
/// - Index 1+: SubViews
class SubViewFactory {
  final String userId;
  final String walletId;

  const SubViewFactory({
    required this.userId,
    required this.walletId,
  });

  /// Create all subviews for a slider state
  List<Widget> createSubViewsForState(String stateType) {
    return switch (stateType) {
      'savedMoney' => [
          InvestmentDetailPage(userId: userId, walletId: walletId),
        ],
      'transactions' => [
          TransactionDetailPage(userId: userId, walletId: walletId),
          TransactionReportPage(userId: userId, walletId: walletId),
          TransactionPendingPage(userId: userId, walletId: walletId),
        ],
      'debt' => [
          DebtHistoryPage(userId: userId, walletId: walletId),
        ],
      _ => [],
    };
  }
}
