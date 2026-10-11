import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/services/recent_categories_service.dart';
import 'package:cunehat/features/bank_import/data/card_statement_parser.dart';
import 'package:cunehat/features/bank_import/data/statement_verification.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/bank_import/presentation/pages/bank_import_review_view.dart';
import 'package:cunehat/features/bank_import/presentation/widgets/leftover_review_sheet.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/wallet_category_service.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockBankImportCubit extends MockCubit<BankImportState>
    implements BankImportCubit {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

class MockWalletCategoryService extends Mock implements WalletCategoryService {}

class FakeCategoryEntity extends Fake implements CategoryEntity {}

CategoryEntity _cat(
  String id, {
  bool expense = true,
  String? name,
  String? parent,
}) =>
    CategoryEntity(
      id: id,
      name: name ?? id,
      iconName: 'category',
      isExpense: expense,
      parentId: parent,
      sortOrder: 1,
    );

ImportDraft _draft({
  required String description,
  String? categoryId,
  bool duplicate = false,
  bool income = false,
  double amount = 100,
  int day = 5,
}) =>
    ImportDraft(
      date: DateTime(2026, 3, day),
      description: description,
      amount: amount,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      categoryId: categoryId,
      duplicateOf: duplicate
          ? DuplicateMatch(
              kind: DuplicateKind.exact,
              existingId: 'tx-$description',
              existingTitle: description,
              existingAmount: amount,
              existingDate: DateTime(2026, 3, day),
            )
          : null,
    );

void main() {
  // Para metni Intl.defaultLocale'e bakar; testte boş bırakılırsa intl onu
  // sessizce sistem locale'ine (genelde en_US) bağlar ve beklentiler
  // makineye göre kayar. Uygulamanın varsayılanına sabitliyoruz.
  setUpAll(() {
    Intl.defaultLocale = 'tr';
    getIt.allowReassignment = true;
    registerFallbackValue(FakeCategoryEntity());
    registerFallbackValue(TransactionTypeModel.expense);
  });

  late MockBankImportCubit cubit;
  late MockCategoryRepository categoryRepo;
  late int fullscreenToggles;

  setUp(() async {
    // Seçici "son kullanılanlar" şeridini bu servisten okuyor.
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton<RecentCategoriesService>(
      RecentCategoriesService(await SharedPreferences.getInstance()),
    );

    cubit = MockBankImportCubit();
    fullscreenToggles = 0;
    // Kategori seçicileri kapsamlarını cubit'in hedef cüzdanından alır.
    when(() => cubit.walletId).thenReturn('w1');
    when(() => cubit.setSelectedAt(any(), any())).thenReturn(null);
    when(() => cubit.setAllType(any())).thenReturn(null);
    when(() => cubit.switchTarget(any())).thenAnswer((_) async {});
    when(() => cubit.toggleDraft(any())).thenReturn(null);
    when(() => cubit.setDraftCategory(any(), any())).thenReturn(null);
    when(() => cubit.applyCategoryToIndexes(any(), any())).thenReturn(null);
    when(() => cubit.registerCreatedCategory(any())).thenReturn(null);

    // Kategori sayfasından "Yeni kategori" akışı `showCategoryForm` üzerinden
    // gerçek depoyu (getIt) kullanır.
    categoryRepo = MockCategoryRepository();
    getIt.registerSingleton<CategoryRepository>(categoryRepo);
    when(() => categoryRepo.getAllCategories()).thenAnswer((_) async => [
          ...await categoryRepo.getCategories(true),
          ...await categoryRepo.getCategories(false),
        ]);
    // Seçici paylaşılan yüzeydir ve listeyi DEPODAN okur (eskiden state'ten
    // parametreyle alıyordu).
    when(() => categoryRepo.getCategories(true))
        .thenAnswer((_) async => [_cat('Market'), _cat('Fatura')]);
    when(() => categoryRepo.getCategories(false))
        .thenAnswer((_) async => <CategoryEntity>[]);
    when(() => categoryRepo.addCategory(
              name: any(named: 'name'),
              iconName: any(named: 'iconName'),
              isExpense: any(named: 'isExpense'),
              parentId: any(named: 'parentId'),
            ))
        .thenAnswer((invocation) async =>
            _cat(invocation.namedArguments[#name] as String));

    // Kapsam servisi "kürasyon yok" davranışını taklit eder: bu dosyanın
    // konusu inceleme ekranı, cüzdan görünürlüğü değil.
    final walletCategories = MockWalletCategoryService();
    getIt.registerSingleton<WalletCategoryService>(walletCategories);
    when(() => walletCategories.categoriesFor(
              walletId: any(named: 'walletId'),
              isExpense: any(named: 'isExpense'),
              alwaysInclude: any(named: 'alwaysInclude'),
            ))
        .thenAnswer((invocation) => categoryRepo
            .getCategories(invocation.namedArguments[#isExpense] as bool));
    when(() => walletCategories.include(
          walletId: any(named: 'walletId'),
          categoryIds: any(named: 'categoryIds'),
        )).thenAnswer((_) async => 0);
  });

  tearDown(() => getIt.reset());

  BankImportReview review({
    required List<ImportDraft> drafts,
    int skippedRows = 0,
    String? walletCurrency = 'TRY',
    String? foreignCurrency,
    bool fromOcr = false,
    bool sourceTruncated = false,
    int sourceUnresolvedCells = 0,
    StatementVerification verification = StatementVerification.none,
    List<CategoryEntity>? expenseCategories,
    List<LedgerLeftover> leftovers = const [],
    TargetSuggestion? targetSuggestion,
    CardStatementFacts? cardFacts,
    bool accountStatementOnCard = false,
  }) =>
      BankImportReview(
        drafts: drafts,
        expenseCategories:
            expenseCategories ?? [_cat('Market'), _cat('Fatura')],
        incomeCategories: [_cat('Maaş', expense: false)],
        skippedRows: skippedRows,
        walletCurrency: walletCurrency,
        foreignCurrency: foreignCurrency,
        fromOcr: fromOcr,
        sourceTruncated: sourceTruncated,
        sourceUnresolvedCells: sourceUnresolvedCells,
        verification: verification,
        leftovers: leftovers,
        targetSuggestion: targetSuggestion,
        cardFacts: cardFacts,
        accountStatementOnCard: accountStatementOnCard,
      );

  Future<void> pump(
    WidgetTester tester,
    BankImportReview state, {
    bool fullscreen = false,
    List<WalletEntity>? wallets,
  }) async {
    when(() => cubit.state).thenReturn(state);
    Widget withWallets(Widget child) {
      if (wallets == null) return child;
      final bloc = _MockWalletBloc();
      when(() => bloc.state).thenReturn(WalletLoadedSt(wallets, wallets.first));
      return BlocProvider<WalletBloc>.value(value: bloc, child: child);
    }

    await tester.pumpWidget(withWallets(
      MaterialApp(
        // Öneri mesajı [AppMessenger] üzerinden gösteriliyor; anahtar üretimde
        // olduğu gibi burada da bağlanmalı, yoksa snackbar hiç doğmaz.
        scaffoldMessengerKey: appMessengerKey,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: BlocProvider<BankImportCubit>.value(
            value: cubit,
            child: BankImportReviewView(
              state: state,
              fullscreen: fullscreen,
              onToggleFullscreen: () => fullscreenToggles++,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// Arama alanı artık süzgeç çiplerinin ucundaki büyüteçle açılır.
  Future<void> openSearch(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('review-search-open')));
    await tester.pumpAndSettle();
  }

  testWidgets('inceleme listesi hatasız çizilir ve satırları gösterir',
      (tester) async {
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'MARKET ALISVERISI', categoryId: 'Market'),
        _draft(description: 'TRENDYOL.COM', day: 6),
      ]),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('MARKET ALISVERISI'), findsOneWidget);
    expect(find.text('TRENDYOL.COM'), findsOneWidget);
  });

  testWidgets('tutarlar hedef cüzdanın para birimiyle gösterilir',
      (tester) async {
    await pump(
      tester,
      review(
        drafts: [_draft(description: 'AMAZON', amount: 250)],
        walletCurrency: 'USD',
      ),
    );

    // ₺ sabit kodluydu; artık cüzdan birimi kullanılıyor.
    expect(find.textContaining(r'$'), findsWidgets);
    expect(find.textContaining('₺'), findsNothing);
  });

  testWidgets('arama açıklamaya göre süzer', (tester) async {
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'MARKET ALISVERISI'),
        _draft(description: 'TRENDYOL.COM', day: 6),
      ]),
    );

    await openSearch(tester);
    await tester.enterText(find.byType(TextField), 'trendyol');
    await tester.pumpAndSettle();

    expect(find.text('TRENDYOL.COM'), findsOneWidget);
    expect(find.text('MARKET ALISVERISI'), findsNothing);
  });

  testWidgets('"Kategorisiz" filtresi yalnız kategorisi olmayanları gösterir',
      (tester) async {
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'MARKET ALISVERISI', categoryId: 'Market'),
        _draft(description: 'BILINMEYEN ISLEM', day: 6),
      ]),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Kategorisiz (1)'));
    await tester.pumpAndSettle();

    expect(find.text('BILINMEYEN ISLEM'), findsOneWidget);
    expect(find.text('MARKET ALISVERISI'), findsNothing);
  });

  testWidgets('filtreliyken seçim doğru satıra uygulanır (indeks eşlemesi)',
      (tester) async {
    // Kritik: cubit mutasyonları indeks tabanlı; filtre uygulanınca görünür
    // sıradaki 0. satır gerçekte 1. taslak olabilir.
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'MARKET ALISVERISI', categoryId: 'Market'),
        _draft(description: 'BILINMEYEN ISLEM', day: 6),
      ]),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Kategorisiz (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    // Görünürde tek satır var ama gerçek indeksi 1 olmalı, 0 değil.
    verify(() => cubit.toggleDraft(1)).called(1);
    verifyNever(() => cubit.toggleDraft(0));
  });

  testWidgets('genel uyarı her zaman görünür, para birimi uyarısı koşullu',
      (tester) async {
    await pump(tester, review(drafts: [_draft(description: 'X')]));
    expect(find.textContaining('otomatik algılandı'), findsOneWidget);
    expect(find.byIcon(Icons.currency_exchange_rounded), findsNothing);

    await pump(
      tester,
      review(drafts: [_draft(description: 'X')], foreignCurrency: 'USD'),
    );
    expect(find.byIcon(Icons.currency_exchange_rounded), findsOneWidget);
  });

  testWidgets('OCR yolundan gelen taslaklar ayrıca uyarılır', (tester) async {
    // Görüntüden okuma en hatalı yol; kullanıcı bunu bilmeli.
    await pump(tester, review(drafts: [_draft(description: 'X')]));
    expect(find.byIcon(Icons.image_search_rounded), findsNothing);

    await pump(
      tester,
      review(drafts: [_draft(description: 'X')], fromOcr: true),
    );
    expect(find.byIcon(Icons.image_search_rounded), findsOneWidget);
    expect(find.textContaining('GÖRÜNTÜDEN'), findsOneWidget);
  });

  testWidgets('kaynak dosya bütünlüğü şüpheliyse uyarılır', (tester) async {
    await pump(
      tester,
      review(
        drafts: [_draft(description: 'X')],
        sourceTruncated: true,
        sourceUnresolvedCells: 3,
      ),
    );
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
  });

  testWidgets('doğrulama geçtiyse yeşil kanıt kartı ve kontrol dökümü',
      (tester) async {
    await pump(
      tester,
      review(
        drafts: [_draft(description: 'MARKET')],
        verification: const StatementVerification(
          status: StatementVerificationStatus.verified,
          checks: [
            StatementCheck(
              kind: StatementCheckKind.balanceChain,
              passed: true,
              detail: '84 / 84',
            ),
            StatementCheck(
              kind: StatementCheckKind.recordCount,
              passed: true,
              detail: '85 / 85',
            ),
          ],
        ),
      ),
    );

    // Sıkı kipte olumlu sonuç tek çip: ayrıntılı kart ekranın ~%40'ını
    // kaplıyordu (cihazda ölçüldü). Döküm bir dokunuşla açılır.
    expect(find.text('Doğrulandı'), findsOneWidget);
    expect(find.text('Aritmetik olarak doğrulandı'), findsNothing);
    await tester.tap(find.byTooltip('Ayrıntıları göster'));
    await tester.pumpAndSettle();

    expect(find.text('Aritmetik olarak doğrulandı'), findsOneWidget);
    // Kullanıcı neye güvendiğini görebilmeli: kontrollerin dökümü de basılır.
    expect(find.text('Bakiye zinciri: 84 / 84'), findsOneWidget);
    expect(find.text('Kayıt sayısı: 85 / 85'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('doğrulama tutmazsa kırmızı uyarı ve tutmayan kontrol işaretli',
      (tester) async {
    await pump(
      tester,
      review(
        drafts: [_draft(description: 'MARKET')],
        verification: const StatementVerification(
          status: StatementVerificationStatus.failed,
          checks: [
            StatementCheck(
              kind: StatementCheckKind.balanceChain,
              passed: false,
              detail: '80 / 84',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Doğrulanamadı'), findsOneWidget);
    expect(find.text('Bakiye zinciri: 80 / 84'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('doğrulama yapılamadıysa kart hiç çizilmez', (tester) async {
    await pump(tester, review(drafts: [_draft(description: 'MARKET')]));
    expect(find.text('Aritmetik olarak doğrulandı'), findsNothing);
    expect(find.text('Doğrulanamadı'), findsNothing);
  });

  testWidgets('taslak yoksa boş durum mesajı', (tester) async {
    await pump(tester, review(drafts: const []));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('bulunamadı'), findsOneWidget);
  });

  // ------------------------------------------------------------- Tam ekran

  testWidgets('tam ekranda özet/uyarı kartı listeden çıkar ama kaybolmaz',
      (tester) async {
    final state =
        review(drafts: [_draft(description: 'X', categoryId: 'Market')]);

    await pump(tester, state);
    expect(find.textContaining('otomatik algılandı'), findsOneWidget);

    await pump(tester, state, fullscreen: true);
    expect(find.textContaining('otomatik algılandı'), findsNothing);

    // Kart gizlendi, bilgi değil: taşma menüsünden sayfa olarak açılır.
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Özet ve uyarılar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('otomatik algılandı'), findsOneWidget);
  });

  testWidgets('tam ekran düğmesi sayfaya haber verir (AppBar orada gizlenir)',
      (tester) async {
    await pump(tester,
        review(drafts: [_draft(description: 'X', categoryId: 'Market')]));

    await tester.tap(find.byIcon(Icons.fullscreen_rounded));
    await tester.pumpAndSettle();

    expect(fullscreenToggles, 1);
  });

  // -------------------------------------------------- Kategorisiz satır kapısı

  testWidgets('seçili kategorisiz satır varken ekleme kapalı', (tester) async {
    await pump(tester, review(drafts: [_draft(description: 'X')]));

    final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Seçilenleri ekle (1)'));
    expect(button.onPressed, isNull);
    expect(find.textContaining('kategorisi yok'), findsOneWidget);
  });

  testWidgets('hepsi kategoriliyse ekleme açık', (tester) async {
    await pump(tester,
        review(drafts: [_draft(description: 'X', categoryId: 'Market')]));

    final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Seçilenleri ekle (1)'));
    expect(button.onPressed, isNotNull);
    expect(find.textContaining('kategorisi yok'), findsNothing);
  });

  // --------------------------------------------------------- Kategori seçimi

  testWidgets('satırdan kategori seçimi doğru (filtrelenmemiş) indekse gider',
      (tester) async {
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'MARKET ALISVERISI', categoryId: 'Market'),
        _draft(description: 'BILINMEYEN ISLEM', day: 6),
      ]),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Kategorisiz (1)'));
    await tester.pumpAndSettle();

    // Kategorisiz satırın kırmızı "Kategori seç" çağrısı.
    await tester.tap(find.text('Kategori seç'));
    await tester.pumpAndSettle();

    // Seçim sayfası: yeni kategori kurma girişi + mevcut kategoriler.
    expect(find.byTooltip('Yeni Kategori Ekle'), findsOneWidget);
    // Seçici iki sütun: ana kategorinin adı SOLDA (gezinme) ve SAĞDA
    // (seçilebilir satır) görünür. Seçen satır sağdaki, yani sonuncusu.
    await tester.tap(find.text('Fatura').last);
    await tester.pumpAndSettle();

    verify(() => cubit.setDraftCategory(1, 'Fatura')).called(1);
  });

  testWidgets('seçim sayfasından yeni kategori kurulup satıra atanır',
      (tester) async {
    await pump(tester, review(drafts: [_draft(description: 'KAHVECI')]));

    await tester.tap(find.text('Kategori seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Yeni Kategori Ekle'));
    await tester.pumpAndSettle();

    // Form: ad alanı (üst kategori seçicisi dropdown'dır, TextFormField değil).
    await tester.enterText(find.byType(TextFormField).first, 'Kahve');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();

    // Kategori gerçekten yazıldı, akışa tanıtıldı ve satıra atandı: kullanıcı
    // kurduğu kategoriyi bir de listeden aramak zorunda kalmamalı.
    verify(() => categoryRepo.addCategory(
          name: any(named: 'name'),
          iconName: any(named: 'iconName'),
          isExpense: any(named: 'isExpense'),
          parentId: any(named: 'parentId'),
        )).called(1);
    verify(() => cubit.registerCreatedCategory(any())).called(1);
    verify(() => cubit.setDraftCategory(0, 'Kahve')).called(1);
  });

  testWidgets('dar ekranda tekrar rozeti + uzun kategori satırı taşırmaz',
      (tester) async {
    // Satırın alt şeridi en yoğun hâli: tarih + "olası tekrar" rozeti +
    // kategori düğmesi + tür simgesi. Telefon genişliğinde ölçülür.
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pump(
      tester,
      review(drafts: [
        _draft(
          description: 'ODEME ISLEMI ACIKLAMASI COK UZUN OLAN BIR SATIR',
          categoryId: 'Fatura',
          duplicate: true,
        ),
        // Kategorisiz satır: alt şeritteki engel uyarısı da bu genişlikte
        // çizilsin.
        _draft(description: 'BILINMEYEN ISLEM', day: 6),
      ]),
    );

    expect(find.textContaining('kategorisi yok'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toplu kategori yalnız GÖRÜNEN satırlara uygulanır',
      (tester) async {
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'MARKET ALISVERISI', categoryId: 'Market'),
        _draft(description: 'BILINMEYEN ISLEM', day: 6),
      ]),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Kategorisiz (1)'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Kategorisiz 1 satıra'));
    await tester.pumpAndSettle();
    // Seçici iki sütun: ana kategorinin adı SOLDA (gezinme) ve SAĞDA
    // (seçilebilir satır) görünür. Seçen satır sağdaki, yani sonuncusu.
    await tester.tap(find.text('Fatura').last);
    await tester.pumpAndSettle();
    // Önizleme diyaloğu: uygulanacak satır listelenir, onaylanınca uygulanır.
    expect(find.text('“Fatura” kategorisini uygula'), findsOneWidget);
    await tester.tap(find.text('1 satıra uygula'));
    await tester.pumpAndSettle();

    // Doğru tahmin edilmiş 0. satıra DOKUNULMAZ: kapsamı süzgeç belirler.
    final captured = verify(
      () => cubit.applyCategoryToIndexes(captureAny(), 'Fatura'),
    ).captured;
    expect(captured.single, [1]);
  });

  testWidgets(
      'REGRESYON: süzgeçsiz toplu atama elle seçilmiş kategorileri EZMEZ',
      (tester) async {
    // Bildirilen hata: kullanıcı bazı satırları elle kategorize edip kalan
    // boşlar için toplu atama düğmesine basınca, ELLE seçtikleri dahil TÜM
    // liste tek kategoriye dönüyordu (varsayılan süzgeç "tümü" olduğu için
    // "görünen satırlar" bütün listeydi).
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'MARKET ALISVERISI', categoryId: 'Market'),
        _draft(description: 'BILINMEYEN ISLEM', day: 6),
        _draft(description: 'BASKA BILINMEYEN', day: 7),
      ]),
    );

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Kategorisiz 2 satıra'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fatura').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 satıra uygula'));
    await tester.pumpAndSettle();

    final captured = verify(
      () => cubit.applyCategoryToIndexes(captureAny(), 'Fatura'),
    ).captured;
    expect(captured.single, [1, 2]);
  });

  testWidgets('üzerine yazma AYRI bir eylem ve kapsamı adında yazıyor',
      (tester) async {
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'MARKET ALISVERISI', categoryId: 'Market'),
        _draft(description: 'BILINMEYEN ISLEM', day: 6),
      ]),
    );

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Görünen 2 satırı değiştir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fatura').last);
    await tester.pumpAndSettle();

    // Üzerine yazma onaydan ÖNCE görünür: hangi satırın kategorisi neden
    // neye dönecek.
    expect(find.text('Market → Fatura'), findsOneWidget);
    expect(find.textContaining('1 satırın mevcut kategorisi değişecek'),
        findsOneWidget);
    await tester.tap(find.text('2 satıra uygula'));
    await tester.pumpAndSettle();

    final captured = verify(
      () => cubit.applyCategoryToIndexes(captureAny(), 'Fatura'),
    ).captured;
    expect(captured.single, [0, 1]);
  });

  testWidgets('kategorisiz satır kalmayınca boşluk doldurma eylemi görünmez',
      (tester) async {
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'MARKET ALISVERISI', categoryId: 'Market'),
        _draft(description: 'FATURA ODEMESI', categoryId: 'Fatura', day: 6),
      ]),
    );

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('Kategorisiz'), findsNothing);
    expect(find.textContaining('Görünen 2 satırı değiştir'), findsOneWidget);
  });

  testWidgets('Türkçe arama büyük harfli açıklamayı bulur', (tester) async {
    // Dart noktasız `I`'yı `i`'ye çevirir: "IŞIK" → `işik`. Kullanıcı doğal
    // yazımıyla "ışık" arayınca eski `toLowerCase()` yolu HİÇ bulmuyordu.
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'IŞIK ELEKTRİK ODEMESI'),
        _draft(description: 'SHELL ANKARA', day: 6),
      ]),
    );

    await openSearch(tester);
    await tester.enterText(find.byType(TextField), 'ışık');
    await tester.pumpAndSettle();

    expect(find.text('IŞIK ELEKTRİK ODEMESI'), findsOneWidget);
    expect(find.text('SHELL ANKARA'), findsNothing);
  });

  testWidgets('aynı adlı alt kategoriler ana kategorileriyle ayırt edilir',
      (tester) async {
    // "Su" hem Fatura hem Market altında olabilir (tekillik yalnız kardeşler
    // arasında aranır); satırda çıplak "Su" yazmak ikisini ayırt edilemez
    // kılıyordu.
    await pump(
      tester,
      review(
        drafts: [_draft(description: 'ISKI ODEME', categoryId: 'fatura-su')],
        expenseCategories: [
          _cat('Fatura'),
          _cat('fatura-su', name: 'Su', parent: 'Fatura'),
          _cat('Market'),
          _cat('market-su', name: 'Su', parent: 'Market'),
        ],
      ),
    );

    expect(find.text('Fatura › Su'), findsOneWidget);
    expect(find.text('Su'), findsNothing);
  });

  testWidgets('benzer hareketler sayfası grubun TÜM satırlarına uygular',
      (tester) async {
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'SOK-10419-USKUDAR', day: 5),
        _draft(description: 'SOK 22133 KADIKOY', day: 6),
        _draft(description: 'BASKA BIR ISLEM', day: 7),
      ]),
    );

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Benzerleri grupla'));
    await tester.pumpAndSettle();

    // Grup başlığı ekstrenin kendi yazımıyla; satır sayısı rozette, altında
    // hangi satırların toplandığı örneklenir.
    expect(find.text('SOK'), findsOneWidget);
    expect(
        find.text('SOK-10419-USKUDAR  ·  SOK 22133 KADIKOY'), findsOneWidget);

    await tester.tap(find.text('SOK'));
    await tester.pumpAndSettle();
    // Seçicide açılışta ilk kök etkin: adı hem solda (gezinme) hem sağda
    // (seçilebilir satır) görünür, seçen sonuncusu.
    await tester.tap(find.text('Fatura').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 satıra uygula'));
    await tester.pumpAndSettle();

    final captured = verify(
      () => cubit.applyCategoryToIndexes(captureAny(), 'Fatura'),
    ).captured;
    // "BASKA BIR ISLEM" gruba GİRMEZ: yalnız benzer olanlar toplu değişir.
    expect(captured.single, [0, 1]);
  });

  testWidgets('benzer gruplar sayfası dar ekranda taşmaz ve "kalanı" doldurur',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pump(
      tester,
      review(
        drafts: [
          _draft(
            description: 'ENERJISA ELEKTRIK FATURA ODEMESI 2026/03 ISTANBUL',
            categoryId: 'fatura-elektrik',
            amount: 1234567.89,
          ),
          _draft(
            description: 'ENERJISA ELEKTRIK FATURA ODEMESI 2026/04 ISTANBUL',
            categoryId: 'fatura-elektrik',
            day: 6,
          ),
          _draft(
            description: 'ENERJISA ELEKTRIK FATURA ODEMESI 2026/05 ISTANBUL',
            day: 7,
          ),
        ],
        expenseCategories: [
          _cat('Fatura'),
          _cat('fatura-elektrik',
              name: 'Elektrik ve Aydınlatma Giderleri', parent: 'Fatura'),
        ],
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Benzerleri grupla'));
    await tester.pumpAndSettle();

    // Varsayılan kapsam "yalnız kategorisiz": tek satır kalıyor, grup yok.
    expect(find.textContaining('Birbirine benzeyen'), findsOneWidget);

    // "Tümü"ye geçince üç satır tek grup; ikisi kategorili, biri boş.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tümü').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.textContaining('Kalanını'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('1 satıra uygula'));
    await tester.pumpAndSettle();

    // Yalnız BOŞ satır doldurulur; kategorili ikisinin üzerine yazılmaz.
    final captured = verify(
      () => cubit.applyCategoryToIndexes(captureAny(), 'fatura-elektrik'),
    ).captured;
    expect(captured.single, [2]);
    expect(tester.takeException(), isNull);
  });
  // F1 güvenlik ağı: kümeleme ortak ÖN EKE bakıyor ve ön ek her zaman marka
  // değil ("TURK HAVA YOLLARI" + "TURK EKONOMI BANKASI" tek grup —
  // `description_grouper.dart` "BİLİNEN SINIR"). Öneri artık snackbar değil
  // diyalog: etkilenecek satırlar listelenir ve tek tek çıkarılabilir.
  group('benzer satır önerisi (diyalog)', () {
    final drafts = [
      _draft(description: 'MIGROS SANAL MARKET'),
      _draft(description: 'MIGROS JET KADIKOY', day: 6),
      _draft(description: 'MIGROS 3421 USKUDAR', day: 7),
    ];

    Future<void> pickFirstRow(WidgetTester tester) async {
      await pump(tester, review(drafts: drafts));
      await tester.tap(find.text('Kategori seç').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fatura').last);
      await tester.pumpAndSettle();
    }

    testWidgets('satır seçilince kendiliğinden açılır, satırları listeler',
        (tester) async {
      await pickFirstRow(tester);

      expect(
          find.text('“Fatura” benzerlerine de uygulansın mı?'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
      final inDialog = find.descendant(
          of: find.byType(Dialog), matching: find.text('MIGROS JET KADIKOY'));
      expect(inDialog, findsOneWidget);
      // Snackbar YOK (eski 6 sn'lik öneri alttaki "Ekle"yi örtüyordu).
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('işareti kaldırılan satır uygulanmaz', (tester) async {
      await pickFirstRow(tester);

      await tester.tap(find.descendant(
          of: find.byType(Dialog), matching: find.text('MIGROS JET KADIKOY')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 satıra uygula'));
      await tester.pumpAndSettle();

      final captured = verify(
        () => cubit.applyCategoryToIndexes(captureAny(), 'Fatura'),
      ).captured;
      expect(captured.single, [2]);
    });

    testWidgets('"Yalnız bu satır" başka hiçbir satıra dokunmaz',
        (tester) async {
      await pickFirstRow(tester);

      await tester.tap(find.text('Yalnız bu satır'));
      await tester.pumpAndSettle();

      verify(() => cubit.setDraftCategory(0, 'Fatura')).called(1);
      verifyNever(() => cubit.applyCategoryToIndexes(any(), any()));
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('dar ekranda (360dp) diyalog taşmaz', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Tam ekran: 640dp'de özet kartı + alt çubuk ilk satırı örtüyor.
      await pump(
        tester,
        fullscreen: true,
        review(drafts: [
          for (var i = 0; i < 14; i++)
            _draft(
              description:
                  'ENERJISA ELEKTRIK FATURA ODEMESI 2026/$i ISTANBUL SUBESI',
              amount: 1234567.89,
              day: i + 1,
            ),
        ]),
      );
      await tester.tap(find.text('Kategori seç').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fatura').last);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('incelemeden geri çıkış onay ister; vazgeçilirse kalınır',
      (tester) async {
    await pump(tester, review(drafts: [_draft(description: 'A')]));

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('İçe aktarımdan çıkılsın mı?'), findsOneWidget);
    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();
    expect(find.byType(BankImportReviewView), findsOneWidget);
  });

  testWidgets('"Görünenleri seç" yalnız görünen satırları verir',
      (tester) async {
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'MARKET ALISVERISI', categoryId: 'Market')
            .copyWith(selected: false),
        _draft(description: 'BILINMEYEN ISLEM', day: 6)
            .copyWith(selected: false),
      ]),
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Kategorisiz (1)'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Görünenleri seç (tekrarlar hariç)'));
    await tester.pumpAndSettle();

    final captured =
        verify(() => cubit.setSelectedAt(captureAny(), true)).captured;
    expect(captured.single, [1]);
  });

  testWidgets('yalnız tekrarlar görünürken "seç" pasif (sessiz no-op değil)',
      (tester) async {
    // Cihazda ölçüldü: dosya zaten aktarılmışken 157 satırın hepsi tekrardı,
    // düğmeye basınca hiçbir şey olmuyor ama düğme etkin görünüyordu.
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'A', categoryId: 'Market', duplicate: true)
            .copyWith(selected: false),
        _draft(description: 'B', categoryId: 'Market', day: 6),
      ]),
    );
    // Kayıtlı satır katlanmış olabilir; açıp yine de denenir.
    if (find.text('Göster').evaluate().isNotEmpty) {
      await tester.tap(find.text('Göster').first);
      await tester.pumpAndSettle();
    }

    final select = tester.widget<IconButton>(find.ancestor(
        of: find.byIcon(Icons.done_all_rounded),
        matching: find.byType(IconButton)));
    expect(select.onPressed, isNull);
  });

  testWidgets('menü/diyalog kapanınca odak aramaya DÖNMEZ (klavye açılmaz)',
      (tester) async {
    // Cihazda ölçüldü: aranıp klavye kapatıldıktan sonra açılan her menü ya
    // da diyalog kapanınca Flutter odağı arama alanına iade ediyor, klavye
    // kendiliğinden açılıyordu.
    await pump(tester, review(drafts: [_draft(description: 'A')]));
    await openSearch(tester);
    // Sorgu doluyken satır açık kalır (boşken odak bırakılınca kapanırdı).
    await tester.enterText(find.byType(TextField), 'A');
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);
    tester.testTextInput.hide();

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5)); // menüyü kapat
    await tester.pumpAndSettle();

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('aranırken özet kartı çekilir, odak bırakılınca geri gelir',
      (tester) async {
    // Cihazda ölçüldü: birkaç uyarılı ekstrede klavye açılınca kaydırılmayan
    // özet kartı sayfayı 41px taşırıyordu.
    await pump(tester, review(drafts: [_draft(description: 'A')]));
    expect(find.textContaining('otomatik algılandı'), findsOneWidget);
    // Arama alanı kapalı başlar: kalıcı bir satır tutmaz.
    expect(find.byType(TextField), findsNothing);

    await openSearch(tester);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('otomatik algılandı'), findsNothing);

    await tester.tapAt(const Offset(5, 590)); // alan dışına
    await tester.pumpAndSettle();
    expect(find.textContaining('otomatik algılandı'), findsOneWidget);
    // Sorgu boşken odak bırakılınca satır da kapanır.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('sorgu doluyken arama satırı kapanmaz; çarpı siler ve kapatır',
      (tester) async {
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'MARKET', categoryId: 'Market'),
        _draft(description: 'TRENDYOL', categoryId: 'Market', day: 6),
      ]),
    );
    await openSearch(tester);
    await tester.enterText(find.byType(TextField), 'trend');
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 590)); // odak bırakılır
    await tester.pumpAndSettle();

    // Görünmeyen bir süzgeç listeyi sessizce daraltmasın.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('MARKET'), findsNothing);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('MARKET'), findsOneWidget);
  });

  testWidgets('toplu tür çevirme önce kaç satırın değişeceğini sorar',
      (tester) async {
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'A', categoryId: 'Market'),
        _draft(description: 'B', income: true, day: 6),
      ]),
    );

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Tümünü çevir: Gider'));
    await tester.pumpAndSettle();

    expect(find.text('Tümü gider yapılsın mı?'), findsOneWidget);
    expect(find.textContaining('1 satırın türü değişecek'), findsOneWidget);
    verifyNever(() => cubit.setAllType(any()));

    await tester.tap(find.text('Çevir'));
    await tester.pumpAndSettle();
    verify(() => cubit.setAllType(TransactionTypeModel.expense)).called(1);
  });

  testWidgets('hepsi zaten gider ise "gider yap" menüde yok', (tester) async {
    await pump(tester, review(drafts: [_draft(description: 'A')]));

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tümünü çevir: Gider'), findsNothing);
    expect(find.textContaining('Tümünü çevir: Gelir'), findsOneWidget);
  });

  group('yaklaşık tekrar paneli', () {
    // Kullanıcının senaryosu: bankada 913,15; elle "bim" · 910 · aynı gün.
    ImportDraft approx({
      bool selected = false,
      bool correctExisting = false,
      bool strong = true,
      bool system = false,
    }) =>
        ImportDraft(
          date: DateTime(2026, 9, 5),
          description: 'SATIŞ-517040*4626-BİM L508 YUNUS EMRE',
          amount: 913.15,
          type: TransactionTypeModel.expense,
          categoryId: 'Market',
          selected: selected,
          correctExisting: correctExisting,
          duplicateOf: DuplicateMatch(
            kind: DuplicateKind.approximate,
            existingId: 'm1',
            existingTitle: 'bim',
            existingTag: 'Market',
            existingAmount: 910,
            existingDate: DateTime(2026, 9, 5, 21, 40),
            existingIsSystem: system,
            amountDelta: 3.15,
            amountPattern: AmountPattern.roundedSmall,
            sharedWord: 'bim',
            categoryMatches: true,
            strong: strong,
          ),
        );

    setUp(() {
      when(() => cubit.setDraftSelected(any(), any())).thenReturn(null);
      when(() => cubit.setCorrectExisting(any(), any())).thenReturn(null);
      when(() => cubit.correctAllApproximate()).thenReturn(null);
    });

    testWidgets('NEYLE ve NEDEN eşleştiği satırda yazar', (tester) async {
      await pump(tester, review(drafts: [approx()]));

      expect(find.text('Büyük olasılıkla elle girdiğin kayıt'), findsOneWidget);
      // Eşleşen kaydın kendisi: başlık · kategori · tutar · tarih-saat.
      expect(find.textContaining('“bim” · Market · −'), findsOneWidget);
      expect(find.textContaining('21:40'), findsOneWidget);
      // Gerekçeler tek tek.
      expect(find.textContaining('fark · yuvarlanmış'), findsOneWidget);
      expect(find.text('aynı gün'), findsOneWidget);
      expect(find.text('“bim” ikisinde de geçiyor'), findsOneWidget);
      expect(find.text('kategori aynı'), findsOneWidget);
      expect(find.text('Eklenmeyecek.'), findsOneWidget);
    });

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
    }

    testWidgets('"Farklı işlem, ekle" satırı eklemeye alır', (tester) async {
      await pump(tester, review(drafts: [approx()]));
      await tapVisible(tester, find.text('Farklı işlem, ekle'));
      verify(() => cubit.setDraftSelected(0, true)).called(1);
    });

    testWidgets('"Tutarı … yap" eşleşen kaydı düzeltme kararını verir',
        (tester) async {
      await pump(tester, review(drafts: [approx()]));
      await tapVisible(tester, find.textContaining('Tutarı '));
      verify(() => cubit.setCorrectExisting(0, true)).called(1);
    });

    testWidgets('düzeltme açıkken ne olacağını ve geri dönüşü söyler',
        (tester) async {
      await pump(tester, review(drafts: [approx(correctExisting: true)]));
      expect(find.textContaining('kaydın tutarı'), findsWidgets);
      await tapVisible(tester, find.text('Düzeltmeden vazgeç'));
      verify(() => cubit.setCorrectExisting(0, false)).called(1);
      // Yalnız düzeltme varsa ana düğme "ekle" değil "düzeltmeleri uygula".
      expect(find.text('Düzeltmeleri uygula (1)'), findsOneWidget);
    });

    testWidgets('sistem kaydıyla eşleşmede düzeltme önerilmez', (tester) async {
      await pump(tester, review(drafts: [approx(system: true)]));
      expect(find.text('Borç/yatırım kaydınla eşleşiyor'), findsOneWidget);
      expect(find.textContaining('Tutarı '), findsNothing);
    });

    testWidgets('özet kartı tahminle eklenmeyecek satırları sayar ve süzer',
        (tester) async {
      await pump(
        tester,
        review(drafts: [
          approx(),
          _draft(description: 'MARKET ALISVERISI', categoryId: 'Market'),
        ]),
      );

      expect(find.textContaining('1 satır elle girdiğin kayıtlara benzediği'),
          findsOneWidget);
      await tester.tap(find.textContaining('1 satır elle girdiğin'));
      await tester.pumpAndSettle();
      // Süzgeç "olası tekrar"a geçti: yalnız eşleşen satır görünür.
      expect(find.text('MARKET ALISVERISI'), findsNothing);
      expect(find.textContaining('BİM L508'), findsOneWidget);
    });

    testWidgets('dar ekranda (360dp) panel taşmaz', (tester) async {
      // Uzun yüzey: iki satır da (tembel liste) çizilsin.
      tester.view.physicalSize = const Size(360, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pump(tester, review(drafts: [approx(), approx(strong: false)]));

      expect(find.text('Elle girdiğin bir kayda benziyor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('toplu düzeltme taşma menüsünde, sayısıyla', (tester) async {
      await pump(tester, review(drafts: [approx(), approx(strong: false)]));
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Benzeyen 2 kaydın tutarını'));
      await tester.pumpAndSettle();
      verify(() => cubit.correctAllApproximate()).called(1);
    });
  });

  // REGRESYON (M2, 23 Eyl 2026): adım adım modda büyük (birincil) düğme hep
  // "Ekle"ydi. Panel "zaten defterde" derken hızlı ilerleyen kullanıcı
  // büyük düğmeye basıyor ve satır ikinci kez ekleniyordu.
  group('adım adım mod — tekrar satırı', () {
    Future<void> openStepper(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tek tek incele'));
      await tester.pumpAndSettle();
    }

    setUp(() {
      when(() => cubit.setDraftSelected(any(), any())).thenReturn(null);
      when(() => cubit.commit()).thenAnswer((_) async {});
    });

    testWidgets('birincil düğme ATLA; eklemek ayrı ve açık bir karar',
        (tester) async {
      final flagged = _draft(
        description: 'MIGROS',
        categoryId: 'Market',
        duplicate: true,
      ).copyWith(selected: false);
      await pump(tester, review(drafts: [flagged, _draft(description: 'B')]));
      await openStepper(tester);

      expect(find.widgetWithText(FilledButton, 'Atla'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Ekle'), findsNothing);
      expect(
          find.widgetWithText(OutlinedButton, 'Yine de ekle'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Atla'));
      await tester.pumpAndSettle();
      verify(() => cubit.setDraftSelected(0, false)).called(1);
      verifyNever(() => cubit.setDraftSelected(0, true));
    });

    testWidgets('tekrar olmayan satırda düzen değişmez (birincil EKLE)',
        (tester) async {
      await pump(
          tester,
          review(drafts: [
            _draft(description: 'A', categoryId: 'Market'),
            _draft(description: 'B', categoryId: 'Market'),
          ]));
      await openStepper(tester);

      expect(find.widgetWithText(FilledButton, 'Ekle'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Atla'), findsOneWidget);
    });
  });

  // M3 (23 Eyl 2026): eşik altındaki elle kayıt artık görünür bir ÖNERİ;
  // karar kullanıcınındır ve hiçbir satır onaysız düşmez.
  group('karşılığı bulunamayan kayıtlar', () {
    final entry = TransactionEntity(
      id: 'm-910',
      userId: 'u1',
      walletId: 'w1',
      title: 'Market',
      tag: 'Market',
      amount: 910,
      date: DateTime(2026, 3, 7, 20, 15),
      type: TransactionTypeModel.expense,
    );
    final leftover = LedgerLeftover(
      entry: entry,
      isCoupling: false,
      candidates: const [
        LeftoverCandidate(
          draftIndex: 1,
          amountPattern: AmountPattern.roundedSmall,
          amountDelta: 3.15,
          dayDistance: 2,
          categoryMatches: false,
          score: 2.5,
        ),
      ],
    );
    List<ImportDraft> drafts() => [
          _draft(description: 'MARKET ALISVERISI', categoryId: 'Market'),
          _draft(description: 'DEMKAR GIDA ISTANBUL', amount: 913.15, day: 5),
        ];

    setUp(() {
      when(() => cubit.linkLeftover(any(), any())).thenReturn(null);
      when(() => cubit.dismissLeftover(any())).thenReturn(null);
    });

    testWidgets(
        'şerit sayıyla görünür, sayfa kaydı ve adayı gerekçeleriyle '
        'gösterir; "bu satırla aynı" kararı cubit\'e gider', (tester) async {
      await pump(tester, review(drafts: drafts(), leftovers: [leftover]));

      expect(find.textContaining('1 kaydın bu ekstrede olası eşi var'),
          findsOneWidget);
      await tester.tap(find.text('İncele'));
      await tester.pumpAndSettle();

      expect(find.text('Karşılığı bulunamayan kayıtlar'), findsOneWidget);
      expect(find.textContaining('“Market”'), findsOneWidget);
      // Aday satır (sayfada) + gerekçe çipleri.
      expect(
          find.descendant(
            of: find.byType(LeftoverReviewSheet),
            matching: find.text('DEMKAR GIDA ISTANBUL'),
          ),
          findsOneWidget);
      expect(find.textContaining('yuvarlanmış'), findsOneWidget);
      expect(find.textContaining('2 gün'), findsOneWidget);

      await tester.tap(find.text('Bu satırla aynı'));
      await tester.pumpAndSettle();
      verify(() => cubit.linkLeftover('m-910', 1)).called(1);
    });

    testWidgets('"hiçbiri" öneriyi kapatır', (tester) async {
      await pump(tester, review(drafts: drafts(), leftovers: [leftover]));
      await tester.tap(find.text('İncele'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hiçbiri'));
      await tester.pumpAndSettle();
      verify(() => cubit.dismissLeftover('m-910')).called(1);
    });

    testWidgets('"Olası eş" süzgeci yalnız aday satırları gösterir',
        (tester) async {
      await pump(tester, review(drafts: drafts(), leftovers: [leftover]));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Olası eş (1)'));
      await tester.pumpAndSettle();

      expect(find.text('MARKET ALISVERISI'), findsNothing);
      expect(find.text('DEMKAR GIDA ISTANBUL'), findsOneWidget);
    });

    testWidgets('öneri yoksa şerit ve süzgeç yok', (tester) async {
      await pump(tester, review(drafts: drafts()));
      expect(find.text('İncele'), findsNothing);
      expect(find.textContaining('Olası eş'), findsNothing);
    });

    testWidgets('dar ekranda (360dp) şerit ve sayfa taşmaz', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final coupling = LedgerLeftover(
        entry: entry.copyWith(
          id: 'sys-1',
          title: 'Ödeme: İhtiyaç kredisi (Garanti BBVA)',
          tag: 'Borç Ödemesi',
          isSystem: true,
        ),
        isCoupling: true,
        candidates: const [
          LeftoverCandidate(
            draftIndex: 1,
            amountPattern: AmountPattern.exact,
            amountDelta: 0,
            dayDistance: 6,
            categoryMatches: false,
            sharedWord: 'kredisi',
            score: 5.25,
          ),
        ],
      );
      await pump(
          tester, review(drafts: drafts(), leftovers: [leftover, coupling]));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('İncele'));
      await tester.pumpAndSettle();
      expect(find.text('Borç/birikim kaydı'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('belirsiz eşleşme diğer satırı gösterir ve taşıma kararı verir',
      (tester) async {
    when(() => cubit.moveMatch(any(), any())).thenReturn(null);
    final bim = _draft(
        description: 'BIM MAGAZALAR',
        categoryId: 'Market',
        amount: 913.15,
        day: 5);
    final migros = _draft(
            description: 'MIGROS KADIKOY',
            categoryId: 'Market',
            amount: 910,
            day: 7)
        .copyWith(
      selected: false,
      duplicateOf: DuplicateMatch(
        kind: DuplicateKind.approximate,
        existingId: 'm1',
        existingTitle: 'Market',
        existingAmount: 910,
        existingDate: DateTime(2026, 3, 5, 19),
        amountPattern: AmountPattern.exact,
        dayDistance: 2,
        categoryMatches: true,
        strong: false,
        alternativeDraftIndex: 0,
      ),
    );
    await pump(tester, review(drafts: [bim, migros]));

    expect(find.textContaining('Şu satıra da benziyor: BIM MAGAZALAR'),
        findsOneWidget);
    await tester.ensureVisible(find.text('Diğer satırla eşleştir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diğer satırla eşleştir'));
    await tester.pumpAndSettle();
    verify(() => cubit.moveMatch(1, 0)).called(1);
  });

  group('elden geçirme (2026-09-24)', () {
    ImportDraft known(String description, {int day = 5}) => _draft(
            description: description,
            categoryId: 'Market',
            duplicate: true,
            day: day)
        .copyWith(selected: false);

    testWidgets('yanlış cüzdan önerisi en üstte ve tek dokunuşla değiştirir',
        (tester) async {
      await pump(
        tester,
        review(
          drafts: [_draft(description: 'KIRA', categoryId: 'Fatura')],
          targetSuggestion: const TargetSuggestion(
            walletId: 'w2',
            walletName: 'Banka',
            reason: TargetSuggestionReason.entriesElsewhere,
            matchCount: 157,
          ),
        ),
      );

      expect(find.textContaining('157 hareket “Banka”'), findsOneWidget);
      await tester.tap(find.text('Hedefi “Banka” yap'));
      await tester.pump();
      verify(() => cubit.switchTarget('w2')).called(1);
    });

    testWidgets('hesap ekstresi karta gidiyorsa (öneri yoksa) uyarı çıkar',
        (tester) async {
      await pump(
        tester,
        review(
          drafts: [_draft(description: 'KIRA', categoryId: 'Fatura')],
          accountStatementOnCard: true,
        ),
      );
      expect(find.textContaining('HESAP ekstresi'), findsOneWidget);
    });

    testWidgets(
        'REGRESYON (cihaz): ekstrenin TAMAMI kayıtlıysa liste yerine "yeni '
        'hareket yok"', (tester) async {
      await pump(
        tester,
        review(drafts: [known('A'), known('B', day: 6)]),
      );

      expect(find.text('Bu ekstrede yeni hareket yok'), findsOneWidget);
      expect(find.text('A'), findsNothing);

      await tester.tap(find.text('Satırları yine de göster'));
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('birebir kayıtlı satırlar tek satıra katlanır, açılabilir',
        (tester) async {
      await pump(
        tester,
        review(drafts: [
          known('ESKI HAREKET'),
          _draft(description: 'YENI HAREKET', categoryId: 'Market', day: 6),
        ]),
      );

      expect(find.text('YENI HAREKET'), findsOneWidget);
      expect(find.text('ESKI HAREKET'), findsNothing);
      expect(find.text('1 satır zaten kayıtlı olduğu için gizlendi'),
          findsOneWidget);

      await tester.tap(find.text('1 satır zaten kayıtlı olduğu için gizlendi'));
      await tester.pumpAndSettle();
      expect(find.text('ESKI HAREKET'), findsOneWidget);
      expect(find.text('Gizle'), findsOneWidget);
    });

    testWidgets('"Olası tekrar" süzgecinde kayıtlılar katlanmaz',
        (tester) async {
      await pump(
        tester,
        review(drafts: [
          known('ESKI HAREKET'),
          _draft(description: 'YENI HAREKET', categoryId: 'Market', day: 6),
        ]),
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Olası tekrar (1)'));
      await tester.pumpAndSettle();
      expect(find.text('ESKI HAREKET'), findsOneWidget);
    });

    testWidgets('arama tutarı da bulur (913 → 913,15)', (tester) async {
      await pump(
        tester,
        review(drafts: [
          _draft(description: 'BIM', categoryId: 'Market', amount: 913.15),
          _draft(description: 'SOK', categoryId: 'Market', amount: 45, day: 6),
        ]),
      );
      await openSearch(tester);
      await tester.enterText(find.byType(TextField), '913');
      await tester.pumpAndSettle();
      expect(find.text('BIM'), findsOneWidget);
      expect(find.text('SOK'), findsNothing);
    });

    testWidgets(
        'yalnız banka etiketinden tahmin edilenler işaretli ve süzülebilir',
        (tester) async {
      await pump(
        tester,
        review(drafts: [
          _draft(description: 'POS 1234', categoryId: 'Market')
              .withCategory('Market', CategorySource.bankTag),
          _draft(description: 'MIGROS', categoryId: 'Market', day: 6)
              .withCategory('Market', CategorySource.keyword),
        ]),
      );

      expect(
          find.byTooltip(
              'Yalnız bankanın etiketinden tahmin edildi — kontrol et'),
          findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Kontrol et (1)'));
      await tester.pumpAndSettle();
      expect(find.text('POS 1234'), findsOneWidget);
      expect(find.text('MIGROS'), findsNothing);
    });

    testWidgets('Gelir/Gider süzgeci ve eklenecek toplamlar', (tester) async {
      await pump(
        tester,
        review(drafts: [
          _draft(description: 'MARKET', categoryId: 'Market', amount: 100),
          _draft(
              description: 'MAAS',
              categoryId: 'Maaş',
              income: true,
              amount: 250,
              day: 6),
        ]),
      );

      expect(find.textContaining('Eklenecek: gider'), findsOneWidget);
      expect(find.textContaining('250,00'), findsWidgets);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Gelir'));
      await tester.pumpAndSettle();
      expect(find.text('MAAS'), findsOneWidget);
      expect(find.text('MARKET'), findsNothing);
    });

    testWidgets('kart künyesi sıkı kipte tek satır, ayrıntı açılınca tam',
        (tester) async {
      await pump(
        tester,
        review(
          drafts: [_draft(description: 'A', categoryId: 'Market')],
          cardFacts: CardStatementFacts(
            closingDate: DateTime(2026, 8, 25),
            dueDate: DateTime(2026, 9, 4),
            statementBalance: 1750,
            last4: '4321',
          ),
        ),
      );

      expect(find.textContaining('•••• 4321 ·'), findsOneWidget);
      expect(find.text('Asgari ödeme'), findsNothing);
      await tester.tap(find.byTooltip('Ayrıntıları göster'));
      await tester.pumpAndSettle();
      expect(find.textContaining('4321'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dar ekranda (360dp) öneri şeridi ve sıkı kart taşmaz',
        (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pump(
        tester,
        review(
          drafts: [
            known('ESKI'),
            _draft(description: 'YENI', categoryId: 'Market', day: 6),
          ],
          targetSuggestion: const TargetSuggestion(
            walletId: 'w2',
            walletName: 'Çok Uzun Adlı Vadesiz Hesap › Bonus Platinum Kart',
            reason: TargetSuggestionReason.cardNumber,
            last4: '4321',
          ),
          cardFacts: CardStatementFacts(
            dueDate: DateTime(2026, 9, 4),
            statementBalance: 1234567.89,
            last4: '4321',
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------
  // UX Tur 2 (11 Eki 2026) — en sık gereken eylemler görünür yerde
  // ---------------------------------------------------------------------
  group('engel şeridi ve görünür eylemler', () {
    testWidgets(
        'engel şeridinden toplu atama: seçili kategorisizlerin HEPSİ, '
        'süzgeç onları gizlese de', (tester) async {
      // ÖNCE: şerit yalnız "Göster" diyordu; toplu atama ⋮ menüsündeydi ve
      // kullanıcı satırları tek tek kategorize ediyordu.
      await pump(
        tester,
        review(drafts: [
          _draft(description: 'MARKET ALISVERISI', categoryId: 'Market'),
          _draft(description: 'BILINMEYEN ISLEM', day: 6),
          _draft(description: 'BASKA BILINMEYEN', day: 7),
          _draft(description: 'MAAS', income: true, categoryId: 'Maaş'),
        ]),
      );
      // Gelir süzgeci açık: kategorisiz (gider) satırlar ekranda yok.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Gelir'));
      await tester.pumpAndSettle();
      expect(find.text('BILINMEYEN ISLEM'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('review-assign-blocked')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fatura').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 satıra uygula'));
      await tester.pumpAndSettle();

      final captured = verify(
        () => cubit.applyCategoryToIndexes(captureAny(), 'Fatura'),
      ).captured;
      expect(captured.single, [1, 2]);
    });

    testWidgets(
        'kural değişmedi: kategorisiz seçili satır varken ekleme kapalı',
        (tester) async {
      await pump(
        tester,
        review(drafts: [
          _draft(description: 'A', categoryId: 'Market'),
          _draft(description: 'B', day: 6),
        ]),
      );
      final add = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(add.onPressed, isNull);
      expect(
          find.textContaining('kategori seçilmeden eklenemez'), findsOneWidget);
    });

    testWidgets('benzer grup varsa listenin başında kısayol; sayfayı açar',
        (tester) async {
      await pump(
        tester,
        review(drafts: [
          _draft(description: 'SOK-10419-USKUDAR', day: 5),
          _draft(description: 'SOK 22133 KADIKOY', day: 6),
          _draft(description: 'BASKA BIR ISLEM', day: 7),
        ]),
      );
      final tile = find.byKey(const ValueKey('review-group-tile'));
      expect(tile, findsOneWidget);
      expect(find.textContaining('Benzer 1 grubu'), findsOneWidget);

      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(
          find.text('SOK-10419-USKUDAR  ·  SOK 22133 KADIKOY'), findsOneWidget);
    });

    testWidgets('gruplanacak kategorisiz satır yoksa kısayol çıkmaz',
        (tester) async {
      await pump(
        tester,
        review(drafts: [
          _draft(description: 'SOK-10419-USKUDAR', categoryId: 'Market'),
          _draft(description: 'SOK 22133 KADIKOY', categoryId: 'Market'),
          _draft(description: 'TEK KATEGORISIZ', day: 7),
        ]),
      );
      expect(find.byKey(const ValueKey('review-group-tile')), findsNothing);
    });

    testWidgets(
        'satırda GÖRÜNÜR düzenleme kolu: açıklama, tutar ve tür tek sayfada',
        (tester) async {
      await pump(
        tester,
        review(drafts: [
          _draft(description: 'ESKI ACIKLAMA', categoryId: 'Market'),
        ]),
      );

      // ÖNCE: satırın ucunda dokununca türü ONAYSIZ çeviren 20dp'lik bir ok
      // vardı; artık yok.
      expect(find.byIcon(Icons.trending_down_rounded), findsNothing);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Satırı düzenle'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextField, 'Açıklama'), 'Yeni açıklama');
      await tester.tap(find.descendant(
        of: find.byKey(const ValueKey('draft-edit-type')),
        matching: find.text('Gelir'),
      ));
      await tester.pumpAndSettle();
      // Türün yan etkisi kaydetmeden önce yazıyor.
      expect(find.textContaining('kategori yeniden tahmin'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
      await tester.pumpAndSettle();

      verify(() => cubit.setDraftDescription(0, 'Yeni açıklama')).called(1);
      verify(() => cubit.setDraftType(0, TransactionTypeModel.income))
          .called(1);
      // Tutar değişmedi: yazılmaz.
      verifyNever(() => cubit.setDraftAmount(any(), any()));
    });

    testWidgets('düzenleme sayfasında vazgeçmek hiçbir şey yazmaz',
        (tester) async {
      await pump(
        tester,
        review(drafts: [_draft(description: 'X', categoryId: 'Market')]),
      );
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Açıklama'), 'Y');
      await tester.tap(find.widgetWithText(OutlinedButton, 'İptal'));
      await tester.pumpAndSettle();

      verifyNever(() => cubit.setDraftDescription(any(), any()));
      verifyNever(() => cubit.setDraftType(any(), any()));
    });

    testWidgets(
        'dar ekranda (360dp) şerit, kısayol ve düzenleme sayfası taşmaz',
        (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pump(
        tester,
        review(drafts: [
          _draft(description: 'SOK-10419-USKUDAR', day: 5),
          _draft(description: 'SOK 22133 KADIKOY', day: 6),
          _draft(
            description: 'ODEME ISLEMI ACIKLAMASI COK UZUN OLAN BIR SATIR',
            categoryId: 'Fatura',
            amount: 123456.78,
          ),
        ]),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------
  // UX Tur 2 (11 Eki 2026) — listeye kalan yer
  // ---------------------------------------------------------------------
  group('kendi cüzdanların arasındaki para taşıması', () {
    // Bankadan karta ödeme harcama değildir; karttaki "Ödeme - Teşekkür
    // Ederiz" de gelir değildir. Eskiden bu satırlara da kategori ("Maaş"?)
    // seçtiriliyor, bağlama ancak içe aktarmadan SONRA yapılabiliyordu.
    WalletEntity wallet(String id, String name, {CreditCardInfo? card}) =>
        WalletEntity(
          id: id,
          userId: 'u1',
          name: name,
          balance: 1000,
          debt: 0,
          credit: 0,
          investment: 0,
          colorHex: '0xFF000000',
          iconName: 'money',
          createdAt: DateTime(2026, 1, 1),
          openingBalance: 0,
          creditCard: card,
        );
    final bank = wallet('w1', 'Banka');
    final card = wallet('c1', 'Bonus',
        card: const CreditCardInfo(closingDay: 25, dueDay: 5, last4: '4321'));
    final other = wallet('w2', 'Nakit');

    ImportDraft payment({String? transferTo}) => ImportDraft(
          date: DateTime(2026, 9, 30),
          description: 'Kart İşlemleri - 4321 nolu kart ödemesi',
          amount: 1303.03,
          type: TransactionTypeModel.expense,
          transferWalletId: transferTo,
        );

    setUp(() {
      when(() => cubit.setDraftTransfer(any(), any())).thenReturn(null);
    });

    testWidgets(
        'kart ödemesi satırında kategori yerine BAĞLAMAK önerilir; tek '
        'dokunuş satırı o karta bağlar', (tester) async {
      await pump(tester, review(drafts: [payment()]),
          wallets: [bank, card, other]);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));

      final suggestion =
          find.byKey(const ValueKey('review-transfer-suggest-0'));
      expect(suggestion, findsOneWidget);
      // Son 4 hanesi açıklamada geçen TEK kart önceden bulunur.
      expect(
        find.textContaining(l10n.bankImportTransferLinkTo('Bonus'),
            findRichText: true),
        findsOneWidget,
      );

      await tester.tap(suggestion);
      await tester.pumpAndSettle();

      verify(() => cubit.setDraftTransfer(0, 'c1')).called(1);
    });

    testWidgets(
        'işaretli satırda kategori kolu yok, çip var; engel şeridi çıkmaz; '
        'çipe dokunmak işareti kaldırır', (tester) async {
      await pump(tester, review(drafts: [payment(transferTo: 'c1')]),
          wallets: [bank, card, other]);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));

      expect(find.text(l10n.bankImportTransferChip('Bonus')), findsOneWidget);
      expect(find.text(l10n.bankImportPickCategoryHint), findsNothing);
      expect(find.byKey(const ValueKey('review-transfer-suggest-0')),
          findsNothing);
      // Kategorisi yok ama içe aktarmayı ENGELLEMEZ.
      expect(find.byKey(const ValueKey('review-assign-blocked')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('review-transfer-chip-0')));
      await tester.pumpAndSettle();

      verify(() => cubit.setDraftTransfer(0, null)).called(1);
    });

    testWidgets('karşı cüzdan belli değilse hangi cüzdan olduğu SORULUR',
        (tester) async {
      // Kartın son 4 hanesi kayıtlı değil: hangi kart olduğu bilinemez.
      final unknownCard = wallet('c1', 'Bonus',
          card: const CreditCardInfo(closingDay: 25, dueDay: 5));
      await pump(tester, review(drafts: [payment()]),
          wallets: [bank, unknownCard, other]);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));

      await tester.tap(find.byKey(const ValueKey('review-transfer-suggest-0')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.baglaCuzdanSec), findsOneWidget);
      // Hedef cüzdanın kendisi listede yok.
      expect(find.byKey(const ValueKey('review-transfer-wallet-w1')),
          findsNothing);
      await tester.tap(find.byKey(const ValueKey('review-transfer-wallet-c1')));
      await tester.pumpAndSettle();

      verify(() => cubit.setDraftTransfer(0, 'c1')).called(1);
    });

    testWidgets('sıradan harcama satırında bağlama önerisi yok',
        (tester) async {
      await pump(
        tester,
        review(
            drafts: [_draft(description: 'ORNEK BUFE', categoryId: 'Market')]),
        wallets: [bank, card],
      );

      expect(find.byKey(const ValueKey('review-transfer-suggest-0')),
          findsNothing);
    });

    testWidgets(
        'engel şeridindeki toplu "Kategori ata", kart ödemesi satırına '
        'kategori BASMAZ', (tester) async {
      await pump(
        tester,
        review(drafts: [
          payment(),
          _draft(description: 'ORNEK BUFE'),
        ]),
        wallets: [bank, card],
      );

      await tester.tap(find.byKey(const ValueKey('review-assign-blocked')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fatura').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 satıra uygula'));
      await tester.pumpAndSettle();

      // Yalnız sıradan satır (1) kategorilendi; ödeme satırı (0) kendi
      // önerisinden karar bekliyor.
      final indexes =
          verify(() => cubit.applyCategoryToIndexes(captureAny(), any()))
              .captured
              .single as List<int>;
      expect(indexes, [1]);
    });
  });

  group('taksitli satır', () {
    ImportDraft installment({bool selected = true}) {
      final info = DraftInstallment(
          no: 1, count: 6, purchaseDate: DateTime(2026, 10, 6));
      return ImportDraft(
        date: info.dateOf(1),
        description: 'ORNEK MOTOR (1/6)',
        amount: 1200.5,
        type: TransactionTypeModel.expense,
        categoryId: 'Market',
        installment: info,
        selected: selected,
      );
    }

    testWidgets('kalan taksitlerin de yazılacağı satırda SÖYLENİR',
        (tester) async {
      // Yazınca beş satır daha oluşacak: sürpriz olmamalı.
      await pump(tester, review(drafts: [installment()]));
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));

      expect(find.byKey(const ValueKey('review-installment-note-0')),
          findsOneWidget);
      expect(
        find.text(l10n.bankImportInstallmentNote(5, '06.03.27')),
        findsOneWidget,
      );
    });

    testWidgets('satır eklenmeyecekse not da yok', (tester) async {
      await pump(tester, review(drafts: [installment(selected: false)]));

      expect(find.byKey(const ValueKey('review-installment-note-0')),
          findsNothing);
    });

    testWidgets('taksitsiz satırda not yok', (tester) async {
      await pump(
        tester,
        review(
            drafts: [_draft(description: 'ORNEK BUFE', categoryId: 'Market')]),
      );

      expect(find.byKey(const ValueKey('review-installment-note-0')),
          findsNothing);
    });
  });

  group('listeye kalan yer (360×800)', () {
    /// Uygulamadaki gövde: 800 − durum çubuğu 24 − AppBar 56 = 720dp.
    Future<({double listHeight, int rows})> measure(
      WidgetTester tester,
      BankImportReview state,
    ) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pump(tester, state);
      final list = tester.getRect(find.byType(ListView));
      var rows = 0;
      for (final box in find.byType(Checkbox).evaluate()) {
        final rect = tester.getRect(find.byWidget(box.widget));
        if (rect.top >= list.top && rect.bottom <= list.bottom) rows++;
      }
      debugPrint('ÖLÇÜM liste: top=${list.top} bottom=${list.bottom} '
          'yükseklik=${list.height} · tam görünen satır=$rows');
      return (listHeight: list.height, rows: rows);
    }

    List<ImportDraft> statement({int uncategorized = 3}) => [
          for (var i = 0; i < 20; i++)
            _draft(
              description: 'HAREKET ${i + 1}',
              categoryId: i < uncategorized ? null : 'Market',
              income: i == 19,
              day: 1 + i,
            ),
        ];

    // ÖNCE (ölçüldü): liste 151dp (gövdenin %21'i), 2 tam satır. Üstte özet
    // kartı + arama alanı 299dp, altta engel şeridi + toplam + düğme 270dp
    // tutuyordu. Test fontu gerçek fonttan ~1,5× geniş olduğundan metinler
    // burada daha çok satıra bölünür; cihazdaki sayı bundan iyidir.
    testWidgets('kategorisiz satır varken liste gövdenin en az %40\'ı',
        (tester) async {
      final m = await measure(tester, review(drafts: statement()));
      expect(tester.takeException(), isNull);
      expect(m.listHeight, greaterThanOrEqualTo(720 * 0.40));
      expect(m.rows, greaterThanOrEqualTo(3));
    });

    // ÖNCE (ölçüldü): liste 315dp, 4 tam satır.
    testWidgets('hepsi kategoriliyken en az 5 tam satır', (tester) async {
      final m =
          await measure(tester, review(drafts: statement(uncategorized: 0)));
      expect(tester.takeException(), isNull);
      expect(m.rows, greaterThanOrEqualTo(5));
    });
  });
}
