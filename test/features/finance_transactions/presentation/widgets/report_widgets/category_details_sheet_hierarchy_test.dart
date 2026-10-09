import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/category_details_bottom_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

class _MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

/// Kırılım KÖK seviyede toplanır; alt kategoriler yalnız `children` içinde
/// durur. Detay sayfası dokunulan dilimi eskiden yalnız kök listesinde
/// arıyordu → alt kategoriye dokunan kullanıcı 0 ₺ ve "işlem yok" görüyordu.
void main() {
  setUpAll(() => Intl.defaultLocale = 'tr');

  final day = DateTime(2026, 9, 15);
  final range = DateTimeRange(
    start: DateTime(2026, 9, 1),
    end: DateTime(2026, 9, 30, 23, 59, 59),
  );

  TransactionEntity tx(String id, String tag, double amount, String title) =>
      TransactionEntity(
        id: id,
        userId: 'u',
        walletId: 'w',
        title: title,
        tag: tag,
        amount: amount,
        date: day,
        type: TransactionTypeModel.expense,
      );

  // Fatura (kök) › Elektrik, Su; Fatura'nın kendisine de bir kayıt.
  final ledger = [
    tx('e1', 'elektrik', 300, 'Elektrik faturası'),
    tx('s1', 'su', 120, 'Su faturası'),
    tx('f1', 'fatura', 50, 'Genel fatura'),
    tx('m1', 'market', 900, 'Market alışverişi'),
  ];
  const roots = {
    'elektrik': 'fatura',
    'su': 'fatura',
    'fatura': 'fatura',
    'market': 'market',
  };
  const labels = {
    'elektrik': 'Elektrik',
    'su': 'Su',
    'fatura': 'Fatura',
    'market': 'Market',
  };

  ReportCategoryDataBuilder builder({List<BudgetEntity> budgets = const []}) =>
      ReportCategoryDataBuilder(
        range: range,
        budgets: budgets,
        otherCategoryLabel: 'Diğer',
        rootIndex: roots,
        includeSystemMovements: false,
      );

  late _MockTransactionBloc bloc;

  setUp(() {
    bloc = _MockTransactionBloc();
    when(() => bloc.state).thenReturn(TransactionLoaded(
      groupedTransactions: {day: ledger},
      allTransactions: ledger,
    ));
  });

  Future<void> openSheet(
    WidgetTester tester,
    CategoryData slice, {
    ReportSliceMode mode = ReportSliceMode.full,
    List<BudgetEntity> budgets = const [],
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(BlocProvider<AmountVisibilityCubit>(
      create: (_) => AmountVisibilityCubit(),
      child: BlocProvider<TransactionBloc>.value(
        value: bloc,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          locale: const Locale('tr'),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => CategoryDetailsBottomSheet.show(
                  context: context,
                  initialCategory: slice,
                  isExpense: true,
                  sliceMode: mode,
                  categoryIcons: const {},
                  categoryLabels: labels,
                  dataBuilder: builder(budgets: budgets),
                  sourceOf: (all) => all,
                ),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
  }

  CategoryData childOf(String root, String child, {bool direct = false}) {
    final full = builder().buildFull(ledger, isExpense: true);
    final parent = full.firstWhere((c) => c.name == root);
    return parent.children
        .firstWhere((c) => c.name == child && c.isDirect == direct);
  }

  group('findSlice', () {
    test('kök, alt kategori ve doğrudan dilimi ayrı ayrı bulur', () {
      final full = builder().buildFull(ledger, isExpense: true);
      final probe = CategoryData('su', 0, const [], Colors.black);
      expect(
          ReportCategoryDataBuilder.findSlice(full, probe)?.totalAmount, 120);

      final direct =
          CategoryData('fatura', 0, const [], Colors.black, isDirect: true);
      final hit = ReportCategoryDataBuilder.findSlice(full, direct)!;
      expect(hit.isDirect, isTrue);
      expect(hit.totalAmount, 50);

      final root = CategoryData('fatura', 0, const [], Colors.black);
      expect(ReportCategoryDataBuilder.findSlice(full, root)?.totalAmount, 470);
    });
  });

  testWidgets('REGRESYON: alt kategoriye dokununca işlemleri DOLU açılır',
      (tester) async {
    await openSheet(tester, childOf('fatura', 'elektrik'));

    expect(find.text('Elektrik faturası'), findsOneWidget);
    expect(find.text('Su faturası'), findsNothing);
    expect(find.text('Bu kategoriye ait işlem bulunmuyor.'), findsNothing);
  });

  testWidgets('doğrudan dilim yalnız kökün KENDİ işlemlerini gösterir',
      (tester) async {
    await openSheet(tester, childOf('fatura', 'fatura', direct: true));

    expect(find.text('Genel fatura'), findsOneWidget);
    expect(find.text('Elektrik faturası'), findsNothing);
    expect(find.textContaining('Doğrudan'), findsWidgets);
  });

  testWidgets('kök detayındaki alt satıra dokunmak o alt kalemi açar',
      (tester) async {
    final full = builder().buildFull(ledger, isExpense: true);
    await openSheet(tester, full.firstWhere((c) => c.name == 'fatura'));
    // Kökün detayı alt ağacın tamamını listeler.
    expect(find.text('Su faturası'), findsOneWidget);
    expect(find.text('Elektrik faturası'), findsOneWidget);

    // Kırılım satırı başlıkta, işlem kartlarından ÖNCE gelir (kartlar da
    // kategori adını yazar; onlara dokunmak işlem detayını açar).
    await tester.tap(find.text('Su').first);
    await tester.pumpAndSettle();

    final top = find.byType(CategoryDetailsBottomSheet).last;
    expect(find.descendant(of: top, matching: find.text('Su faturası')),
        findsOneWidget);
    expect(find.descendant(of: top, matching: find.text('Elektrik faturası')),
        findsNothing);
  });

  testWidgets('aşılan bütçe etiketi %100\'de KIRPILMAZ', (tester) async {
    // Su: 120 harcandı, limit 100 → %120.
    final budget = BudgetEntity(
      categoryId: 'su',
      walletId: 'w',
      limitAmount: 100,
      spentAmount: 0,
    );
    await openSheet(tester, childOf('fatura', 'su'), budgets: [budget]);

    expect(find.textContaining('%120'), findsWidgets);
    expect(find.textContaining('%100'), findsNothing);
  });
}
