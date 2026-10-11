import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_event.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_state.dart';
import 'package:cunehat/features/budgets/presentation/pages/budgets_page.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/wallet_category_service.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
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

CategoryEntity _cat(String id, String name) => CategoryEntity(
      id: id,
      name: name,
      iconName: 'category',
      isExpense: true,
      sortOrder: 1,
    );

/// Bütçe limiti düzenleme (UX Tur 4 · D1).
///
/// ÖNCE: karta dokunmak boştu. Limiti değiştirmek = "+" → yeni bütçe formu →
/// AYNI kategoriyi yeniden seç → form sessizce "Güncelle"ye döner.
void main() {
  late _MockBudgetsBloc budgets;
  late _MockWalletBloc wallets;
  late _MockAuthBloc auth;

  setUpAll(() {
    registerFallbackValue(
        const SaveBudgetEvent(BudgetEntity(categoryId: 'x', limitAmount: 1)));
  });

  setUp(() {
    Intl.defaultLocale = 'tr_TR';
    getIt.allowReassignment = true;
    budgets = _MockBudgetsBloc();
    wallets = _MockWalletBloc();
    auth = _MockAuthBloc();
    when(() => wallets.state).thenReturn(NoWalletSt());
    when(() => auth.state).thenReturn(AppAuthInitial());
    when(() => budgets.state).thenReturn(const BudgetsLoaded([
      BudgetEntity(categoryId: 'market', limitAmount: 5000, spentAmount: 1200),
      BudgetEntity(categoryId: 'fatura', limitAmount: 2000, spentAmount: 0),
    ]));

    getIt.registerFactory<BudgetsBloc>(() => budgets);
    getIt.registerSingleton<CategoriesChangedNotifier>(
        CategoriesChangedNotifier());
    final repo = _MockCategoryRepository();
    when(() => repo.getCategories(true)).thenAnswer(
        (_) async => [_cat('market', 'Market'), _cat('fatura', 'Fatura')]);
    getIt.registerSingleton<CategoryRepository>(repo);
    final scope = _MockWalletCategoryService();
    when(() => scope.categoriesFor(
              walletId: any(named: 'walletId'),
              isExpense: any(named: 'isExpense'),
              alwaysInclude: any(named: 'alwaysInclude'),
            ))
        .thenAnswer(
            (_) async => [_cat('market', 'Market'), _cat('fatura', 'Fatura')]);
    getIt.registerSingleton<WalletCategoryService>(scope);
  });

  tearDown(() async => getIt.reset());

  Future<AppLocalizations> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<WalletBloc>.value(value: wallets),
          BlocProvider<AppAuthBloc>.value(value: auth),
        ],
        child: const MaterialApp(
          locale: Locale('tr'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: BudgetsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.delegate.load(const Locale('tr'));
  }

  BudgetEntity savedBudget() => verify(() => budgets.add(captureAny()))
      .captured
      .whereType<SaveBudgetEvent>()
      .single
      .budget;

  testWidgets(
      'karta dokun → limit dolu açılır, kategori kilitli; kaydet günceller',
      (tester) async {
    final l10n = await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('budget-card-market')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.butceyiDuzenle), findsOneWidget);
    // Kategori seçici YOK: bütçenin kimliği kategorisidir.
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    final field = find.byKey(const ValueKey('budget-limit-field'));
    expect(
      tester
          .widget<TextField>(
              find.descendant(of: field, matching: find.byType(TextField)))
          .controller!
          .text,
      '5.000',
    );

    await tester.enterText(field, '6500');
    await tester.tap(find.widgetWithText(FilledButton, l10n.guncelle));
    await tester.pumpAndSettle();

    final saved = savedBudget();
    expect(saved.categoryId, 'market');
    expect(saved.limitAmount, 6500);
    // Sayfa kapandı.
    expect(find.text(l10n.butceyiDuzenle), findsNothing);
  });

  testWidgets('düzenlemede vazgeçmek hiçbir şey yazmaz', (tester) async {
    final l10n = await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('budget-card-fatura')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('budget-limit-field')), '1');
    await tester.tap(find.widgetWithText(OutlinedButton, l10n.iptal));
    await tester.pumpAndSettle();

    verifyNever(() => budgets.add(any(that: isA<SaveBudgetEvent>())));
  });

  testWidgets('"+" yeni bütçe formunu açar: kategori seçilir, alt sayfadır',
      (tester) async {
    final l10n = await pumpPage(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.yeniButceEkle), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);

    // Kategori seçmeden kaydet → çevrilmiş doğrulama metni, kayıt yok.
    await tester.enterText(
        find.byKey(const ValueKey('budget-limit-field')), '100');
    await tester.tap(find.widgetWithText(FilledButton, l10n.kaydet));
    await tester.pumpAndSettle();
    expect(find.text(l10n.kategoriSecmeUyarisi), findsOneWidget);
    verifyNever(() => budgets.add(any(that: isA<SaveBudgetEvent>())));
  });
}
