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
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_budget_summary_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_change_badge.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_compare_chart_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_cumulative_balance_chart.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_daily_net_flow_chart.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_monthly_trend_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_period_chart_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_range_header.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_summary_cards.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_system_movements_toggle.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_top_payees_card.dart';
import 'package:fl_chart/fl_chart.dart';
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

/// Rapor sayfasının uçtan uca smoke testi: GERÇEK fontla, gerçek telefon
/// genişliklerinde, her modda ve her etkileşim yolunda.
///
/// İki ölçüm tuzağı burada kapatılıyor, çünkü bu projede ikisine de birden çok
/// kez düşüldü: 800×600 varsayılan test yüzeyi genişlik hatalarını GİZLİYOR,
/// test fontu ise (~1,45-1,7× geniş) olmayan taşmalar UYDURUYOR.
///
/// Dosya üç şeyi birden sabitler:
///  1. **Düzen** — hiçbir kombinasyonda tek bir düzen istisnası çıkmamalı.
///  2. **Etkileşim** — mod, görünüm, çözünürlük, ay penceresi, kuplaj anahtarı
///     ve kırılım chevron'u; hepsi çizim bozmadan çalışmalı.
///  3. **Tutarlılık** — farklı kartların AYNI sayıyı göstermesi. Bir kart
///     kendi evrenini kurarsa (kuplaj hareketlerini farklı süzerse, önceki
///     dönemi farklı tanımlarsa) toplamlar sessizce birbirini tutmaz.
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

  // Başlangıç paketindeki gibi: bazı kökler alt kategori taşır.
  const expenseCats = <({String id, String? parent})>[
    (id: 'Kira', parent: null),
    (id: 'Market', parent: null),
    (id: 'Ulaşım', parent: null),
    (id: 'Fatura', parent: null),
    (id: 'Elektrik', parent: 'Fatura'),
    (id: 'Su', parent: 'Fatura'),
    (id: 'Sağlık', parent: null),
    (id: 'Eğlence', parent: null),
    (id: 'Giyim', parent: null),
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
                id: c.id,
                name: c.id,
                iconName: 'shopping_cart',
                isExpense: true,
                parentId: c.parent),
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

  Widget app(
    Widget child, {
    double textScale = 1.0,
    bool dark = false,
    Locale locale = const Locale('tr'),
  }) =>
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
          locale: locale,
          theme: ThemeData(
            fontFamily: kRealFontFamily,
            brightness: dark ? Brightness.dark : Brightness.light,
          ),
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
      String? title,
    }) =>
        TransactionEntity(
          id: '$tag-$day-$amount',
          userId: 'u',
          walletId: 'w',
          title: title ?? tag,
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
      for (var i = 0; i < 12; i++)
        t(i * 2, 'Market', 850 + i * 30.0,
            title: i.isEven ? 'MIGROS TICARET AS' : 'SOK-1041$i-USKUDAR'),
      for (var i = 0; i < 8; i++) t(i * 3, 'Ulaşım', 180),
      t(5, 'Elektrik', 1240),
      t(9, 'Su', 620),
      t(9, 'Fatura', 260),
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

  testWidgets('320dp (en dar yaygın telefon) — düzen bozulmaz', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final errors = await layoutErrors(tester, () async {
      await pumpPage(tester);
    });
    expect(errors, isEmpty, reason: '$errors');
  });

  testWidgets('koyu tema — düzen bozulmaz', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final txs = lastMonth();
    when(() => bloc.state).thenReturn(
      TransactionLoaded(groupedTransactions: {}, allTransactions: txs),
    );
    final errors = await layoutErrors(tester, () async {
      await tester.pumpWidget(app(
        const TransactionReportPage(userId: 'u', walletId: 'w'),
        dark: true,
      ));
      await tester.pumpAndSettle();
    });
    expect(errors, isEmpty, reason: '$errors');
  });

  testWidgets('İngilizce arayüz — daha uzun başlıklarla da taşmaz',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final txs = lastMonth();
    when(() => bloc.state).thenReturn(
      TransactionLoaded(groupedTransactions: {}, allTransactions: txs),
    );
    final errors = await layoutErrors(tester, () async {
      await tester.pumpWidget(app(
        const TransactionReportPage(userId: 'u', walletId: 'w'),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();
    });
    expect(errors, isEmpty, reason: '$errors');
    expect(find.text('Monthly trend'), findsOneWidget);
  });

  testWidgets('bütün analiz kartları çizilir', (tester) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpPage(tester);

    // Dönem kontrolü + beş bölüm başlığı + iki yeni kart.
    expect(find.byType(ReportRangeHeader), findsOneWidget);
    expect(find.byType(ReportSummaryCards), findsOneWidget);
    expect(find.byType(ReportSystemMovementsToggle), findsOneWidget);
    // Akış ve bakiye TEK kartta, mercek seçimiyle (bkz.
    // ReportPeriodChartCard); açılış merceği akış.
    expect(find.byType(ReportPeriodChartCard), findsOneWidget);
    expect(find.byType(ReportDailyNetFlowChart), findsOneWidget);
    expect(find.byType(ReportCumulativeBalanceChart), findsNothing);
    expect(find.byType(ReportMonthlyTrendCard), findsOneWidget);
    expect(find.byType(ReportPeriodLensSelector), findsOneWidget);
    expect(find.byType(ReportCompareChartCard), findsOneWidget);
    expect(find.byType(ReportBudgetSummaryCard), findsOneWidget);
    expect(find.byType(ReportTopPayeesCard), findsOneWidget);
  });

  group('tutarlılık', () {
    /// Sayfadaki bütün metinler.
    List<String> texts(WidgetTester tester) => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((t) => t.isNotEmpty)
        .toList();

    testWidgets('özet gideri ile kategori kartının toplamı AYNI',
        (tester) async {
      tester.view.physicalSize = const Size(360, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpPage(tester);

      // Kuplaj hareketleri hariç gerçek gider: 24.000 Kira + Market + Ulaşım
      // + 2.120 Fatura + 2.350 Sağlık + 640 Eğlence + 1.890 Giyim.
      const marketTotal =
          12 * 850 + 30 * (0 + 1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10 + 11);
      const expected = 24000 + marketTotal + 8 * 180 + 2120 + 2350 + 640 + 1890;
      final expectedText = formatMoney(expected.toDouble());

      // Özet kartında BİR, karşılaştırma kartının gider satırında BİR.
      expect(
        texts(tester).where((t) => t == expectedText).length,
        greaterThanOrEqualTo(2),
        reason: 'özet ve kategori kartı aynı gideri göstermeli',
      );
      // Transfer + yatırım alımı (35.000) hiçbir yerde gider olarak
      // görünmemeli.
      expect(texts(tester).where((t) => t.contains('35.000')), isEmpty);
    });

    testWidgets(
        'kuplaj anahtarı toplamı TAM olarak sistem tutarı kadar artırır',
        (tester) async {
      tester.view.physicalSize = const Size(360, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpPage(tester);

      const marketTotal = 12 * 850 + 30 * 66;
      const base = 24000 + marketTotal + 8 * 180 + 2120 + 2350 + 640 + 1890;
      expect(find.text(formatMoney(base.toDouble())), findsWidgets);

      final toggle = find.byType(Switch).first;
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      // 20.000 transfer + 15.000 yatırım alımı.
      expect(find.text(formatMoney((base + 35000).toDouble())), findsWidgets);
    });

    testWidgets('bakiye çizgisinin son değeri dönemin net akışıdır',
        (tester) async {
      tester.view.physicalSize = const Size(360, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpPage(tester);

      const marketTotal = 12 * 850 + 30 * 66;
      const income = 62500 + 4200;
      // Bakiye TÜM hareketleri içerir (transfer + yatırım dahil).
      const expense =
          24000 + marketTotal + 8 * 180 + 2120 + 2350 + 640 + 1890 + 35000;

      // Bakiye merceğine geç.
      final balanceChip = find.text('Bakiye');
      await tester.ensureVisible(balanceChip);
      await tester.pumpAndSettle();
      await tester.tap(balanceChip);
      await tester.pumpAndSettle();

      final line = tester.widget<LineChart>(find.byType(LineChart));
      expect(
        line.data.lineBarsData.first.spots.last.y,
        closeTo(income - expense, 0.01),
        reason: 'kuplaj hareketleri bakiyeden düşülemez',
      );
    });

    testWidgets('aylık seyirdeki ay, o ay seçilince özet gideriyle uyuşur',
        (tester) async {
      tester.view.physicalSize = const Size(360, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpPage(tester);

      // Oto-ayar aralığı geçen aya kaydırdı; trend kartında o ay vurgulu
      // olmalı ve gideri özet kartıyla aynı çıkmalı.
      final trend = tester
          .widget<ReportMonthlyTrendCard>(find.byType(ReportMonthlyTrendCard));
      final now = DateTime.now();
      final selected = DateTime(now.year, now.month - 1, 1);
      expect(trend.selectedMonth, selected);

      final bucket =
          trend.series.buckets.firstWhere((b) => b.start == selected);
      const marketTotal = 12 * 850 + 30 * 66;
      const expected = 24000 + marketTotal + 8 * 180 + 2120 + 2350 + 640 + 1890;
      expect(bucket.expense, closeTo(expected.toDouble(), 0.01));
    });
  });

  testWidgets('kategori kırılımı çubuk görünümünde açılır', (tester) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpPage(tester);

    // Gider moduna geç, sonra çubuk görünümüne.
    final expenseIcon = find.byIcon(FinanceMode.expense.icon);
    await tester.ensureVisible(expenseIcon);
    await tester.pumpAndSettle();
    await tester.tap(expenseIcon);
    await tester.pumpAndSettle();

    final bars = find.byIcon(Icons.bar_chart);
    await tester.ensureVisible(bars);
    await tester.pumpAndSettle();
    await tester.tap(bars);
    await tester.pumpAndSettle();

    // Fatura'nın altında Elektrik/Su var.
    expect(find.text('Elektrik'), findsNothing);
    final chevron = find.byIcon(Icons.expand_more_rounded);
    expect(chevron, findsWidgets);
    await tester.ensureVisible(chevron.first);
    await tester.pumpAndSettle();

    final errors = await layoutErrors(tester, () async {
      await tester.tap(chevron.first);
      await tester.pumpAndSettle();
    });
    expect(errors, isEmpty, reason: '$errors');
  });

  group('sayfa yapısı', () {
    testWidgets('dönem kontrolü YAPIŞKAN — kaydırınca kaybolmaz',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpPage(tester);
      final before = tester.getTopLeft(find.byType(ReportRangeHeader));

      // Sayfanın sonuna kadar kaydır.
      await tester.drag(
          find.byType(ReportSummaryCards), const Offset(0, -1500));
      await tester.pumpAndSettle();

      expect(find.byType(ReportRangeHeader), findsOneWidget,
          reason: 'hangi dönemin raporuna bakıldığı hep görünmeli');
      expect(tester.getTopLeft(find.byType(ReportRangeHeader)), before);
    });

    testWidgets('bölümler ÜRÜN ÖNCELİĞİNE göre sıralı', (tester) async {
      tester.view.physicalSize = const Size(360, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpPage(tester);

      double topOf(String title) =>
          tester.getTopLeft(find.text(title)).dy;

      // Kullanıcının sorduğu sıra: ne oldu → nereye gitti → bütçeyi aştım mı
      // → eğilim ne → tam olarak nereye. Kategori dağılımı eskiden 1507dp'de,
      // yani iki ekran aşağıdaydı.
      final kategori = topOf('Kategori Dağılımı');
      final butce = topOf('Bütçe durumu');
      final aylik = topOf('Aylık seyir');
      final yerler = topOf('En çok harcanan yerler');

      expect(kategori, lessThan(butce));
      expect(butce, lessThan(aylik));
      expect(aylik, lessThan(yerler));
      // Kategori dağılımı İLK ekranda başlamalı.
      expect(kategori, lessThan(800));
    });

    testWidgets('akış ↔ bakiye merceği kartı değiştirir', (tester) async {
      tester.view.physicalSize = const Size(360, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpPage(tester);

      expect(find.byType(ReportDailyNetFlowChart), findsOneWidget);
      expect(find.byType(ReportCumulativeBalanceChart), findsNothing);

      final balance = find.text('Bakiye');
      await tester.ensureVisible(balance);
      await tester.pumpAndSettle();
      await tester.tap(balance);
      await tester.pumpAndSettle();

      expect(find.byType(ReportDailyNetFlowChart), findsNothing);
      expect(find.byType(ReportCumulativeBalanceChart), findsOneWidget);
      // Başlık merceği izler.
      expect(find.text('Bakiye Trendi'), findsOneWidget);
    });
  });

  testWidgets('kategori bazlı değişim rozeti AÇILIŞ modunda görünür',
      (tester) async {
    tester.view.physicalSize = const Size(360, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Geçen ay + ondan önceki ay: kıyas kurulabilsin.
    final now = DateTime.now();
    final prevBase = DateTime(now.year, now.month - 2, 1);
    final txs = [
      ...lastMonth(),
      TransactionEntity(
        id: 'prev-kira',
        userId: 'u',
        walletId: 'w',
        title: 'Kira',
        tag: 'Kira',
        amount: 12000,
        date: prevBase.add(const Duration(days: 1)),
        type: TransactionTypeModel.expense,
      ),
    ];
    when(() => bloc.state).thenReturn(
      TransactionLoaded(groupedTransactions: {}, allTransactions: txs),
    );
    await tester.pumpWidget(app(
      const TransactionReportPage(userId: 'u', walletId: 'w'),
    ));
    await tester.pumpAndSettle();

    // Kira 12.000 → 24.000 = %100 artış; gider tarafında artış KÖTÜ.
    expect(find.byType(ReportCompareChartCard), findsOneWidget);
    final badges = find.descendant(
      of: find.byType(ReportCompareChartCard),
      matching: find.byType(ReportChangeBadge),
    );
    expect(badges, findsWidgets);
    expect(
      find.descendant(of: badges, matching: find.text('%100')),
      findsOneWidget,
    );
  });
}
