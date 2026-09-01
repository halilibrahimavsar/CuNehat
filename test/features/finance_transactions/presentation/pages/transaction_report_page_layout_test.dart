import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
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

/// Rapor sayfasının 360dp telefonda GERÇEK fontla düzen denetimi.
///
/// Bu dosya var çünkü bu projede aynı tuzağa birden çok kez düşüldü: 800×600
/// varsayılan test yüzeyi genişlik hatalarını gizliyor, test fontu ise olmayan
/// taşmalar uyduruyor (~1,45-1,7× geniş). Burada ikisi de kapatılıyor —
/// gerçek Roboto, gerçek telefon genişliği — ve sayfa üç modda + iki metin
/// ölçeğinde tek bir düzen istisnası ÜRETMEDEN çizilmek zorunda.
class MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockOnboardingCoordinator extends Mock implements OnboardingCoordinator {}

void main() {
  late MockTransactionBloc bloc;
  late MockCategoryRepository catRepo;
  late MockBudgetRepository budgetRepo;
  late MockOnboardingCoordinator onboarding;

  setUpAll(() async {
    Intl.defaultLocale = 'tr';
    await loadRealRoboto();
    getIt.allowReassignment = true;
    registerFallbackValue(OnboardingFlow.shell);
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
  });

  const expenseCats = [
    'Kira',
    'Market',
    'Ulaşım',
    'Fatura',
    'Sağlık',
    'Eğlence',
    'Giyim',
  ];
  const incomeCats = ['Maaş', 'Ek Gelir'];

  setUp(() {
    bloc = MockTransactionBloc();
    catRepo = MockCategoryRepository();
    budgetRepo = MockBudgetRepository();
    onboarding = MockOnboardingCoordinator();
    getIt.registerSingleton<TransactionBloc>(bloc);
    getIt.registerSingleton<CategoryRepository>(catRepo);
    getIt.registerSingleton<CategoriesChangedNotifier>(
        CategoriesChangedNotifier());
    getIt.registerSingleton<BudgetsChangedNotifier>(BudgetsChangedNotifier());
    getIt.registerSingleton<BudgetRepository>(budgetRepo);
    getIt.registerSingleton<OnboardingCoordinator>(onboarding);

    when(() => catRepo.getCategories(true)).thenAnswer((_) async => [
          for (final c in expenseCats)
            CategoryEntity(
                id: c, name: c, iconName: 'shopping_cart', isExpense: true),
        ]);
    when(() => catRepo.getCategories(false)).thenAnswer((_) async => [
          for (final c in incomeCats)
            CategoryEntity(
                id: c, name: c, iconName: 'attach_money', isExpense: false),
        ]);
    when(() => catRepo.getAllCategories()).thenAnswer((_) async => [
          ...await catRepo.getCategories(true),
          ...await catRepo.getCategories(false),
        ]);
    when(() => budgetRepo.getBudgets(any())).thenAnswer(
      (_) async => const Right<Failure, List<BudgetEntity>>([
        BudgetEntity(categoryId: 'Market', limitAmount: 9000, spentAmount: 0),
        BudgetEntity(categoryId: 'Kira', limitAmount: 20000, spentAmount: 0),
      ]),
    );
    when(() => onboarding.isSeen(any())).thenReturn(true);
  });

  tearDown(() => getIt.reset());

  Widget app(Widget child, {double textScale = 1.0}) =>
      BlocProvider<AmountVisibilityCubit>(
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
          builder: (context, inner) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: inner!,
          ),
          home: child,
        ),
      );

  /// Geçen ay: oto-ayar aralığı o aya kaydırır, yani tam bir ay görünür.
  /// Kuplaj hareketi de var — anahtar kartı çizilsin.
  List<TransactionEntity> lastMonth() {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month - 1, 1);
    TransactionEntity t(
      int day,
      String tag,
      double amount, {
      bool income = false,
      bool system = false,
    }) =>
        TransactionEntity(
          id: '$tag-$day-$amount',
          userId: 'u',
          walletId: 'w',
          title: tag,
          tag: tag,
          amount: amount,
          date: base.add(Duration(days: day)),
          type: income
              ? TransactionTypeModel.income
              : TransactionTypeModel.expense,
          isSystem: system,
        );

    return [
      t(0, 'Maaş', 62500, income: true),
      t(14, 'Ek Gelir', 4200, income: true),
      t(1, 'Kira', 24000),
      for (var i = 0; i < 12; i++) t(i * 2, 'Market', 850 + i * 30.0),
      for (var i = 0; i < 8; i++) t(i * 3, 'Ulaşım', 180),
      t(5, 'Fatura', 1240),
      t(9, 'Fatura', 880),
      t(11, 'Sağlık', 2350),
      t(18, 'Eğlence', 640),
      t(21, 'Giyim', 1890),
      t(7, CashMovementTags.transfer, 20000, system: true),
      t(20, CashMovementTags.investmentBuy, 15000, system: true),
    ];
  }

  /// Bir kare çizerken ortaya çıkan düzen istisnalarını toplar.
  Future<List<String>> layoutErrors(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.exceptionAsString());
    await body();
    FlutterError.onError = previous;
    return errors;
  }

  Future<void> pumpPage(WidgetTester tester, {double textScale = 1.0}) async {
    final txs = lastMonth();
    when(() => bloc.state).thenReturn(
      TransactionLoaded(groupedTransactions: {}, allTransactions: txs),
    );
    await tester.pumpWidget(app(
      const TransactionReportPage(userId: 'u', walletId: 'w'),
      textScale: textScale,
    ));
    await tester.pumpAndSettle();
  }

  for (final textScale in [1.0, 1.3]) {
    testWidgets('360dp / metin ölçeği $textScale — üç mod da taşmaz',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final errors = await layoutErrors(tester, () async {
        await pumpPage(tester, textScale: textScale);
      });
      expect(errors, isEmpty, reason: 'karşılaştırma modu: $errors');

      for (final mode in [FinanceMode.expense, FinanceMode.income]) {
        final modeErrors = await layoutErrors(tester, () async {
          final icon = find.byIcon(mode.icon);
          await tester.ensureVisible(icon);
          await tester.pumpAndSettle();
          await tester.tap(icon);
          await tester.pumpAndSettle();
        });
        expect(modeErrors, isEmpty, reason: '$mode: $modeErrors');

        // Aynı modda çubuk görünümüne de geç.
        final barErrors = await layoutErrors(tester, () async {
          final bars = find.byIcon(Icons.bar_chart);
          await tester.ensureVisible(bars);
          await tester.pumpAndSettle();
          await tester.tap(bars);
          await tester.pumpAndSettle();
        });
        expect(barErrors, isEmpty, reason: '$mode çubuk: $barErrors');
      }
    });
  }

  testWidgets('kuplaj anahtarını açıp kapatmak da taşma üretmez',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpPage(tester);

    final errors = await layoutErrors(tester, () async {
      final toggle = find.byType(Switch).first;
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
    });
    expect(errors, isEmpty, reason: '$errors');
  });

  testWidgets('çözünürlük seçicisi de taşma üretmez', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpPage(tester);

    final errors = await layoutErrors(tester, () async {
      final week = find.text('Hafta');
      await tester.ensureVisible(week);
      await tester.pumpAndSettle();
      await tester.tap(week);
      await tester.pumpAndSettle();
    });
    expect(errors, isEmpty, reason: '$errors');
    // Başlık çözünürlüğü izler.
    expect(find.text('Haftalık Gelir–Gider'), findsOneWidget);
  });
}
