import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_fields.dart';
import 'package:cunehat/features/main_feature/utils/section_records.dart';
import 'package:cunehat/features/finance_transactions/presentation/utils/fresh_entry_marker.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/save_recurring_transaction_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_event.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

import '../../../../../support/real_font.dart';
import '../../../../../support/wallet_category_stub.dart';

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

/// Düzenli işlem seçilerek kaydedildiğinde sheet bekleyen listeyi tazeler
/// (TransactionEntrySheet: `context.read<PendingRecurringBloc>()`).
class MockPendingRecurringBloc
    extends MockBloc<PendingRecurringEvent, PendingRecurringState>
    implements PendingRecurringBloc {}

class _MockSectionRecords extends Mock implements SectionRecords {}

void main() {
  late MockPendingRecurringBloc mockPendingRecurringBloc;
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
    registerUncuratedWalletCategories(mockCategoryRepository);
    getIt.registerSingleton<SaveRecurringTransactionUsecase>(
        mockSaveRecurringTransactionUsecase);

    when(() => mockCategoryRepository.getAllCategories())
        .thenAnswer((_) async => [
              ...await mockCategoryRepository.getCategories(true),
              ...await mockCategoryRepository.getCategories(false),
            ]);
    when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Food',
          name: 'Food',
          iconName: 'fastfood',
          isExpense: true,
        ),
      ],
    );

    when(() => mockCategoryRepository.getCategories(false)).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Salary',
          name: 'Salary',
          iconName: 'work',
          isExpense: false,
        ),
      ],
    );

    when(() => mockSaveRecurringTransactionUsecase.call(any()))
        .thenAnswer((_) async => const Right(null));

    mockPendingRecurringBloc = MockPendingRecurringBloc();
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildTestableWidget(Widget child, {ThemeData? theme}) {
    return BlocProvider<AmountVisibilityCubit>(
      create: (_) => AmountVisibilityCubit(),
      child: MaterialApp(
        theme: theme,
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
          body: MultiBlocProvider(
            providers: [
              BlocProvider<TransactionBloc>.value(value: mockTransactionBloc),
              BlocProvider<PendingRecurringBloc>.value(
                  value: mockPendingRecurringBloc),
            ],
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets(
      'TransactionSheetHandler.showSheet opens sheet and closes on cancel',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => TransactionSheetHandler.showSheet(
                context: context,
                userId: 'user_123',
                walletId: 'wallet_123',
                type: TransactionTypeModel.expense,
              ),
              child: const Text('Open Form'),
            );
          },
        ),
      ),
    );

    // Click button to open
    await tester.tap(find.text('Open Form'));
    await tester.pumpAndSettle();

    // Verify it is open
    expect(find.text('Kaydet'), findsOneWidget);

    // Tap outside or close (let's tap close icon if exists, or drag down, or tap cancel)
    // Looking at transaction_form_fields.dart, there is a cancel button or back icon
    // Let's tap 'İptal' if it exists or use navigator pop
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Kaydet'), findsNothing);
  });

  testWidgets(
      'Submitting form for new transaction dispatches AddTransactionEvent',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => TransactionSheetHandler.showSheet(
                context: context,
                userId: 'user_123',
                walletId: 'wallet_123',
                type: TransactionTypeModel.expense,
              ),
              child: const Text('Open Form'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Form'));
    await tester.pumpAndSettle();

    // Enter note
    final noteTextField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText?.contains('Not') == true,
    );
    await tester.enterText(noteTextField, 'Burger King');

    // Enter amount
    final amountTextField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.keyboardType.decimal == true,
    );
    await tester.enterText(amountTextField, '250');
    await tester.pumpAndSettle();

    // Kategori zorunlu ve varsayılan seçili GELMEZ — kullanıcı seçmeli.
    await tester.ensureVisible(find.text('Food'));
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    // Tap save
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    // Verify AddTransactionEvent is dispatched
    verify(() => mockTransactionBloc.add(any(that: isA<AddTransactionEvent>())))
        .called(1);
    expect(find.text('Kaydet'), findsNothing); // Sheet is closed
  });

  group('"Kaydet ve yeni" kullandıkça gelir', () {
    Future<void> open(WidgetTester tester, {required int records}) async {
      final counter = _MockSectionRecords();
      when(() => counter.transactionCount).thenReturn(records);
      getIt.registerSingleton<SectionRecords>(counter);

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => TransactionSheetHandler.showSheet(
                context: context,
                userId: 'user_123',
                walletId: 'wallet_123',
                type: TransactionTypeModel.expense,
              ),
              child: const Text('Open Form'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Form'));
      await tester.pumpAndSettle();
    }

    testWidgets('ilk kayıtlarda formun dibinde TEK düğme var', (tester) async {
      await open(tester, records: 0);

      expect(find.text('Kaydet'), findsOneWidget);
      expect(find.text('Kaydet ve yeni'), findsNothing);
    });

    testWidgets('eşiğin hemen altında da yok', (tester) async {
      await open(tester, records: kSaveAndNewAfterRecords - 1);

      expect(find.text('Kaydet ve yeni'), findsNothing);
    });

    testWidgets('beş kayıttan sonra sunulur', (tester) async {
      await open(tester, records: kSaveAndNewAfterRecords);

      expect(find.text('Kaydet'), findsOneWidget);
      expect(find.text('Kaydet ve yeni'), findsOneWidget);
    });
  });

  testWidgets(
      'kayıt anı: titreşim verir ve yeni satırı listeye girişi için işaretler',
      (WidgetTester tester) async {
    FreshEntryMarker.instance.clear();
    addTearDown(FreshEntryMarker.instance.clear);
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => TransactionSheetHandler.showSheet(
              context: context,
              userId: 'user_123',
              walletId: 'wallet_123',
              type: TransactionTypeModel.expense,
            ),
            child: const Text('Open Form'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Form'));
    await tester.pumpAndSettle();

    // Doğrulama geçmeden hiçbir şey olmaz: tutar yok.
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(haptics, isEmpty);
    expect(FreshEntryMarker.instance.isEmpty, isTrue);

    final amountTextField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.keyboardType.decimal == true,
    );
    await tester.enterText(amountTextField, '250');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Food'));
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(haptics, ['HapticFeedbackType.lightImpact']);
    final event = verify(() => mockTransactionBloc.add(captureAny()))
        .captured
        .whereType<AddTransactionEvent>()
        .single;
    // Deftere düşen satır, formun bıraktığı imzayla eşleşir — bir kez.
    expect(FreshEntryMarker.instance.consume(event.transaction), isTrue);
    expect(FreshEntryMarker.instance.consume(event.transaction), isFalse);
  });

  testWidgets(
      'Submitting form for updating transaction dispatches UpdateTransactionEvent',
      (WidgetTester tester) async {
    final initialTx = TransactionEntity(
      id: 'tx_old',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'Old Burger',
      tag: 'Food',
      amount: 150.0,
      date: DateTime(2026, 6, 13),
      type: TransactionTypeModel.expense,
      isSystem: false,
    );

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => TransactionSheetHandler.showSheet(
                context: context,
                userId: 'user_123',
                walletId: 'wallet_123',
                type: TransactionTypeModel.expense,
                initialTransaction: initialTx,
              ),
              child: const Text('Open Form'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Form'));
    await tester.pumpAndSettle();

    // Note should have 'Old Burger' initially, let's change it
    final noteTextField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText?.contains('Not') == true,
    );
    await tester.enterText(noteTextField, 'New Burger');

    // Amount should have '150' initially, let's change it
    final amountTextField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.keyboardType.decimal == true,
    );
    await tester.enterText(amountTextField, '180');
    await tester.pumpAndSettle();

    // Tap save
    await tester.tap(find.text('Güncelle'));
    await tester.pumpAndSettle();

    // Verify UpdateTransactionEvent is dispatched
    verify(() =>
            mockTransactionBloc.add(any(that: isA<UpdateTransactionEvent>())))
        .called(1);
    expect(find.text('Kaydet'), findsNothing); // Sheet is closed
  });

  testWidgets(
      'Submitting form with recurring frequency dispatches AddTransactionEvent and calls SaveRecurringTransactionUsecase',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => TransactionSheetHandler.showSheet(
                context: context,
                userId: 'user_123',
                walletId: 'wallet_123',
                type: TransactionTypeModel.expense,
              ),
              child: const Text('Open Form'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Form'));
    await tester.pumpAndSettle();

    // Enter note
    final noteTextField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText?.contains('Not') == true,
    );
    await tester.enterText(noteTextField, 'Monthly Rent');

    // Enter amount
    final amountTextField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.keyboardType.decimal == true,
    );
    await tester.enterText(amountTextField, '5000');
    await tester.pumpAndSettle();

    // Kategori zorunlu ve varsayılan seçili GELMEZ — kullanıcı seçmeli.
    await tester.ensureVisible(find.text('Food'));
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    // Open recurring frequency dropdown
    // Finding the dropdown
    final dropdownFinder = find.byType(DropdownButton<RecurringFrequency?>);
    // Form kaydırılabilir; görünür alana alınmazsa tap ıskalıyor ve menü
    // hiç açılmadığından 'Aylık' araması boş listede patlıyordu.
    await tester.ensureVisible(dropdownFinder);
    await tester.pumpAndSettle();
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    // Tap the 'Aylık' option from the dropdown menu
    await tester.tap(find.text('Aylık').last);
    await tester.pumpAndSettle();

    // Tap save
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    // Verify AddTransactionEvent is dispatched
    verify(() => mockTransactionBloc.add(any(that: isA<AddTransactionEvent>())))
        .called(1);

    // Verify SaveRecurringTransactionUsecase is called
    verify(() => mockSaveRecurringTransactionUsecase.call(any())).called(1);
    expect(find.text('Kaydet'), findsNothing); // Sheet is closed
  });

  // Form eskiden ilk açılışta üç adımlı bir tanıtım oynatıyordu; yeni
  // kullanıcı tutarı yazmadan önce üç baloncuğu kapatmak zorundaydı ve o
  // yüzden klavye de açılmıyordu.
  testWidgets('formda tanıtım yok: açılır açılmaz tutar yazılabilir',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => TransactionSheetHandler.showSheet(
                context: context,
                userId: 'user_123',
                walletId: 'wallet_123',
                type: TransactionTypeModel.expense,
              ),
              child: const Text('Open Form'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Open Form'));
    await tester.pumpAndSettle();

    expect(find.byType(Showcase), findsNothing);
    // Odak tutarda: klavye açık.
    expect(tester.testTextInput.isVisible, isTrue);
    // Tekrar sıklığının ne işe yaradığı satırın altında yazar.
    expect(
      find.textContaining('Kira, maaş, abonelik gibi düzenli işlemler'),
      findsOneWidget,
    );
  });
  // Büyük yazı: "herkes kullanabilsin" ölçütünün bir parçası. Sistem yazı
  // boyutu 1,3 ve 2,0'a çekilmiş telefonda form taşmamalı ve Kaydet, klavye
  // açıkken de ekranda kalmalı.
  group('büyük yazı (360×800)', () {
    // Varsayılan test fontu gerçek Roboto'dan belirgin biçimde geniştir ve
    // var olmayan taşmalar raporlar; ölçüm uygulamanın temasıyla yapılır.
    setUpAll(loadRealRoboto);

    /// Taşan widget'ın kaynak satırını da taşıyan özet.
    String describe(List<FlutterErrorDetails> errors) => [
          for (final e in errors)
            '${e.exception.toString().split('\n').first} @ '
                '${e.informationCollector?.call().map((n) => n.toString()).firstWhere((l) => l.contains('.dart:'), orElse: () => '?') ?? '?'}',
        ].join('\n');

    Future<List<FlutterErrorDetails>> openForm(
      WidgetTester tester, {
      required double textScale,
      double keyboard = 0,
    }) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      try {
        final appTheme = ThemeNames.all[ThemeNames.sysLight]!;
        await tester.pumpWidget(
          buildTestableWidget(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TransactionSheetHandler.showSheet(
                  context: context,
                  userId: 'user_123',
                  walletId: 'wallet_123',
                  type: TransactionTypeModel.expense,
                ),
                child: const Text('Open Form'),
              ),
            ),
            theme: appTheme.copyWith(
              textTheme: appTheme.textTheme.apply(fontFamily: kRealFontFamily),
            ),
          ),
        );
        await tester.tap(find.text('Open Form'));
        await tester.pumpAndSettle();
      } finally {
        FlutterError.onError = previous;
      }
      return errors;
    }

    for (final scale in const [1.0, 1.3, 2.0]) {
      testWidgets('yazı ölçeği $scale: form taşmaz', (tester) async {
        final errors = await openForm(tester, textScale: scale);

        expect(errors, isEmpty, reason: describe(errors));
      });

      testWidgets('yazı ölçeği $scale, klavye açık: Kaydet klavyenin üstünde',
          (tester) async {
        const keyboard = 320.0;
        final errors =
            await openForm(tester, textScale: scale, keyboard: keyboard);

        expect(errors, isEmpty, reason: describe(errors));
        final save = tester.getRect(find.text('Kaydet').last);
        expect(save.bottom, lessThanOrEqualTo(800 - keyboard));
        expect(save.top, greaterThanOrEqualTo(0));
      });
    }
  });
}
