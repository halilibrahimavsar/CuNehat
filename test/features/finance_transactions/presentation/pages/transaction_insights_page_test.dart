import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_summary_cards.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/main_feature/controllers/home_navigation_requests.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_insights_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/insight_widgets/insight_budget_cards.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/insight_widgets/recurring_suggestion_card.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/services/recurring_suggestion_dismiss_store.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/get_all_recurring_templates_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_period_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

import '../../../../support/real_font.dart';

class MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

class MockGetAllRecurringTemplatesUsecase extends Mock
    implements GetAllRecurringTemplatesUsecase {}

class MockOnboardingCoordinator extends Mock implements OnboardingCoordinator {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockBudgetRepository extends Mock implements BudgetRepository {}

class _MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

void main() {
  late MockTransactionBloc bloc;
  late MockGetAllRecurringTemplatesUsecase templates;
  late MockOnboardingCoordinator onboarding;
  late MockCategoryRepository categories;
  late SharedPreferences prefs;
  late AmountVisibilityCubit visibility;

  final now = DateTime.now();

  /// Bugünün ayına yerleşir: varsayılan dönem "Bu Ay".
  DateTime dayThisMonth(int day) => DateTime(now.year, now.month, day, 12);

  setUpAll(() async {
    Intl.defaultLocale = 'tr';
    await loadRealRoboto();
    getIt.allowReassignment = true;
    registerFallbackValue(OnboardingFlow.shell);
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
  });

  setUp(() async {
    bloc = MockTransactionBloc();
    templates = MockGetAllRecurringTemplatesUsecase();
    onboarding = MockOnboardingCoordinator();
    categories = MockCategoryRepository();

    // Cubit prefs'i OKUYARAK kuruluyor; mock değerler ondan önce yazılmalı.
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(prefs);
    visibility = AmountVisibilityCubit();

    // Sayfa kategori etiketlerini yükler (tag → görünen ad); kırılım anahtarı
    // hep tag kalır, harita yalnız gösterim içindir.
    when(() => categories.getCategories(any()))
        .thenAnswer((_) async => const <CategoryEntity>[]);
    when(() => categories.getAllCategories()).thenAnswer((_) async => const [
          CategoryEntity(
              id: 'Market',
              name: 'Market',
              iconName: 'shopping_cart',
              isExpense: true),
          CategoryEntity(
              id: 'Fatura',
              name: 'Fatura',
              iconName: 'receipt_long',
              isExpense: true),
        ]);
    getIt.registerSingleton<CategoryRepository>(categories);
    // Sayfa, kategoriler değiştiğinde ikon/ad indeksini tazelemek için bu
    // kanala abone olur (bkz. CategoriesChangedNotifier).
    getIt.registerSingleton<CategoriesChangedNotifier>(
        CategoriesChangedNotifier());

    getIt.registerSingleton<TransactionBloc>(bloc);
    getIt.registerSingleton<GetAllRecurringTemplatesUsecase>(templates);
    getIt.registerSingleton<OnboardingCoordinator>(onboarding);

    when(() => templates()).thenAnswer(
      (_) async => const Right<Failure, List<RecurringTransactionEntity>>([]),
    );
    when(() => onboarding.isSeen(any())).thenReturn(true);
  });

  tearDown(() => getIt.reset());

  TransactionEntity tx({
    required String id,
    required DateTime date,
    required double amount,
    String tag = 'Market',
    String title = 'islem',
    TransactionTypeModel type = TransactionTypeModel.expense,
    bool isSystem = false,
    String walletId = 'w',
  }) =>
      TransactionEntity(
        id: id,
        userId: 'u',
        walletId: walletId,
        title: title,
        tag: tag,
        amount: amount,
        date: date,
        type: type,
        isSystem: isSystem,
      );

  void seed(List<TransactionEntity> txs) {
    when(() => bloc.state).thenReturn(TransactionLoaded(
      groupedTransactions: {DateTime(2020): txs},
      allTransactions: txs,
    ));
  }

  Future<void> pumpPage(WidgetTester tester,
      {Size size = const Size(360, 900)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      BlocProvider<TransactionFilterCubit>(
          create: (_) => TransactionFilterCubit(),
          child: BlocProvider<AmountVisibilityCubit>.value(
            value: visibility,
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
              home: const TransactionInsightsPage(userId: 'u', walletId: 'w'),
            ),
          )),
    );
    await tester.pumpAndSettle();
  }

  /// Ekranda görünen tüm metinler.
  List<String> allTexts(WidgetTester tester) => [
        for (final e in find.byType(Text).evaluate())
          (e.widget as Text).data ?? '',
      ];

  testWidgets('işlem yokken boş durum çizilir', (tester) async {
    seed(const []);
    await pumpPage(tester);

    expect(find.text('Henüz içgörü yok'), findsOneWidget);
  });

  testWidgets('gelir giderden fazlayken günlük harcanabilir tutar çizilir',
      (tester) async {
    seed([
      tx(
          id: 'i1',
          date: dayThisMonth(1),
          amount: 10000,
          tag: 'Maaş',
          type: TransactionTypeModel.income),
      tx(id: 'e1', date: dayThisMonth(1), amount: 2000),
    ]);
    await pumpPage(tester);

    expect(find.byType(TransactionPeriodBar), findsOneWidget);
    expect(find.byType(DailySafeToSpendCard), findsOneWidget);
    expect(find.byType(InsightOverspentCard), findsNothing);
  });

  testWidgets('açık verildiğinde kart KAYBOLMAZ, uyarıya döner',
      (tester) async {
    // Eski davranış: harcanabilir tutar ≤ 0 iken kart tamamen çizilmiyordu.
    // Kullanıcı en çok uyarıya ihtiyaç duyduğu anda hiçbir şey görmüyordu.
    seed([
      tx(
          id: 'i1',
          date: dayThisMonth(1),
          amount: 1000,
          tag: 'Maaş',
          type: TransactionTypeModel.income),
      tx(id: 'e1', date: dayThisMonth(1), amount: 4000),
    ]);
    await pumpPage(tester);

    expect(find.byType(DailySafeToSpendCard), findsNothing);
    expect(find.byType(InsightOverspentCard), findsOneWidget);
    expect(find.text('Bu dönem açıktasın'), findsOneWidget);
  });

  testWidgets('göz düğmesi kapalıyken sayfada AÇIK rakam kalmaz',
      (tester) async {
    // Ölçülen sızıntı: gizliyken 44.620,00 ₺ / 38.155,75 ₺ / 1.271,86 ₺ /
    // "Çarşamba (20.155,75 ₺)" hepsi ekranda duruyordu — sayfa `formatMoney`i
    // doğrudan çağırıyor ve görünürlük anahtarını hiç okumuyordu.
    seed([
      tx(
          id: 'i1',
          date: dayThisMonth(1),
          amount: 44620,
          tag: 'Maaş',
          type: TransactionTypeModel.income),
      tx(id: 'e1', date: dayThisMonth(1), amount: 12000),
      tx(id: 'e2', date: dayThisMonth(2), amount: 8155.75, tag: 'Fatura'),
    ]);
    await pumpPage(tester);
    // Dönem özeti satırı gideri yazar (20.155,75 ₺).
    expect(find.textContaining('20.155'), findsWidgets);

    visibility.emit(false);
    await tester.pumpAndSettle();

    final digits = RegExp(r'\d{1,3}[.,]\d{3}');
    final leaked = allTexts(tester).where(digits.hasMatch).toList();
    expect(leaked, isEmpty, reason: 'gizliyken açık kalan tutarlar: $leaked');
  });

  testWidgets('kuplaj hareketi gidere, en büyük harcamaya ve kategoriye girmez',
      (tester) async {
    seed([
      tx(id: 'e1', date: dayThisMonth(1), amount: 500),
      tx(
        id: 's1',
        date: dayThisMonth(1),
        amount: 18000,
        tag: 'Transfer',
        title: 'Cüzdanlar arası',
        isSystem: true,
      ),
    ]);
    await pumpPage(tester);

    final texts = allTexts(tester).join(' | ');
    expect(texts.contains('Cüzdanlar arası'), isFalse,
        reason: 'transfer "en büyük harcama" olarak yazıldı: $texts');
    expect(find.textContaining('18.000'), findsNothing);
    expect(find.text(formatMoney(500)), findsWidgets);
    // Sessizce atılmaz.
    expect(find.textContaining('sayılmadı'), findsOneWidget);
  });

  testWidgets(
      'REGRESYON: yalnız para taşıma hareketi olan dönem "işlem yok" DEMEZ',
      (tester) async {
    // İşlemler sayfası aynı dönemde kart ödemesini gösterirken bu sayfa
    // "Bu dönemde işlem yok" diyordu.
    final lastMonth = DateTime(now.year, now.month - 1, 10);
    seed([
      tx(
        id: 's1',
        date: dayThisMonth(1),
        amount: 2500,
        tag: 'Transfer',
        title: 'Kart ödemesi',
        isSystem: true,
      ),
      tx(id: 'e1', date: lastMonth, amount: 300),
    ]);
    await pumpPage(tester);

    expect(find.text('Bu dönemde gelir ya da gider yok'), findsOneWidget);
    expect(find.textContaining('1 para taşıma hareketi var'), findsOneWidget);

    final previous = DateFormat.yMMMM('tr')
        .format(DateTime(lastMonth.year, lastMonth.month));
    await tester.tap(find.text('$previous dönemine git'));
    await tester.pumpAndSettle();
    expect(find.text(previous), findsOneWidget);
    expect(find.textContaining(formatMoney(300)), findsWidgets);
  });

  testWidgets('günlük ortalama YAŞANAN güne bölünür', (tester) async {
    // "Bu Ay" ayın 1'inde başlar; bugüne kadar geçen gün sayısı = bugünün
    // ayın kaçı olduğu. Eski kod ayın TAMAMINA bölüyordu ve ayın 3'ünde
    // günlük ortalamayı 10 kat düşük gösteriyordu.
    final elapsed = now.day;
    seed([tx(id: 'e1', date: dayThisMonth(1), amount: 900)]);
    await pumpPage(tester);

    expect(find.text(formatMoney(900 / elapsed)), findsWidgets);
    expect(find.text('$elapsed günün ortalaması'), findsOneWidget);
  });

  testWidgets(
      'ay ortasında başlayan kullanıcıda ortalama, kayıt tuttuğu '
      'günlere bölünür', (tester) async {
    // İlk (ve tek) kayıt bugün: uygulamayı kullanmadığı günler "harcamadığı
    // gün" sayılmaz.
    seed([tx(id: 'e1', date: now, amount: 900)]);
    await pumpPage(tester);

    expect(find.text('1 günün ortalaması'), findsOneWidget);
    expect(find.text(formatMoney(900)), findsWidgets);
  });

  testWidgets('dönem ORTAK: başka sayfada seçilen dönem burada görünür',
      (tester) async {
    final lastMonth = DateTime(now.year, now.month - 1, 10);
    seed([tx(id: 'e1', date: lastMonth, amount: 432)]);
    await pumpPage(tester);
    expect(find.text(formatMoney(432)), findsNothing);

    tester
        .element(find.byType(TransactionInsightsPage))
        .read<TransactionFilterCubit>()
        .setPeriod(monthRangeOf(lastMonth));
    await tester.pumpAndSettle();

    expect(find.text(DateFormat.yMMMM('tr').format(lastMonth)), findsOneWidget);
    expect(find.textContaining(formatMoney(432)), findsWidgets);
  });

  testWidgets(
      'açılış dönemi boşsa SESSİZCE kaymaz, verinin olduğu döneme götürür',
      (tester) async {
    // Dönem artık İşlemler ve Rapor ile ORTAK. Eskiden sayfa boş dönemde
    // kendi dönemini verinin olduğu aya sessizce kaydırıyordu; ortak dönemi
    // arka planda değiştirmek diğer iki sayfayı da kaydırırdı. Kullanıcı
    // yine tek dokunuşla oraya ulaşır.
    final twoMonthsAgo = DateTime(now.year, now.month - 2, 12);
    seed([tx(id: 'e1', date: twoMonthsAgo, amount: 750)]);
    await pumpPage(tester);

    final thisMonth = DateFormat.yMMMM('tr').format(now);
    expect(find.text(thisMonth), findsOneWidget);
    expect(find.text('Seçilen tarih aralığında işlem yok'), findsOneWidget);

    final movedMonth = DateFormat.yMMMM('tr')
        .format(DateTime(twoMonthsAgo.year, twoMonthsAgo.month, 1));
    await tester.tap(find.text('$movedMonth dönemine git'));
    await tester.pumpAndSettle();
    expect(find.text(movedMonth), findsOneWidget);
    expect(find.textContaining(formatMoney(750)), findsWidgets);
  });

  testWidgets(
      'Rapor\'u tekrar etmez: kategori kartı YOK, dönem özeti Rapor\'a götürür',
      (tester) async {
    final requests = HomeNavigationRequests();
    getIt.registerSingleton<HomeNavigationRequests>(requests);
    TransactionsSection? opened;
    requests.sectionHandler = (s) => opened = s;

    seed([
      tx(id: 'e1', date: dayThisMonth(1), amount: 1200),
      tx(id: 'e2', date: dayThisMonth(2), amount: 300, tag: 'Fatura'),
    ]);
    await pumpPage(tester);

    // "En çok harcanan kategori" Rapor'un kategori dağılımının ilk dilimi;
    // cihazda aynı kira ödemesi "en büyük harcama" ile iki kez yazıyordu.
    expect(find.textContaining('Market ·'), findsNothing);
    // Özet kartları (Rapor'la birebir aynıydı) yerine tek satır.
    expect(find.byType(ReportSummaryCards), findsNothing);

    final link = find.textContaining('özeti');
    expect(link, findsOneWidget);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(opened, TransactionsSection.report);
  });

  testWidgets(
      'bütçe %80\'i geçince "Durum"da uyarı çıkar (Rapor ile aynı hesap)',
      (tester) async {
    final budgets = _MockBudgetRepository();
    getIt.registerSingleton<BudgetRepository>(budgets);
    when(() => budgets.getBudgets(any()))
        .thenAnswer((_) async => const Right<Failure, List<BudgetEntity>>([
              BudgetEntity(categoryId: 'Market', limitAmount: 1000),
              BudgetEntity(categoryId: 'Fatura', limitAmount: 5000),
            ]));
    seed([
      tx(id: 'e1', date: dayThisMonth(1), amount: 950),
      tx(id: 'e2', date: dayThisMonth(1), amount: 100, tag: 'Fatura'),
    ]);
    await pumpPage(tester);

    // Market %95 → uyarı; Fatura %2 → uyarıda YOK.
    expect(find.text('Bütçe uyarısı'), findsOneWidget);
    expect(find.textContaining('%95'), findsOneWidget);
    expect(find.textContaining('Fatura %'), findsNothing);
  });

  group('düzenli ödeme önerileri', () {
    /// Üç ay üst üste aynı tutar → aylık örüntü.
    List<TransactionEntity> monthlyPattern() {
      final base = DateTime(now.year, now.month, 10);
      return [
        for (var i = 3; i >= 1; i--)
          tx(
            id: 'r$i',
            date: DateTime(base.year, base.month - i, base.day),
            amount: 250,
            title: 'Spotify',
            tag: 'Abonelik',
          ),
      ];
    }

    testWidgets('yoksayılan öneri listeden düşer ve KALICI yazılır',
        (tester) async {
      seed(monthlyPattern());
      await pumpPage(tester);

      expect(find.byType(RecurringSuggestionCard), findsOneWidget);

      final dismiss = find.text('Yoksay');
      await tester.ensureVisible(dismiss);
      await tester.pumpAndSettle();
      await tester.tap(dismiss);
      await tester.pumpAndSettle();

      expect(find.byType(RecurringSuggestionCard), findsNothing);
      expect(
        RecurringSuggestionDismissStore(prefs).read(),
        contains('spotify|expense'),
        reason: 'yoksayma yalnız bellekte kalırsa açılışta geri gelir',
      );
    });

    testWidgets('kalıcı yoksayma sonraki açılışta da geçerli', (tester) async {
      await prefs.setStringList(
          RecurringSuggestionDismissStore.key, ['spotify|expense']);
      seed(monthlyPattern());
      await pumpPage(tester);

      expect(find.byType(RecurringSuggestionCard), findsNothing);
    });

    testWidgets('öneri kartı sıradaki vadeyi de yazar', (tester) async {
      seed(monthlyPattern());
      await pumpPage(tester);

      final card = find.byType(RecurringSuggestionCard);
      expect(card, findsOneWidget);
      final subtitle = find.descendant(
        of: card,
        matching: find.textContaining('kez tekrarlandı'),
      );
      expect(subtitle, findsOneWidget);
    });
  });

  testWidgets('360dp dar ekranda hiçbir satır taşmaz', (tester) async {
    seed([
      tx(
          id: 'i1',
          date: dayThisMonth(1),
          amount: 1234567.89,
          tag: 'Maaş',
          type: TransactionTypeModel.income),
      tx(
        id: 'e1',
        date: dayThisMonth(1),
        amount: 44620,
        title: 'ÇOK UZUN BİR İŞLEM BAŞLIĞI OLABİLİR BU',
      ),
    ]);
    await pumpPage(tester, size: const Size(360, 900));

    // Taşma, Flutter tarafından hata olarak raporlanır; test bu noktaya
    // gelmişse düzen sığmıştır. Yine de rakamların KESİLMEDİĞİNİ de ölçelim.
    for (final value in [formatMoney(1234567.89), formatMoney(44620)]) {
      final finder = find.text(value);
      if (finder.evaluate().isEmpty) continue;
      final box = tester.renderObject<RenderBox>(finder.first);
      expect(
        box.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(box.size.width + 0.5),
        reason: '"$value" kutusuna sığmıyor → kesiliyor',
      );
    }
  });

  group('cüzdan kapsamı', () {
    testWidgets('BAŞKA cüzdanın işlemleri toplamlara girmez', (tester) async {
      // Bloc state'i cüzdan geçişinde kısa süre ESKİ cüzdanın listesini
      // taşır (`TransactionLoading.previousTransactions`). İşlemler sayfası
      // bunu bilerek süzüyordu, bu sayfa süzmüyordu: yabancı cüzdanın
      // rakamları YENİ cüzdanın para birimi sembolüyle çiziliyordu.
      seed([
        tx(id: 'e1', date: dayThisMonth(1), amount: 2000),
        tx(
            id: 'x1',
            date: dayThisMonth(1),
            amount: 50000,
            walletId: 'baska-cuzdan'),
      ]);
      await pumpPage(tester);

      final texts = allTexts(tester).join(' | ');
      expect(texts.contains(formatMoney(2000, currency: 'TRY')), isTrue,
          reason: 'bu cüzdanın gideri yok');
      expect(texts.contains('52.000'), isFalse,
          reason: 'yabancı cüzdanın gideri toplama girdi');
      expect(texts.contains('50.000'), isFalse);
    });

    testWidgets('BAŞKA cüzdanın düzenli şablonu yükümlülükten düşülmez',
        (tester) async {
      // `GetAllRecurringTemplatesUsecase` adı gibi davranır: cüzdan filtresi
      // yoktur. Süzülmediğinde USD cüzdanındaki 500 $ kira, TRY cüzdanının
      // netinden 500 ₺ olarak düşülüyordu (tutarlar cüzdanın biriminde
      // saklanır, dönüşüm YOK).
      final today = DateTime(now.year, now.month, now.day, 12);
      when(() => templates()).thenAnswer(
        (_) async => Right<Failure, List<RecurringTransactionEntity>>([
          RecurringTransactionEntity(
            id: 'r1',
            userId: 'u',
            walletId: 'baska-cuzdan',
            title: 'Yabancı kira',
            tag: 'Fatura',
            amount: 9999999,
            type: TransactionTypeModel.expense,
            frequency: RecurringFrequency.monthly,
            nextExecutionDate: today,
            anchorDay: today.day,
          ),
        ]),
      );

      seed([
        tx(
            id: 'i1',
            date: dayThisMonth(1),
            amount: 10000,
            tag: 'Maaş',
            type: TransactionTypeModel.income),
        tx(id: 'e1', date: dayThisMonth(1), amount: 2000),
      ]);
      await pumpPage(tester);

      // Süzülmeseydi harcanabilir tutar eksiye düşer ve kart "açıktasınız"
      // uyarısına dönerdi.
      expect(find.byType(DailySafeToSpendCard), findsOneWidget);
      expect(find.byType(InsightOverspentCard), findsNothing);
    });
  });

  group('kart cüzdanı', () {
    // Smoke test C-52: aynı "Ekstre · …" başlığı altında İşlemler bu
    // ekstrenin harcamasını (kayıt tarihi), İçgörü ise ödeme gününe taşınmış
    // ÖNCEKİ ekstrenin harcamasını gösteriyordu.
    const info =
        CreditCardInfo(closingDay: 25, dueDay: 5, paymentWalletId: 'bank');
    final cycle = CardCycle(info);
    final current = cycle.periodContaining(now);
    final previous =
        cycle.periodContaining(current.start.subtract(const Duration(days: 1)));

    Future<TransactionFilterCubit> pumpCard(WidgetTester tester) async {
      final card = WalletEntity(
        id: 'w',
        userId: 'u',
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
      DateTime noon(DateTime d) => DateTime(d.year, d.month, d.day, 12);
      seed([
        tx(id: 'onceki', date: noon(previous.start), amount: 1000),
        tx(id: 'bu', date: noon(current.start), amount: 400),
      ]);
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final cubit = TransactionFilterCubit();
      await tester.pumpWidget(BlocProvider<WalletBloc>.value(
        value: walletBloc,
        child: BlocProvider<TransactionFilterCubit>.value(
          value: cubit,
          child: BlocProvider<AmountVisibilityCubit>.value(
            value: visibility,
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
              home: const TransactionInsightsPage(userId: 'u', walletId: 'w'),
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
