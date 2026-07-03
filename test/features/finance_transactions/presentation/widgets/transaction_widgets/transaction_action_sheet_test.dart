import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_action_sheet.dart';
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
      home: Scaffold(
        body: child,
      ),
    );
  }

  final txExpense = TransactionEntity(
    id: 'tx_123',
    userId: 'user_123',
    walletId: 'wallet_123',
    title: 'Market Shopping',
    tag: 'Yemek',
    amount: 150.0,
    date: DateTime(2026, 6, 13),
    type: TransactionTypeModel.expense,
    isSystem: false,
  );

  final txIncome = TransactionEntity(
    id: 'tx_456',
    userId: 'user_123',
    walletId: 'wallet_123',
    title: 'Salary',
    tag: 'Maaş',
    amount: 2000.0,
    date: DateTime(2026, 6, 13),
    type: TransactionTypeModel.income,
    isSystem: false,
  );

  final txSystem = TransactionEntity(
    id: 'tx_789',
    userId: 'user_123',
    walletId: 'wallet_123',
    title: 'Borç Ödemesi',
    tag: 'Borç Ödemesi',
    amount: 300.0,
    date: DateTime(2026, 6, 13),
    type: TransactionTypeModel.expense,
    isSystem: true,
  );

  testWidgets('renders TransactionActionSheet with correct details for expense',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        TransactionActionSheet(
          transaction: txExpense,
          accent: Colors.red,
        ),
      ),
    );

    // Verify title is rendered
    expect(find.text('Market Shopping'), findsOneWidget);

    // Verify expense indicator icon (arrow_downward_rounded)
    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);

    // Verify actions are rendered with correct Turkish titles
    expect(find.text('Düzenle'), findsOneWidget);
    expect(find.text('İşlemi Sil'), findsOneWidget);
  });

  testWidgets('renders TransactionActionSheet with correct details for income',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        TransactionActionSheet(
          transaction: txIncome,
          accent: Colors.green,
        ),
      ),
    );

    // Verify title is rendered
    expect(find.text('Salary'), findsOneWidget);

    // Verify income indicator icon (arrow_upward_rounded)
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
  });

  testWidgets(
      'renders read-only notice instead of Edit/Delete for system transaction',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        TransactionActionSheet(
          transaction: txSystem,
          accent: Colors.red,
        ),
      ),
    );

    // Verify title is still rendered
    expect(find.text('Borç Ödemesi'), findsWidgets);

    // Düzenle/Sil dokunulabilir satırları hiç render edilmemeli.
    expect(find.text('Düzenle'), findsNothing);
    expect(find.text('İşlemi Sil'), findsNothing);

    // Bunun yerine bilgi notu görünmeli (detay sayfasıyla aynı l10n metni).
    expect(
      find.textContaining('Bu işlem otomatik oluşturuldu'),
      findsOneWidget,
    );
  });

  testWidgets('tapping Edit option pops with TransactionAction.edit',
      (WidgetTester tester) async {
    TransactionAction? selectedAction;

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                selectedAction = await TransactionActionSheet.show(
                  context,
                  transaction: txExpense,
                  accent: Colors.red,
                );
              },
              child: const Text('Show Sheet'),
            );
          },
        ),
      ),
    );

    // Open sheet
    await tester.tap(find.text('Show Sheet'));
    await tester.pumpAndSettle();

    // Verify sheet is open
    expect(find.byType(TransactionActionSheet), findsOneWidget);

    // Tap edit
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();

    // Verify sheet is closed and action is edit
    expect(find.byType(TransactionActionSheet), findsNothing);
    expect(selectedAction, TransactionAction.edit);
  });

  testWidgets('tapping Delete option pops with TransactionAction.delete',
      (WidgetTester tester) async {
    TransactionAction? selectedAction;

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                selectedAction = await TransactionActionSheet.show(
                  context,
                  transaction: txExpense,
                  accent: Colors.red,
                );
              },
              child: const Text('Show Sheet'),
            );
          },
        ),
      ),
    );

    // Open sheet
    await tester.tap(find.text('Show Sheet'));
    await tester.pumpAndSettle();

    // Verify sheet is open
    expect(find.byType(TransactionActionSheet), findsOneWidget);

    // Tap delete
    await tester.tap(find.text('İşlemi Sil'));
    await tester.pumpAndSettle();

    // Verify sheet is closed and action is delete
    expect(find.byType(TransactionActionSheet), findsNothing);
    expect(selectedAction, TransactionAction.delete);
  });
}
