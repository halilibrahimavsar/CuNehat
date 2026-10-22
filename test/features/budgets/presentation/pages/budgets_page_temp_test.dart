import 'package:shared_preferences/shared_preferences.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_picker_sheet.dart';
import 'package:cunehat/core/services/recent_categories_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_event.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_state.dart';
import 'package:cunehat/features/budgets/presentation/pages/budgets_page.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/wallet_category_service.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

class _MockBudgetsBloc extends MockBloc<BudgetsEvent, BudgetsState>
    implements BudgetsBloc {}

class _MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

class _MockAuthBloc extends MockBloc<AppAuthEvent, AppAuthState>
    implements AppAuthBloc {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockWalletCategoryService extends Mock
    implements WalletCategoryService {}

CategoryEntity _cat(String id, String name, {String? parentId}) =>
    CategoryEntity(
      id: id,
      name: name,
      iconName: 'category',
      isExpense: true,
      parentId: parentId,
      sortOrder: 1,
    );

/// Market(Manav) · Fatura · Ulaşım — Market ve Fatura'nın bütçesi var.
final _categories = [
  _cat('market', 'Market'),
  _cat('manav', 'Manav', parentId: 'market'),
  _cat('fatura', 'Fatura'),
  _cat('ulasim', 'Ulaşım'),
];

/// Tek seferlik bütçe: Bütçeler sayfasındaki bölüm ve form.
void main() {
  late _MockBudgetsBloc budgets;
  late _MockWalletBloc wallets;
  late _MockAuthBloc auth;

  final today = DateTime.now();
  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);

  final active = TempBudgetEntity(
    id: 'active',
    walletId: 'w',
    name: 'Tatil',
    limitAmount: 10000,
    startDate: day(-2),
    endDate: day(3),
    categoryIds: const ['market', 'ulasim'],
    spentAmount: 6000,
  );
  final finished = TempBudgetEntity(
    id: 'done',
    walletId: 'w',
    name: 'Bayram',
    limitAmount: 3000,
    startDate: day(-30),
    endDate: day(-25),
    categoryIds: const ['fatura'],
    spentAmount: 3500,
  );

  setUpAll(() {
    registerFallbackValue(const DeleteTempBudgetEvent('x'));
  });

  setUp(() async {
    Intl.defaultLocale = 'tr_TR';
    getIt.allowReassignment = true;
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton<RecentCategoriesService>(
        RecentCategoriesService(await SharedPreferences.getInstance()));
    budgets = _MockBudgetsBloc();
    wallets = _MockWalletBloc();
    auth = _MockAuthBloc();
    when(() => wallets.state).thenReturn(NoWalletSt());
    when(() => auth.state).thenReturn(AppAuthInitial());
    when(() => budgets.state)
        .thenReturn(BudgetsLoaded(const [], tempBudgets: [active, finished]));

    getIt.registerFactory<BudgetsBloc>(() => budgets);
    getIt.registerSingleton<CategoriesChangedNotifier>(
        CategoriesChangedNotifier());
    final repo = _MockCategoryRepository();
    when(() => repo.getCategories(true)).thenAnswer((_) async => _categories);
    getIt.registerSingleton<CategoryRepository>(repo);
    final scope = _MockWalletCategoryService();
    when(() => scope.categoriesFor(
          walletId: any(named: 'walletId'),
          isExpense: any(named: 'isExpense'),
          alwaysInclude: any(named: 'alwaysInclude'),
        )).thenAnswer((_) async => _categories);
    getIt.registerSingleton<WalletCategoryService>(scope);
  });

  tearDown(() async => getIt.reset());

  Future<AppLocalizations> pumpPage(WidgetTester tester,
      {Size size = const Size(800, 1600), double textScale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<WalletBloc>.value(value: wallets),
          BlocProvider<AppAuthBloc>.value(value: auth),
        ],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const BudgetsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.delegate.load(const Locale('tr'));
  }

  TempBudgetEntity savedTemp() => verify(() => budgets.add(captureAny()))
      .captured
      .whereType<SaveTempBudgetEvent>()
      .single
      .budget;

  testWidgets(
      'yalnız geçici bütçe varken "bu ay" özeti ÇİZİLMEZ; süren kart kalan '
      'günü ve günlük payı yazar, biten daraltılmış durur', (tester) async {
    final l10n = await pumpPage(tester);

    expect(find.text(l10n.bUAyToplamHarcama), findsNothing);
    expect(find.text(l10n.henuzButceYok), findsNothing);
    expect(find.text(l10n.tempBudgetSectionTitle), findsOneWidget);

    final card = find.byKey(const ValueKey('temp-budget-card-active'));
    expect(card, findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('Tatil')),
        findsOneWidget);
    expect(
        find.descendant(
            of: card, matching: find.text(l10n.tempBudgetDaysLeft(4))),
        findsOneWidget);
    // Kalan 4.000 / 4 gün = günde 1.000.
    expect(find.descendant(of: card, matching: find.textContaining('1.000')),
        findsWidgets);
    // Kategori adları çözülür (ham kimlik değil).
    expect(find.descendant(of: card, matching: find.text('Market')),
        findsOneWidget);

    expect(find.text(l10n.tempBudgetFinishedSection(1)), findsOneWidget);
    expect(find.byKey(const ValueKey('temp-budget-card-done')), findsNothing);
    await tester.tap(find.text(l10n.tempBudgetFinishedSection(1)));
    await tester.pumpAndSettle();
    final done = find.byKey(const ValueKey('temp-budget-card-done'));
    expect(done, findsOneWidget);
    expect(find.descendant(of: done, matching: find.textContaining('aştı')),
        findsOneWidget);
  });

  // Cihazda 320dp + 1,3 yazı ölçeğinde özet rozeti kesiliyor, "Harcanan" ile
  // "Limit" yapışıp taşıyor, tek seferlik kartta ad ile rozet ikisi birden
  // kısalıyordu.
  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('320dp telefonda (yazı ölçeği $scale) bütçe kartları taşmaz',
        (tester) async {
      when(() => budgets.state).thenReturn(BudgetsLoaded(const [
        BudgetEntity(
            categoryId: 'market',
            walletId: 'w',
            limitAmount: 1250000,
            spentAmount: 987654.32),
      ], tempBudgets: [
        active
      ]));
      await pumpPage(tester, size: const Size(320, 4000), textScale: scale);

      expect(tester.takeException(), isNull);
      // Ad rozetle yarışmaz: "Tatil" kısalmadan tek satırda sığar. 2,0'da
      // test fontu (her harf tam kare) gerçeğinin ~iki katı geniş, ölçülmez.
      if (scale <= 1.3) {
        final name = tester.renderObject<RenderParagraph>(find.text('Tatil'));
        expect(name.didExceedMaxLines, isFalse);
      }
    });
  }

  testWidgets('"+" → tek seferlik: boş formda üç doğrulama, kayıt yok',
      (tester) async {
    final l10n = await pumpPage(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('budget-kind-oneTime')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.tempBudgetNewTitle), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('temp-budget-save')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.tempBudgetNameRequired), findsOneWidget);
    expect(find.text(l10n.tempBudgetRangeRequired), findsOneWidget);
    expect(find.text(l10n.tempBudgetCategoriesRequired), findsOneWidget);
    verifyNever(() => budgets.add(any(that: isA<SaveTempBudgetEvent>())));
  });

  testWidgets(
      'karta dokun → dolu form; seçili ana kategorinin altı KİLİTLİ; '
      'kaydet aynı kimlikle günceller', (tester) async {
    final l10n = await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('temp-budget-card-active')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.tempBudgetEditTitle), findsOneWidget);
    expect(
        find.byKey(const ValueKey('temp-budget-cat-market')), findsOneWidget);

    // Market seçiliyken Manav (alt kategori) seçilemez.
    await tester.tap(find.byKey(const ValueKey('temp-budget-add-category')));
    await tester.pumpAndSettle();
    await tester.tap(find
        .descendant(
            of: find.byType(CategoryPickerSheet), matching: find.text('Market'))
        .first);
    await tester.pumpAndSettle();
    final manav = find.byKey(const ValueKey('category-pick-manav'));
    expect(tester.widget<ListTile>(manav).enabled, isFalse);
    expect(
        find.descendant(
            of: manav,
            matching:
                find.textContaining(l10n.tempBudgetCategoryCovered('Market'))),
        findsOneWidget);
    // Fatura eklenir.
    await tester.tap(find
        .descendant(
            of: find.byType(CategoryPickerSheet), matching: find.text('Fatura'))
        .first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-pick-fatura')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('temp-budget-cat-fatura')), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('temp-budget-name-field')), 'Yaz tatili');
    await tester.tap(find.byKey(const ValueKey('temp-budget-save')));
    await tester.pumpAndSettle();

    final saved = savedTemp();
    expect(saved.id, 'active');
    expect(saved.name, 'Yaz tatili');
    expect(saved.limitAmount, 10000);
    expect(saved.startDate, active.startDate);
    expect(saved.endDate, active.endDate);
    expect(saved.categoryIds, ['market', 'ulasim', 'fatura']);
  });

  testWidgets('ana kategori eklenince altındaki seçili kategori listeden düşer',
      (tester) async {
    when(() => budgets.state).thenReturn(BudgetsLoaded(const [], tempBudgets: [
      active.copyWith(categoryIds: const ['manav'])
    ]));
    await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('temp-budget-card-active')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('temp-budget-add-category')));
    await tester.pumpAndSettle();
    await tester.tap(find
        .descendant(
            of: find.byType(CategoryPickerSheet), matching: find.text('Market'))
        .first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-pick-market')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('temp-budget-cat-market')), findsOneWidget);
    expect(find.byKey(const ValueKey('temp-budget-cat-manav')), findsNothing);
  });

  testWidgets('silme onaylanınca kimlikle silinir', (tester) async {
    final l10n = await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('temp-budget-menu-active')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('row-action-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.sil));
    await tester.pumpAndSettle();

    verify(() => budgets.add(const DeleteTempBudgetEvent('active'))).called(1);
  });
}
