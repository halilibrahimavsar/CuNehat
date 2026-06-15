import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_pending_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      locale: const Locale('tr'),
      home: child,
    );
  }

  testWidgets('renders TransactionPendingPage without AppBar by default',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionPendingPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    // Verify no app bar is shown
    expect(find.byType(AppBar), findsNothing);

    // Verify main content
    expect(find.text('Tüm İşlemleriniz Güncel'), findsOneWidget);
    expect(
      find.textContaining('Bekleyen çevrimdışı işlem bulunmuyor'),
      findsOneWidget,
    );

    // Verify sync icon
    expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
  });

  testWidgets('renders TransactionPendingPage with AppBar when showAppBar is true',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionPendingPage(
          userId: 'user_123',
          walletId: 'wallet_123',
          showAppBar: true,
        ),
      ),
    );

    // Verify AppBar exists and has the correct title
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Bekleyen İşlemler'), findsOneWidget);

    // Verify main content still exists
    expect(find.text('Tüm İşlemleriniz Güncel'), findsOneWidget);
    expect(
      find.textContaining('Bekleyen çevrimdışı işlem bulunmuyor'),
      findsOneWidget,
    );
  });
}
