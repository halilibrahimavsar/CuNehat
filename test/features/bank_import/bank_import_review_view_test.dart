import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/services/recent_categories_service.dart';
import 'package:cunehat/features/bank_import/data/statement_verification.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/bank_import/presentation/pages/bank_import_review_view.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
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
      isDuplicate: duplicate,
    );

void main() {
  // Para metni Intl.defaultLocale'e bakar; testte boş bırakılırsa intl onu
  // sessizce sistem locale'ine (genelde en_US) bağlar ve beklentiler
  // makineye göre kayar. Uygulamanın varsayılanına sabitliyoruz.
  setUpAll(() {
    Intl.defaultLocale = 'tr';
    getIt.allowReassignment = true;
    registerFallbackValue(FakeCategoryEntity());
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
    when(() => cubit.setAllSelected(any())).thenReturn(null);
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
      );

  Future<void> pump(
    WidgetTester tester,
    BankImportReview state, {
    bool fullscreen = false,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
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
    );
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

    // Yalnız BOŞ satır doldurulur; kategorili ikisinin üzerine yazılmaz.
    final captured = verify(
      () => cubit.applyCategoryToIndexes(captureAny(), 'fatura-elektrik'),
    ).captured;
    expect(captured.single, [2]);
    expect(tester.takeException(), isNull);
  });
  // F1 güvenlik ağı: kümeleme ortak ÖN EKE bakıyor ve ön ek her zaman marka
  // değil ("TURK HAVA YOLLARI" + "TURK EKONOMI BANKASI" tek grup —
  // `description_grouper.dart` "BİLİNEN SINIR"). Tek dokunuşluk kısayol yalnız
  // SAYI gösterirse kullanıcı neye dokunduğunu görmeden onaylar; öneri
  // etkilenecek satırdan örnek metin taşımalı.
  testWidgets('benzer satır önerisi örnek açıklama gösterir', (tester) async {
    final drafts = [
      _draft(description: 'MIGROS SANAL MARKET'),
      _draft(description: 'MIGROS JET KADIKOY', day: 6),
    ];

    await pump(tester, review(drafts: drafts));

    await tester.tap(find.text('Kategori seç').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fatura').last);
    await tester.pumpAndSettle();

    // Satırın kendisi de aynı metni taşıyor; iddia MESAJIN tamamına kurulur.
    expect(
      find.textContaining('daha var: MIGROS JET KADIKOY'),
      findsOneWidget,
    );
    expect(find.text('Hepsine uygula'), findsOneWidget);
  });
}
