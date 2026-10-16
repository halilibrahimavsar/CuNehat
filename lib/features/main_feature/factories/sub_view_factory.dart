import 'package:cunehat/features/debt_and_receivable/presentation/pages/debt_history_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_insights_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_report_page.dart';
import 'package:cunehat/features/forecast/presentation/pages/forecast_page.dart';
import 'package:cunehat/features/investments/presentation/pages/investment_history_page.dart';
import 'package:flutter/material.dart';

/// Factory for creating sub views
///
/// Returns widgets based on index:
/// - Index 0: MainView (handled separately)
/// - Index 1+: SubViews
class SubViewFactory {
  final String userId;
  final String walletId;

  /// Cüzdanın para birimi; alt görünümlerdeki tutarların gösterimi buna bağlı
  /// (borç/alacak geçmişi kaydın kendi cüzdanının biriminde yazar).
  final String walletCurrency;

  /// Birikim ve borç alt görünümlerinin cüzdanı. Aktif cüzdan bir KARTSA
  /// sahibi (kartın yatırımı/borç kaydı olmaz; bkz. `card_family.dart`);
  /// verilmezse [walletId].
  final String? accountWalletId;

  /// [accountWalletId]'nin birimi; verilmezse [walletCurrency].
  final String? accountCurrency;

  const SubViewFactory({
    required this.userId,
    required this.walletId,
    required this.walletCurrency,
    this.accountWalletId,
    this.accountCurrency,
  });

  String get _accountId => accountWalletId ?? walletId;
  String get _accountCurrency => accountCurrency ?? walletCurrency;

  /// Create all subviews for a slider state.
  ///
  /// walletId'li ValueKey ŞART: sayfalar bloc'larını `BlocProvider(create:)`
  /// ile kurar; key olmadan Flutter cüzdan değişiminde Element'i yeniden
  /// kullanır ve eski cüzdanın bloc'u/verisi ekranda kalır.
  List<Widget> createSubViewsForState(String stateType) {
    return switch (stateType) {
      'savedMoney' => [
          InvestmentHistoryPage(
              key: ValueKey('invHistory-$_accountId'),
              userId: userId,
              walletId: _accountId),
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
          ForecastPage(
              key: ValueKey('txForecast-$walletId'),
              userId: userId,
              walletId: walletId),
        ],
      'debt' => [
          DebtHistoryPage(
              key: ValueKey('debtHistory-$_accountId'),
              userId: userId,
              walletId: _accountId,
              walletCurrency: _accountCurrency),
        ],
      _ => [],
    };
  }
}
