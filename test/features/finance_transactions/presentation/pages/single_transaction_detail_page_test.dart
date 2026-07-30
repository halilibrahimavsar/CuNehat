import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/single_transaction_detail_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/save_recurring_transaction_usecase.dart';
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
}
