import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/page/wallet_managment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

class _MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

class _MockRates extends Mock implements ExchangeRateService {}

class _MockOnboarding extends Mock implements OnboardingCoordinator {}

WalletEntity _wallet(
  String id,
  String name, {
  double balance = 1000,
  double investment = 0,
  String color = '0xFF2196F3',
}) =>
    WalletEntity(
      id: id,
      userId: 'u',
      name: name,
      balance: balance,
      debt: 0,
      credit: 0,
      investment: investment,
      colorHex: color,
      iconName: 'wallet',
      createdAt: DateTime(2025, 1, 1),
      openingBalance: balance,
    );

/// Cüzdan destesi (UX Tur 3b).
///
/// ÖNCE (cihazda ölçüldü, 411×914): sayfa %60 açılıyor, cüzdan kutuları
/// ~250dp → ekranda TEK cüzdan, o da "Düzenle" düğmesinde kesik. Kutuya
/// dokunmak cüzdanı seçiyor ama sayfayı kapatmıyordu.
void main() {
  late _MockWalletBloc bloc;

  setUpAll(() {
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
    registerFallbackValue(OnboardingFlow.walletManagement);
    registerFallbackValue(
        const SetActiveWalletEvent(userId: 'u', walletId: 'x'));
  });

  setUp(() {
    Intl.defaultLocale = 'tr_TR';
    SharedPreferences.setMockInitialValues({});
    bloc = _MockWalletBloc();

    final rates = _MockRates();
    when(() => rates.rateToTry(any())).thenAnswer((_) async => null);
    when(() => rates.cachedRateToTry(any())).thenReturn(1.0);
    getIt.registerSingleton<ExchangeRateService>(rates);

    final onboarding = _MockOnboarding();
    when(() => onboarding.isSeen(any())).thenReturn(true);
    getIt.registerSingleton<OnboardingCoordinator>(onboarding);
  });

  tearDown(() async => getIt.reset());

  /// Uygulamadaki gibi: sayfa ekranın %60'ında, alt sayfa olarak açılır.
  Future<void> openSheet(
    WidgetTester tester, {
    Size screen = const Size(360, 800),
    bool createOnOpen = false,
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<WalletBloc>.value(value: bloc),
          BlocProvider<AmountVisibilityCubit>(
              create: (_) => AmountVisibilityCubit()),
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
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => SizedBox(
                      height: screen.height * 0.6,
                      child: WalletSheetContent(
                        userId: 'u',
                        scrollController: scroll,
                        createOnOpen: createOnOpen,
                      ),
                    ),
                  ),
                  child: const Text('aç'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
  }

  final deck = find.byKey(const ValueKey('wallet-deck'));
  Finder card(String id) => find.byKey(ValueKey('wallet-deck-card-$id'));

  List<SetActiveWalletEvent> selections() =>
      verify(() => bloc.add(captureAny()))
          .captured
          .whereType<SetActiveWalletEvent>()
          .toList();

  final cash = _wallet('a', 'Nakit');
  final bank = _wallet('b', 'Banka', balance: 5000, investment: 250);
  final euro = _wallet('c', 'Euro', color: '0xFFFFEB3B');

  testWidgets(
      'açılışta etkin cüzdan ortada ve TAMAMI görünür; komşu kenardan '
      'görünür; eylemler kaydırmadan erişilir', (tester) async {
    when(() => bloc.state).thenReturn(WalletLoadedSt([cash, bank, euro], bank));
    await openSheet(tester);
    expect(tester.takeException(), isNull);

    const screen = Rect.fromLTWH(0, 0, 360, 800);
    final focused = tester.getRect(card('b'));
    debugPrint('ÖLÇÜM deste: odaktaki kart $focused');
    expect(focused.left, greaterThanOrEqualTo(0));
    expect(focused.right, lessThanOrEqualTo(360));
    expect(focused.bottom, lessThan(800));

    // İki komşu da ekranda bir şeritle görünüyor: "başka cüzdan var".
    final left = tester.getRect(card('a'));
    final right = tester.getRect(card('c'));
    expect(left.overlaps(screen), isTrue);
    expect(right.overlaps(screen), isTrue);
    expect(left.right, lessThan(focused.left + 1));
    expect(right.left, greaterThan(focused.right - 1));

    // Odaktaki cüzdanın eylemleri ve genel eylemler ilk bakışta ekranda.
    for (final key in const [
      'wallet-deck-select',
      'wallet-deck-edit',
      'wallet-sheet-transfer',
      'wallet-sheet-import',
      'wallet-sheet-create',
    ]) {
      final rect = tester.getRect(find.byKey(ValueKey(key)));
      expect(rect.bottom, lessThanOrEqualTo(800), reason: key);
      expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget,
          reason: key);
    }
    expect(find.byKey(const ValueKey('wallet-deck-dots')), findsOneWidget);
  });

  testWidgets('yana kaydırmak yalnız GEZER; hiçbir cüzdan seçilmez',
      (tester) async {
    when(() => bloc.state).thenReturn(WalletLoadedSt([cash, bank], cash));
    await openSheet(tester);

    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    expect(find.text(l10n.aktifCuzdan), findsOneWidget);

    await tester.fling(deck, const Offset(-250, 0), 1200);
    await tester.pumpAndSettle();

    verifyNever(() => bloc.add(any(that: isA<SetActiveWalletEvent>())));
    // Sayfa açık; eylem düğmesi artık odaktaki (etkin olmayan) cüzdan için.
    expect(find.text(l10n.cuzdanaGec), findsOneWidget);
    expect(find.text(l10n.aktifCuzdan), findsNothing);
  });

  testWidgets('ortadaki karta dokun → o cüzdana geçilir VE sayfa kapanır',
      (tester) async {
    when(() => bloc.state).thenReturn(WalletLoadedSt([cash, bank], cash));
    await openSheet(tester);

    await tester.fling(deck, const Offset(-250, 0), 1200);
    await tester.pumpAndSettle();
    await tester.tap(card('b'));
    await tester.pumpAndSettle();

    final sent = selections().single;
    expect(sent.walletId, 'b');
    expect(sent.announce, isFalse);
    expect(find.byType(WalletSheetContent), findsNothing);
  });

  testWidgets('"Bu cüzdana geç" düğmesi de aynı işi yapar', (tester) async {
    when(() => bloc.state).thenReturn(WalletLoadedSt([cash, bank], cash));
    await openSheet(tester);

    await tester.fling(deck, const Offset(-250, 0), 1200);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('wallet-deck-select')));
    await tester.pumpAndSettle();

    expect(selections().single.walletId, 'b');
    expect(find.byType(WalletSheetContent), findsNothing);
  });

  testWidgets('etkin cüzdanın kartına dokunmak yalnız sayfayı kapatır',
      (tester) async {
    when(() => bloc.state).thenReturn(WalletLoadedSt([cash, bank], cash));
    await openSheet(tester);

    await tester.tap(card('a'));
    await tester.pumpAndSettle();

    verifyNever(() => bloc.add(any(that: isA<SetActiveWalletEvent>())));
    expect(find.byType(WalletSheetContent), findsNothing);
  });

  testWidgets('kenardaki komşuya dokunmak onu ortaya getirir, seçmez',
      (tester) async {
    when(() => bloc.state).thenReturn(WalletLoadedSt([cash, bank], cash));
    await openSheet(tester);

    // Komşunun ekranda görünen şeridine dokun.
    final neighbour = tester.getRect(card('b'));
    await tester.tapAt(Offset(356, neighbour.center.dy));
    await tester.pumpAndSettle();

    verifyNever(() => bloc.add(any(that: isA<SetActiveWalletEvent>())));
    expect(find.byType(WalletSheetContent), findsOneWidget);
    final centered = tester.getRect(card('b'));
    expect(centered.center.dx, closeTo(180, 1));
  });

  testWidgets('etkin cüzdan silinemez ve NEDENİ menüde yazar', (tester) async {
    when(() => bloc.state).thenReturn(WalletLoadedSt([cash, bank], cash));
    await openSheet(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));

    await tester.tap(find.byKey(const ValueKey('wallet-deck-more')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.aktifCuzdanSilinemez), findsOneWidget);
    await tester.tap(find.text(l10n.aktifCuzdanSilinemez));
    await tester.pumpAndSettle();
    verifyNever(() => bloc.add(any(that: isA<DeleteWalletEvent>())));
  });

  testWidgets('tek cüzdan: nokta yok, kart ortada', (tester) async {
    when(() => bloc.state).thenReturn(WalletLoadedSt([cash], cash));
    await openSheet(tester);

    expect(find.byKey(const ValueKey('wallet-deck-dots')), findsNothing);
    expect(tester.getRect(card('a')).center.dx, closeTo(180, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('turun iki hedefi de her durumda ağaçta', (tester) async {
    for (final state in <WalletState>[
      WalletLoadedSt([cash, bank], cash),
      NoWalletSt(),
    ]) {
      when(() => bloc.state).thenReturn(state);
      await openSheet(tester);
      final showcase = ShowcaseView.get();
      expect(showcase.isTargetRendered(OnboardingKeys.walletManagementHeader),
          isTrue);
      expect(
          showcase.isTargetRendered(OnboardingKeys.walletManagementAddButton),
          isTrue);
      await tester.pumpWidget(const SizedBox());
    }
  });

  // UX Tur 3c — ÖNCE: "İlk Cüzdanı Oluştur" BOŞ bir yönetim sayfası açıyor,
  // kullanıcı orada bir de "Yeni Cüzdan Oluştur"a basıyordu.
  testWidgets('ilk cüzdan: sayfa oluşturma formuyla birlikte açılır',
      (tester) async {
    when(() => bloc.state).thenReturn(NoWalletSt());
    await openSheet(tester, screen: const Size(800, 1400), createOnOpen: true);

    // Form (ad alanı) sayfanın üstünde açık.
    expect(find.byType(TextField), findsWidgets);
    expect(find.byType(WalletSheetContent), findsOneWidget);
  });

  testWidgets('olağan açılışta form kendiliğinden açılmaz', (tester) async {
    when(() => bloc.state).thenReturn(NoWalletSt());
    await openSheet(tester);

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('320dp genişlikte, üç cüzdanla taşma yok', (tester) async {
    when(() => bloc.state).thenReturn(WalletLoadedSt([cash, bank, euro], euro));
    await openSheet(tester, screen: const Size(320, 640));
    expect(tester.takeException(), isNull);
  });
}
