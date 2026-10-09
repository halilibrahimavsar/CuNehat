import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_trend.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/category_details_bottom_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_bar_list.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_explorer.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_trend_card.dart';
import 'package:cunehat/core/shared/widgets/labeled_segment.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
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
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_budget_summary_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_change_badge.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_period_bar.dart';
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
      BlocProvider<TransactionFilterCubit>(
        // Dönem ORTAK ve sessizce kaymıyor: veri geçen ayda, dönem de oraya
        // alınır (eskiden sayfanın oto-ayarı yapıyordu).
        create: (_) => TransactionFilterCubit()
          ..setPeriod(monthRangeOf(
              DateTime(DateTime.now().year, DateTime.now().month - 1, 1))),
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
      ));

  /// Geçen ay: ortak dönem kurulumda o aya alınır, yani tam bir ay görünür.
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

  /// Zaman çizgisinin ölçüsünü seçer.
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

  /// Keşifte bir satıra dokunur (iner ya da işlemleri açar).
  Future<void> tapExplorerRow(WidgetTester tester, String label) async {
    final row = find.descendant(
      of: find.byType(ReportCategoryBarList),
      matching: find.text(label),
    );
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
  }

  for (final textScale in [1.0, 1.3]) {
    testWidgets('360dp / metin ölçeği $textScale — her ölçü ve görünüm taşmaz',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final errors = await layoutErrors(tester, () async {
        await pumpPage(tester, textScale: textScale);
      });
      expect(errors, isEmpty, reason: 'açılış: $errors');

      for (final metric in ['Gelir', 'Net', 'Bakiye', 'Gider']) {
        final metricErrors = await layoutErrors(tester, () async {
          await selectMetric(tester, metric);
        });
        expect(metricErrors, isEmpty, reason: '$metric: $metricErrors');
      }

      // Çubuk görünümü (Gider'de) ve geri çizgiye.
      final barErrors = await layoutErrors(tester, () async {
        final bars = find.byTooltip('Çubuk görünümü');
        await tester.ensureVisible(bars);
        await tester.pumpAndSettle();
        await tester.tap(bars);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Çizgi görünümü'));
        await tester.pumpAndSettle();
      });
      expect(barErrors, isEmpty, reason: 'çubuk: $barErrors');

      // Kategoriye in, gelire geç, geri gel.
      final drillErrors = await layoutErrors(tester, () async {
        await tapExplorerRow(tester, 'Fatura');
        // İniş yol çubuğunu görünür alana getirir: geri ok kaydırmadan
        // dokunulabilir olmalı.
        await tester.tap(find.byTooltip('Bir üst seviyeye çık'));
        await tester.pumpAndSettle();
        final incomeChip = find.widgetWithText(ChoiceChip, 'Gelir');
        await tester.ensureVisible(incomeChip);
        await tester.pumpAndSettle();
        await tester.tap(incomeChip);
        await tester.pumpAndSettle();
      });
      expect(drillErrors, isEmpty, reason: 'iniş: $drillErrors');
      expect(
        tester
            .widget<ReportCategoryExplorer>(find.byType(ReportCategoryExplorer))
            .isExpense,
        isFalse,
      );
    });
  }

  testWidgets('kuplaj anahtarını açıp kapatmak da taşma üretmez',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpPage(tester);

    final errors = await layoutErrors(tester, () async {
      final toggle = find.byKey(const ValueKey('report-moved-toggle'));
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
    });
    expect(errors, isEmpty, reason: '$errors');
  });

  testWidgets('çözünürlük seçicisi bir AYDA çıkmaz, uzun aralıkta çıkar',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpPage(tester);

    // Bir ay (≤35 gün) her zaman GÜNLÜK çizilir; seçenek sunmak kalıcı bir
    // çip satırından ibaretti.
    expect(find.text('Hafta'), findsNothing);
    ReportTrendCard card() =>
        tester.widget<ReportTrendCard>(find.byType(ReportTrendCard));
    expect(card().flow.unit, ReportBucketUnit.day);

    // Dönemi "Son 3 Ay"a al: seçici artık bir işe yarıyor.
    final errors = await layoutErrors(tester, () async {
      await tester.tap(find.descendant(
        of: find.byType(TransactionPeriodBar),
        matching: find.byType(InkWell),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Son 3 Ay'));
      await tester.pumpAndSettle();

      // Üç ay otomatik olarak HAFTALIK çizilir; elle aylığa geç.
      expect(card().flow.unit, ReportBucketUnit.week);
      final month = find.widgetWithText(ChoiceChip, 'Ay');
      await tester.ensureVisible(month);
      await tester.pumpAndSettle();
      await tester.tap(month);
      await tester.pumpAndSettle();
    });
    expect(errors, isEmpty, reason: '$errors');
    expect(card().flow.unit, ReportBucketUnit.month);
  });

  testWidgets('320dp (en dar yaygın telefon) — düzen bozulmaz', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final errors = await layoutErrors(tester, () async {
      await pumpPage(tester);
      await tapExplorerRow(tester, 'Fatura');
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
    expect(find.text('This period'), findsOneWidget);
    expect(find.text('Balance'), findsWidgets);
  });

  testWidgets('bütün analiz kartları çizilir', (tester) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpPage(tester);

    expect(find.byType(TransactionPeriodBar), findsOneWidget);
    expect(find.byKey(const ValueKey('report-moved-toggle')), findsOneWidget);
    // Manşet: varsayılan ÇİZGİ + GİDER.
    expect(find.byType(ReportTrendCard), findsOneWidget);
    expect(
      find.descendant(
          of: find.byType(ReportTrendCard), matching: find.byType(LineChart)),
      findsOneWidget,
    );
    expect(find.byType(ReportCategoryExplorer), findsOneWidget);
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

    // Kuplaj hareketleri hariç gerçek gider: 24.000 Kira + Market + Ulaşım
    // + 2.120 Fatura + 2.350 Sağlık + 640 Eğlence + 1.890 Giyim.
    const marketTotal =
        12 * 850 + 30 * (0 + 1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10 + 11);
    const expense = 24000 + marketTotal + 8 * 180 + 2120 + 2350 + 640 + 1890;

    testWidgets('manşet gideri, çizginin sonu ve kategori keşfi AYNI',
        (tester) async {
      tester.view.physicalSize = const Size(360, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpPage(tester);

      expect(texts(tester), contains(formatMoney(expense.toDouble())));
      // Transfer + yatırım alımı (35.000) hiçbir yerde gider olarak
      // görünmemeli.
      expect(texts(tester).where((t) => t.contains('35.000')), isEmpty);

      final explorer = tester
          .widget<ReportCategoryExplorer>(find.byType(ReportCategoryExplorer));
      expect(explorer.top.fold<double>(0, (s, c) => s + c.totalAmount),
          closeTo(expense, 0.01));

      final line = tester.widget<LineChart>(find.descendant(
          of: find.byType(ReportTrendCard), matching: find.byType(LineChart)));
      expect(line.data.lineBarsData.last.spots.last.y, closeTo(expense, 0.01),
          reason: 'birikimli gider çizgisi dönem gideriyle bitmeli');
    });

    testWidgets(
        'kuplaj anahtarı toplamı TAM olarak sistem tutarı kadar artırır',
        (tester) async {
      tester.view.physicalSize = const Size(360, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpPage(tester);
      expect(find.text(formatMoney(expense.toDouble())), findsWidgets);

      final toggle = find.byKey(const ValueKey('report-moved-toggle'));
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      // 20.000 transfer + 15.000 yatırım alımı.
      expect(
          find.text(formatMoney((expense + 35000).toDouble())), findsWidgets);
    });

    testWidgets('bakiye çizgisinin son değeri dönemin net akışıdır',
        (tester) async {
      tester.view.physicalSize = const Size(360, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpPage(tester);
      await selectMetric(tester, 'Bakiye');

      const income = 62500 + 4200;
      // Bakiye TÜM hareketleri içerir (transfer + yatırım dahil).
      const allExpense = expense + 35000;

      final line = tester.widget<LineChart>(find.descendant(
          of: find.byType(ReportTrendCard), matching: find.byType(LineChart)));
      expect(
        line.data.lineBarsData.last.spots.last.y,
        closeTo(income - allExpense, 0.01),
        reason: 'kuplaj hareketleri bakiyeden düşülemez',
      );
    });

    testWidgets('kategoriye inmek zaman çizgisini O KATEGORİYE süzer',
        (tester) async {
      tester.view.physicalSize = const Size(360, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpPage(tester);
      await tapExplorerRow(tester, 'Fatura');

      // Alt kırılım yerinde açıldı.
      expect(find.text('Elektrik'), findsWidgets);
      expect(find.text('Su'), findsWidgets);

      final card = tester.widget<ReportTrendCard>(find.byType(ReportTrendCard));
      expect(card.focus?.amount, 2120);
      final flowTotal =
          card.flow.buckets.fold<double>(0, (s, b) => s + b.expense);
      expect(flowTotal, closeTo(2120, 0.01),
          reason: 'çizgi kategorinin kendi işlemlerinden kurulmalı');
      expect(texts(tester), contains(formatMoney(2120)));

      // Çipteki ✕ odağı kaldırır; keşif de üst seviyeye döner.
      await tester.ensureVisible(find.byTooltip('Kategori odağını kaldır'));
      await tester.tap(find.byTooltip('Kategori odağını kaldır'));
      await tester.pumpAndSettle();
      expect(
          tester.widget<ReportTrendCard>(find.byType(ReportTrendCard)).focus,
          isNull);
      expect(find.text('Elektrik'), findsNothing);
    });

    testWidgets('REGRESYON: inilen ALT kategorinin işlemleri DOLU açılır',
        (tester) async {
      tester.view.physicalSize = const Size(360, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpPage(tester);
      await tapExplorerRow(tester, 'Fatura');
      await tapExplorerRow(tester, 'Elektrik');

      expect(find.byType(CategoryDetailsBottomSheet), findsOneWidget);
      expect(find.text('Bu kategoriye ait işlem bulunmuyor.'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(CategoryDetailsBottomSheet),
          matching: find.text(formatMoney(1240)),
        ),
        findsWidgets,
      );
    });
  });

  group('sayfa yapısı', () {
    testWidgets('dönem kontrolü YAPIŞKAN — kaydırınca kaybolmaz',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpPage(tester);
      final before = tester.getTopLeft(find.byType(TransactionPeriodBar));

      // Sayfanın sonuna kadar kaydır.
      await tester.drag(find.byType(ReportTrendCard), const Offset(0, -1500));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionPeriodBar), findsOneWidget,
          reason: 'hangi dönemin raporuna bakıldığı hep görünmeli');
      expect(tester.getTopLeft(find.byType(TransactionPeriodBar)), before);
    });

    testWidgets('bölümler ÜRÜN ÖNCELİĞİNE göre sıralı', (tester) async {
      tester.view.physicalSize = const Size(360, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpPage(tester);

      double topOf(String title) => tester.getTopLeft(find.text(title)).dy;

      // Kullanıcının sorduğu sıra: nasıl gidiyor (zaman) → nereye gitti →
      // bütçeyi aştım mı → tam olarak nereye.
      final trend = tester.getTopLeft(find.byType(ReportTrendCard)).dy;
      final kategori = topOf('Kategori dağılımı');
      final butce = topOf('Bütçe durumu');
      final yerler = topOf('En çok harcanan yerler');

      expect(trend, lessThan(kategori));
      expect(kategori, lessThan(butce));
      expect(butce, lessThan(yerler));
      // Kategori dağılımı İLK ekranda başlamalı.
      expect(kategori, lessThan(800));
    });
  });

  testWidgets('kategori bazlı değişim rozeti AÇILIŞTA görünür',
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
    final badges = find.descendant(
      of: find.byType(ReportCategoryExplorer),
      matching: find.byType(ReportChangeBadge),
    );
    expect(badges, findsWidgets);
    expect(
      find.descendant(of: badges, matching: find.text('%100')),
      findsOneWidget,
    );
  });
}
