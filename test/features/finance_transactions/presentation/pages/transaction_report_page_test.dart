import 'package:cunehat/core/shared/widgets/labeled_segment.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'package:cunehat/core/services/csv_service.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_report_page.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_trend.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_explorer.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_trend_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_budget_summary_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/category_details_bottom_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_daily_net_flow_chart.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_period_bar.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:intl/intl.dart';

class MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockOnboardingCoordinator extends Mock implements OnboardingCoordinator {}

class _MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

class _MockTxRepo extends Mock implements TransactionsRepository {}

class _MockCsvService extends Mock implements CsvService {}

void main() {
  // Para metni Intl.defaultLocale'e bakar; testte boş bırakılırsa intl onu
  // sessizce sistem locale'ine (genelde en_US) bağlar ve beklentiler
  // makineye göre kayar. Uygulamanın varsayılanına sabitliyoruz.
  setUpAll(() => Intl.defaultLocale = 'tr');

  late MockTransactionBloc mockTransactionBloc;
  late MockCategoryRepository mockCategoryRepository;
  late MockBudgetRepository mockBudgetRepository;
  late MockOnboardingCoordinator mockOnboardingCoordinator;

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(OnboardingFlow.shell);
    ShowcaseView.register(
      onFinish: () {},
      onDismiss: (_) {},
    );
  });

  setUp(() {
    mockTransactionBloc = MockTransactionBloc();
    mockCategoryRepository = MockCategoryRepository();
    mockBudgetRepository = MockBudgetRepository();
    mockOnboardingCoordinator = MockOnboardingCoordinator();

    getIt.registerSingleton<TransactionBloc>(mockTransactionBloc);
    getIt.registerSingleton<CategoryRepository>(mockCategoryRepository);
    // Sayfa, kategoriler değiştiğinde ikon/ad indeksini tazelemek için bu
    // kanala abone olur (bkz. CategoriesChangedNotifier).
    getIt.registerSingleton<CategoriesChangedNotifier>(
        CategoriesChangedNotifier());
    // Bütçeler Bütçeler sayfasından değiştirildiğinde rapor kendi kopyasını
    // tazeler (bkz. BudgetsChangedNotifier).
    getIt.registerSingleton<BudgetsChangedNotifier>(BudgetsChangedNotifier());
    getIt.registerSingleton<BudgetRepository>(mockBudgetRepository);
    getIt.registerSingleton<OnboardingCoordinator>(mockOnboardingCoordinator);

    when(() => mockCategoryRepository.getAllCategories())
        .thenAnswer((_) async => [
              ...await mockCategoryRepository.getCategories(true),
              ...await mockCategoryRepository.getCategories(false),
            ]);
    when(() => mockCategoryRepository.getCategories(true))
        .thenAnswer((_) async => [
              const CategoryEntity(
                id: 'Food',
                name: 'Food',
                iconName: 'fastfood',
                isExpense: true,
              ),
            ]);

    when(() => mockCategoryRepository.getCategories(false))
        .thenAnswer((_) async => [
              const CategoryEntity(
                id: 'Salary',
                name: 'Salary',
                iconName: 'attach_money',
                isExpense: false,
              ),
            ]);

    when(() => mockBudgetRepository.getBudgets(any()))
        .thenAnswer((_) async => const Right<Failure, List<BudgetEntity>>([]));

    when(() => mockOnboardingCoordinator.isSeen(any())).thenReturn(true);
  });

  tearDown(() {
    getIt.reset();
  });

  /// Zaman çizgisinin ölçüsünü seçer (Gider · Gelir · Net · Bakiye).
  Future<void> selectMetric(WidgetTester tester, String label) async {
    final cell = find.descendant(
      of: find.byType(LabeledSegment<TrendMetric>),
      matching: find.text(label),
    );
    await tester.ensureVisible(cell);
    await tester.pumpAndSettle();
    await tester.tap(cell);
    await tester.pumpAndSettle();
  }

  Widget buildTestableWidget(Widget child) {
    return BlocProvider<TransactionFilterCubit>(
        create: (_) => TransactionFilterCubit(),
        child: BlocProvider<AmountVisibilityCubit>(
          create: (_) => AmountVisibilityCubit(),
          child: MaterialApp(
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
          ),
        ));
  }

  testWidgets(
      'renders CircularProgressIndicator when loading and transactions empty',
      (WidgetTester tester) async {
    when(() => mockTransactionBloc.state)
        .thenReturn(const TransactionLoading(previousTransactions: []));

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionReportPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders empty state when transaction list is empty',
      (WidgetTester tester) async {
    when(() => mockTransactionBloc.state).thenReturn(
      const TransactionLoaded(
        groupedTransactions: {},
        allTransactions: [],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionReportPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rapor için kayıt yok'), findsOneWidget);
  });

  testWidgets('renders charts and summary cards when transactions are present',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final transactions = [
      TransactionEntity(
        id: 'tx_1',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Lunch',
        tag: 'Food',
        amount: 50.0,
        date: now,
        type: TransactionTypeModel.expense,
      ),
      TransactionEntity(
        id: 'tx_2',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Salary',
        tag: 'Salary',
        amount: 200.0,
        date: now,
        type: TransactionTypeModel.income,
      ),
    ];

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {now: transactions},
        allTransactions: transactions,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionReportPage(
          userId: 'user_123',
          walletId: 'wallet_123',
          showAppBar: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Kullanıcı isteği: açılışta ZAMAN ÇİZGİSİ (çizgi grafik) + GİDER.
    final trend = tester.widget<ReportTrendCard>(find.byType(ReportTrendCard));
    expect(trend.metric, TrendMetric.expense);
    expect(trend.asLine, isTrue);
    expect(
      find.descendant(
          of: find.byType(ReportTrendCard), matching: find.byType(LineChart)),
      findsOneWidget,
    );
    // Özet kutuları manşete katıldı: seçili ölçü büyük, diğerleri altında.
    expect(find.text('50,00 ₺'), findsWidgets);
    expect(find.textContaining('Gelir 200,00 ₺'), findsOneWidget);
    // Kategori keşfi gider tarafında açılır.
    final explorer = tester
        .widget<ReportCategoryExplorer>(find.byType(ReportCategoryExplorer));
    expect(explorer.isExpense, isTrue);
    expect(find.text('Giderler'), findsOneWidget);
  });

  testWidgets('çubuk görünümüne geçilebilir; Bakiye ölçüsü hep çizgidir',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final now = DateTime.now();
    final transactions = [
      TransactionEntity(
        id: 'tx_1',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Lunch',
        tag: 'Food',
        amount: 50.0,
        date: now,
        type: TransactionTypeModel.expense,
      ),
    ];
    when(() => mockTransactionBloc.state).thenReturn(TransactionLoaded(
      groupedTransactions: {now: transactions},
      allTransactions: transactions,
    ));
    await tester.pumpWidget(buildTestableWidget(const TransactionReportPage(
      userId: 'user_123',
      walletId: 'wallet_123',
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Çubuk görünümü'));
    await tester.pumpAndSettle();
    expect(find.byType(ReportDailyNetFlowChart), findsOneWidget);
    final bars = tester
        .widget<ReportDailyNetFlowChart>(find.byType(ReportDailyNetFlowChart));
    expect(bars.showExpense, isTrue);
    expect(bars.showIncome, isFalse,
        reason: 'Gider ölçüsünde gelir çubuğu yok');

    await selectMetric(tester, 'Bakiye');
    expect(find.byType(ReportDailyNetFlowChart), findsNothing);
    expect(find.byTooltip('Çubuk görünümü'), findsNothing);
  });

  testWidgets('Gelir ölçüsü seçilince kategori keşfi de GELİRE geçer',
      (WidgetTester tester) async {
    // Mod seçici varsayılan 800x600 görünümde katlamanın altında kalıyor;
    // dokunma isabet etmiyor.
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final now = DateTime.now();
    final transactions = [
      TransactionEntity(
        id: 'tx_1',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Lunch',
        tag: 'Food',
        amount: 50.0,
        date: now,
        type: TransactionTypeModel.expense,
      ),
      TransactionEntity(
        id: 'tx_2',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Salary',
        tag: 'Salary',
        amount: 200.0,
        date: now,
        type: TransactionTypeModel.income,
      ),
    ];

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {now: transactions},
        allTransactions: transactions,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionReportPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await selectMetric(tester, 'Gelir');

    final explorer = tester
        .widget<ReportCategoryExplorer>(find.byType(ReportCategoryExplorer));
    expect(explorer.isExpense, isFalse);
    expect(find.text('Gelirler'), findsOneWidget);

    // Net seçmek keşfi olduğu yerde bırakır.
    await selectMetric(tester, 'Net');
    expect(
      tester
          .widget<ReportCategoryExplorer>(find.byType(ReportCategoryExplorer))
          .isExpense,
      isFalse,
    );

    // Keşifte tarafı değiştirmek ölçüyü de taşır (Gider/Gelir'deyken).
    await selectMetric(tester, 'Gelir');
    final expenseChip = find.widgetWithText(ChoiceChip, 'Gider');
    await tester.ensureVisible(expenseChip);
    await tester.tap(expenseChip);
    await tester.pumpAndSettle();
    expect(
      tester.widget<ReportTrendCard>(find.byType(ReportTrendCard)).metric,
      TrendMetric.expense,
    );
  });

  testWidgets('opens DateRangePickerDialog on takvim düğmesi tap',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final now = DateTime.now();
    final tx = TransactionEntity(
      id: 'tx_dummy',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'Dummy',
      tag: 'Food',
      amount: 10.0,
      date: now,
      type: TransactionTypeModel.expense,
    );

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          now: [tx]
        },
        allTransactions: [tx],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionReportPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Dönem etiketine ("Eylül 2026") dokunmak hızlı seçenek menüsünü açar;
    // ayrı bir takvim düğmesi yok (bkz. TransactionPeriodBar).
    await tester.tap(find.descendant(
      of: find.byType(TransactionPeriodBar),
      matching: find.byType(InkWell),
    ));
    await tester.pumpAndSettle();

    // Tap Choose from calendar in the quick options sheet to open the dialog
    await tester.tap(find.text('Takvimden seç'));
    await tester.pumpAndSettle();

    // Verify DateRangePickerDialog is shown
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
  });

  testWidgets('groups minor categories (<3%) into Diğer',
      (WidgetTester tester) async {
    final now = DateTime.now();
    TransactionEntity expense(String id, String tag, double amount) =>
        TransactionEntity(
          id: id,
          userId: 'user_123',
          walletId: 'wallet_123',
          title: id,
          tag: tag,
          amount: amount,
          date: now,
          type: TransactionTypeModel.expense,
        );

    // İKİ küçük kategori: kovaya birden fazla kalem düştüğü için "Diğer"
    // gerçekten kurulur (tek kalem düşseydi kendi adıyla kalırdı — aşağıdaki
    // teste bakın).
    final transactions = [
      expense('tx_large', 'Main', 1000.0),
      expense('tx_small', 'Tiny', 1.0),
      expense('tx_small_2', 'Tiny2', 1.0),
    ];

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {now: transactions},
        allTransactions: transactions,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionReportPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify 'Diğer' is rendered in the legend for <3% categories
    expect(find.text('Diğer'), findsOneWidget);
    expect(find.text('Tiny'), findsNothing);
    expect(find.text('Tiny2'), findsNothing);
  });

  testWidgets('kovaya TEK kategori düşerse adı "Diğer" ardına saklanmaz',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final transactions = [
      TransactionEntity(
        id: 'tx_large',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Large Expense',
        tag: 'Main',
        amount: 1000.0,
        date: now,
        type: TransactionTypeModel.expense,
      ),
      TransactionEntity(
        id: 'tx_small',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Small Expense',
        tag: 'Tiny',
        amount: 1.0,
        date: now,
        type: TransactionTypeModel.expense,
      ),
    ];

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {now: transactions},
        allTransactions: transactions,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionReportPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Diğer'), findsNothing);
    expect(find.text('Tiny'), findsOneWidget);
  });

  testWidgets('dönem kontrolü, dönemde işlem YOKKEN de görünür',
      (WidgetTester tester) async {
    final oldDate = DateTime.now().subtract(const Duration(days: 100));
    final tx = TransactionEntity(
      id: 'tx_old',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'Old Transaction',
      tag: 'Food',
      amount: 100.0,
      date: oldDate,
      type: TransactionTypeModel.expense,
    );

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          oldDate: [tx]
        },
        allTransactions: [tx],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionReportPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Dönem kontrolü, dönem boş olsa da görünür kalmalı: aksi hâlde
    // kullanıcı dönemi değiştirecek kontrolü bulamıyordu.
    expect(find.byType(TransactionPeriodBar), findsOneWidget);
    // Oklar da burada: bir önceki/sonraki ay tek dokunuş.
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });

  testWidgets('tapping legend item opens category details bottom sheet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final now = DateTime.now();
    final transactions = [
      TransactionEntity(
        id: 'tx_1',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Lunch',
        tag: 'Food',
        amount: 50.0,
        date: now,
        type: TransactionTypeModel.expense,
      ),
    ];

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {now: transactions},
        allTransactions: transactions,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionReportPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    await tester.pumpAndSettle();

    final foodLegendFinder = find.text('Food');
    expect(foodLegendFinder, findsOneWidget);

    await tester.tap(foodLegendFinder);
    await tester.pumpAndSettle();

    expect(find.text('Food'), findsWidgets);
    expect(find.text('50,00 ₺'), findsWidgets);
  });

  group('kuplaj hareketleri', () {
    /// Nakitten bankaya 20.000 TL transfer + 1.500 TL gerçek harcama.
    List<TransactionEntity> withTransfer() {
      final now = DateTime.now();
      return [
        TransactionEntity(
          id: 'tx_market',
          userId: 'user_123',
          walletId: 'wallet_123',
          title: 'Market',
          tag: 'Food',
          amount: 1500,
          date: now,
          type: TransactionTypeModel.expense,
        ),
        TransactionEntity(
          id: 'tx_transfer',
          userId: 'user_123',
          walletId: 'wallet_123',
          title: 'Transfer',
          tag: CashMovementTags.transfer,
          amount: 20000,
          date: now,
          type: TransactionTypeModel.expense,
          isSystem: true,
        ),
      ];
    }

    group('dönemde YALNIZ para taşıma hareketi varken', () {
      /// Bu ay yalnız bir kart ödemesi (transfer); geçen ay gerçek harcama.
      List<TransactionEntity> onlyMoved() {
        final now = DateTime.now();
        return [
          TransactionEntity(
            id: 'tx_transfer',
            userId: 'user_123',
            walletId: 'wallet_123',
            title: 'Kart ödemesi',
            tag: CashMovementTags.transfer,
            amount: 2500,
            date: DateTime(now.year, now.month, 1, 12),
            type: TransactionTypeModel.expense,
            isSystem: true,
          ),
          TransactionEntity(
            id: 'tx_old',
            userId: 'user_123',
            walletId: 'wallet_123',
            title: 'Market',
            tag: 'Food',
            amount: 300,
            date: DateTime(now.year, now.month - 1, 10, 12),
            type: TransactionTypeModel.expense,
          ),
        ];
      }

      Future<void> pump(WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        when(() => mockTransactionBloc.state).thenReturn(TransactionLoaded(
            groupedTransactions: const {}, allTransactions: onlyMoved()));
        await tester.pumpWidget(buildTestableWidget(
          const TransactionReportPage(
              userId: 'user_123', walletId: 'wallet_123'),
        ));
        await tester.pumpAndSettle();
      }

      testWidgets(
          'REGRESYON: 0/0 özet ve "↓%100" yerine nedeni söyleyen kart çizilir',
          (tester) async {
        await pump(tester);
        // Eskiden: Gelir 0, Gider 0, "↓%100 önceki döneme göre" ve boş
        // eksenli karşılaştırma grafiği. Kategori keşfi çizilmez; zaman
        // çizgisi bakiyeyi gösterir (orada hareket var).
        expect(find.byType(ReportCategoryExplorer), findsNothing);
        expect(
          tester.widget<ReportTrendCard>(find.byType(ReportTrendCard)).metric,
          TrendMetric.balance,
        );
        expect(find.text('Bu dönemde gelir ya da gider yok'), findsOneWidget);
        expect(
            find.textContaining('1 para taşıma hareketi var'), findsOneWidget);
      });

      testWidgets('"Para taşımayı dahil et" normal rapora döner',
          (tester) async {
        await pump(tester);
        await tester.tap(find.text('Para taşımayı dahil et'));
        await tester.pumpAndSettle();
        expect(find.byType(ReportCategoryExplorer), findsOneWidget);
        expect(find.text('2.500,00 ₺'), findsWidgets);
      });

      testWidgets('"… dönemine git" son HAREKETLİ aya götürür', (tester) async {
        await pump(tester);
        final now = DateTime.now();
        final previous =
            DateFormat.yMMMM('tr').format(DateTime(now.year, now.month - 1));
        await tester.tap(find.text('$previous dönemine git'));
        await tester.pumpAndSettle();
        expect(find.text(previous), findsOneWidget);
        expect(find.byType(ReportCategoryExplorer), findsOneWidget);
        expect(find.text('300,00 ₺'), findsWidgets);
      });
    });

    testWidgets('REGRESYON: transfer varsayılan olarak GİDERE sayılmaz',
        (tester) async {
      final txs = withTransfer();
      when(() => mockTransactionBloc.state).thenReturn(
        TransactionLoaded(groupedTransactions: {}, allTransactions: txs),
      );

      await tester.pumpWidget(buildTestableWidget(
        const TransactionReportPage(userId: 'user_123', walletId: 'wallet_123'),
      ));
      await tester.pumpAndSettle();

      // Gider özeti yalnız gerçek harcamayı sayar.
      expect(find.text('1.500,00 ₺'), findsWidgets);
      expect(find.text('21.500,00 ₺'), findsNothing,
          reason: 'transfer gidere eklenmemeli');
      // Anahtar kartı görünür ve kaç hareketin dışarıda kaldığını söyler.
      expect(find.byKey(const ValueKey('report-moved-toggle')), findsOneWidget);
      expect(find.text('Para taşıma · 1'), findsOneWidget);
    });

    testWidgets('anahtar açılınca kuplaj hareketleri gidere katılır',
        (tester) async {
      final txs = withTransfer();
      when(() => mockTransactionBloc.state).thenReturn(
        TransactionLoaded(groupedTransactions: {}, allTransactions: txs),
      );

      await tester.pumpWidget(buildTestableWidget(
        const TransactionReportPage(userId: 'user_123', walletId: 'wallet_123'),
      ));
      await tester.pumpAndSettle();

      final toggle = find.byKey(const ValueKey('report-moved-toggle'));
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(find.text('21.500,00 ₺'), findsWidgets);
      expect(
          tester
              .widget<FilterChip>(
                  find.byKey(const ValueKey('report-moved-toggle')))
              .selected,
          isTrue);
    });

    /// 20.000 TL transfer + DÖRT gerçek harcama.
    ///
    /// Küçüklerin payı gerçek evrende %3 eşiğinin üstünde (60/1910 = %3,14),
    /// transfer eklenince altına düşüyor (60/21910 = %0,27). Kuplaj evreni
    /// karışırsa ikisi birden "Diğer" kovasına katlanır — hatanın çıkması
    /// için gereken tam koşul.
    List<TransactionEntity> withTransferAndSmallCategories() {
      final now = DateTime.now();
      TransactionEntity tx(String tag, String title, double amount,
              {bool system = false}) =>
          TransactionEntity(
            id: 'tx_$tag',
            userId: 'user_123',
            walletId: 'wallet_123',
            title: title,
            tag: tag,
            amount: amount,
            date: now,
            type: TransactionTypeModel.expense,
            isSystem: system,
          );

      return [
        tx('Market', 'Market alışverişi', 1000),
        tx('Kira', 'Ev kirası', 800),
        tx('Saglik', 'Eczane alışverişi', 60),
        tx('Eglence', 'Sinema bileti', 50),
        tx(CashMovementTags.transfer, 'Transfer', 20000, system: true),
      ];
    }

    // REGRESYON (bildirildi 2026-09-05): "bu ay seçilince grafik görünüyor ama
    // gidere tıklayınca işlem görünmüyor; kuplajı aktif edince görünüyor."
    //
    // Kök neden: kırılım İKİ yerde hesaplanıyordu ve evrenleri ayrışmıştı —
    // sayfa kuplaj hareketlerini ayırıyor, `CategoryDetailsBottomSheet` ise
    // kendi hesabını kuplaj DAHİL yapıyordu. Şişen toplam yüzde eşiğini
    // kaydırınca sayfada dilim olan kategori alt sayfada "Diğer"e katlanıyor,
    // `firstWhere` bulamıyor ve liste boş çıkıyordu.
    testWidgets(
        'REGRESYON: kuplaj KAPALIYKEN küçük kategorinin işlemleri görünür',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final txs = withTransferAndSmallCategories();
      when(() => mockTransactionBloc.state).thenReturn(
        TransactionLoaded(groupedTransactions: {}, allTransactions: txs),
      );

      await tester.pumpWidget(buildTestableWidget(
        const TransactionReportPage(userId: 'user_123', walletId: 'wallet_123'),
      ));
      await tester.pumpAndSettle();

      // Sayfa onu ayrı bir dilim olarak çiziyor (katlanmış olsaydı bu
      // beklenti zaten düşerdi).
      final slice = find.text('Saglik');
      expect(slice, findsWidgets);

      await tester.tap(slice.first);
      await tester.pumpAndSettle();

      expect(find.text('Bu kategoriye ait işlem bulunmuyor.'), findsNothing,
          reason: 'alt sayfa kırılımı sayfadan FARKLI bir evrenden hesapladı');
      expect(find.text('Eczane alışverişi'), findsWidgets);
      expect(find.text('60,00 ₺'), findsWidgets);
    });

    testWidgets('kuplaj hareketi yokken anahtar kartı hiç çizilmez',
        (tester) async {
      final now = DateTime.now();
      final txs = [
        TransactionEntity(
          id: 'tx_market',
          userId: 'user_123',
          walletId: 'wallet_123',
          title: 'Market',
          tag: 'Food',
          amount: 1500,
          date: now,
          type: TransactionTypeModel.expense,
        ),
      ];
      when(() => mockTransactionBloc.state).thenReturn(
        TransactionLoaded(groupedTransactions: {}, allTransactions: txs),
      );

      await tester.pumpWidget(buildTestableWidget(
        const TransactionReportPage(userId: 'user_123', walletId: 'wallet_123'),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('report-moved-toggle')), findsNothing);
    });
  });

  testWidgets('REGRESYON: paylaş düğmesi AppBar OLMADAN da erişilebilir',
      (tester) async {
    final now = DateTime.now();
    final txs = [
      TransactionEntity(
        id: 'tx_1',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Market',
        tag: 'Food',
        amount: 50,
        date: now,
        type: TransactionTypeModel.expense,
      ),
    ];
    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(groupedTransactions: {}, allTransactions: txs),
    );

    await tester.pumpWidget(buildTestableWidget(
      // SubViewFactory sayfayı böyle kuruyor: showAppBar VERİLMEZ.
      const TransactionReportPage(userId: 'user_123', walletId: 'wallet_123'),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
  });

  group('bütçeler', () {
    List<TransactionEntity> withFood() {
      final now = DateTime.now();
      return [
        TransactionEntity(
          id: 'tx_food',
          userId: 'user_123',
          walletId: 'wallet_123',
          title: 'Market',
          tag: 'Food',
          amount: 1500,
          date: now,
          type: TransactionTypeModel.expense,
        ),
        TransactionEntity(
          id: 'tx_salary',
          userId: 'user_123',
          walletId: 'wallet_123',
          title: 'Maaş',
          tag: 'Salary',
          amount: 5000,
          date: now,
          type: TransactionTypeModel.income,
        ),
      ];
    }

    testWidgets(
        'REGRESYON: bütçe ilerlemesi açılıştaki kategori keşfinde görünür',
        (tester) async {
      when(() => mockBudgetRepository.getBudgets(any())).thenAnswer(
        (_) async => const Right<Failure, List<BudgetEntity>>([
          BudgetEntity(categoryId: 'Food', limitAmount: 1000, spentAmount: 0),
        ]),
      );
      final txs = withFood();
      when(() => mockTransactionBloc.state).thenReturn(
        TransactionLoaded(groupedTransactions: {}, allTransactions: txs),
      );

      await tester.pumpWidget(buildTestableWidget(
        const TransactionReportPage(userId: 'user_123', walletId: 'wallet_123'),
      ));
      await tester.pumpAndSettle();

      // Açılıştaki (Gider) keşif listesinde bütçe çubuğu var.
      expect(
        find.descendant(
          of: find.byType(ReportCategoryExplorer),
          matching: find.byType(LinearProgressIndicator),
        ),
        findsWidgets,
      );
    });

    testWidgets(
        'REGRESYON: harcaması olmayan bütçe satırı dokununca detay AÇAR',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      when(() => mockBudgetRepository.getBudgets(any())).thenAnswer(
        (_) async => const Right<Failure, List<BudgetEntity>>([
          BudgetEntity(categoryId: 'Rent', limitAmount: 2000),
        ]),
      );
      when(() => mockTransactionBloc.state).thenReturn(
        TransactionLoaded(groupedTransactions: {}, allTransactions: withFood()),
      );
      await tester.pumpWidget(buildTestableWidget(
        const TransactionReportPage(userId: 'user_123', walletId: 'wallet_123'),
      ));
      await tester.pumpAndSettle();

      // Eskiden dokunuş sessizce boşa gidiyordu: kırılımda karşılığı yok.
      await tester.tap(find.descendant(
        of: find.byType(ReportBudgetSummaryCard),
        matching: find.text('Rent'),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryDetailsBottomSheet), findsOneWidget);
    });

    testWidgets('tüm limitler 0 iken bütçe başlığı YETİM kalmaz',
        (tester) async {
      when(() => mockBudgetRepository.getBudgets(any())).thenAnswer(
        (_) async => const Right<Failure, List<BudgetEntity>>([
          BudgetEntity(categoryId: 'Food', limitAmount: 0),
        ]),
      );
      when(() => mockTransactionBloc.state).thenReturn(
        TransactionLoaded(groupedTransactions: {}, allTransactions: withFood()),
      );
      await tester.pumpWidget(buildTestableWidget(
        const TransactionReportPage(userId: 'user_123', walletId: 'wallet_123'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Bütçe durumu'), findsNothing);
    });

    testWidgets('bütçe değişince rapor kendi kopyasını TAZELER',
        (tester) async {
      var limit = 1000.0;
      when(() => mockBudgetRepository.getBudgets(any())).thenAnswer(
        (_) async => Right<Failure, List<BudgetEntity>>([
          BudgetEntity(categoryId: 'Food', limitAmount: limit, spentAmount: 0),
        ]),
      );
      final txs = withFood();
      when(() => mockTransactionBloc.state).thenReturn(
        TransactionLoaded(groupedTransactions: {}, allTransactions: txs),
      );

      await tester.pumpWidget(buildTestableWidget(
        const TransactionReportPage(userId: 'user_123', walletId: 'wallet_123'),
      ));
      await tester.pumpAndSettle();

      double progressOf() => tester
          .widget<LinearProgressIndicator>(find.descendant(
            of: find.byType(ReportCategoryExplorer),
            matching: find.byType(LinearProgressIndicator),
          ))
          .value!;

      // 1500 / 1000 → tavana kırpılır.
      expect(progressOf(), 1.0);

      // Bütçeler sayfasında limit yükseltildi.
      limit = 3000;
      getIt<BudgetsChangedNotifier>().notify();
      await tester.pumpAndSettle();

      expect(progressOf(), closeTo(0.5, 0.001));
    });
  });

  group('cüzdan kapsamı', () {
    testWidgets('BAŞKA cüzdanın işlemleri rapora girmez',
        (WidgetTester tester) async {
      // Bloc state'i cüzdan geçişinde kısa süre ESKİ cüzdanın listesini taşır
      // (`TransactionLoading.previousTransactions`). İşlemler sayfası bunu
      // bilerek süzüyordu, rapor süzmüyordu: yabancı cüzdanın toplamları
      // YENİ cüzdanın para birimi sembolüyle çiziliyordu.
      final now = DateTime.now();
      final transactions = [
        TransactionEntity(
          id: 'tx_1',
          userId: 'user_123',
          walletId: 'wallet_123',
          title: 'Lunch',
          tag: 'Food',
          amount: 50.0,
          date: now,
          type: TransactionTypeModel.expense,
        ),
        TransactionEntity(
          id: 'tx_foreign',
          userId: 'user_123',
          walletId: 'baska_cuzdan',
          title: 'Yabancı',
          tag: 'Food',
          amount: 90000.0,
          date: now,
          type: TransactionTypeModel.expense,
        ),
      ];

      when(() => mockTransactionBloc.state).thenReturn(
        TransactionLoaded(
          groupedTransactions: {now: transactions},
          allTransactions: transactions,
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const TransactionReportPage(
            userId: 'user_123',
            walletId: 'wallet_123',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final texts = [
        for (final e in find.byType(Text).evaluate())
          (e.widget as Text).data ?? '',
      ].join(' | ');

      expect(texts.contains('50,00'), isTrue,
          reason: 'bu cüzdanın gideri görünmüyor');
      expect(texts.contains('90.000'), isFalse,
          reason: 'yabancı cüzdanın gideri rapora girdi');
      expect(texts.contains('90.050'), isFalse);
    });
  });

  group('grafik penceresi', () {
    /// [days] listesindeki günlerde birer gider üretir (bu ay).
    List<TransactionEntity> monthDays(List<int> days, {DateTime? now}) {
      final base = now ?? DateTime.now();
      return [
        for (final d in days)
          TransactionEntity(
            id: 'tx_$d',
            userId: 'user_123',
            walletId: 'wallet_123',
            title: 'Market',
            tag: 'Food',
            amount: 100.0 + d,
            date: DateTime(base.year, base.month, d, 12),
            type: TransactionTypeModel.expense,
          ),
      ];
    }

    /// Zaman çizgisinin ÇİZDİĞİ son kova: güncel çizgi yaşanmış kısımda
    /// biter (eksen önceki dönem için daha uzun olabilir).
    DateTime lastDrawn(WidgetTester tester) {
      final card = tester.widget<ReportTrendCard>(find.byType(ReportTrendCard));
      return card.flow.buckets[card.elapsedCount - 1].start;
    }

    Future<void> pump(WidgetTester tester, List<TransactionEntity> txs) async {
      when(() => mockTransactionBloc.state).thenReturn(
        TransactionLoaded(groupedTransactions: {}, allTransactions: txs),
      );
      await tester.pumpWidget(
        buildTestableWidget(
          const TransactionReportPage(
              userId: 'user_123', walletId: 'wallet_123'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('REGRESYON: yaşanmamış günler çizilmez', (tester) async {
      // "Bu Ay" ayın son gününe kadar sürer. Kullanıcının bildirdiği hata:
      // ayın 10'undayken grafiğin sağ üçte ikisi boş, bakiye çizgisi 20 gün
      // DÜMDÜZ gidiyordu (ölçüldü: 30 kovanın 20'si gelecekte).
      final now = DateTime.now();
      await pump(tester, monthDays([1]));

      final card = tester.widget<ReportTrendCard>(find.byType(ReportTrendCard));
      final today = DateTime(now.year, now.month, now.day);
      expect(lastDrawn(tester), today);
      // Önceki dönem boş: eksen de bugünde biter (boş sağ yarı çizilmez).
      expect(
        card.flow.buckets.where((b) => b.start.isAfter(today)),
        isEmpty,
        reason: 'gelecek bir gün "harcama yapılmadı" demek değil',
      );
    });

    testWidgets(
        'önceki dönemde hareket varsa eksen dönem sonuna uzar, güncel çizgi '
        'yine BUGÜNDE biter', (tester) async {
      final now = DateTime.now();
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      if (now.day >= lastDay) return; // ayın son günü: uzatılacak gün yok
      final previousMonth = DateTime(now.year, now.month - 1, 5, 12);
      await pump(tester, [
        ...monthDays([1]),
        TransactionEntity(
          id: 'tx_prev',
          userId: 'user_123',
          walletId: 'wallet_123',
          title: 'Geçen ay',
          tag: 'Food',
          amount: 400,
          date: previousMonth,
          type: TransactionTypeModel.expense,
        ),
      ]);

      final card = tester.widget<ReportTrendCard>(find.byType(ReportTrendCard));
      expect(
          card.flow.buckets.last.start, DateTime(now.year, now.month, lastDay));
      expect(lastDrawn(tester), DateTime(now.year, now.month, now.day));
      // Kesikli çizgi: önceki dönemin serisi gerçekten veri taşıyor.
      expect(card.previousFlow?.hasNoActivity, isFalse);
      final lines = tester
          .widget<LineChart>(find.descendant(
              of: find.byType(ReportTrendCard),
              matching: find.byType(LineChart)))
          .data
          .lineBarsData;
      expect(lines, hasLength(2));
      expect(lines.first.dashArray, isNotNull, reason: 'önceki dönem kesikli');
    });

    testWidgets('ileri tarihli kayıt pencereden DÜŞMEZ', (tester) async {
      // Kırpma bugünde değil "bugün ya da son kayıt"ta durur: planlanmış bir
      // işlem özet kartında sayılıyor, grafikten düşerse iki kart aynı dönem
      // için farklı toplam gösterirdi.
      final now = DateTime.now();
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      if (now.day >= lastDay) return; // ayın son günü: ileri tarih yok
      final future = now.day + 1;
      await pump(tester, monthDays([1, future]));

      expect(lastDrawn(tester), DateTime(now.year, now.month, future));
    });

    testWidgets('veri OLMAYAN bir aya gidince başlıksız boşluk kalmaz',
        (tester) async {
      // Grafik hareketsiz seride kendini gizliyor; bölüm başlığı ve
      // çözünürlük seçicisi ise her hâlükârda çiziliyordu — geriye başlık +
      // BOŞLUK kalıyordu.
      await pump(tester, monthDays([1]));

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ReportTrendCard), findsNothing);
      expect(find.text('Kategori dağılımı'), findsNothing);
    });
  });

  testWidgets('ay oku dönemi bir ay geri alır', (WidgetTester tester) async {
    final now = DateTime.now();
    final txs = [
      TransactionEntity(
        id: 'tx_1',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Market',
        tag: 'Food',
        amount: 100,
        date: DateTime(now.year, now.month, 1, 12),
        type: TransactionTypeModel.expense,
      ),
    ];
    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(groupedTransactions: {}, allTransactions: txs),
    );
    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionReportPage(userId: 'user_123', walletId: 'wallet_123'),
      ),
    );
    await tester.pumpAndSettle();

    final label = DateFormat.yMMMM('tr');
    expect(find.text(label.format(now)), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();

    final previous = DateTime(now.year, now.month - 1, 1);
    expect(find.text(label.format(previous)), findsOneWidget);
    expect(find.text(label.format(now)), findsNothing);

    // Dönem ORTAK: ok İşlemler ve İçgörü'nün de okuduğu süzgece yazar.
    // Eskiden raporun kendi `_range`'ı vardı; yan sayfaya geçen kullanıcı
    // başka bir ayın rakamlarına bakıyordu.
    final shared = tester
        .element(find.byType(TransactionReportPage))
        .read<TransactionFilterCubit>();
    expect(shared.period.start, previous);
  });

  testWidgets('dönem ORTAK: başka sayfada seçilen dönem raporda görünür',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 10, 12);
    when(() => mockTransactionBloc.state).thenReturn(TransactionLoaded(
      groupedTransactions: const {},
      allTransactions: [
        TransactionEntity(
          id: 'tx_old',
          userId: 'user_123',
          walletId: 'wallet_123',
          title: 'Market',
          tag: 'Food',
          amount: 321,
          date: lastMonth,
          type: TransactionTypeModel.expense,
        ),
      ],
    ));
    await tester.pumpWidget(buildTestableWidget(
      const TransactionReportPage(userId: 'user_123', walletId: 'wallet_123'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('321,00 ₺'), findsNothing);

    tester
        .element(find.byType(TransactionReportPage))
        .read<TransactionFilterCubit>()
        .setPeriod(monthRangeOf(lastMonth));
    await tester.pumpAndSettle();

    expect(find.text(DateFormat.yMMMM('tr').format(lastMonth)), findsOneWidget);
    expect(find.text('321,00 ₺'), findsWidgets);
  });

  testWidgets('kullanıcının "Diğer" kategorisi varsa kova BAŞKA ad alır',
      (WidgetTester tester) async {
    // Cihazda ölçüldü: karşılaştırma kartının gider tarafında "Diğer %28" ve
    // "Diğer %15" alt alta duruyordu — biri kullanıcının gerçek kategorisi,
    // öteki eşiğin altındakileri toplayan sentetik kova.
    when(() => mockCategoryRepository.getCategories(true))
        .thenAnswer((_) async => const [
              CategoryEntity(
                  id: 'Food',
                  name: 'Food',
                  iconName: 'fastfood',
                  isExpense: true),
              CategoryEntity(
                  id: 'diger',
                  name: 'Diğer',
                  iconName: 'category',
                  isExpense: true),
            ]);

    final now = DateTime.now();
    TransactionEntity expense(String id, String tag, double amount) =>
        TransactionEntity(
          id: id,
          userId: 'user_123',
          walletId: 'wallet_123',
          title: id,
          tag: tag,
          amount: amount,
          date: now,
          type: TransactionTypeModel.expense,
        );

    final transactions = [
      expense('tx_large', 'Food', 1000.0),
      expense('tx_diger', 'diger', 300.0),
      expense('tx_small', 'Tiny', 1.0),
      expense('tx_small_2', 'Tiny2', 1.0),
    ];
    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {now: transactions},
        allTransactions: transactions,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionReportPage(userId: 'user_123', walletId: 'wallet_123'),
      ),
    );
    await tester.pumpAndSettle();

    // Kullanıcının kategorisi adını korur, kova kendi adını alır.
    expect(find.text('Diğer'), findsOneWidget);
    expect(find.text('Küçük kalemler'), findsOneWidget);
  });

  // Hesabın raporu bağlı kartların harcamalarını İSTEĞE bağlı kapsar.
  group('kartlar dahil anahtarı', () {
    WalletEntity w(String id, {CreditCardInfo? card}) => WalletEntity(
          id: id,
          userId: 'user_123',
          name: id,
          balance: 0,
          debt: 0,
          credit: 0,
          investment: 0,
          colorHex: '0xFF2196F3',
          iconName: 'wallet',
          createdAt: DateTime(2025, 1, 1),
          openingBalance: 0,
          creditCard: card,
        );

    Future<void> pumpWith(WidgetTester tester, {required bool withCard}) async {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, 1, 12);
      final bank = w('bank');
      final card = w('card',
          card: const CreditCardInfo(
              closingDay: 15, dueDay: 25, paymentWalletId: 'bank'));
      final walletBloc = _MockWalletBloc();
      when(() => walletBloc.state)
          .thenReturn(WalletLoadedSt(withCard ? [bank, card] : [bank], bank));
      final repo = _MockTxRepo();
      getIt.registerSingleton<TransactionsRepository>(repo);
      when(() => repo.getTransactions(
            userId: any(named: 'userId'),
            walletId: 'card',
          )).thenAnswer((_) async => Right([
            TransactionEntity(
              id: 'c1',
              userId: 'user_123',
              walletId: 'card',
              title: 'Kartla market',
              tag: 'Food',
              amount: 500,
              date: day,
              type: TransactionTypeModel.expense,
            ),
          ]));
      when(() => mockTransactionBloc.state).thenReturn(TransactionLoaded(
        groupedTransactions: const {},
        allTransactions: [
          TransactionEntity(
            id: 'b1',
            userId: 'user_123',
            walletId: 'bank',
            title: 'Market',
            tag: 'Food',
            amount: 200,
            date: day,
            type: TransactionTypeModel.expense,
          ),
        ],
      ));
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(BlocProvider<WalletBloc>.value(
        value: walletBloc,
        child: buildTestableWidget(const TransactionReportPage(
          userId: 'user_123',
          walletId: 'bank',
        )),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('bağlı kart yoksa anahtar görünmez', (tester) async {
      await pumpWith(tester, withCard: false);
      expect(find.byKey(const ValueKey('report-cards-toggle')), findsNothing);
    });

    testWidgets('açınca gider özeti kartın harcamasını da kapsar',
        (tester) async {
      await pumpWith(tester, withCard: true);
      expect(find.textContaining('700,00'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('report-cards-toggle')));
      await tester.pumpAndSettle();
      expect(find.textContaining('700,00'), findsWidgets);
    });

    testWidgets('paylaşılan CSV anahtar açıkken kart satırlarını da içerir',
        (tester) async {
      final csv = _MockCsvService();
      getIt.registerSingleton<CsvService>(csv);
      when(() => csv.exportTransactionsToCSV(any(),
          shareText: any(named: 'shareText'))).thenAnswer((_) async {});
      await pumpWith(tester, withCard: true);
      await tester.tap(find.byKey(const ValueKey('report-cards-toggle')));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.ios_share_rounded));
      await tester.pumpAndSettle();

      final captured = verify(() => csv.exportTransactionsToCSV(
            captureAny(),
            shareText: captureAny(named: 'shareText'),
          )).captured;
      final rows = captured[0] as List<TransactionEntity>;
      expect(rows.map((t) => t.id), containsAll(['b1', 'c1']));
      // Ay adı arayüz dilinde (locale'siz DateFormat sistem diline düşüyordu).
      final month = DateFormat.MMM('tr').format(DateTime.now());
      expect(captured[1] as String, contains(month));
    });

    testWidgets(
        'REGRESYON: anahtar açıkken kategori detayı kart satırlarını da listeler',
        (tester) async {
      await pumpWith(tester, withCard: true);
      await tester.tap(find.byKey(const ValueKey('report-cards-toggle')));
      await tester.pumpAndSettle();

      // Dilim kartlar DAHİL hesaplanıyor; detay aynı evrenden gelmeli. Kanca
      // yokken sayfa kendi hesabını hesabın defterinden yapıyor, kart
      // satırı ("Kartla market") listede hiç görünmüyordu.
      await tester.tap(find.text('Food').first);
      await tester.pumpAndSettle();

      expect(find.text('Kartla market'), findsOneWidget);
      expect(find.text('Market'), findsOneWidget);
    });
  });

  group('kart cüzdanı', () {
    // Smoke test C-52: kart bağlamında ortak dönem EKSTRE döngüsüdür. Rapor
    // harcamayı önce ödeme gününe taşıyıp sonra ekstre aralığına süzünce
    // "Ekstre · 26 Eyl – 25 Eki" altında ÖNCEKİ ekstrenin harcaması
    // görünüyordu (İşlemler 1.400, Rapor 1.500).
    const info =
        CreditCardInfo(closingDay: 25, dueDay: 5, paymentWalletId: 'bank');
    final cycle = CardCycle(info);
    final now = DateTime.now();
    final current = cycle.periodContaining(now);
    final previous =
        cycle.periodContaining(current.start.subtract(const Duration(days: 1)));

    Future<TransactionFilterCubit> pumpCard(WidgetTester tester) async {
      final card = WalletEntity(
        id: 'card',
        userId: 'user_123',
        name: 'Kart',
        balance: 0,
        debt: 0,
        credit: 0,
        investment: 0,
        colorHex: '0xFFF44336',
        iconName: 'wallet',
        createdAt: DateTime(2025, 1, 1),
        openingBalance: 0,
        creditCard: info,
      );
      final walletBloc = _MockWalletBloc();
      when(() => walletBloc.state).thenReturn(WalletLoadedSt([card], card));
      final repo = _MockTxRepo();
      getIt.registerSingleton<TransactionsRepository>(repo);
      when(() => repo.getTransactions(
            userId: any(named: 'userId'),
            walletId: any(named: 'walletId'),
          )).thenAnswer((_) async => const Right([]));
      TransactionEntity tx(String id, double amount, DateTime day) =>
          TransactionEntity(
            id: id,
            userId: 'user_123',
            walletId: 'card',
            title: id,
            tag: 'Food',
            amount: amount,
            date: DateTime(day.year, day.month, day.day, 12),
            type: TransactionTypeModel.expense,
          );
      when(() => mockTransactionBloc.state).thenReturn(TransactionLoaded(
        groupedTransactions: const {},
        allTransactions: [
          // Önceki ekstre: ödemesi BU ekstrenin aralığına düşer.
          tx('onceki', 1000, previous.start),
          // Bu ekstre.
          tx('bu', 400, current.start),
        ],
      ));
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final cubit = TransactionFilterCubit();
      await tester.pumpWidget(BlocProvider<WalletBloc>.value(
        value: walletBloc,
        child: BlocProvider<TransactionFilterCubit>.value(
          value: cubit,
          child: BlocProvider<AmountVisibilityCubit>(
            create: (_) => AmountVisibilityCubit(),
            child: MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('tr'), Locale('en')],
              locale: const Locale('tr'),
              home: const TransactionReportPage(
                userId: 'user_123',
                walletId: 'card',
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return cubit;
    }

    testWidgets('ekstre döneminde harcama KAYIT tarihiyle sayılır (C-52)',
        (tester) async {
      final cubit = await pumpCard(tester);
      expect(cubit.isStatementPeriod, isTrue);
      expect(find.textContaining('400,00'), findsWidgets);
      expect(find.textContaining('1.000,00'), findsNothing);
    });

    testWidgets('takvim ayında harcama ÖDENDİĞİ aya sayılır', (tester) async {
      final cubit = await pumpCard(tester);
      // Önceki ekstrenin son ödeme günü bu ekstrenin içinde; o günün
      // takvim ayına bakılınca önceki ekstrenin harcaması orada görünür.
      final due = cycle.dueFor(previous.end);
      cubit.setPeriod(DateTimeRange(
        start: DateTime(due.year, due.month, 1),
        end: DateTime(due.year, due.month + 1, 0, 23, 59, 59),
      ));
      await tester.pumpAndSettle();
      expect(cubit.isStatementPeriod, isFalse);
      expect(find.textContaining('1.000,00'), findsWidgets);
    });
  });
}
