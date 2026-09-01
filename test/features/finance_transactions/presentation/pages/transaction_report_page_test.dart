import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/core/shared/widgets/date_range_chips.dart';
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
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_chart_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_compare_chart_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_range_header.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_system_movements_toggle.dart';
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

  Widget buildTestableWidget(Widget child) {
    return BlocProvider<AmountVisibilityCubit>(
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
    );
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

    expect(find.text('Rapor Oluşturmak İçin Veri Yok'), findsOneWidget);
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

    // Varsayılan mod Karşılaştırma: kategori dağılımı TEK kart çizer.
    // 'Gelir'/'Gider' özet kartında, karşılaştırma kartının çubuk etiketinde,
    // efsane başlığında ve haftalık net akış grafiğinin açıklamasında geçer.
    expect(find.text('Gelir'), findsNWidgets(4));
    expect(find.text('Gider'), findsNWidgets(4));
    expect(find.text('Net'), findsNWidgets(2));

    expect(find.byType(ReportCompareChartCard), findsOneWidget);
    // Karşılaştırma modunda tek taraflı pasta kartları GÖSTERİLMEZ — eskiden
    // "compare" sadece ikisini alt alta diziyordu.
    expect(find.byType(ReportCategoryChartCard), findsNothing);
    expect(find.text('Giderler'), findsNothing);
    expect(find.text('Gelirler'), findsNothing);

    // İki taraf da kendi toplamını yazar (özet kartıyla birlikte iki kez).
    expect(find.text('200,00 ₺'), findsNWidgets(2));
    expect(find.text('50,00 ₺'), findsNWidgets(2));
  });

  testWidgets('mod Gidere alınınca tek taraflı pasta kartına dönülür',
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

    final expenseModeIcon = find.byIcon(FinanceMode.expense.icon);
    await tester.ensureVisible(expenseModeIcon);
    await tester.pumpAndSettle();
    await tester.tap(expenseModeIcon);
    await tester.pumpAndSettle();

    expect(find.byType(ReportCompareChartCard), findsNothing);
    expect(find.byType(ReportCategoryChartCard), findsOneWidget);
    expect(find.text('Giderler'), findsOneWidget);
    // Yalnız gider tarafı — gelir kartı bu modda yok.
    expect(find.text('Gelirler'), findsNothing);
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

    // "Değiştir" metin düğmesi ikona döndü: hızlı çipler aynı satıra
    // geldiğinde metin 360dp'de dar kalıyordu.
    await tester.tap(find.byIcon(Icons.edit_calendar_rounded));
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

  testWidgets(
      'renders ReportRangeHeader even when transactions in current range are empty',
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

    // Aralık başlığı VE dönem kontrolü, dönem boş olsa da görünür kalmalı:
    // aksi hâlde kullanıcı aralığı değiştirecek kontrolü bulamıyordu.
    expect(find.byType(ReportRangeHeader), findsOneWidget);
    expect(find.byIcon(Icons.edit_calendar_rounded), findsOneWidget);
    // Hızlı çipler de burada: dönem değiştirmek artık tek dokunuş.
    expect(find.byType(DateRangeChips), findsOneWidget);
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
      expect(find.byType(ReportSystemMovementsToggle), findsOneWidget);
      expect(find.text('1 hareket gelir–giderin dışında'), findsOneWidget);
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

      final toggle = find.byType(Switch).first;
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(find.text('21.500,00 ₺'), findsWidgets);
      expect(find.text('1 hareket gelir–gidere dahil'), findsOneWidget);
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

      expect(find.byType(ReportSystemMovementsToggle), findsNothing);
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
}
