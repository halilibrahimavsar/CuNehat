import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/transactions_usecases.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/usecase_params.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/single_transaction_detail_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/save_recurring_transaction_usecase.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:intl/intl.dart';

class MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockSaveRecurringTransactionUsecase extends Mock
    implements SaveRecurringTransactionUsecase {}

class FakeTransactionEvent extends Fake implements TransactionEvent {}

class FakeTransactionEntity extends Fake implements TransactionEntity {}

class FakeRecurringTransactionEntity extends Fake
    implements RecurringTransactionEntity {}

class MockOnboardingCoordinator extends Mock implements OnboardingCoordinator {}

class MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

class MockGetTransactionsGroupedUseCase extends Mock
    implements GetTransactionsGroupedUseCase {}

class MockAddTransactionUseCase extends Mock implements AddTransactionUseCase {}

class MockUpdateTransactionUseCase extends Mock
    implements UpdateTransactionUseCase {}

class MockDeleteTransactionUseCase extends Mock
    implements DeleteTransactionUseCase {}

class MockGetTransactionByIdUseCase extends Mock
    implements GetTransactionByIdUseCase {}

class MockWalletMetricsService extends Mock implements WalletMetricsService {}

void main() {
  // Para metni Intl.defaultLocale'e bakar; testte boş bırakılırsa intl onu
  // sessizce sistem locale'ine (genelde en_US) bağlar ve beklentiler
  // makineye göre kayar. Uygulamanın varsayılanına sabitliyoruz.
  setUpAll(() => Intl.defaultLocale = 'tr');

  late MockTransactionBloc mockTransactionBloc;
  late MockCategoryRepository mockCategoryRepository;
  late MockSaveRecurringTransactionUsecase mockSaveRecurringTransactionUsecase;
  late MockOnboardingCoordinator mockOnboardingCoordinator;

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(FakeTransactionEvent());
    registerFallbackValue(FakeTransactionEntity());
    registerFallbackValue(FakeRecurringTransactionEntity());
    registerFallbackValue(OnboardingFlow.transactions);
    // Sayfa Showcase kullanır; kayıtlı bir scope yoksa initState fırlatır.
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockTransactionBloc = MockTransactionBloc();
    mockCategoryRepository = MockCategoryRepository();
    mockSaveRecurringTransactionUsecase = MockSaveRecurringTransactionUsecase();
    mockOnboardingCoordinator = MockOnboardingCoordinator();

    getIt.registerSingleton<TransactionBloc>(mockTransactionBloc);
    getIt.registerSingleton<CategoryRepository>(mockCategoryRepository);
    // Sayfa kategori görüntüleme indeksini kendi yükler ve kategori
    // değişimlerinde tazeler (donmuş etiket düzenlemede yanlışa dönüyordu).
    getIt.registerSingleton<CategoriesChangedNotifier>(
        CategoriesChangedNotifier());
    getIt.registerSingleton<SaveRecurringTransactionUsecase>(
        mockSaveRecurringTransactionUsecase);
    // OnboardingAutoTourTrigger getIt üzerinden koordinatörü çeker.
    getIt.registerSingleton<OnboardingCoordinator>(mockOnboardingCoordinator);
    when(() => mockOnboardingCoordinator.isSeen(any())).thenReturn(true);

    when(() => mockCategoryRepository.getCategories(any())).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Food',
          iconName: 'fastfood',
          isExpense: true,
          isDefault: true,
        ),
      ],
    );
    when(() => mockCategoryRepository.getExpenseCategories()).thenAnswer(
      (_) async => const [
        CategoryEntity(
          id: 'Food',
          iconName: 'fastfood',
          isExpense: true,
          isDefault: true,
        ),
        CategoryEntity(
          id: 'Ulaşım',
          iconName: 'directions_bus',
          isExpense: true,
          isDefault: true,
        ),
      ],
    );
    when(() => mockCategoryRepository.getIncomeCategories())
        .thenAnswer((_) async => const []);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      locale: const Locale('tr'),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<TransactionBloc>.value(value: mockTransactionBloc),
          BlocProvider<AmountVisibilityCubit>(
            create: (_) => AmountVisibilityCubit(),
          ),
        ],
        child: Scaffold(body: child),
      ),
    );
  }

  testWidgets(
      'renders SingleTransactionDetailPage with normal transaction details',
      (WidgetTester tester) async {
    final now = DateTime(2026, 6, 13, 14, 30);
    final tx = TransactionEntity(
      id: 'tx_123',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'Market Shopping',
      tag: 'Food',
      amount: 150.0,
      date: now,
      type: TransactionTypeModel.expense,
      isSystem: false,
    );

    final item = TransactionWithBalance(transaction: tx, balanceAfter: 850.0);

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          now: [tx]
        },
        allTransactions: [tx],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        SingleTransactionDetailPage(
          item: item,
          heroTag: 'hero_tx_123',
        ),
      ),
    );

    // Verify Title and Amount
    expect(find.text('Market Shopping'), findsOneWidget);
    expect(find.text('-150,00 ₺'), findsOneWidget);

    // Verify Action buttons (Sil & Düzenle)
    expect(find.text('Sil'), findsOneWidget);
    expect(find.text('Düzenle'), findsOneWidget);
  });

  testWidgets(
      'renders system-generated transaction details with restriction badges',
      (WidgetTester tester) async {
    final now = DateTime(2026, 6, 13, 14, 30);
    final tx = TransactionEntity(
      id: 'tx_sys',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'Auto Payment',
      tag: 'Bills',
      amount: 45.0,
      date: now,
      type: TransactionTypeModel.expense,
      isSystem: true,
    );

    final item = TransactionWithBalance(transaction: tx, balanceAfter: 955.0);

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          now: [tx]
        },
        allTransactions: [tx],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        SingleTransactionDetailPage(
          item: item,
          heroTag: 'hero_tx_sys',
        ),
      ),
    );

    // Verify system badge and system notice
    expect(find.text('Otomatik işlem'), findsOneWidget);
    expect(
        find.text(
            'Bu işlem otomatik oluşturuldu. İlgili borç/yatırım/alacak kaydından düzenleyin veya silin.'),
        findsOneWidget);

    // Verify Action buttons (Sil & Düzenle) are NOT shown
    expect(find.text('Sil'), findsNothing);
    expect(find.text('Düzenle'), findsNothing);
  });

  testWidgets('tapping Edit opens edit transaction sheet',
      (WidgetTester tester) async {
    final now = DateTime(2026, 6, 13, 14, 30);
    final tx = TransactionEntity(
      id: 'tx_123',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'Market Shopping',
      tag: 'Food',
      amount: 150.0,
      date: now,
      type: TransactionTypeModel.expense,
      isSystem: false,
    );

    final item = TransactionWithBalance(transaction: tx, balanceAfter: 850.0);

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          now: [tx]
        },
        allTransactions: [tx],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        SingleTransactionDetailPage(
          item: item,
          heroTag: 'hero_tx_123',
        ),
      ),
    );

    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();

    // Verify edit sheet shows
    expect(find.text('Güncelle'), findsOneWidget);
  });

  testWidgets('tapping Sil dispatches immediately, no confirmation dialog',
      (WidgetTester tester) async {
    final now = DateTime(2026, 6, 13, 14, 30);
    final tx = TransactionEntity(
      id: 'tx_123',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'Market Shopping',
      tag: 'Food',
      amount: 150.0,
      date: now,
      type: TransactionTypeModel.expense,
      isSystem: false,
    );

    final item = TransactionWithBalance(transaction: tx, balanceAfter: 850.0);

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          now: [tx]
        },
        allTransactions: [tx],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        SingleTransactionDetailPage(
          item: item,
          heroTag: 'hero_tx_123',
        ),
      ),
    );

    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();

    // Onay diyaloğu YOK: koruma modal değil, 6 saniyelik "Geri al" penceresi
    // (bkz. showDeletionMessage). Modal çıkarsa akış eski davranışa dönmüş
    // demektir.
    expect(find.text('İptal'), findsNothing);
    verify(() =>
            mockTransactionBloc.add(const DeleteTransactionEvent('tx_123')))
        .called(1);
  });

  testWidgets('tapping Sil dispatches DeleteTransactionEvent',
      (WidgetTester tester) async {
    final now = DateTime(2026, 6, 13, 14, 30);
    final tx = TransactionEntity(
      id: 'tx_123',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'Market Shopping',
      tag: 'Food',
      amount: 150.0,
      date: now,
      type: TransactionTypeModel.expense,
      isSystem: false,
    );

    final item = TransactionWithBalance(transaction: tx, balanceAfter: 850.0);

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          now: [tx]
        },
        allTransactions: [tx],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        SingleTransactionDetailPage(
          item: item,
          heroTag: 'hero_tx_123',
        ),
      ),
    );

    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();

    verify(() =>
            mockTransactionBloc.add(const DeleteTransactionEvent('tx_123')))
        .called(1);
  });

  group('canlı defter senkronizasyonu (regresyon)', () {
    final now = DateTime(2026, 6, 13, 14, 30);
    final tx = TransactionEntity(
      id: 'tx_123',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'Market Shopping',
      tag: 'Food',
      amount: 150.0,
      date: now,
      type: TransactionTypeModel.expense,
    );
    final other = TransactionEntity(
      id: 'tx_999',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'Kahve',
      tag: 'Food',
      amount: 50.0,
      date: DateTime(2026, 6, 12, 9),
      type: TransactionTypeModel.expense,
    );

    final wallet = WalletEntity(
      id: 'wallet_123',
      userId: 'user_123',
      name: 'Ana',
      balance: 800.0,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '#000000',
      iconName: 'wallet',
      createdAt: DateTime(2026, 1, 1),
      openingBalance: 1000.0,
      isActive: true,
    );

    TransactionLoaded loaded(List<TransactionEntity> list) => TransactionLoaded(
          groupedTransactions: {now: list},
          allTransactions: list,
        );

    /// Sayfayı gerçekteki gibi ALT ROUTE olarak iter: kapanıp kapanmadığı
    /// ancak altında bir route varken ölçülebilir. Provider'lar gerçek
    /// uygulamadaki gibi (bkz. AppProviders) MaterialApp'in üstündedir.
    Future<void> pushDetail(
      WidgetTester tester, {
      required TransactionWithBalance item,
      String? categoryLabel,
      WalletBloc? walletBloc,
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider<TransactionBloc>.value(value: mockTransactionBloc),
          BlocProvider<AmountVisibilityCubit>(
            create: (_) => AmountVisibilityCubit(),
          ),
          if (walletBloc != null)
            BlocProvider<WalletBloc>.value(value: walletBloc),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          locale: const Locale('tr'),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<TransactionBloc>(),
                        child: SingleTransactionDetailPage(
                          item: item,
                          heroTag: 'hero_tx_123',
                          categoryLabel: categoryLabel,
                        ),
                      ),
                    ),
                  ),
                  child: const Text('AÇ'),
                ),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('AÇ'));
      await tester.pumpAndSettle();
      expect(find.text('İşlem Detayı'), findsOneWidget);
    }

    testWidgets('silme sonrası sayfa KENDİNİ KAPATIR', (tester) async {
      // TransactionActionSuccess artık silme SONRASINDAKİ defteri taşır;
      // eskiden eylem öncesi liste taşındığı için sayfa hiç kapanmıyordu.
      final states = StreamController<TransactionState>.broadcast();
      addTearDown(states.close);
      whenListen(mockTransactionBloc, states.stream,
          initialState: loaded([tx]));

      await pushDetail(
        tester,
        item: TransactionWithBalance(transaction: tx, balanceAfter: 850.0),
      );

      states.add(const TransactionActionSuccess(
        'Market Shopping silindi',
        transactions: [],
      ));
      await tester.pumpAndSettle();

      expect(find.text('İşlem Detayı'), findsNothing);
      expect(find.text('AÇ'), findsOneWidget);
    });

    testWidgets('yükleme ara durumunda sayfa YANLIŞLIKLA kapanmaz',
        (tester) async {
      // TransactionLoading yenileme sırasında listeyi boş taşıyabilir;
      // "gitti" sanılıp kapatılmamalı.
      final states = StreamController<TransactionState>.broadcast();
      addTearDown(states.close);
      whenListen(mockTransactionBloc, states.stream,
          initialState: loaded([tx]));

      await pushDetail(
        tester,
        item: TransactionWithBalance(transaction: tx, balanceAfter: 850.0),
      );

      states.add(const TransactionLoading());
      states.add(const TransactionError('boom'));
      await tester.pumpAndSettle();

      expect(find.text('İşlem Detayı'), findsOneWidget);
    });

    testWidgets('düzenleme kategoriyi ANINDA yansıtır', (tester) async {
      // Kart çözülmüş etiketi taşır ama o etiket AÇILIŞ tag'ine donmuştur;
      // kategori değişince sayfa canlı indeksten yeniden çözmeli.
      final states = StreamController<TransactionState>.broadcast();
      addTearDown(states.close);
      whenListen(mockTransactionBloc, states.stream,
          initialState: loaded([tx]));

      await pushDetail(
        tester,
        item: TransactionWithBalance(transaction: tx, balanceAfter: 850.0),
        categoryLabel: 'Yemek',
      );

      states.add(TransactionActionSuccess(
        'Market Shopping başarıyla güncellendi',
        transactions: [tx.copyWith(tag: 'Ulaşım', amount: 500)],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Ulaşım'), findsOneWidget);
      expect(find.text('Yemek'), findsNothing);
      expect(find.text('-500,00 ₺'), findsOneWidget);
    });

    testWidgets('işlem sonrası bakiye CANLI defterden hesaplanır',
        (tester) async {
      // Karttan gelen balanceAfter açılış anına donmuştur; tutar düzenlenince
      // yanlışa döner. Cüzdan bakiyesi 800, defter: 12 Haz -50, 13 Haz -150.
      // Düzenleme sonrası (13 Haz -500) cüzdan bakiyesi 450'ye iner ve
      // en yeni işlemin "sonrası bakiye"si cüzdan bakiyesidir.
      final walletStates = StreamController<WalletState>.broadcast();
      addTearDown(walletStates.close);
      final walletBloc = MockWalletBloc();
      whenListen(walletBloc, walletStates.stream,
          initialState: WalletLoadedSt([wallet], wallet));

      final states = StreamController<TransactionState>.broadcast();
      addTearDown(states.close);
      whenListen(mockTransactionBloc, states.stream,
          initialState: loaded([tx, other]));

      await pushDetail(
        tester,
        item: TransactionWithBalance(transaction: tx, balanceAfter: 800.0),
        walletBloc: walletBloc,
      );

      // Açılışta: cüzdan 800, tx en yeni işlem → sonrası bakiye 800.
      expect(find.text('800,00 ₺'), findsOneWidget);

      // Düzenleme: tutar 150 → 500, cüzdan bakiyesi 800 → 450.
      states.add(TransactionActionSuccess(
        'Market Shopping başarıyla güncellendi',
        transactions: [tx.copyWith(amount: 500), other],
      ));
      walletStates.add(WalletLoadedSt(
        [wallet.copyWith(balance: 450.0)],
        wallet.copyWith(balance: 450.0),
      ));
      await tester.pumpAndSettle();

      // Düzenleme sonrası donmuş 800 değil, canlı 450 görünmeli.
      expect(find.text('450,00 ₺'), findsOneWidget);
      expect(find.text('800,00 ₺'), findsNothing);
    });

    testWidgets('uçtan uca: GERÇEK bloc ile Sil sayfayı kapatır',
        (tester) async {
      // Kullanıcının bildirdiği hata tam bu dikişte kalmıştı: bloc "silindi"
      // derken defterin eylem ÖNCESİ hâlini taşıyordu, sayfa da bu listeye
      // bakıp "hâlâ duruyor" sonucuna varıyordu. İki katman ayrı ayrı
      // doğru görünüyordu; yalnız birlikte koştuğunda hata çıkıyordu.
      registerFallbackValue(
          GetTransactionsGroupedParams(userId: 'user_123', walletId: 'w'));

      final getGrouped = MockGetTransactionsGroupedUseCase();
      final del = MockDeleteTransactionUseCase();
      final byId = MockGetTransactionByIdUseCase();
      final metrics = MockWalletMetricsService();
      final notifier = TransactionsChangedNotifier();

      var ledger = <TransactionEntity>[tx];
      when(() => getGrouped(any()))
          .thenAnswer((_) async => Right({now: List.of(ledger)}));
      when(() => byId('tx_123')).thenAnswer((_) async => Right(tx));
      when(() => del(any(), keepReceiptFile: any(named: 'keepReceiptFile')))
          .thenAnswer((_) async {
        ledger = [];
        return const Right(null);
      });
      when(() => metrics.syncBalance(any())).thenAnswer((_) async => true);

      final realBloc = TransactionBloc(
        getTransactionsGroupedUseCase: getGrouped,
        addTransactionUseCase: MockAddTransactionUseCase(),
        updateTransactionUseCase: MockUpdateTransactionUseCase(),
        deleteTransactionUseCase: del,
        getTransactionByIdUseCase: byId,
        walletMetricsService: metrics,
        transactionsChangedNotifier: notifier,
      );
      addTearDown(() async {
        await realBloc.close();
        notifier.dispose();
      });

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider<TransactionBloc>.value(value: realBloc),
          BlocProvider<AmountVisibilityCubit>(
            create: (_) => AmountVisibilityCubit(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          locale: const Locale('tr'),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<TransactionBloc>(),
                        child: SingleTransactionDetailPage(
                          item: TransactionWithBalance(
                              transaction: tx, balanceAfter: 850.0),
                          heroTag: 'hero_tx_123',
                        ),
                      ),
                    ),
                  ),
                  child: const Text('AÇ'),
                ),
              ),
            ),
          ),
        ),
      ));

      realBloc.add(GetTransactionsEvent(userId: 'user_123', walletId: 'w'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AÇ'));
      await tester.pumpAndSettle();
      expect(find.text('İşlem Detayı'), findsOneWidget);

      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();

      expect(find.text('İşlem Detayı'), findsNothing);
      expect(find.text('AÇ'), findsOneWidget);
    });
  });
}
