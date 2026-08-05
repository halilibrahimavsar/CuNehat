import 'package:cunehat/features/debt_and_receivable/presentation/pages/debt_history_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_insights_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_report_page.dart';
import 'package:cunehat/features/investments/presentation/pages/investment_detail_page.dart';
import 'package:cunehat/features/main_feature/factories/sub_view_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubViewFactory', () {
    const userId = 'user_123';
    const walletId = 'wallet_456';
    const walletCurrency = 'USD';
    const factory = SubViewFactory(
      userId: userId,
      walletId: walletId,
      walletCurrency: walletCurrency,
    );

    test(
        'createSubViewsForState returns InvestmentDetailPage for savedMoney state',
        () {
      final views = factory.createSubViewsForState('savedMoney');
      expect(views.length, 1);
      expect(views[0], isA<InvestmentDetailPage>());

      final page = views[0] as InvestmentDetailPage;
      expect(page.userId, userId);
      expect(page.walletId, walletId);
      expect(page.key, const ValueKey('invDetail-wallet_456'));
    });

    test(
        'createSubViewsForState returns transaction pages for transactions state',
        () {
      final views = factory.createSubViewsForState('transactions');
      expect(views.length, 2);

      expect(views[0], isA<TransactionInsightsPage>());
      final insightsPage = views[0] as TransactionInsightsPage;
      expect(insightsPage.userId, userId);
      expect(insightsPage.walletId, walletId);
      expect(insightsPage.key, const ValueKey('txInsights-wallet_456'));

      expect(views[1], isA<TransactionReportPage>());
      final reportPage = views[1] as TransactionReportPage;
      expect(reportPage.userId, userId);
      expect(reportPage.walletId, walletId);
      expect(reportPage.key, const ValueKey('txReport-wallet_456'));
    });

    test('createSubViewsForState returns DebtHistoryPage for debt state', () {
      final views = factory.createSubViewsForState('debt');
      expect(views.length, 1);
      expect(views[0], isA<DebtHistoryPage>());

      final page = views[0] as DebtHistoryPage;
      expect(page.userId, userId);
      expect(page.walletId, walletId);
      expect(page.key, const ValueKey('debtHistory-wallet_456'));
      // Geçmişteki tutarlar cüzdanın kendi biriminde yazılmalı; birim
      // fabrikadan geçmezse sayfa sessizce TL sembolüne düşerdi.
      expect(page.walletCurrency, walletCurrency);
    });

    test('createSubViewsForState returns empty list for unknown state', () {
      final views = factory.createSubViewsForState('unknown');
      expect(views, isEmpty);
    });
  });
}
