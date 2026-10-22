import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_fields.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/period_unit_editor.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_period_bar.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/features/main_feature/controllers/home_navigation_requests.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/core/services/recent_categories_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/single_transaction_detail_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/filter_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/active_filter_chips.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_action_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_day_rail.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_summary_strip.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_search_field.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/forecast/data/forecast_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cunehat/features/main_feature/utils/section_visibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cunehat/features/finance_transactions/data/ledger_view_store.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/balance_line/balance_line_view.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

import '../../../../support/wallet_category_stub.dart';

class _MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockForecastService extends Mock implements ForecastService {}

class _MockOnboardingCoordinator extends Mock
    implements OnboardingCoordinator {}

class _FakeTransactionEvent extends Fake implements TransactionEvent {}

void main() {
  setUpAll(() {
    Intl.defaultLocale = 'tr';
    getIt.allowReassignment = true;
    registerFallbackValue(OnboardingFlow.shell);
    registerFallbackValue(_FakeTransactionEvent());
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
  });

  late _MockTransactionBloc bloc;
  late _MockCategoryRepository categories;

  // Bugünün ayına yerleştirilir: varsayılan dönem "bu ay" olduğundan sabit bir
  // takvim yılı kullanmak testi ay başında/sonunda kırılgan yapardı.
  final now = DateTime.now();
  DateTime dayInThisMonth(int day) => DateTime(now.year, now.month, day, 12);

  final txMarket = TransactionEntity(
    id: 'tx-market',
    userId: 'u',
    walletId: 'w1',
    title: 'ŞOK 4712',
    tag: 'cat-market',
    amount: 250,
    date: dayInThisMonth(3),
    type: TransactionTypeModel.expense,
  );
  final txFatura = TransactionEntity(
    id: 'tx-fatura',
    userId: 'u',
    walletId: 'w1',
    title: 'Elektrik faturası',
    tag: 'cat-fatura',
    amount: 500,
    date: dayInThisMonth(4),
    type: TransactionTypeModel.expense,
  );

  // Geçmiş aya ait kayıt: dönem penceresi artık HER ZAMAN uygulandığı için
  // "bu dönemde yok ama geçmişte var" durumunun testi buna dayanıyor.
  final txOldMarket = TransactionEntity(
    id: 'tx-old-market',
    userId: 'u',
    walletId: 'w1',
    title: 'Geçen ay marketi',
    tag: 'cat-market',
    amount: 700,
    date: DateTime(now.year, now.month - 2, 15, 12),
    type: TransactionTypeModel.expense,
  );

  /// Sayfayı gerçekten kaydırılabilir yapacak kadar kayıt. Kısa listede
  /// "kaydırdım" diyen bir test aslında hiçbir şey kaydırmaz.
  List<TransactionEntity> bulk(int count, int day) => [
        for (var i = 0; i < count; i++)
          TransactionEntity(
            id: 'tx-bulk-$i',
            userId: 'u',
            walletId: 'w1',
            title: 'Yığın kaydı $i',
            tag: 'cat-market',
            amount: 100 + i.toDouble(),
            date: dayInThisMonth(day),
            type: TransactionTypeModel.expense,
          ),
      ];

  final wallet = WalletEntity(
    id: 'w1',
    userId: 'u',
    name: 'Cüzdan',
    balance: 1000,
    debt: 0,
    credit: 0,
    investment: 0,
    colorHex: '#3B82F6',
    iconName: 'wallet',
    createdAt: DateTime(2026),
    openingBalance: 1000,
  );

  const categoryList = [
    CategoryEntity(
      id: 'cat-market',
      name: 'Market',
      iconName: 'shopping_cart',
      isExpense: true,
    ),
    CategoryEntity(
      id: 'cat-fatura',
      name: 'Fatura',
      iconName: 'receipt_long',
      isExpense: true,
    ),
  ];

  setUp(() async {
    // Bu dosya LİSTE görünümünü sınar; varsayılan görünüm bakiye hattı
    // (bkz. balance_line_view_test.dart).
    SharedPreferences.setMockInitialValues(
        {LedgerViewStore.key: LedgerView.list.name});
    getIt.registerSingleton<SharedPreferences>(
        await SharedPreferences.getInstance());
    bloc = _MockTransactionBloc();
    categories = _MockCategoryRepository();

    final coordinator = _MockOnboardingCoordinator();
    when(() => coordinator.isSeen(any())).thenReturn(true);

    getIt.registerSingleton<TransactionBloc>(bloc);
    getIt.registerSingleton<CategoryRepository>(categories);
    registerUncuratedWalletCategories(categories);
    getIt.registerSingleton<CategoriesChangedNotifier>(
        CategoriesChangedNotifier());
    getIt.registerSingleton<OnboardingCoordinator>(coordinator);

    when(() => categories.getAllCategories())
        .thenAnswer((_) async => categoryList);
    // Gelir/gider AYRI stub'lanır: filtre paneli karşılaştırma modunda ikisini
    // de yükler; aynı listeyi döndürmek her kategoriyi ekranda iki kez
    // gösterirdi (gerçek depo böyle davranmaz).
    when(() => categories.getCategories(true))
        .thenAnswer((_) async => categoryList);
    when(() => categories.getCategories(false))
        .thenAnswer((_) async => const []);
  });

  tearDown(() => getIt.reset());

  void seed(List<TransactionEntity> transactions) {
    when(() => bloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: const {},
        allTransactions: transactions,
      ),
    );
  }

  Future<void> pumpPage(WidgetTester tester) async {
    // Varsayılan 800×600 test yüzeyi telefon değil tablet oranı: filtre
    // sayfası (0,85 yükseklik) 510px'e sıkışıp bölümler üst üste biniyor.
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      BlocProvider<TransactionFilterCubit>(
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
              supportedLocales: const [Locale('tr'), Locale('en')],
              locale: const Locale('tr'),
              home: BlocProvider<TransactionBloc>.value(
                value: bloc,
                child: TransactionsPage(userId: 'u', wallet: wallet),
              ),
            ),
          )),
    );
    await tester.pumpAndSettle();
  }

  /// Arama artık üst çubukta bir İKON: alan dokununca açılır.
  Future<Finder> openSearch(WidgetTester tester) async {
    final field = find.byType(TransactionSearchField);
    if (field.evaluate().isEmpty) {
      await tester.tap(find.byKey(const ValueKey('tx-search-open')));
      await tester.pumpAndSettle();
    }
    return field;
  }

  testWidgets('tek akış: özet + gün şeridi + defter aynı ekranda',
      (tester) async {
    // Liste/Takvim ikiliği kaldırıldı; ekran tek kaydırma oldu.
    seed([txMarket, txFatura]);
    await pumpPage(tester);

    expect(find.byType(TransactionSummaryStrip), findsOneWidget);
    expect(find.byType(TransactionDayRail), findsOneWidget);
    expect(find.byType(TransactionCard), findsWidgets);
    // Görünüm geçişi düğmesi artık yok.
    expect(find.byIcon(Icons.view_agenda_rounded), findsNothing);
    expect(find.byIcon(Icons.calendar_month_rounded), findsNothing);
  });

  group('arama', () {
    testWidgets('başlıkta eşleşmeyen satır listeden düşer', (tester) async {
      seed([txMarket, txFatura]);
      await pumpPage(tester);

      expect(find.text('ŞOK 4712'), findsOneWidget);
      expect(find.text('Elektrik faturası'), findsOneWidget);

      await tester.enterText(await openSearch(tester), 'elektrik');
      await tester.pumpAndSettle();

      expect(find.text('ŞOK 4712'), findsNothing);
      expect(find.text('Elektrik faturası'), findsOneWidget);
    });

    testWidgets('kategori ADINDA eşleşen satır kalır', (tester) async {
      // "ŞOK 4712" başlığında "market" geçmiyor; kategori adı eşleşmeli.
      seed([txMarket, txFatura]);
      await pumpPage(tester);

      await tester.enterText(await openSearch(tester), 'market');
      await tester.pumpAndSettle();

      expect(find.text('ŞOK 4712'), findsOneWidget);
      expect(find.text('Elektrik faturası'), findsNothing);
    });

    testWidgets('çok kelimeli sorgu alanda ve süzgeçte korunur',
        (tester) async {
      seed([txMarket, txFatura]);
      await pumpPage(tester);
      await openSearch(tester);

      final field = find.descendant(
        of: find.byType(TransactionSearchField),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, 'elektrik fatura');
      await tester.pumpAndSettle();

      expect(
          tester.widget<TextField>(field).controller!.text, 'elektrik fatura');
      expect(find.text('Elektrik faturası'), findsOneWidget);
      expect(find.text('ŞOK 4712'), findsNothing);
    });

    testWidgets('sonuç yoksa sorguyu içeren boş durum çıkar', (tester) async {
      seed([txMarket, txFatura]);
      await pumpPage(tester);

      await tester.enterText(await openSearch(tester), 'zzzz');
      await tester.pumpAndSettle();

      expect(find.textContaining('zzzz'), findsWidgets);
      expect(find.text('Filtreleri temizle'), findsOneWidget);
    });

    testWidgets('sonuç yokken özet ve gün şeridi de çekilir', (tester) async {
      // Özetlenecek bir şey ve çizilecek bir ısı yokken kartı ve şeridi
      // çizmek boş ekranı gürültüyle doldurur.
      seed([txMarket]);
      await pumpPage(tester);

      await openSearch(tester);

      await tester.enterText(
          find.descendant(
            of: find.byType(TransactionSearchField),
            matching: find.byType(TextField),
          ),
          'zzzz');
      await tester.pumpAndSettle();

      expect(find.byType(TransactionSummaryStrip), findsNothing);
      expect(find.byType(TransactionDayRail), findsNothing);
      expect(find.text('Filtreleri temizle'), findsOneWidget);
    });

    testWidgets('boş durumdaki temizle düğmesi listeyi geri getirir',
        (tester) async {
      seed([txMarket, txFatura]);
      await pumpPage(tester);

      await tester.enterText(await openSearch(tester), 'zzzz');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Filtreleri temizle'));
      await tester.pumpAndSettle();

      expect(find.text('ŞOK 4712'), findsOneWidget);
      expect(find.text('Elektrik faturası'), findsOneWidget);
    });
  });

  group('boş durum ayrımı', () {
    testWidgets('cüzdan boşken filtre temizleme ÖNERİLMEZ', (tester) async {
      seed(const []);
      await pumpPage(tester);

      expect(find.text('Henüz kayıt yok'), findsOneWidget);
      expect(find.text('Filtreleri temizle'), findsNothing);
    });

    // Boş defter eskiden yalnız "sürgü butonunu kullanın" diyordu.
    testWidgets('cüzdan boşken Gider/Gelir ekle düğmeleri görünür',
        (tester) async {
      seed(const []);
      await pumpPage(tester);

      expect(
          find.byKey(const ValueKey('tx-empty-add-expense')), findsOneWidget);
      expect(find.byKey(const ValueKey('tx-empty-add-income')), findsOneWidget);
    });

    testWidgets('filtre boşalttıysa ekle düğmeleri ÇIKMAZ', (tester) async {
      seed([txMarket]);
      await pumpPage(tester);

      await tester.enterText(await openSearch(tester), 'zzzz');
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('tx-empty-add-expense')), findsNothing);
    });

    testWidgets('kayıt varken filtre boşaltmışsa temizleme önerilir',
        (tester) async {
      seed([txMarket]);
      await pumpPage(tester);

      await tester.enterText(await openSearch(tester), 'zzzz');
      await tester.pumpAndSettle();

      expect(find.text('Henüz kayıt yok'), findsNothing);
      expect(find.text('Filtreleri temizle'), findsOneWidget);
    });

    // Üçüncü durum: kayıt var, süzgeç YOK, yalnız bu dönem boş. Eskiden bu da
    // arama diliyle konuşuyordu: "Bu dönemde sonuç yok · Tüm geçmişte 160
    // eşleşme var · Filtreleri temizle" (cihazda görüldü). Hiçbir şey aramamış
    // kullanıcıya "eşleşme" ve "filtre" demek yanlış yere gönderir.
    group('süzgeçsiz boş dönem', () {
      Future<void> pumpEmptyPeriod(WidgetTester tester) async {
        seed([txOldMarket]); // yalnız GEÇEN ayda kayıt var
        await pumpPage(tester);
      }

      testWidgets('arama/filtre dili kullanılmaz', (tester) async {
        await pumpEmptyPeriod(tester);

        expect(find.text('Bu dönemde kayıt yok'), findsOneWidget);
        expect(find.text('Bu dönemde sonuç yok'), findsNothing);
        expect(find.textContaining('eşleşme'), findsNothing);
        expect(find.text('Filtreleri temizle'), findsNothing);
        expect(find.text('Tüm geçmişte ara'), findsNothing);
        // "Henüz kayıt yok" da değil: cüzdan boş değil.
        expect(find.text('Henüz kayıt yok'), findsNothing);
      });

      testWidgets('yeni kayıt eklenebilir', (tester) async {
        await pumpEmptyPeriod(tester);

        expect(
            find.byKey(const ValueKey('tx-empty-add-expense')), findsOneWidget);
        expect(
            find.byKey(const ValueKey('tx-empty-add-income')), findsOneWidget);
      });

      testWidgets('"Tüm kayıtları göster" dönemi veriye genişletir',
          (tester) async {
        await pumpEmptyPeriod(tester);

        await tester.tap(find.byKey(const ValueKey('tx-empty-show-all')));
        await tester.pumpAndSettle();

        expect(find.text('Geçen ay marketi'), findsOneWidget);
      });
    });

    // Yalnız İşlemler bölümü açıkken ekranın altında "+ Gelir / − Gider"
    // çubuğu durur; aynı düğmeleri boş ekranda yinelemeye gerek yok.
    group('sade çubuk varken', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        final sections =
            SectionVisibility(await SharedPreferences.getInstance());
        await sections.ensureInitialized(existingInstall: false);
        getIt.registerSingleton<SectionVisibility>(sections);
      });

      testWidgets('boş cüzdanda ekle düğmeleri yinelenmez', (tester) async {
        seed(const []);
        await pumpPage(tester);

        expect(find.text('Henüz kayıt yok'), findsOneWidget);
        expect(
            find.byKey(const ValueKey('tx-empty-add-expense')), findsNothing);
        expect(find.byKey(const ValueKey('tx-empty-add-income')), findsNothing);
      });

      testWidgets('boş dönemde "Tüm kayıtları göster" yine sunulur',
          (tester) async {
        seed([txOldMarket]);
        await pumpPage(tester);

        expect(
            find.byKey(const ValueKey('tx-empty-add-expense')), findsNothing);
        expect(find.byKey(const ValueKey('tx-empty-show-all')), findsOneWidget);
      });
    });
  });

  group('dönem', () {
    testWidgets('ok dönemi kaydırır ve dönem dışı kayıtlar listeden düşer',
        (tester) async {
      seed([txMarket, txFatura]);
      await pumpPage(tester);

      expect(find.text('ŞOK 4712'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      // Bir önceki ayda bu kayıtlar yok.
      expect(find.text('ŞOK 4712'), findsNothing);
      expect(find.text('Elektrik faturası'), findsNothing);
    });

    group('dışarıdan dönem isteği (ekstre "Eklenenleri göster")', () {
      // Sayfa KENDİ süzgeç cubit'ini kuruyor; uygulama seviyesindeki süzgece
      // yazılan dönem buraya hiç ulaşmıyordu (cihazda ölçüldü). İstek artık
      // HomeNavigationRequests ile taşınıyor.
      final old = TransactionEntity(
        id: 'tx-old',
        userId: 'u',
        walletId: 'w1',
        title: 'ESKI EKSTRE SATIRI',
        tag: 'cat-market',
        amount: 42,
        date: DateTime(2025, 6, 10),
        type: TransactionTypeModel.expense,
      );
      final june = DateTimeRange(
        start: DateTime(2025, 6, 1),
        end: DateTime(2025, 6, 30, 23, 59, 59),
      );

      testWidgets('sayfa kurulurken bekleyen istek uygulanır', (tester) async {
        final requests = HomeNavigationRequests();
        getIt.registerSingleton<HomeNavigationRequests>(requests);
        requests.showTransactions(period: june);
        seed([txMarket, old]);

        await pumpPage(tester);

        expect(find.text('ESKI EKSTRE SATIRI'), findsOneWidget);
        expect(find.text('ŞOK 4712'), findsNothing);
        expect(requests.pendingPeriod, isNull, reason: 'bir kez uygulanır');
      });

      testWidgets('açık sayfada istek gelince dönem değişir', (tester) async {
        final requests = HomeNavigationRequests();
        getIt.registerSingleton<HomeNavigationRequests>(requests);
        seed([txMarket, old]);
        await pumpPage(tester);
        expect(find.text('ESKI EKSTRE SATIRI'), findsNothing);

        requests.showTransactions(period: june);
        await tester.pumpAndSettle();

        expect(find.text('ESKI EKSTRE SATIRI'), findsOneWidget);
      });
    });

    testWidgets('dönem etiketi üst çubukta görünür', (tester) async {
      seed([txMarket]);
      await pumpPage(tester);

      final label = DateFormat.yMMMM('tr').format(now);
      expect(find.text(label), findsOneWidget);
    });
  });

  group('filtre paneli', () {
    Future<void> openFilters(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
    }

    /// Panelin İÇİNDEKİ metni bulur.
    ///
    /// Çıplak `find.text` kullanılamaz: sayfa modal panelin ARDINDA duruyor
    /// ve varsayılan takvim görünümü seçili günün kartlarını çiziyor. Kart
    /// kendi kategori rozetini yazdığından, seed edilen kaydın günü takvimin
    /// açılışta seçtiği güne (bugün) denk geldiğinde aynı metin ekranda İKİ
    /// kez bulunuyor ve finder "Too many elements" ile patlıyordu — yani test
    /// ayın 3'ünde kırmızı, 5'inde yeşildi.
    Finder inPanel(String text) => find.descendant(
          of: find.byType(FilterView),
          matching: find.text(text),
        );

    /// Panel listesi tembel: yeni bölümler (tür, para taşıma, diğer) kategori
    /// ağacını ilk ekranın altına itti; öğe kurulana dek kaydırılır.
    Future<void> revealInPanel(WidgetTester tester, String text) async {
      await tester.scrollUntilVisible(
        inPanel(text),
        200,
        scrollable: find
            .descendant(
                of: find.byType(FilterView), matching: find.byType(Scrollable))
            .first,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('düğme kaç işlemin kalacağını ÖNCEDEN söyler', (tester) async {
      seed([txMarket, txFatura]);
      await pumpPage(tester);
      await openFilters(tester);

      expect(find.text('2 işlemi göster'), findsOneWidget);
    });

    testWidgets('klavye açıkken "göster" düğmesi klavyenin ardında kalmaz',
        (tester) async {
      // Panelde iki metin alanı var (tutar + kategori araması). Sabit
      // yükseklikli sheet klavye açılınca daralmazsa alt düğme görünmez olur.
      seed([txMarket]);
      await pumpPage(tester);
      await openFilters(tester);

      const keyboard = 320.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      final button = tester.getRect(find.text('1 işlemi göster'));
      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(button.bottom, lessThanOrEqualTo(screenHeight - keyboard));
    });

    testWidgets('para taşıma "Gizle" transferi listeden düşürür, çip çıkar',
        (tester) async {
      final transfer = TransactionEntity(
        id: 'tx-transfer',
        userId: 'u',
        walletId: txMarket.walletId,
        title: 'Kart ödemesi',
        tag: 'Transfer',
        amount: 2500,
        date: txMarket.date,
        type: TransactionTypeModel.expense,
        isSystem: true,
      );
      seed([txMarket, txFatura, transfer]);
      await pumpPage(tester);
      expect(find.text('Kart ödemesi'), findsOneWidget);

      await openFilters(tester);
      await revealInPanel(tester, 'Gizle');
      await tester.tap(inPanel('Gizle'));
      await tester.pumpAndSettle();
      expect(inPanel('2 işlemi göster'), findsOneWidget);

      await tester.tap(inPanel('2 işlemi göster'));
      await tester.pumpAndSettle();
      expect(find.text('Kart ödemesi'), findsNothing);
      expect(find.text('Para taşıma gizli'), findsOneWidget);
    });

    testWidgets('kategori seçimi anında uygulanır ve sayı güncellenir',
        (tester) async {
      seed([txMarket, txFatura]);
      await pumpPage(tester);
      await openFilters(tester);

      // Kategori ağacındaki "Market" satırı (liste sonunda; görünür kıl).
      await revealInPanel(tester, 'Market');
      await tester.tap(inPanel('Market'));
      await tester.pumpAndSettle();

      expect(inPanel('1 işlemi göster'), findsOneWidget);
    });

    testWidgets('seçim panel kapanınca çip olarak görünür ve × kaldırır',
        (tester) async {
      seed([txMarket, txFatura]);
      await pumpPage(tester);
      await openFilters(tester);

      await revealInPanel(tester, 'Market');
      await tester.tap(inPanel('Market'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('1 işlemi göster'));
      await tester.pumpAndSettle();

      // Çip tek kategori seçiliyken adı yazar. Arama çip ŞERİDİNE
      // daraltılır: aynı ad kartın kategori rozetinde de geçiyor.
      Finder inChips(String text) => find.descendant(
            of: find.byType(ActiveFilterChips),
            matching: find.text(text),
          );
      expect(inChips('Market'), findsOneWidget);

      await tester.tap(find.descendant(
        of: find.byType(ActiveFilterChips),
        matching: find.byIcon(Icons.close_rounded),
      ));
      await tester.pumpAndSettle();
      expect(inChips('Market'), findsNothing);
    });

    testWidgets('eşleşme kalmayınca düğme "Eşleşen işlem yok" der',
        (tester) async {
      seed([txMarket]);
      await pumpPage(tester);
      await openSearch(tester);
      await tester.enterText(
          find.descendant(
            of: find.byType(TransactionSearchField),
            matching: find.byType(TextField),
          ),
          'zzzz');
      await tester.pumpAndSettle();
      await openFilters(tester);

      expect(find.text('Eşleşen işlem yok'), findsOneWidget);
    });

    testWidgets('panel "Temizle" dönemi de varsayılana döndürür',
        (tester) async {
      seed([txMarket]);
      await pumpPage(tester);

      // Önce dönemi geçen aya kaydır.
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();
      await openFilters(tester);

      await tester.tap(find.text('Temizle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 işlemi göster'));
      await tester.pumpAndSettle();

      expect(find.text(DateFormat.yMMMM('tr').format(now)), findsOneWidget);
    });
  });
  group('bugüne dön', () {
    testWidgets('dönem bugünü kapsarken düğme YOKTUR', (tester) async {
      seed([txMarket]);
      await pumpPage(tester);
      expect(find.text('Bugüne dön'), findsNothing);
    });

    testWidgets('geçmiş döneme gidilince çıkar ve TÜRÜ koruyarak döner',
        (tester) async {
      seed([txMarket, txOldMarket]);
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Bugüne dön'), findsOneWidget);

      await tester.tap(find.text('Bugüne dön'));
      await tester.pumpAndSettle();

      expect(find.text(DateFormat.yMMMM('tr').format(now)), findsOneWidget);
      expect(find.text('Bugüne dön'), findsNothing);
    });
  });

  group('dönem dışı eşleşme', () {
    testWidgets('bu dönemde yok ama geçmişte varsa çıkış yolu sunulur',
        (tester) async {
      seed([txFatura, txOldMarket]);
      await pumpPage(tester);

      await openSearch(tester);

      await tester.enterText(
          find.descendant(
            of: find.byType(TransactionSearchField),
            matching: find.byType(TextField),
          ),
          'market');
      await tester.pumpAndSettle();

      expect(find.text('Bu dönemde sonuç yok'), findsOneWidget);
      expect(find.text('Tüm geçmişte 1 eşleşme var.'), findsOneWidget);
      expect(find.text('Tüm geçmişte ara'), findsOneWidget);
    });

    testWidgets('"Tüm geçmişte ara" dönemi veriye genişletir', (tester) async {
      seed([txFatura, txOldMarket]);
      await pumpPage(tester);

      await openSearch(tester);

      await tester.enterText(
          find.descendant(
            of: find.byType(TransactionSearchField),
            matching: find.byType(TextField),
          ),
          'market');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tüm geçmişte ara'));
      await tester.pumpAndSettle();

      expect(find.text('Geçen ay marketi'), findsOneWidget);
    });

    testWidgets('hiçbir yerde eşleşme yoksa genişletme ÖNERİLMEZ',
        (tester) async {
      seed([txMarket, txOldMarket]);
      await pumpPage(tester);

      await openSearch(tester);

      await tester.enterText(
          find.descendant(
            of: find.byType(TransactionSearchField),
            matching: find.byType(TextField),
          ),
          'zzzz');
      await tester.pumpAndSettle();

      expect(find.text('Tüm geçmişte ara'), findsNothing);
      expect(find.text('Filtreleri temizle'), findsOneWidget);
    });
  });

  group('satır eylemleri', () {
    testWidgets('⋮ eylem sayfasını açar, detay sayfasını AÇMAZ',
        (tester) async {
      // Kaydırma eylemleri 29 Ağu'da kaldırıldığından beri düzenle/sil'e
      // giden tek yol uzun basmaktı ve ekranda hiçbir işareti yoktu.
      seed([txMarket]);
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
      await tester.pumpAndSettle();

      expect(find.byType(SingleTransactionDetailPage), findsNothing);
      expect(find.byType(TransactionActionSheet), findsOneWidget);
      expect(find.text('Düzenle'), findsOneWidget);
      expect(find.text('İşlemi sil'), findsOneWidget);
    });
  });

  // UX Tur 4 · E6 — ÖNCE: yanlış kategoriye düşen on satırı düzeltmenin tek
  // yolu her birini tek tek açıp düzenlemekti.
  group('çoklu seçim → toplu kategori', () {
    final selectionBar = find.byKey(const ValueKey('ledger-selection-bar'));

    setUp(() async {
      // Kategori seçicisi "son kullanılanlar"ı bu servisten okur.
      SharedPreferences.setMockInitialValues({});
      getIt.registerSingleton<RecentCategoriesService>(
        RecentCategoriesService(await SharedPreferences.getInstance()),
      );
    });

    /// İlk satırın (Elektrik faturası) ⋮ menüsünden seçimi başlatır.
    Future<void> startSelection(WidgetTester tester) async {
      seed([txMarket, txFatura]);
      await pumpPage(tester);
      await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Birden çok seç'));
      await tester.pumpAndSettle();
    }

    testWidgets(
        'eylem sayfasından başlar; dokunmak seçer (detay AÇMAZ); seçilenlerin '
        'kategorisi tek onayla değişir', (tester) async {
      await startSelection(tester);

      expect(selectionBar, findsOneWidget);
      expect(find.text('1 seçili'), findsOneWidget);

      await tester.tap(find.text('ŞOK 4712'));
      await tester.pumpAndSettle();
      expect(find.byType(SingleTransactionDetailPage), findsNothing);
      expect(find.text('2 seçili'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ledger-recategorize')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fatura').last);
      await tester.pumpAndSettle();

      // Yazmadan önce kaç işlemin neye döneceği söylenir.
      expect(find.text('Kategori değiştirilsin mi?'), findsOneWidget);
      expect(
          find.textContaining('2 işlemin kategorisi “Fatura”'), findsOneWidget);
      await tester.tap(find.text('Değiştir'));
      await tester.pumpAndSettle();

      final event = verify(() => bloc.add(captureAny()))
          .captured
          .whereType<ChangeTransactionsCategoryEvent>()
          .single;
      expect(event.categoryId, 'cat-fatura');
      expect(event.transactions.map((t) => t.id).toSet(),
          {'tx-market', 'tx-fatura'});
      // Seçim kipi kapanır.
      expect(selectionBar, findsNothing);
    });

    testWidgets('onayda vazgeçilirse hiçbir şey yazılmaz, seçim durur',
        (tester) async {
      await startSelection(tester);

      await tester.tap(find.byKey(const ValueKey('ledger-recategorize')));
      await tester.pumpAndSettle();
      // Seçicide açılışta ilk kök (Fatura) etkin: sağdaki satırı seçilir.
      await tester.tap(find.text('Fatura').last);
      await tester.pumpAndSettle();
      expect(find.text('Kategori değiştirilsin mi?'), findsOneWidget);
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();

      verifyNever(
          () => bloc.add(any(that: isA<ChangeTransactionsCategoryEvent>())));
      expect(find.text('1 seçili'), findsOneWidget);
    });

    testWidgets('son seçim kalkınca kip biter; çarpı da kapatır',
        (tester) async {
      await startSelection(tester);

      // Seçili satıra yeniden dokun: seçim kalkar, kip biter.
      await tester.tap(find.text('Elektrik faturası'));
      await tester.pumpAndSettle();
      expect(selectionBar, findsNothing);
      expect(find.byType(SingleTransactionDetailPage), findsNothing);

      await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Birden çok seç'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Seçimi kapat'));
      await tester.pumpAndSettle();
      expect(selectionBar, findsNothing);
    });
  });

  group('gün şeridi', () {
    testWidgets('dönemin TÜM günlerini taşır (yalnız işlem olanları değil)',
        (tester) async {
      seed([txMarket]);
      await pumpPage(tester);

      final rail = find.byType(TransactionDayRail);
      expect(rail, findsOneWidget);

      // Şerit tembel çizer VE açılışta bugüne ortalanır, yani hangi hücrenin
      // ağaçta olduğu duvar saatine bağlıdır: ayın 1'ini doğrudan aramak
      // takvim ilerledikçe kendiliğinden kırılan bir iddiaydı (ölçüldü —
      // 3 Eyl'de çapa 0, 7 Eyl'de 93 px; 1. gün hiç kurulmadı). Şeridi BAŞA
      // kaydırıp aramak hem saatten bağımsızdır hem de asıl iddiayı ("şerit
      // yalnız işlem olan günleri değil, dönemin tamamını kapsar") daha
      // sadık ölçer: işlem olmayan 1. gün ancak kapsam gerçekse oradadır.
      await tester.drag(rail, const Offset(3000, 0));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: rail, matching: find.text('1')),
        findsOneWidget,
      );
    });

    testWidgets('bir güne dokunmak defteri oraya kaydırır, dönemi DEĞİŞTİRMEZ',
        (tester) async {
      // Şerit gezinme aracıdır. Eski takvimde sayfa çevirmek kullanıcının
      // seçtiği dönemi sessizce yeniden yazıyordu (ölçüldü: "Bu yıl" → tek
      // ay); şerit bunu yapmamalı.
      //
      // Hedef günün BAŞTA GÖRÜNMEZ olması şart, yoksa test kaydırmayı değil
      // yalnız "kart var mı"yı ölçer. Ayın son gününe 14 kayıt yığılıyor;
      // defter yeniden eskiye sıralı olduğu için ayın 1'indeki tek kayıt
      // listenin çok altında kalıyor. Kurulum bugünün ayın kaçı olduğundan
      // BAĞIMSIZ.
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      seed([
        for (var i = 0; i < 14; i++)
          TransactionEntity(
            id: 'tx-bulk-\$i',
            userId: 'u',
            walletId: 'w1',
            title: 'Yığın kaydı \$i',
            tag: 'cat-market',
            amount: 100 + i.toDouble(),
            date: dayInThisMonth(lastDay),
            type: TransactionTypeModel.expense,
          ),
        TransactionEntity(
          id: 'tx-oldest',
          userId: 'u',
          walletId: 'w1',
          title: 'Ayın ilk kaydı',
          tag: 'cat-fatura',
          amount: 999,
          date: dayInThisMonth(1),
          type: TransactionTypeModel.expense,
        ),
      ]);
      await pumpPage(tester);

      final label = DateFormat.yMMMM('tr').format(now);
      expect(find.text('Ayın ilk kaydı'), findsNothing,
          reason: 'hedef başta görünüyorsa test kaydırmayı ölçmez');

      final cell = find.descendant(
        of: find.byType(TransactionDayRail),
        matching: find.text('1'),
      );
      await tester.dragUntilVisible(
        cell,
        find.byType(TransactionDayRail),
        const Offset(120, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(cell);
      await tester.pumpAndSettle();

      expect(find.text('Ayın ilk kaydı'), findsOneWidget);
      // Dönem etiketi değişmedi.
      expect(find.text(label), findsOneWidget);
    });
  });

  group('tarihe hızlı giriş', () {
    Future<void> tapRailDay(WidgetTester tester, int day) async {
      final cell = find.descendant(
        of: find.byType(TransactionDayRail),
        matching: find.text('$day'),
      );
      await tester.dragUntilVisible(
        cell,
        find.byType(TransactionDayRail),
        const Offset(120, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(cell);
      await tester.pumpAndSettle();
    }

    testWidgets('kaydı OLMAYAN gün seçilince "ekle" satırı çıkar',
        (tester) async {
      // Eskiden boş güne dokunmak yalnız şeritteki vurguyu değiştiriyordu.
      seed([txMarket, txFatura]); // ayın 3'ü ve 4'ü
      await pumpPage(tester);
      final add = find.byKey(const ValueKey('tx-empty-day-add'));
      expect(add, findsNothing);

      await tapRailDay(tester, 1);
      expect(add, findsOneWidget);
      expect(find.textContaining('kayıt yok'), findsOneWidget);

      // Kaydı olan güne geçilince satır çekilir: o günün başlığında "+" var.
      await tapRailDay(tester, 3);
      expect(add, findsNothing);
    });

    testWidgets('gün başlığındaki "+" formu O GÜNLE açar', (tester) async {
      seed([txMarket, txFatura]);
      await pumpPage(tester);

      final month = now.month.toString().padLeft(2, '0');
      await tester
          .tap(find.byKey(ValueKey('tx-day-add-${now.year}-$month-03')));
      await tester.pumpAndSettle();

      final form = tester
          .widget<TransactionFormSheet>(find.byType(TransactionFormSheet));
      expect(form.initialTransaction, isNull);
      expect(
          DateTime(form.initialDate!.year, form.initialDate!.month,
              form.initialDate!.day),
          DateTime(now.year, now.month, 3));
    });
  });

  group('şerit seçimi dönemle tutarlı', () {
    testWidgets('ay değişince önceki günün vurgusu düşer', (tester) async {
      // Seçim dönem dışına düşerse hem yanlış bir gün vurgulanır hem de
      // şerit kendini ortalayamaz (indexWhere -1 döner).
      // Geçen ayda da kayıt olmalı: boş dönemde şerit hiç çizilmiyor ve
      // test "vurgu düştü" yerine "şerit yok" ölçerdi.
      seed([
        txMarket,
        TransactionEntity(
          id: 'tx-last-month',
          userId: 'u',
          walletId: 'w1',
          title: 'Geçen ay kaydı',
          tag: 'cat-market',
          amount: 120,
          date: DateTime(now.year, now.month - 1, 15, 12),
          type: TransactionTypeModel.expense,
        ),
      ]);
      await pumpPage(tester);

      // Şerit tembel çizer ve açılışta bugüne ortalanır: sabit bir gün
      // numarasını doğrudan aramak, çapa ilerledikçe kendiliğinden kırılan
      // bir iddiadır (ölçüldü — aynı kod 8 Eyl'de yeşil, 9 Eyl'de "0 widget
      // with text '3'"). Aynı kalıp bu dosyadaki "dönemin TÜM günleri"
      // testinde de var: önce başa kaydır, sonra ara.
      final rail = find.byType(TransactionDayRail);
      await tester.drag(rail, const Offset(3000, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: rail,
        matching: find.text('3'),
      ));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TransactionDayRail>(find.byType(TransactionDayRail))
            .selectedDay,
        isNotNull,
      );

      // Geçen aya git: seçim artık dönemde değil.
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TransactionDayRail>(find.byType(TransactionDayRail))
            .selectedDay,
        isNull,
      );
    });
  });

  group('arama çipi', () {
    testWidgets('arama kapanınca sorgu KORUNUR; çip sabit çubukta kalır',
        (tester) async {
      // Sayfa gerçekten kaydırılabilmeli.
      seed(bulk(14, 5));
      await pumpPage(tester);

      await openSearch(tester);

      await tester.enterText(
          find.descendant(
            of: find.byType(TransactionSearchField),
            matching: find.byType(TextField),
          ),
          'a');
      await tester.pumpAndSettle();

      // Klavyedeki "Ara": alan kapanır, sorgu korunur.
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.byType(TransactionSearchField), findsNothing);

      await tester.drag(
          find.byType(CustomScrollView).first, const Offset(0, -400));
      await tester.pumpAndSettle();

      // Çip metni l10n'deki `txChipSearch` kalıbı: “sorgu” — kaydırınca da
      // sabit çubukta kalır.
      expect(
        find.descendant(
          of: find.byType(ActiveFilterChips),
          matching: find.text('\u201Ca\u201D'),
        ),
        findsOneWidget,
      );
    });
  });

  group('tümünü daralt / genişlet', () {
    testWidgets('tek dokunuşla bütün günler kapanır, ikincisiyle açılır',
        (tester) async {
      seed([txMarket, txFatura]);
      await pumpPage(tester);
      expect(find.byType(TransactionCard), findsWidgets);

      // Özet kartındaki ikon (ayrı satır değil).
      final toggle = find.byKey(const ValueKey('tx-collapse-all'));
      expect(
          find.descendant(
              of: find.byType(TransactionSummaryStrip), matching: toggle),
          findsOneWidget);
      expect(find.byTooltip('Tümünü daralt'), findsOneWidget);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.byType(TransactionCard), findsNothing);
      expect(find.byTooltip('Tümünü genişlet'), findsOneWidget);

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.byType(TransactionCard), findsWidgets);
    });

    testWidgets('tek günlük listede düğme YOK', (tester) async {
      seed([txMarket]);
      await pumpPage(tester);
      expect(find.byKey(const ValueKey('tx-collapse-all')), findsNothing);
    });
  });

  group('dönem sayfası', () {
    testWidgets(
        'birim DÜZENLENMEZ: yalnız geçerli birim ve Ayarlar yönlendirmesi var',
        (tester) async {
      seed([txMarket, txFatura]);
      await pumpPage(tester);

      await tester.tap(find.text(periodLabel(monthRangeOf(DateTime.now()),
          lookupAppLocalizations(const Locale('tr')))));
      await tester.pumpAndSettle();
      expect(find.text('Dönem'), findsOneWidget);

      // Eskiden sayfanın en üstünde Gün/Hafta/2 Hafta/Ay seçimi ve başlangıç
      // ayarı duruyordu; tarih seçmeye gelen kullanıcıyı kalıcı bir ayarla
      // karşılıyordu. Düzenleme artık yalnız Ayarlar'da.
      expect(find.byType(PeriodUnitEditor), findsNothing);
      expect(find.text('DÖNEM BİRİMİ'), findsNothing);
      expect(find.text('2 Hafta'), findsNothing);
      expect(find.text('Hazır aralıklar'), findsOneWidget);

      final footer = find.byKey(const ValueKey('period-unit-settings'));
      await tester.ensureVisible(footer);
      expect(
          find.descendant(of: footer, matching: find.text('Dönem birimi: Ay')),
          findsOneWidget);
      expect(
          find.descendant(
              of: footer, matching: find.text("Ayarlar'dan değiştir")),
          findsOneWidget);

      // Yönlendiricisiz ağaçta dokunuş sayfayı kapatır, hata vermez.
      await tester.tap(footer);
      await tester.pumpAndSettle();
      expect(find.text('Hazır aralıklar'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('bakiye hattı (varsayılan görünüm)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      getIt.registerSingleton<SharedPreferences>(
          await SharedPreferences.getInstance());
    });

    testWidgets('tercih yokken bakiye hattı açılır, liste değil',
        (tester) async {
      seed([txMarket, txFatura]);
      await pumpPage(tester);

      expect(find.byType(BalanceLineView), findsOneWidget);
      expect(find.byType(TransactionSummaryStrip), findsNothing);
      expect(find.byType(TransactionCard), findsNothing);
    });

    testWidgets('liste ↔ bakiye hattı geçişi tercihi saklar', (tester) async {
      seed([txMarket, txFatura]);
      await pumpPage(tester);
      final prefs = getIt<SharedPreferences>();

      await tester.tap(find.byKey(const ValueKey('bl-show-list')));
      await tester.pumpAndSettle();
      expect(find.byType(BalanceLineView), findsNothing);
      expect(find.byType(TransactionCard), findsNWidgets(2));
      expect(prefs.getString(LedgerViewStore.key), LedgerView.list.name);

      await tester.tap(find.byKey(const ValueKey('tx-show-line')));
      await tester.pumpAndSettle();
      expect(find.byType(BalanceLineView), findsOneWidget);
      expect(prefs.getString(LedgerViewStore.key), LedgerView.balanceLine.name);
    });

    testWidgets('arama etkinken sonuçlar LİSTEDE; aramayı silince geri döner',
        (tester) async {
      seed([txMarket, txFatura]);
      await pumpPage(tester);

      await tester.enterText(await openSearch(tester), 'elektrik');
      await tester.pumpAndSettle();
      expect(find.byType(BalanceLineView), findsNothing);
      expect(find.text('Elektrik faturası'), findsOneWidget);
      // Arama etkinken listeden bakiye hattına geçiş önerilmez.
      expect(find.byKey(const ValueKey('tx-show-line')), findsNothing);

      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();
      expect(find.byType(BalanceLineView), findsOneWidget);
    });

    testWidgets('boş cüzdanda bakiye hattı değil, karşılama durumu çıkar',
        (tester) async {
      seed(const []);
      await pumpPage(tester);
      expect(find.byType(BalanceLineView), findsNothing);
    });

    // ÖNCE: fişteki "Birden çok seç" seçimi başlatıyordu ama fişte seçili
    // satır görünmüyordu — kullanıcı görmediği kayıtlara toplu işlem
    // uygulayabilirdi.
    testWidgets(
        'fişten seçim başlayınca LİSTE açılır; seçim bitince hat döner, '
        'tercih değişmez', (tester) async {
      final txToday = TransactionEntity(
        id: 'tx-bugun',
        userId: 'u',
        walletId: 'w1',
        title: 'Simit',
        tag: 'cat-market',
        amount: 20,
        date: DateTime(now.year, now.month, now.day, 9),
        type: TransactionTypeModel.expense,
      );
      seed([txMarket, txToday]);
      await pumpPage(tester);
      expect(find.byType(BalanceLineView), findsOneWidget);

      await tester.longPress(find.text('Simit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Birden çok seç'));
      await tester.pumpAndSettle();

      expect(find.byType(BalanceLineView), findsNothing);
      expect(
          find.byKey(const ValueKey('ledger-selection-bar')), findsOneWidget);
      expect(find.text('1 seçili'), findsOneWidget);
      // Seçim sürerken hatta dönüş düğmesi ölü kalırdı: gösterilmez.
      expect(find.byKey(const ValueKey('tx-show-line')), findsNothing);

      // Seçim kipinde dokunmak seçimi kaldırır → kip biter.
      await tester.tap(find.text('Simit'));
      await tester.pumpAndSettle();
      expect(find.byType(BalanceLineView), findsOneWidget);
      expect(getIt<SharedPreferences>().getString(LedgerViewStore.key), isNull);
    });

    testWidgets(
        'tahmin yalnız aktif cüzdan için istenir; bütçe değişince ve '
        'uygulamaya dönünce yenilenir', (tester) async {
      registerFallbackValue(
          DateTimeRange(start: DateTime(2026), end: DateTime(2026, 1, 2)));
      final service = _MockForecastService();
      when(() => service.forecast(
                userId: any(named: 'userId'),
                period: any(named: 'period'),
                horizonDays: any(named: 'horizonDays'),
                walletId: any(named: 'walletId'),
              ))
          .thenAnswer(
              (_) async => const ForecastResult(wallets: {}, categories: []));
      getIt.registerSingleton<ForecastService>(service);
      final budgets = BudgetsChangedNotifier();
      getIt.registerSingleton<BudgetsChangedNotifier>(budgets);

      seed([txMarket, txFatura]);
      await pumpPage(tester);

      // Ayın son günüyse dönemde gelecek yok, tahmin hiç istenmez.
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      final calls = monthEnd.day == now.day ? 0 : 1;
      verify(() => service.forecast(
            userId: 'u',
            period: any(named: 'period'),
            horizonDays: any(named: 'horizonDays'),
            walletId: 'w1',
          )).called(calls);

      budgets.notify();
      await tester.pumpAndSettle();
      verify(() => service.forecast(
            userId: 'u',
            period: any(named: 'period'),
            horizonDays: any(named: 'horizonDays'),
            walletId: 'w1',
          )).called(calls);

      // Uygulamaya dönüş: şablon/borç başka yerde değişmiş olabilir.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      verify(() => service.forecast(
            userId: 'u',
            period: any(named: 'period'),
            horizonDays: any(named: 'horizonDays'),
            walletId: 'w1',
          )).called(calls);
    });
  });
}
