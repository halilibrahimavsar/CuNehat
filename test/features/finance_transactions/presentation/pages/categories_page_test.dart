import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/delete_category_usecase.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/categories_page.dart';
import 'package:cunehat/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/wallet_category_stub.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockDeleteCategoryUseCase extends Mock implements DeleteCategoryUseCase {}

class MockRecurringRepository extends Mock
    implements RecurringTransactionRepository {}

class MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

void main() {
  late MockCategoryRepository repository;
  late MockWalletBloc walletBloc;
  late MockWalletCategoryService walletCategories;

  CategoryEntity cat(String id, String name, {bool isExpense = true}) =>
      CategoryEntity(
        id: id,
        name: name,
        iconName: 'category',
        isExpense: isExpense,
      );

  final expense = [cat('m', 'Market'), cat('f', 'Fatura')];
  final income = [cat('s', 'Maaş', isExpense: false)];

  WalletEntity wallet(String name) => WalletEntity(
        id: 'w1',
        userId: 'u1',
        name: name,
        balance: 0,
        debt: 0,
        credit: 0,
        investment: 0,
        colorHex: '0xFF2196F3',
        iconName: 'wallet',
        createdAt: DateTime(2026, 1, 1),
        openingBalance: 0,
        categoryIds: const [],
      );

  setUpAll(() => getIt.allowReassignment = true);

  setUp(() {
    repository = MockCategoryRepository();
    getIt.registerSingleton<CategoryRepository>(repository);
    walletCategories = registerUncuratedWalletCategories(repository);
    getIt.registerSingleton<TransactionsRepository>(
        MockTransactionsRepository());
    getIt.registerSingleton<DeleteCategoryUseCase>(MockDeleteCategoryUseCase());
    getIt.registerSingleton<RecurringTransactionRepository>(
        MockRecurringRepository());

    when(() => repository.getCategories(true)).thenAnswer((_) async => expense);
    when(() => repository.getCategories(false)).thenAnswer((_) async => income);

    walletBloc = MockWalletBloc();
  });

  tearDown(() => getIt.reset());

  Future<void> pump(WidgetTester tester, {WalletState? state}) async {
    whenListen(
      walletBloc,
      const Stream<WalletState>.empty(),
      initialState: state ?? WalletLoadedSt([wallet('İş')], wallet('İş')),
    );

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr'), Locale('en')],
      locale: const Locale('tr'),
      home: BlocProvider<WalletBloc>.value(
        value: walletBloc,
        child: const CategoriesPage(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('gider sekmesi açılışta gösterilir', (tester) async {
    await pump(tester);

    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Fatura'), findsOneWidget);
  });

  testWidgets('GELİR kategorilerine işlem formu olmadan ulaşılır',
      (tester) async {
    // Sayfanın varlık sebebi: yönetici eskiden yalnız işlem formundan ve
    // FORMUN TÜRÜNE KİLİTLİ açılıyordu — gider formundayken gelir ağacına
    // hiç ulaşılamıyordu.
    await pump(tester);

    expect(find.text('Maaş'), findsNothing);

    await tester.tap(find.text('Gelir Kategorileri'));
    await tester.pumpAndSettle();

    expect(find.text('Maaş'), findsOneWidget);
  });

  testWidgets('başlıkta AKTİF CÜZDANIN adı yazar (kapsam görünür olsun)',
      (tester) async {
    await pump(tester);

    expect(find.text('İş'), findsWidgets);
  });

  testWidgets('anahtar kapsamı aktif cüzdana yazar', (tester) async {
    await pump(tester);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    verify(() => walletCategories.setVisibility(
          walletId: 'w1',
          categoryId: any(named: 'categoryId'),
          visible: false,
        )).called(1);
  });

  testWidgets('cüzdan yoksa yönetilecek kapsam da yok', (tester) async {
    // Görünürlük cüzdana yazılıyor; cüzdansız açılan sayfa hiçbir anahtarı
    // kaydedemez, boş bir liste göstermek kullanıcıyı yanıltırdı.
    await pump(tester, state: const NoWalletSt());

    expect(find.text('Cüzdan oluşturunuz'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });
}
