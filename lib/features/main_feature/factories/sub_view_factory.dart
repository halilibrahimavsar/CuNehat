import 'package:cunehat/features/debt_and_receivable/presentation/pages/debt_history_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_insights_page.dart';
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

  /// Create all subviews for a slider state.
  ///
  /// walletId'li ValueKey ŞART: sayfalar bloc'larını `BlocProvider(create:)`
  /// ile kurar; key olmadan Flutter cüzdan değişiminde Element'i yeniden
  /// kullanır ve eski cüzdanın bloc'u/verisi ekranda kalır.
  List<Widget> createSubViewsForState(String stateType) {
    return switch (stateType) {
      'savedMoney' => [
          InvestmentDetailPage(
              key: ValueKey('invDetail-$walletId'),
              userId: userId,
              walletId: walletId),
        ],
      'transactions' => [
          TransactionInsightsPage(
              key: ValueKey('txInsights-$walletId'),
              userId: userId,
              walletId: walletId),
          TransactionReportPage(
              key: ValueKey('txReport-$walletId'),
              userId: userId,
              walletId: walletId),
          TransactionPendingPage(
              key: ValueKey('txPending-$walletId'),
              userId: userId,
              walletId: walletId),
        ],
      'debt' => [
          DebtHistoryPage(
              key: ValueKey('debtHistory-$walletId'),
              userId: userId,
              walletId: walletId),
        ],
      _ => [],
    };
  }
}
