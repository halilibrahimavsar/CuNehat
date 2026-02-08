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

  factory SubViewFactory.empty() =>
      const SubViewFactory(userId: '', walletId: '');

  void update({required String userId, required String walletId}) {
    // This factory is immutable, create new instance instead
  }

  /// Create view by index
  ///
  /// Index mapping for transactions slider:
  /// 0: MainView (not used here)
  /// 1: TransactionDetailPage
  /// 2: TransactionReportPage
  /// 3: TransactionPendingPage
  Widget createViewByIndex(int index) {
    return switch (index) {
      1 => TransactionDetailPage(userId: userId, walletId: walletId),
      2 => TransactionReportPage(userId: userId, walletId: walletId),
      3 => TransactionPendingPage(userId: userId, walletId: walletId),
      _ => const SizedBox.shrink(),
    };
  }

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
