import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/entities/live_price_quote.dart';
import 'package:cunehat/features/investments/domain/usecases/get_live_quote_usecase.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_gold_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/contribute_sheet.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:intl/intl.dart';

class MockGetLiveQuoteUseCase extends Mock implements GetLiveQuoteUseCase {}

class _MockOnboardingCoordinator extends Mock
    implements OnboardingCoordinator {}

void main() {
  setUpAll(() {
    Intl.defaultLocale = 'tr';
    getIt.allowReassignment = true;
    registerFallbackValue(OnboardingFlow.shell);
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
  });

  late MockGetLiveQuoteUseCase quote;

  setUp(() {
    final coordinator = _MockOnboardingCoordinator();
    when(() => coordinator.isSeen(any())).thenReturn(true);
    getIt.registerSingleton<OnboardingCoordinator>(coordinator);
    quote = MockGetLiveQuoteUseCase();
    getIt.registerSingleton<GetLiveQuoteUseCase>(quote);
  });

  tearDown(() => getIt.reset());

  Widget app(Widget child) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: Scaffold(body: child),
      );

  void dump(WidgetTester tester, String tag) {
    debugPrint('--- $tag ---');
    for (final t in find.byType(Text).evaluate()) {
      final w = t.widget as Text;
      if (w.data != null) debugPrint('TEXT "${w.data}" -> ${t.size}');
    }
    debugPrint('EXC[$tag]: ${tester.takeException()}');
  }

  testWidgets('ekleme formu 360dp', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => quote(
        symbol: 'gram-altin',
        type: InvestmentType.gold,
        targetCurrency: 'TRY')).thenAnswer((_) async => const Right(
        LivePriceQuote(
            price: 4399.35,
            currency: 'TRY',
            convertedPrice: 4399.35,
            targetCurrency: 'TRY')));

    await tester.pumpWidget(app(AddGoldSheet(
      walletId: 'w',
      userId: 'u',
      walletCurrency: 'TRY',
      onSave: (_) {},
    )));
    await tester.pumpAndSettle();

    final qty = find.byWidgetPredicate((w) =>
        w is TextField && w.decoration?.hintText == 'Gram Altın');
    await tester.enterText(qty, '224,5');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();
    dump(tester, 'ADD-TRY');
  });

  testWidgets('katkı (Varlık Ekle) 360dp — döviz cüzdan', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => quote(
        symbol: 'gram-altin',
        type: InvestmentType.gold,
        targetCurrency: 'USD')).thenAnswer((_) async => const Right(
        LivePriceQuote(
            price: 4399.35,
            currency: 'TRY',
            convertedPrice: 129.45,
            targetCurrency: 'USD')));

    final inv = InvestmentEntity(
      id: 'i',
      userId: 'u',
      walletId: 'w',
      name: 'Düğün Altınları',
      amount: 900000,
      currentValue: 987654.32,
      type: InvestmentType.gold,
      color: Colors.amber,
      dateAdded: DateTime(2026, 1, 1),
      symbol: 'gram-altin',
      quantity: 224.5,
    );

    await tester.pumpWidget(app(ContributeSheet(
      investment: inv,
      walletCurrency: 'USD',
      onSave: (_) {},
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Güncel Fiyatı Getir'));
    await tester.pumpAndSettle();
    dump(tester, 'CONTRIB-USD');
  });
}
