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
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_day_rail.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_summary_strip.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_top_bar.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

import '../../../../support/real_font.dart';

/// İşlemler ekranının düzen smoke testi: GERÇEK fontla, gerçek telefon
/// genişliklerinde ve gerçek yazı ölçeklerinde.
///
/// **Neden var.** Elden geçirme turunda ölçülen taşmaların üçü de yalnız
/// belirli bir yazı ölçeğinde ya da belirli bir genişlikte çıkıyordu:
///  * eski takvim özet satırı — ölçek 1.6'da 6px, 2.0'da 53px;
///  * gün şeridi hücresi — sabit yükseklikle ölçek 1.6'da 4px;
///  * işlem kartı — ölçek 2.0'da tutar başlığı 40dp'ye düşürüp 24px.
/// Üçü de ölçek 1.0'da GÖRÜNMÜYORDU. Bu dosya o kombinasyonları sabitler.
///
/// İki ölçüm tuzağı da kapalı: 800×600 varsayılan test yüzeyi genişlik
/// hatalarını gizler, test fontu (~1,45–1,7× geniş) olmayan taşmalar uydurur.
///
/// **Kabuk payı düşülüyor.** Ekran gerçekte tek başına değil: üstünde 70dp
/// AppBar, altında ~100dp sürgü var. Sayfaya kalan alanı testte de aynı
/// tutuyoruz, yoksa "sığıyor" iddiası gerçekte sığmayan bir yerleşimi geçirir.
class _MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockOnboardingCoordinator extends Mock
    implements OnboardingCoordinator {}

class _FakeTransactionEvent extends Fake implements TransactionEvent {}

void main() {
  setUpAll(() async {
    await loadRealRoboto();
    Intl.defaultLocale = 'tr';
    getIt.allowReassignment = true;
    registerFallbackValue(OnboardingFlow.shell);
    registerFallbackValue(_FakeTransactionEvent());
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
  });

  late _MockTransactionBloc bloc;
  late _MockCategoryRepository categories;

  final now = DateTime.now();
  final lastDay = DateTime(now.year, now.month + 1, 0).day;
  DateTime dayInThisMonth(int day) =>
      DateTime(now.year, now.month, day.clamp(1, lastDay), 12);

  // Gerçekçi bir ay: uzun Türkçe başlıklar, yedi haneli tutar, yoğun gün.
  final transactions = <TransactionEntity>[
    for (final e in <List<Object>>[
      ['Maaş — Eylül dönemi ödemesi', 'cat-maas', 1248750.5, 1, false],
      ['Migros Ataşehir alışverişi', 'cat-market', 1284.75, 2, true],
      ['Elektrik faturası (Enerjisa)', 'cat-fatura', 892.4, 3, true],
      ['Kira ödemesi', 'cat-kira', 18500.0, 3, true],
      ['A101 haftalık', 'cat-market', 456.3, 5, true],
      ['Doğalgaz faturası', 'cat-fatura', 1450.0, 7, true],
      ['Freelance proje ödemesi', 'cat-maas', 12500.0, 8, false],
      ['CarrefourSA', 'cat-market', 2145.6, 10, true],
      ['Restoran — akşam yemeği', 'cat-market', 1875.0, 12, true],
      ['İnternet — Türk Telekom', 'cat-fatura', 749.9, 12, true],
    ])
      TransactionEntity(
        id: 'tx-${e[3]}-${e[0]}',
        userId: 'u',
        walletId: 'w1',
        title: e[0] as String,
        tag: e[1] as String,
        amount: e[2] as double,
        date: dayInThisMonth(e[3] as int),
        type: (e[4] as bool)
            ? TransactionTypeModel.expense
            : TransactionTypeModel.income,
      ),
  ];

  final wallet = WalletEntity(
    id: 'w1',
    userId: 'u',
    name: 'Vadesiz Hesap',
    balance: 34521.75,
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
        name: 'Market ve Gıda',
        iconName: 'shopping_cart',
        isExpense: true),
    CategoryEntity(
        id: 'cat-fatura',
        name: 'Fatura',
        iconName: 'receipt_long',
        isExpense: true),
    CategoryEntity(
        id: 'cat-kira', name: 'Kira', iconName: 'home', isExpense: true),
    CategoryEntity(
        id: 'cat-maas', name: 'Maaş', iconName: 'payments', isExpense: false),
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
    when(() => categories.getCategories(true)).thenAnswer(
        (_) async => categoryList.where((c) => c.isExpense).toList());
    when(() => categories.getCategories(false)).thenAnswer(
        (_) async => categoryList.where((c) => !c.isExpense).toList());
    when(() => bloc.state).thenReturn(TransactionLoaded(
        groupedTransactions: const {}, allTransactions: transactions));
  });

  tearDown(() => getIt.reset());

  /// [action] boyunca çıkan TÜM düzen hatalarını toplar ve hatanın hangi
  /// widget'tan geldiğini failure mesajına koyar.
  ///
  /// `tester.takeException()` yalnız İLK hatayı verir ve yalnız özet
  /// cümlesini ("… overflowed by 8.6 pixels") taşır; hangi Column'un taştığı
  /// kaybolur. Bu turda o fark üç ayrı hata avında zaman kaybettirdi.
  Future<void> expectNoLayoutError(
    WidgetTester tester,
    String phase,
    Future<void> Function() action,
  ) async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    try {
      await action();
    } finally {
      FlutterError.onError = previous;
    }
    if (errors.isEmpty) return;
    final where = errors.first.informationCollector
            ?.call()
            .map((n) => n.toString())
            .firstWhere((line) => line.contains('.dart:'),
                orElse: () => '(konum yok)') ??
        '(konum yok)';
    fail('$phase: ${errors.first.exception}\n$where');
  }

  /// Uygulamanın kabuğunu taklit eder: 70dp üst çubuk + ~100dp sürgü.
  Future<void> pump(
    WidgetTester tester, {
    required double width,
    required double textScale,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      BlocProvider<AmountVisibilityCubit>(
        create: (_) => AmountVisibilityCubit(),
        child: MaterialApp(
          theme: ThemeData(fontFamily: kRealFontFamily),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          locale: const Locale('tr'),
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              textScaler: TextScaler.linear(textScale),
            ),
            child: Column(
              children: [
                const SizedBox(height: 70),
                Expanded(
                  child: BlocProvider<TransactionBloc>.value(
                    value: bloc,
                    child: TransactionsPage(userId: 'u', wallet: wallet),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('düzen — genişlik × yazı ölçeği', () {
    for (final width in [320.0, 360.0, 411.0]) {
      for (final scale in [1.0, 1.3, 1.6, 2.0]) {
        testWidgets('${width.toInt()}dp / ölçek $scale taşmaz', (tester) async {
          await expectNoLayoutError(
            tester,
            'açılış',
            () => pump(tester, width: width, textScale: scale),
          );

          // Kaydırma da bozmamalı: yapışkan gün başlıkları ve geri
          // dönüştürülen kartlar yeni kısıtlarla yeniden kuruluyor. Gün
          // şeridi TEMBEL çizdiği için ayın sonundaki iki haneli günler
          // ancak burada kuruluyor — 8,6px'lik taşma tam oradaydı.
          await expectNoLayoutError(tester, 'kaydırma', () async {
            await tester.drag(
                find.byType(CustomScrollView).first, const Offset(0, -300));
            await tester.pumpAndSettle();
          });

          await expectNoLayoutError(tester, 'filtre paneli', () async {
            await tester.tap(find.byIcon(Icons.tune_rounded));
            await tester.pumpAndSettle();
          });
        });
      }
    }
  });

  group('dikey bütçe (360×800, kabuk düşülmüş)', () {
    testWidgets('sabit chrome 60dp; defter satırı ilk ekranda görünür',
        (tester) async {
      await pump(tester, width: 360, textScale: 1.0);

      final page = tester.getRect(find.byType(TransactionsPage));
      final bar = tester.getSize(find.byType(TransactionTopBar));

      // Eski çubuk 110dp sabit yer kaplıyordu (arama + kontrol şeridi).
      // Arama içeriğe indi; kalıcı chrome bu.
      expect(bar.height, 60);

      final strip = tester.getSize(find.byType(TransactionSummaryStrip));
      expect(strip.height, lessThan(100),
          reason: 'eski özet kartı 191dp idi; şerit yarısından az olmalı');

      final rail = tester.getSize(find.byType(TransactionDayRail));
      expect(rail.height, lessThan(80), reason: 'eski takvim bloğu 374dp idi');

      // En az bir işlem kartı ilk ekranda TAM görünmeli. Eski takvim
      // görünümünde seçili günün kartı y=609'da başlıyor, ikincisi sürgünün
      // altında kalıyordu.
      final visible = find.byType(TransactionCard).evaluate().where((e) {
        final r = tester.getRect(find.byWidget(e.widget));
        return r.top >= page.top && r.bottom <= page.bottom;
      });
      expect(visible.length, greaterThanOrEqualTo(2));
    });

    testWidgets('kaydırınca arama yol verir, gün başlığı YAPIŞIR',
        (tester) async {
      await pump(tester, width: 360, textScale: 1.0);
      final page = tester.getRect(find.byType(TransactionsPage));

      await tester.drag(
          find.byType(CustomScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Yapışkan başlık: kaydırırken bir gün başlığı kaydırma gövdesinin
      // TEPESİNE yapışmalı ve başlıklar üst üste YIĞILMAMALI.
      //
      // Bulucu iki kez daraltılıyor. (1) Kaydırma gövdesine: üst çubuktaki
      // dönem etiketi de ("Eylül 2026") ay adını taşıyor ve zaten hep
      // tepede — onu sayan bir test yapışkanlığı değil hiçbir şeyi ölçmez.
      // (2) Metin değil KUTU ölçülüyor: başlık kutusunda dikeyde ortalanan
      // yazının üst kenarı kutudan 12dp aşağıda ve "tepede mi" sorusunu
      // yanlış cevaplıyordu.
      final headerTexts = find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.textContaining(DateFormat.MMMM('tr').format(now)),
      );
      expect(headerTexts, findsWidgets);

      final viewportTop =
          page.top + tester.getSize(find.byType(TransactionTopBar)).height;
      final headerBoxes = headerTexts.evaluate().map((e) => tester.getRect(
          find
              .ancestor(
                  of: find.byWidget(e.widget), matching: find.byType(InkWell))
              .first));

      final pinned = headerBoxes
          .where((r) => (r.top - viewportTop).abs() < 1.0)
          .length;
      expect(pinned, 1,
          reason: 'tam olarak BİR gün başlığı gövdenin tepesine yapışmalı '
              '(0 = yapışmıyor, >1 = yığılıyor)');

      final after = find.byType(TransactionCard).evaluate().where((e) {
        final r = tester.getRect(find.byWidget(e.widget));
        return r.top >= page.top && r.bottom <= page.bottom;
      });
      expect(after.length, greaterThanOrEqualTo(4),
          reason: 'kaydırınca chrome yoldan çekilmeli');
    });
  });
}
