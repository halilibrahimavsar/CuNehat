import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/features/main_feature/utils/wallet_carousel_hint_store.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/main_feature/widgets/app_bar_content.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:dartz/dartz.dart';
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

class _MockTxRepo extends Mock implements TransactionsRepository {}

WalletEntity _wallet(String id, String name, {double balance = 1000}) =>
    WalletEntity(
      id: id,
      userId: 'u',
      name: name,
      balance: balance,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '0xFF2196F3',
      iconName: 'wallet',
      createdAt: DateTime(2025, 1, 1),
      openingBalance: balance,
    );

WalletEntity _cardOf(String ownerId) => WalletEntity(
      id: 'card',
      userId: 'u',
      name: 'Bonus',
      balance: -3700,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '0xFF37474F',
      iconName: 'credit_card',
      createdAt: DateTime(2025, 1, 1),
      openingBalance: -3700,
      creditCard: CreditCardInfo(
        closingDay: 15,
        dueDay: 25,
        last4: '5690',
        limit: 40000,
        paymentWalletId: ownerId,
      ),
    );

/// Üst çubuk karuseli (UX Tur 3a).
///
/// ÖNCE: ekranda yalnız etkin cüzdan vardı. Başka cüzdana geçmek = başlığa
/// dokun → sayfa %60 açılır (≈1 cüzdan görünür) → aşağı kaydır → karta dokun →
/// sayfayı kapat: en az 4 etkileşim. ŞİMDİ: başlığı yana kaydır (1 jest).
class _MockCoordinator extends Mock implements OnboardingCoordinator {}

void main() {
  late _MockWalletBloc bloc;

  setUpAll(() {
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
    registerFallbackValue(
        const SetActiveWalletEvent(userId: 'u', walletId: 'x'));
    registerFallbackValue(OnboardingFlow.shell);
  });

  setUp(() {
    Intl.defaultLocale = 'tr_TR';
    SharedPreferences.setMockInitialValues({});
    bloc = _MockWalletBloc();
    final repo = _MockTxRepo();
    getIt.registerSingleton<TransactionsRepository>(repo);
    when(() => repo.getTransactions(
          userId: any(named: 'userId'),
          walletId: any(named: 'walletId'),
        )).thenAnswer((_) async => const Right(<TransactionEntity>[]));
  });

  tearDown(() async => getIt.reset());

  Future<void> pumpHeader(WidgetTester tester) async {
    // Telefon genişliği: 411dp'lik çubukta başlık alanı ≈ 300dp.
    tester.view.physicalSize = const Size(411, 300);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
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
          home: const Scaffold(
            backgroundColor: Colors.indigo,
            body: SizedBox(
              height: 70,
              child: AppBarContent(
                currentState: SliderState.transactions,
                scaleAnimation: AlwaysStoppedAnimation(1),
                fadeAnimation: AlwaysStoppedAnimation(1),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final carousel = find.byKey(const ValueKey('wallet-carousel'));
  final dots = find.byKey(const ValueKey('wallet-headline-dots'));

  Future<void> swipeLeft(WidgetTester tester) async {
    await tester.fling(carousel, const Offset(-250, 0), 1200);
    await tester.pumpAndSettle();
  }

  List<SetActiveWalletEvent> selections() =>
      verify(() => bloc.add(captureAny()))
          .captured
          .whereType<SetActiveWalletEvent>()
          .toList();

  testWidgets('tek cüzdan: nokta yok, kaydırma hiçbir şey seçmez',
      (tester) async {
    final only = _wallet('a', 'Nakit');
    when(() => bloc.state).thenReturn(WalletLoadedSt([only], only));
    await pumpHeader(tester);

    expect(find.text('NAKİT'), findsOneWidget);
    expect(dots, findsNothing);

    await swipeLeft(tester);
    expect(find.text('NAKİT'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets(
      'iki cüzdan: yana kaydırınca komşu cüzdan SESSİZCE etkinleşir, '
      'noktalar konumu gösterir', (tester) async {
    final a = _wallet('a', 'Nakit');
    final b = _wallet('b', 'Banka', balance: 5000);
    when(() => bloc.state).thenReturn(WalletLoadedSt([a, b], a));
    await pumpHeader(tester);

    expect(find.text('NAKİT'), findsOneWidget);
    expect(dots, findsOneWidget);

    await swipeLeft(tester);

    // Başlık komşu cüzdanı gösteriyor…
    expect(find.text('BANKA'), findsOneWidget);
    expect(find.textContaining('5.000'), findsOneWidget);
    // …ve o cüzdan etkinleştirildi; "Cüzdan seçildi" bildirimi YOK.
    final sent = selections().single;
    expect(sent.walletId, 'b');
    expect(sent.userId, 'u');
    expect(sent.announce, isFalse);

    // Onay penceresi dolsun (bu testte bloc durumu değişmiyor).
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('bloc seçimi onaylamazsa başlık etkin cüzdana geri döner',
      (tester) async {
    final a = _wallet('a', 'Nakit');
    final b = _wallet('b', 'Banka');
    when(() => bloc.state).thenReturn(WalletLoadedSt([a, b], a));
    await pumpHeader(tester);

    await swipeLeft(tester);
    expect(find.text('BANKA'), findsOneWidget);

    // Seçim yazılamadı: etkin cüzdan hâlâ Nakit. Başlık yanlış cüzdanı
    // göstermeye devam etmemeli.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('NAKİT'), findsOneWidget);
    expect(find.text('BANKA'), findsNothing);
  });

  testWidgets(
      'kullanıcı başlığı KENDİ kaydırdıysa "kaydırılabilir" ipucu bir daha '
      'oynamaz', (tester) async {
    // Cihazda görüldü: kabuk turu sürerken ipucu bekletiliyor, tur bitince
    // kullanıcının İLK kaydırmasının ardından oynuyor ve yeni oturmuş
    // başlığı ~36dp yerinden oynatıyordu.
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(prefs);
    final coordinator = _MockCoordinator();
    when(() => coordinator.runningFlow).thenReturn(OnboardingFlow.shell);
    when(() => coordinator.isPending(any())).thenReturn(false);
    when(() => coordinator.isSeen(any())).thenReturn(true);
    getIt.registerSingleton<OnboardingCoordinator>(coordinator);

    final a = _wallet('a', 'Nakit');
    final b = _wallet('b', 'Banka');
    when(() => bloc.state).thenReturn(WalletLoadedSt([a, b], a));
    await pumpHeader(tester);
    expect(WalletCarouselHintStore(prefs).seen, isFalse);

    await swipeLeft(tester);
    expect(find.text('BANKA'), findsOneWidget);
    expect(WalletCarouselHintStore(prefs).seen, isTrue);

    // Tur bitti: ipucu artık serbest ama oynamamalı — başlık yerinde durur.
    when(() => coordinator.runningFlow).thenReturn(null);
    final before = tester.getTopLeft(find.text('BANKA')).dx;
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.getTopLeft(find.text('BANKA')).dx, before);

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('cüzdan başka yerden değişince başlık o sayfaya gider',
      (tester) async {
    final a = _wallet('a', 'Nakit');
    final b = _wallet('b', 'Banka');
    whenListen(
      bloc,
      Stream<WalletState>.fromIterable([
        WalletLoadedSt([a, b], b),
      ]),
      initialState: WalletLoadedSt([a, b], a),
    );
    await pumpHeader(tester);

    expect(find.text('BANKA'), findsOneWidget);
    expect(find.text('NAKİT'), findsNothing);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('kart bağlamı SAHİBİNİN sayfasında yaşar; kart ayrı sayfa değil',
      (tester) async {
    final bank = _wallet('bank', 'Banka');
    final cash = _wallet('cash', 'Nakit');
    final card = _cardOf('bank');
    when(() => bloc.state).thenReturn(WalletLoadedSt([bank, card, cash], card));
    await pumpHeader(tester);

    // Bugünkü kart başlığı: "HESAP › KART • BORÇ".
    expect(find.textContaining('BANKA › BONUS'), findsOneWidget);

    // Bir kaydırma doğrudan öteki HESABA götürür (karta değil).
    await swipeLeft(tester);
    expect(find.text('NAKİT'), findsOneWidget);
    expect(selections().single.walletId, 'cash');

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('karusel 70dp\'lik çubuğun içinde kalır', (tester) async {
    final a = _wallet('a', 'Çok Uzun Adlı Bir Maaş Hesabı');
    final b = _wallet('b', 'Banka');
    when(() => bloc.state).thenReturn(WalletLoadedSt([a, b], a));
    await pumpHeader(tester);

    final box = tester.getRect(carousel);
    expect(box.height, 70);
    expect(tester.takeException(), isNull);
  });
}
