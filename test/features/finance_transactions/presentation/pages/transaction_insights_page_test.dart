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
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_transaction_list_sheet.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/services/recurring_suggestion_dismiss_store.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/get_all_recurring_templates_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
  }) =>
      TransactionEntity(
        id: id,
        userId: 'u',
        walletId: 'w',
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
      BlocProvider<AmountVisibilityCubit>.value(
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

    expect(find.text('Henüz İçgörü Yok'), findsOneWidget);
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

    expect(find.text('Akıllı İçgörüler'), findsWidgets);
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
    expect(find.text('Bu Dönem Açıktasınız'), findsOneWidget);
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
    expect(find.textContaining('44.620'), findsWidgets);

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

  testWidgets('günlük ortalama YAŞANAN güne bölünür', (tester) async {
    // "Bu Ay" ayın 1'inde başlar; bugüne kadar geçen gün sayısı = bugünün
    // ayın kaçı olduğu. Eski kod ayın TAMAMINA bölüyordu ve ayın 3'ünde
    // günlük ortalamayı 10 kat düşük gösteriyordu.
    final elapsed = now.day;
    seed([tx(id: 'e1', date: dayThisMonth(1), amount: 900)]);
    await pumpPage(tester);

    expect(find.text(formatMoney(900 / elapsed)), findsWidgets);
    expect(find.text('Yaşanan $elapsed gün üzerinden'), findsOneWidget);
  });

  testWidgets('açılış dönemi boşsa verinin OLDUĞU aya kayar', (tester) async {
    // Uygulamayı bir aylık aradan sonra açan kullanıcı sayfayı tamamen boş
    // görüyor ve verisinin durduğu döneme kendi elleriyle gitmek zorundaydı.
    // (Rapor sayfasında zaten çözülmüştü.)
    final twoMonthsAgo = DateTime(now.year, now.month - 2, 12);
    seed([tx(id: 'e1', date: twoMonthsAgo, amount: 750)]);
    await pumpPage(tester);

    expect(find.text('Bu dönemde işlem yok'), findsNothing);
    expect(find.text(formatMoney(750)), findsWidgets);
    // Dönem başlığı da kaymış olmalı (etiket tek parça yazılır).
    final movedStart = DateFormat('dd MMM yyyy')
        .format(DateTime(twoMonthsAgo.year, twoMonthsAgo.month, 1));
    expect(find.textContaining(movedStart), findsOneWidget);
  });

  testWidgets('en çok harcanan kategoriye dokunmak işlemleri açar',
      (tester) async {
    seed([
      tx(id: 'e1', date: dayThisMonth(1), amount: 1200),
      tx(id: 'e2', date: dayThisMonth(2), amount: 300, tag: 'Fatura'),
    ]);
    await pumpPage(tester);

    final row = find.textContaining('Market ·');
    expect(row, findsOneWidget);
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.byType(ReportTransactionListSheet), findsOneWidget);
    expect(find.text(formatMoney(1200)), findsWidgets);
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
}
