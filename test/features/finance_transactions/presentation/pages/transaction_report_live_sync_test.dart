import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/transactions_usecases.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/usecase_params.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_report_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/category_details_bottom_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_top_payees_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_transaction_list_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_card.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

import '../../../../support/real_font.dart';

/// Rapor sayfası defterin CANLI hâlini göstermeli: sayfa açıkken yapılan bir
/// silme/düzenleme (kendi bloc'undan ya da başka bir sayfanın bloc'undan)
/// bir sonraki karede rakamlara yansımalı.
class _MockGrouped extends Mock implements GetTransactionsGroupedUseCase {}

class _MockAdd extends Mock implements AddTransactionUseCase {}

class _MockUpdate extends Mock implements UpdateTransactionUseCase {}

class _MockDelete extends Mock implements DeleteTransactionUseCase {}

class _MockGetById extends Mock implements GetTransactionByIdUseCase {}

class _MockMetrics extends Mock implements WalletMetricsService {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockBudgetRepository extends Mock implements BudgetRepository {}

class _MockOnboarding extends Mock implements OnboardingCoordinator {}

void main() {
  late List<TransactionEntity> ledger;
  late TransactionsChangedNotifier changed;
  late _MockGrouped grouped;
  late _MockDelete delete;
  late _MockGetById getById;
  late _MockCategoryRepository catRepo;
  late _MockBudgetRepository budgetRepo;

  setUpAll(() async {
    Intl.defaultLocale = 'tr';
    await loadRealRoboto();
    getIt.allowReassignment = true;
    registerFallbackValue(OnboardingFlow.shell);
    registerFallbackValue(
      GetTransactionsGroupedParams(userId: 'u', walletId: 'w'),
    );
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
  });

  TransactionEntity tx(String id, String tag, double amount) =>
      TransactionEntity(
        id: id,
        userId: 'u',
        walletId: 'w',
        title: tag,
        tag: tag,
        amount: amount,
        // Ayın 15'i: "bu ay" varsayılan aralığının içinde kalsın.
        date: DateTime(DateTime.now().year, DateTime.now().month, 15),
        type: TransactionTypeModel.expense,
      );

  setUp(() {
    ledger = [tx('t1', 'Market', 1000), tx('t2', 'Kira', 4000)];
    changed = TransactionsChangedNotifier();
    grouped = _MockGrouped();
    delete = _MockDelete();
    getById = _MockGetById();
    catRepo = _MockCategoryRepository();
    budgetRepo = _MockBudgetRepository();

    when(() => grouped(any())).thenAnswer(
      (_) async => Right<Failure, Map<DateTime, List<TransactionEntity>>>(
        {DateTime(2020): List.of(ledger)},
      ),
    );
    when(() => delete(any(), keepReceiptFile: any(named: 'keepReceiptFile')))
        .thenAnswer((invocation) async {
      ledger.removeWhere((t) => t.id == invocation.positionalArguments.first);
      return const Right<Failure, void>(null);
    });
    when(() => getById(any())).thenAnswer((invocation) async {
      final id = invocation.positionalArguments.first as String;
      return Right<Failure, TransactionEntity>(
        ledger.firstWhere((t) => t.id == id),
      );
    });

    final metrics = _MockMetrics();
    when(() => metrics.syncBalance(any())).thenAnswer((_) async => true);

    getIt.registerFactory<TransactionBloc>(() => TransactionBloc(
          getTransactionsGroupedUseCase: grouped,
          addTransactionUseCase: _MockAdd(),
          updateTransactionUseCase: _MockUpdate(),
          deleteTransactionUseCase: delete,
          getTransactionByIdUseCase: getById,
          walletMetricsService: metrics,
          transactionsChangedNotifier: changed,
        ));
    getIt.registerSingleton<TransactionsChangedNotifier>(changed);
    getIt.registerSingleton<CategoryRepository>(catRepo);
    getIt.registerSingleton<CategoriesChangedNotifier>(
        CategoriesChangedNotifier());
    getIt.registerSingleton<BudgetsChangedNotifier>(BudgetsChangedNotifier());
    getIt.registerSingleton<BudgetRepository>(budgetRepo);
    final onboarding = _MockOnboarding();
    when(() => onboarding.isSeen(any())).thenReturn(true);
    getIt.registerSingleton<OnboardingCoordinator>(onboarding);

    when(() => catRepo.getCategories(true)).thenAnswer((_) async => const [
          CategoryEntity(
              id: 'Market',
              name: 'Market',
              iconName: 'shopping_cart',
              isExpense: true),
          CategoryEntity(
              id: 'Kira', name: 'Kira', iconName: 'home', isExpense: true),
        ]);
    when(() => catRepo.getCategories(false)).thenAnswer((_) async => const []);
    when(() => catRepo.getAllCategories())
        .thenAnswer((_) async => await catRepo.getCategories(true));
    when(() => budgetRepo.getBudgets(any()))
        .thenAnswer((_) async => const Right<Failure, List<BudgetEntity>>([]));
  });

  tearDown(() => getIt.reset());

  Widget app(Widget child) => BlocProvider<AmountVisibilityCubit>(
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
          theme: ThemeData(fontFamily: kRealFontFamily),
          home: child,
        ),
      );

  testWidgets('başka bir bloc örneğinden silme rapora anında yansır',
      (tester) async {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
        app(const TransactionReportPage(userId: 'u', walletId: 'w')));
    await tester.pumpAndSettle();

    expect(find.text(formatMoney(5000)), findsWidgets,
        reason: 'açılışta 1.000 + 4.000 gider');

    // Başka bir sayfanın bloc'u siliyor: defteri değiştir + kanaldan haber ver.
    ledger.removeWhere((t) => t.id == 't2');
    changed.notify(userId: 'u', walletId: 'w');
    await tester.pumpAndSettle();

    expect(find.text(formatMoney(1000)), findsWidgets,
        reason: 'silinen 4.000 rapordan düşmeli');
    expect(find.text(formatMoney(5000)), findsNothing);
  });

  testWidgets('kategori sayfasından silme rapora ve sayfaya anında yansır',
      (tester) async {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
        app(const TransactionReportPage(userId: 'u', walletId: 'w')));
    await tester.pumpAndSettle();
    expect(find.text(formatMoney(5000)), findsWidgets);

    // Kategori satırı → detay alt sayfası.
    await tester.tap(find.text('Kira').first);
    await tester.pumpAndSettle();
    expect(find.byType(CategoryDetailsBottomSheet), findsOneWidget);
    expect(find.text(formatMoney(4000)), findsWidgets);

    // Kartın uzun basış menüsü → Sil → onay.
    await tester.longPress(find.byType(TransactionCard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('İşlemi Sil'));
    await tester.pumpAndSettle();
    // Onay düğmesi geri sayımlı; sayaç bitene kadar pasif.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sil'));
    await tester.pumpAndSettle();

    // Alt sayfa hâlâ açık: kategori boşalmış olmalı.
    expect(find.text(formatMoney(4000)), findsNothing,
        reason: 'kategori sayfası silineni hâlâ gösteriyor');

    // Alt sayfayı kapat: raporun özeti de düşmüş olmalı.
    Navigator.of(tester.element(find.byType(CategoryDetailsBottomSheet)))
        .pop();
    await tester.pumpAndSettle();
    expect(find.text(formatMoney(1000)), findsWidgets);
    expect(find.text(formatMoney(5000)), findsNothing);
  });

  testWidgets('"en çok harcanan yer" sayfası da silmeyi anında yansıtır',
      (tester) async {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Aynı başlığı taşıyan iki satır bir "yer" grubu kurar (bkz.
    // ReportTopPayeesCard.buildGroups / kMinGroupSize).
    ledger = [
      TransactionEntity(
        id: 'p1',
        userId: 'u',
        walletId: 'w',
        title: 'TAKSI ODEMESI ISTANBUL',
        tag: 'Market',
        amount: 1000,
        date: DateTime(DateTime.now().year, DateTime.now().month, 15),
        type: TransactionTypeModel.expense,
      ),
      TransactionEntity(
        id: 'p2',
        userId: 'u',
        walletId: 'w',
        title: 'TAKSI ODEMESI ANKARA',
        tag: 'Market',
        amount: 4000,
        date: DateTime(DateTime.now().year, DateTime.now().month, 16),
        type: TransactionTypeModel.expense,
      ),
    ];

    await tester.pumpWidget(
        app(const TransactionReportPage(userId: 'u', walletId: 'w')));
    await tester.pumpAndSettle();

    final payeeRow = find.descendant(
      of: find.byType(ReportTopPayeesCard),
      matching: find.textContaining('TAKSI'),
    );
    expect(payeeRow, findsOneWidget, reason: '"yer" kartı grubu kurmadı');
    await tester.ensureVisible(payeeRow);
    await tester.pumpAndSettle();
    await tester.tap(payeeRow);
    await tester.pumpAndSettle();

    expect(find.byType(ReportTransactionListSheet), findsOneWidget);
    expect(find.text(formatMoney(5000)), findsWidgets, reason: 'grup toplamı');

    await tester.longPress(find.byType(TransactionCard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('İşlemi Sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sil'));
    await tester.pumpAndSettle();

    // Sayfa AÇIKKEN güncellenmeli: silinen satır düşer, başlık toplamı azalır.
    expect(find.byType(ReportTransactionListSheet), findsOneWidget);
    expect(find.text(formatMoney(5000)), findsNothing,
        reason: '"yer" sayfası silinen satırı hâlâ sayıyor');
    expect(find.byType(TransactionCard), findsOneWidget);
  });

  testWidgets('raporun KENDİ bloc\'undan silme de anında yansır',
      (tester) async {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
        app(const TransactionReportPage(userId: 'u', walletId: 'w')));
    await tester.pumpAndSettle();

    expect(find.text(formatMoney(5000)), findsWidgets);

    final bloc = tester.element(find.byType(Scaffold)).read<TransactionBloc>();
    bloc.add(const DeleteTransactionEvent('t2'));
    await tester.pumpAndSettle();

    expect(find.text(formatMoney(1000)), findsWidgets);
  });
}
