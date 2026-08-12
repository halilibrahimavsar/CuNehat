import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/single_transaction_detail_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_card.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/save_recurring_transaction_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// Showcase turları getIt üzerinden koordinatörü çeker; widget testlerinde
/// gerçek koordinatör kayıtlı olmadığından mock'lanır.
class _MockOnboardingCoordinator extends Mock
    implements OnboardingCoordinator {}

void main() {
  // Para metni Intl.defaultLocale'e bakar; testte boş bırakılırsa intl onu
  // sessizce sistem locale'ine (genelde en_US) bağlar ve beklentiler
  // makineye göre kayar. Uygulamanın varsayılanına sabitliyoruz.
  setUpAll(() => Intl.defaultLocale = 'tr');

  late MockTransactionBloc mockTransactionBloc;
  late MockCategoryRepository mockCategoryRepository;
  late MockSaveRecurringTransactionUsecase mockSaveRecurringTransactionUsecase;

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(OnboardingFlow.shell);
    // Showcase widget'ı kayıtlı bir scope yoksa initState'te fırlatır.
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
    getIt.allowReassignment = true;
    registerFallbackValue(FakeTransactionEvent());
    registerFallbackValue(FakeTransactionEntity());
    registerFallbackValue(FakeRecurringTransactionEntity());
  });

  setUp(() {
    // tearDown'daki getIt.reset() kayıtları sildiğinden test başına yapılır.
    final onboardingCoordinator = _MockOnboardingCoordinator();
    when(() => onboardingCoordinator.isSeen(any())).thenReturn(true);
    getIt.registerSingleton<OnboardingCoordinator>(onboardingCoordinator);
    SharedPreferences.setMockInitialValues({});
    mockTransactionBloc = MockTransactionBloc();
    mockCategoryRepository = MockCategoryRepository();
    mockSaveRecurringTransactionUsecase = MockSaveRecurringTransactionUsecase();

    getIt.registerSingleton<TransactionBloc>(mockTransactionBloc);
    getIt.registerSingleton<CategoryRepository>(mockCategoryRepository);
    // Detay sayfası kategori indeksini kendi yükler ve kategori
    // değişimlerinde tazeler.
    getIt.registerSingleton<CategoriesChangedNotifier>(
        CategoriesChangedNotifier());
    getIt.registerSingleton<SaveRecurringTransactionUsecase>(
        mockSaveRecurringTransactionUsecase);

    when(() => mockCategoryRepository.getAllCategories())
        .thenAnswer((_) async => [
              ...await mockCategoryRepository.getCategories(true),
              ...await mockCategoryRepository.getCategories(false),
            ]);
    when(() => mockCategoryRepository.getCategories(true))
        .thenAnswer((_) async => const []);
    when(() => mockCategoryRepository.getCategories(false))
        .thenAnswer((_) async => const []);
    when(() => mockCategoryRepository.getCategories(any())).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Yemek',
          name: 'Yemek',
          iconName: 'fastfood',
          isExpense: true,
        ),
      ],
    );
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildTestableWidget(Widget child) {
    return BlocProvider<AmountVisibilityCubit>(
      create: (_) => AmountVisibilityCubit(),
      child: MaterialApp(
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
        home: Scaffold(
          body: BlocProvider<TransactionBloc>.value(
            value: mockTransactionBloc,
            child: child,
          ),
        ),
      ),
    );
  }

  final testDate = DateTime(2026, 6, 13, 14, 30);

  TransactionEntity createTx({required bool isSystem, required String id}) {
    return TransactionEntity(
      id: id,
      userId: 'user_123',
      walletId: 'wallet_123',
      title: isSystem ? 'Sistem İşlemi' : 'Normal İşlem',
      tag: 'Yemek',
      amount: 150.0,
      date: testDate,
      type: TransactionTypeModel.expense,
      isSystem: isSystem,
    );
  }

  testWidgets('renders TransactionCard with correct details',
      (WidgetTester tester) async {
    final tx = createTx(isSystem: false, id: 'tx_123');
    final item = TransactionWithBalance(transaction: tx, balanceAfter: 850.0);

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          testDate: [tx]
        },
        allTransactions: [tx],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) => TransactionCard(
            context: context,
            item: item,
            isListView: true,
          ),
        ),
      ),
    );

    expect(find.text('Normal İşlem'), findsOneWidget);
    expect(find.text('-150,00 ₺'), findsOneWidget);
    expect(find.text('Yemek'), findsOneWidget);
  });

  testWidgets(
      'tapping TransactionCard navigates to SingleTransactionDetailPage',
      (WidgetTester tester) async {
    final tx = createTx(isSystem: false, id: 'tx_123');
    final item = TransactionWithBalance(transaction: tx, balanceAfter: 850.0);

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          testDate: [tx]
        },
        allTransactions: [tx],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) => TransactionCard(
            context: context,
            item: item,
            isListView: true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Normal İşlem'));
    await tester.pumpAndSettle();

    expect(find.byType(SingleTransactionDetailPage), findsOneWidget);
  });

  testWidgets(
      'long press system transaction shows read-only notice instead of edit/delete',
      (WidgetTester tester) async {
    final tx = createTx(isSystem: true, id: 'tx_123');
    final item = TransactionWithBalance(transaction: tx, balanceAfter: 850.0);

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          testDate: [tx]
        },
        allTransactions: [tx],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) => TransactionCard(
            context: context,
            item: item,
            isListView: true,
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Sistem İşlemi'));
    await tester.pumpAndSettle();

    // Düzenle/Sil dokunulabilir satırları hiç render edilmemeli (proaktif
    // kilit — kullanıcı yanlışlıkla "işe yarayacak" bir eylem denemesin).
    expect(find.text('Düzenle'), findsNothing);
    expect(find.text('İşlemi Sil'), findsNothing);

    // Bunun yerine detay sayfasındakiyle aynı bilgi notu görünmeli.
    expect(
      find.textContaining('Bu işlem otomatik oluşturuldu'),
      findsOneWidget,
    );

    // Sheet'te dokunulacak bir aksiyon olmadığından hiçbir bloc event'i
    // tetiklenmemeli.
    verifyNever(() => mockTransactionBloc.add(any()));
  });

  testWidgets('long press edit non-system transaction opens edit sheet',
      (WidgetTester tester) async {
    final tx = createTx(isSystem: false, id: 'tx_123');
    final item = TransactionWithBalance(transaction: tx, balanceAfter: 850.0);

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          testDate: [tx]
        },
        allTransactions: [tx],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) => TransactionCard(
            context: context,
            item: item,
            isListView: true,
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Normal İşlem'));
    await tester.pumpAndSettle();

    // Tap Düzenle
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();

    // Verify edit sheet is shown (has "Güncelle" button)
    expect(find.text('Güncelle'), findsOneWidget);
  });

  testWidgets(
      'long press delete dispatches immediately, no confirmation dialog',
      (WidgetTester tester) async {
    final tx = createTx(isSystem: false, id: 'tx_123');
    final item = TransactionWithBalance(transaction: tx, balanceAfter: 850.0);

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          testDate: [tx]
        },
        allTransactions: [tx],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) => TransactionCard(
            context: context,
            item: item,
            isListView: true,
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Normal İşlem'));
    await tester.pumpAndSettle();

    // Tap İşlemi Sil
    await tester.tap(find.text('İşlemi Sil'));
    await tester.pumpAndSettle();

    // Onay diyaloğu YOK: koruma modal değil, 6 saniyelik "Geri al" penceresi
    // (bkz. showDeletionMessage).
    expect(find.text('İptal'), findsNothing);
    verify(() =>
            mockTransactionBloc.add(const DeleteTransactionEvent('tx_123')))
        .called(1);
  });

  testWidgets(
      'long press delete non-system transaction dispatches DeleteTransactionEvent',
      (WidgetTester tester) async {
    final tx = createTx(isSystem: false, id: 'tx_123');
    final item = TransactionWithBalance(transaction: tx, balanceAfter: 850.0);

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          testDate: [tx]
        },
        allTransactions: [tx],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) => TransactionCard(
            context: context,
            item: item,
            isListView: true,
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Normal İşlem'));
    await tester.pumpAndSettle();

    // Tap İşlemi Sil
    await tester.tap(find.text('İşlemi Sil'));
    await tester.pumpAndSettle();

    // Verify DeleteTransactionEvent was dispatched
    verify(() =>
            mockTransactionBloc.add(const DeleteTransactionEvent('tx_123')))
        .called(1);
  });
}
