import 'package:cunehat/features/debt_and_receivable/presentation/pages/debt_history_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_detail_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_pending_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_report_page.dart';
import 'package:cunehat/features/investments/presentation/pages/investment_detail_page.dart';
import 'package:cunehat/features/main_feature/factories/sub_view_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubViewFactory', () {
    const userId = 'user_123';
    const walletId = 'wallet_456';
    const factory = SubViewFactory(userId: userId, walletId: walletId);

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
      expect(views.length, 3);

      expect(views[0], isA<TransactionDetailPage>());
      final detailPage = views[0] as TransactionDetailPage;
      expect(detailPage.userId, userId);
      expect(detailPage.walletId, walletId);
      expect(detailPage.key, const ValueKey('txDetail-wallet_456'));

      expect(views[1], isA<TransactionReportPage>());
      final reportPage = views[1] as TransactionReportPage;
      expect(reportPage.userId, userId);
      expect(reportPage.walletId, walletId);
      expect(reportPage.key, const ValueKey('txReport-wallet_456'));

      expect(views[2], isA<TransactionPendingPage>());
      final pendingPage = views[2] as TransactionPendingPage;
      expect(pendingPage.userId, userId);
      expect(pendingPage.walletId, walletId);
      expect(pendingPage.key, const ValueKey('txPending-wallet_456'));
    });

    test('createSubViewsForState returns DebtHistoryPage for debt state', () {
      final views = factory.createSubViewsForState('debt');
      expect(views.length, 1);
      expect(views[0], isA<DebtHistoryPage>());

      final page = views[0] as DebtHistoryPage;
      expect(page.userId, userId);
      expect(page.walletId, walletId);
      expect(page.key, const ValueKey('debtHistory-wallet_456'));
    });

    test('createSubViewsForState returns empty list for unknown state', () {
      final views = factory.createSubViewsForState('unknown');
      expect(views, isEmpty);
    });
  });
}
