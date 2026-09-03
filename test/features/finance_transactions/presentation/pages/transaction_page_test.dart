import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

class _MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

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

  setUp(() {
    bloc = _MockTransactionBloc();
    categories = _MockCategoryRepository();

    final coordinator = _MockOnboardingCoordinator();
    when(() => coordinator.isSeen(any())).thenReturn(true);

    getIt.registerSingleton<TransactionBloc>(bloc);
    getIt.registerSingleton<CategoryRepository>(categories);
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
          home: BlocProvider<TransactionBloc>.value(
            value: bloc,
            child: TransactionsPage(userId: 'u', wallet: wallet),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
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

      await tester.enterText(find.byType(TransactionSearchField), 'elektrik');
      await tester.pumpAndSettle();

      expect(find.text('ŞOK 4712'), findsNothing);
      expect(find.text('Elektrik faturası'), findsOneWidget);
    });

    testWidgets('kategori ADINDA eşleşen satır kalır', (tester) async {
      // "ŞOK 4712" başlığında "market" geçmiyor; kategori adı eşleşmeli.
      seed([txMarket, txFatura]);
      await pumpPage(tester);

      await tester.enterText(find.byType(TransactionSearchField), 'market');
      await tester.pumpAndSettle();

      expect(find.text('ŞOK 4712'), findsOneWidget);
      expect(find.text('Elektrik faturası'), findsNothing);
    });

    testWidgets('çok kelimeli sorgu alanda ve süzgeçte korunur',
        (tester) async {
      seed([txMarket, txFatura]);
      await pumpPage(tester);

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

      await tester.enterText(find.byType(TransactionSearchField), 'zzzz');
      await tester.pumpAndSettle();

      expect(find.textContaining('zzzz'), findsWidgets);
      expect(find.text('Filtreleri temizle'), findsOneWidget);
    });

    testWidgets('sonuç yokken özet ve gün şeridi de çekilir', (tester) async {
      // Özetlenecek bir şey ve çizilecek bir ısı yokken kartı ve şeridi
      // çizmek boş ekranı gürültüyle doldurur.
      seed([txMarket]);
      await pumpPage(tester);

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

      await tester.enterText(find.byType(TransactionSearchField), 'zzzz');
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

      expect(find.text('Henüz işlem yok'), findsOneWidget);
      expect(find.text('Filtreleri temizle'), findsNothing);
    });

    testWidgets('kayıt varken filtre boşaltmışsa temizleme önerilir',
        (tester) async {
      seed([txMarket]);
      await pumpPage(tester);

      await tester.enterText(find.byType(TransactionSearchField), 'zzzz');
      await tester.pumpAndSettle();

      expect(find.text('Henüz işlem yok'), findsNothing);
      expect(find.text('Filtreleri temizle'), findsOneWidget);
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

    testWidgets('kategori seçimi anında uygulanır ve sayı güncellenir',
        (tester) async {
      seed([txMarket, txFatura]);
      await pumpPage(tester);
      await openFilters(tester);

      // Kategori ağacındaki "Market" satırı (liste sonunda; görünür kıl).
      await tester.ensureVisible(inPanel('Market'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Market'));
      await tester.pumpAndSettle();

      expect(inPanel('1 işlemi göster'), findsOneWidget);
    });

    testWidgets('seçim panel kapanınca çip olarak görünür ve × kaldırır',
        (tester) async {
      seed([txMarket, txFatura]);
      await pumpPage(tester);
      await openFilters(tester);

      await tester.ensureVisible(inPanel('Market'));
      await tester.pumpAndSettle();
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
      expect(find.text('İşlemi Sil'), findsOneWidget);
    });
  });

  group('gün şeridi', () {
    testWidgets('dönemin TÜM günlerini taşır (yalnız işlem olanları değil)',
        (tester) async {
      seed([txMarket]);
      await pumpPage(tester);

      final rail = find.byType(TransactionDayRail);
      expect(rail, findsOneWidget);
      // Ayın ilk günü şeritte olmalı; şerit tembel çizdiği için görünen
      // hücrelerden en az biri sayılabilsin diye 1'i arıyoruz.
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

      await tester.tap(find.descendant(
        of: find.byType(TransactionDayRail),
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
    testWidgets('sorgu etkinken arama alanı kaysa da çip sabit çubukta kalır',
        (tester) async {
      // Sayfa gerçekten kaydırılabilmeli.
      seed(bulk(14, 5));
      await pumpPage(tester);

      await tester.enterText(
          find.descendant(
            of: find.byType(TransactionSearchField),
            matching: find.byType(TextField),
          ),
          'a');
      await tester.pumpAndSettle();

      await tester.drag(
          find.byType(CustomScrollView).first, const Offset(0, -400));
      await tester.pumpAndSettle();

      // Çip metni l10n'deki `txChipSearch` kalıbı: “sorgu”
      expect(
        find.descendant(
          of: find.byType(ActiveFilterChips),
          matching: find.text('\u201Ca\u201D'),
        ),
        findsOneWidget,
      );
      // Arama ALANI gerçekten kaymış olmalı; çip onun yerine geçiyor.
      expect(find.byType(TransactionSearchField), findsNothing);
    });
  });
}
