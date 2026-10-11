import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/shared/widgets/row_action_sheet.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/pages/debt_and_receivable_page.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry_sheet.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/debt_payment_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:unified_flutter_features/amount_visibility.dart';

class MockDebtBloc extends MockBloc<DebtEvent, DebtState> implements DebtBloc {}

class MockReceivableBloc extends MockBloc<ReceivableEvent, ReceivableState>
    implements ReceivableBloc {}

class MockOnboardingCoordinator extends Mock implements OnboardingCoordinator {}

/// Görünürlük cubit'i gerçek uygulamada `AppProviders` ile MaterialApp'in
/// ÜSTÜNDE duruyor. `MoneyText` onu ZORUNLU kılar (`context.amountsVisible`
/// gibi sessizce true'ya düşmez), bu yüzden test kabuğu da sağlamalı.
/// Gizleme senaryoları ayrı dosyada: debt_amount_visibility_test.dart.
class _FixedVisibilityCubit extends Cubit<bool>
    implements AmountVisibilityCubit {
  _FixedVisibilityCubit(super.initialState);

  @override
  Future<void> setVisibility(bool isVisible) async => emit(isVisible);

  @override
  Future<void> toggleVisibility() async => emit(!state);
}

/// Borç/alacak sayfası artık HER para biriminde açılır: tutarlar cüzdanın
/// kendi birimindedir (kayıtta ayrı birim alanı yok, birim cüzdandan gelir).
void main() {
  late MockDebtBloc mockDebtBloc;
  late MockReceivableBloc mockReceivableBloc;
  late MockOnboardingCoordinator mockOnboardingCoordinator;

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(GetDebtsEvent('wallet_1'));
    registerFallbackValue(GetReceivablesEvent('wallet_1'));
    registerFallbackValue(OnboardingFlow.shell);
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
  });

  setUp(() {
    // Para metinleri locale'e bağlı (bkz. money_format.dart).
    Intl.defaultLocale = 'tr_TR';
    mockDebtBloc = MockDebtBloc();
    mockReceivableBloc = MockReceivableBloc();
    mockOnboardingCoordinator = MockOnboardingCoordinator();
    getIt.registerSingleton<OnboardingCoordinator>(mockOnboardingCoordinator);
    when(() => mockOnboardingCoordinator.isSeen(any())).thenReturn(true);
  });

  tearDown(() {
    getIt.reset();
  });

  final activeDebt = DebtEntity(
    calcMode: DebtCalcMode.none,
    expectedTotalAmount: 1200.0,
    id: 'debt_1',
    userId: 'user_1',
    walletId: 'wallet_1',
    title: 'Araba Kredisi',
    counterparty: 'Ziraat Bankası',
    type: DebtType.bankLoan,
    principalAmount: 1200.0,
    interestRate: 0.0,
    termMonths: 12,
    startDate: DateTime(2026, 1, 1),
    dueDate: DateTime(2026, 12, 1),
  );

  final activeReceivable = ReceivableEntity(
    id: 'rec_1',
    userId: 'user_1',
    walletId: 'wallet_1',
    debtorName: 'Ahmet Yılmaz',
    amount: 500.0,
    dueDate: DateTime(2026, 6, 10),
    createdAt: DateTime(2026, 1, 1),
  );

  /// Bloc'lar MaterialApp'in ÜSTÜNDE sağlanır: ödeme diyaloğu kök
  /// Navigator'da açılır (bkz. `AppProviders`).
  Widget buildTestableWidget({required String currency}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DebtBloc>.value(value: mockDebtBloc),
        BlocProvider<ReceivableBloc>.value(value: mockReceivableBloc),
        BlocProvider<AmountVisibilityCubit>(
          create: (_) => _FixedVisibilityCubit(true),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: DebtAndReceivablePage(
          userId: 'user_1',
          walletId: 'wallet_1',
          walletCurrency: currency,
        ),
      ),
    );
  }

  testWidgets('döviz cüzdanda liste açılır, TL kısıtı görünmez',
      (tester) async {
    when(() => mockDebtBloc.state).thenReturn(DebtLoaded([activeDebt]));
    when(() => mockReceivableBloc.state).thenReturn(const ReceivableLoaded([]));

    await tester.pumpWidget(buildTestableWidget(currency: 'USD'));
    await tester.pumpAndSettle();

    // Eski davranışta burada bir "yalnız TL" bilgilendirmesi vardı ve liste
    // hiç kurulmazdı.
    expect(find.text('Araba Kredisi'), findsOneWidget);
    expect(find.text('1.200,00 \$'), findsOneWidget);
    expect(find.textContaining('₺'), findsNothing);
  });

  testWidgets('alacak sekmesi de cüzdanın biriminde yazar', (tester) async {
    when(() => mockDebtBloc.state).thenReturn(const DebtLoaded([]));
    when(() => mockReceivableBloc.state)
        .thenReturn(ReceivableLoaded([activeReceivable]));

    await tester.pumpWidget(buildTestableWidget(currency: 'EUR'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alacaklarım'));
    await tester.pumpAndSettle();

    expect(find.text('Ahmet Yılmaz'), findsOneWidget);
    expect(find.text('500,00 €'), findsOneWidget);
    expect(find.textContaining('₺'), findsNothing);
  });

  testWidgets('ödeme diyaloğu cüzdanın birimiyle açılır', (tester) async {
    when(() => mockDebtBloc.state).thenReturn(DebtLoaded([activeDebt]));
    when(() => mockReceivableBloc.state).thenReturn(const ReceivableLoaded([]));

    await tester.pumpWidget(buildTestableWidget(currency: 'USD'));
    await tester.pumpAndSettle();

    // Kart üzerindeki "Öde" düğmesi → DebtPaymentDialog.
    await tester.tap(find.text('Öde'));
    await tester.pumpAndSettle();

    // Diyalogdaki toplam/kalan satırları da $ ile: birim zincir boyunca akıyor.
    expect(find.text('1.200,00 \$'), findsWidgets);
    expect(find.textContaining('₺'), findsNothing);
  });

  group('kart eylemleri ortak eylem sayfasında', () {
    testWidgets('borç kartına dokun → Ödeme Yap · Düzenle · Sil',
        (tester) async {
      when(() => mockDebtBloc.state).thenReturn(DebtLoaded([activeDebt]));
      when(() => mockReceivableBloc.state)
          .thenReturn(const ReceivableLoaded([]));

      await tester.pumpWidget(buildTestableWidget(currency: 'TRY'));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));

      await tester.tap(find.text('Araba Kredisi'));
      await tester.pumpAndSettle();

      // Eskiden burada kartın üstüne açılan bir menü vardı; artık işlem ve
      // birikim satırlarıyla AYNI sayfa: başlıkta kaydın adı ve kurumu.
      expect(find.byType(RowActionSheet<String>), findsOneWidget);
      expect(find.byType(PopupMenuItem<String>), findsNothing);
      expect(find.text('Araba Kredisi'), findsNWidgets(2));
      expect(find.text('Ziraat Bankası'), findsNWidgets(2));
      expect(find.text(l10n.odemeYap), findsOneWidget);
      expect(find.byKey(const ValueKey('row-action-edit')), findsOneWidget);
      expect(find.byKey(const ValueKey('row-action-delete')), findsOneWidget);
    });

    testWidgets('Sil → onay ister; onaylanınca borç silinir', (tester) async {
      when(() => mockDebtBloc.state).thenReturn(DebtLoaded([activeDebt]));
      when(() => mockReceivableBloc.state)
          .thenReturn(const ReceivableLoaded([]));

      await tester.pumpWidget(buildTestableWidget(currency: 'TRY'));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));

      await tester.tap(find.text('Araba Kredisi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('row-action-delete')));
      await tester.pumpAndSettle();

      expect(find.byType(RowActionSheet<String>), findsNothing);
      expect(find.text(l10n.borcSilBaslik), findsOneWidget);
      verifyNever(() => mockDebtBloc.add(any(that: isA<DeleteDebtEvent>())));

      await tester.tap(find.text(l10n.sil));
      await tester.pumpAndSettle();
      verify(() => mockDebtBloc.add(any(that: isA<DeleteDebtEvent>())))
          .called(1);
    });

    testWidgets('Ödeme Yap → ödeme diyaloğu açılır', (tester) async {
      when(() => mockDebtBloc.state).thenReturn(DebtLoaded([activeDebt]));
      when(() => mockReceivableBloc.state)
          .thenReturn(const ReceivableLoaded([]));

      await tester.pumpWidget(buildTestableWidget(currency: 'TRY'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Araba Kredisi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('row-action-payment')));
      await tester.pumpAndSettle();

      expect(find.byType(DebtPaymentDialog), findsOneWidget);
    });

    testWidgets('alacak kartı → Ödendi İşaretle olayı gönderir',
        (tester) async {
      when(() => mockDebtBloc.state).thenReturn(const DebtLoaded([]));
      when(() => mockReceivableBloc.state)
          .thenReturn(ReceivableLoaded([activeReceivable]));

      await tester.pumpWidget(buildTestableWidget(currency: 'TRY'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alacaklarım'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ahmet Yılmaz'));
      await tester.pumpAndSettle();
      expect(find.byType(RowActionSheet<String>), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('row-action-mark_paid')));
      await tester.pumpAndSettle();
      verify(() => mockReceivableBloc
          .add(any(that: isA<MarkReceivableAsPaidEvent>()))).called(1);
    });
  });

  group('boş ekrandan doğrudan ekleme', () {
    // Cihazda görüldü: boş ekran yalnız "ekleme butonunu kullanın" diyordu;
    // buton alttaki kaydırıcının "+"sı, ardından bir mini düğmeydi.
    testWidgets('borç yokken "Borç ekle" yeni borç formunu açar',
        (tester) async {
      when(() => mockDebtBloc.state).thenReturn(const DebtLoaded([]));
      when(() => mockReceivableBloc.state)
          .thenReturn(const ReceivableLoaded([]));
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestableWidget(currency: 'TRY'));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));

      await tester.tap(find.byKey(const ValueKey('debt-empty-add')));
      await tester.pumpAndSettle();

      expect(find.byType(AddEntrySheet), findsOneWidget);
      expect(find.text(l10n.yeniBorcTitle), findsOneWidget);
    });

    testWidgets('alacak yokken "Alacak ekle" yeni alacak formunu açar',
        (tester) async {
      when(() => mockDebtBloc.state).thenReturn(const DebtLoaded([]));
      when(() => mockReceivableBloc.state)
          .thenReturn(const ReceivableLoaded([]));
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestableWidget(currency: 'TRY'));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      await tester.tap(find.text('Alacaklarım'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('receivable-empty-add')));
      await tester.pumpAndSettle();

      expect(find.byType(AddEntrySheet), findsOneWidget);
      expect(find.text(l10n.yeniAlacakTitle), findsOneWidget);
    });

    testWidgets('kayıt varken boş ekran düğmesi yok', (tester) async {
      when(() => mockDebtBloc.state).thenReturn(DebtLoaded([activeDebt]));
      when(() => mockReceivableBloc.state)
          .thenReturn(const ReceivableLoaded([]));

      await tester.pumpWidget(buildTestableWidget(currency: 'TRY'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('debt-empty-add')), findsNothing);
    });
  });

  testWidgets('TL cüzdanda gösterim değişmez', (tester) async {
    when(() => mockDebtBloc.state).thenReturn(DebtLoaded([activeDebt]));
    when(() => mockReceivableBloc.state).thenReturn(const ReceivableLoaded([]));

    await tester.pumpWidget(buildTestableWidget(currency: 'TRY'));
    await tester.pumpAndSettle();

    expect(find.text('1.200,00 ₺'), findsOneWidget);
  });
}
