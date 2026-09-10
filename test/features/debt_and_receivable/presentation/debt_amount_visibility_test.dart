import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/pages/debt_and_receivable_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:unified_flutter_features/amount_visibility.dart';

/// Uygulama çubuğundaki göz düğmesi borç/alacak bölümünde HİÇ çalışmıyordu.
///
/// Düğme oradaydı (borç sayfası kabuğun `thirdView`'ı, üstünde `ModernAppbar`
/// duruyor) ve cubit yayın yapıyordu — ama modül dinlemiyordu: modüldeki 27
/// tutar noktasının tamamı `formatMoney`'yi doğrudan çağırıp düz `Text`'e
/// basıyordu. `formatMoney` görünürlükten habersiz saf bir biçimleyicidir.
/// Aynı hata daha önce rapor ve birikim modüllerinde de çıkmıştı; bu dosya
/// borç tarafında sabitler.
class _FixedVisibilityCubit extends Cubit<bool>
    implements AmountVisibilityCubit {
  _FixedVisibilityCubit(super.initialState);

  @override
  Future<void> setVisibility(bool isVisible) async => emit(isVisible);

  @override
  Future<void> toggleVisibility() async => emit(!state);
}

class MockDebtBloc extends MockBloc<DebtEvent, DebtState> implements DebtBloc {}

class MockReceivableBloc extends MockBloc<ReceivableEvent, ReceivableState>
    implements ReceivableBloc {}

class MockOnboardingCoordinator extends Mock implements OnboardingCoordinator {}

void main() {
  late MockDebtBloc mockDebtBloc;
  late MockReceivableBloc mockReceivableBloc;
  late MockOnboardingCoordinator mockOnboarding;

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
    mockOnboarding = MockOnboardingCoordinator();
    getIt.registerSingleton<OnboardingCoordinator>(mockOnboarding);
    when(() => mockOnboarding.isSeen(any())).thenReturn(true);
  });

  tearDown(getIt.reset);

  final debt = DebtEntity(
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

  final receivable = ReceivableEntity(
    id: 'rec_1',
    userId: 'user_1',
    walletId: 'wallet_1',
    debtorName: 'Ahmet Yılmaz',
    amount: 500.0,
    dueDate: DateTime(2026, 6, 10),
    createdAt: DateTime(2026, 1, 1),
  );

  Widget host({required bool visible}) {
    return BlocProvider<AmountVisibilityCubit>(
      create: (_) => _FixedVisibilityCubit(visible),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<DebtBloc>.value(value: mockDebtBloc),
          BlocProvider<ReceivableBloc>.value(value: mockReceivableBloc),
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
          home: const DebtAndReceivablePage(
            userId: 'user_1',
            walletId: 'wallet_1',
            walletCurrency: 'TRY',
          ),
        ),
      ),
    );
  }

  testWidgets('gizliyken borç kartının tutarı maskelenir', (tester) async {
    when(() => mockDebtBloc.state).thenReturn(DebtLoaded([debt]));
    when(() => mockReceivableBloc.state).thenReturn(const ReceivableLoaded([]));

    await tester.pumpWidget(host(visible: false));
    await tester.pumpAndSettle();

    // Kartın en görünür rakamı 20pt: gizlenmezse "tutarları gizle" bu ekranda
    // hiçbir işe yaramıyor.
    expect(find.text('1.200,00 ₺'), findsNothing);
    expect(find.text('**** ₺'), findsWidgets);
    // Başlık maskelenmez; gizlenen yalnız PARA.
    expect(find.text('Araba Kredisi'), findsOneWidget);
  });

  testWidgets('açıkken borç kartı gerçek tutarı gösterir', (tester) async {
    when(() => mockDebtBloc.state).thenReturn(DebtLoaded([debt]));
    when(() => mockReceivableBloc.state).thenReturn(const ReceivableLoaded([]));

    await tester.pumpWidget(host(visible: true));
    await tester.pumpAndSettle();

    expect(find.text('1.200,00 ₺'), findsOneWidget);
    expect(find.text('**** ₺'), findsNothing);
  });

  testWidgets('gizliyken alacak kartının tutarı da maskelenir', (tester) async {
    when(() => mockDebtBloc.state).thenReturn(const DebtLoaded([]));
    when(() => mockReceivableBloc.state)
        .thenReturn(ReceivableLoaded([receivable]));

    await tester.pumpWidget(host(visible: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alacaklarım'));
    await tester.pumpAndSettle();

    expect(find.text('500,00 ₺'), findsNothing);
    expect(find.text('**** ₺'), findsWidgets);
    expect(find.text('Ahmet Yılmaz'), findsOneWidget);
  });

  testWidgets(
      'gizliyken ödeme diyaloğunun özeti ve taksit planı da maskelenir',
      (tester) async {
    when(() => mockDebtBloc.state).thenReturn(DebtLoaded([debt]));
    when(() => mockReceivableBloc.state).thenReturn(const ReceivableLoaded([]));

    await tester.pumpWidget(host(visible: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Öde'));
    await tester.pumpAndSettle();

    // Diyalogdaki 17 tutar tek bir `_money` kısayolundan geçiyor; o kısayol
    // maskesiz kaldığı sürece ekranın tamamı açıkta kalıyordu.
    expect(find.textContaining('**** ₺'), findsWidgets);

    // Açıkta kalan TEK tutar, girdi sınırını söyleyen yardım metni olmalı
    // ("Maksimum: 1.200,00 ₺") — bilinçli istisna, aşağıdaki testte ayrıca
    // sabitleniyor. Özet kartı ve taksit planı ondan geçmez.
    final visibleAmounts = tester
        .widgetList<Text>(find.textContaining('1.200,00 ₺'))
        .map((t) => t.data!)
        .toList();
    expect(visibleAmounts, hasLength(1));
    expect(visibleAmounts.single, startsWith('Maksimum'));
  });

  testWidgets(
      'ödeme alanının SINIR metni bilerek maskelenmez — form kullanılabilir '
      'kalmalı', (tester) async {
    when(() => mockDebtBloc.state).thenReturn(DebtLoaded([debt]));
    when(() => mockReceivableBloc.state).thenReturn(const ReceivableLoaded([]));

    await tester.pumpWidget(host(visible: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Öde'));
    await tester.pumpAndSettle();

    // "En fazla **** ₺" yazan bir yardım metni kullanıcıya ne girebileceğini
    // söylemez. Aynı karar birikim modülündeki sheet'lerde de verilmişti.
    final helper = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where((t) => t.contains('1.200,00 ₺'));
    expect(helper, isNotEmpty,
        reason: 'girdi sınırını söyleyen yardım metni okunabilir kalmalı');
  });
}
