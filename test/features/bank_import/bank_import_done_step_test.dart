import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/models/local_user.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/bank_import/presentation/pages/bank_import_page.dart';
import 'package:cunehat/features/main_feature/controllers/home_navigation_requests.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

class _MockBankImportCubit extends MockCubit<BankImportState>
    implements BankImportCubit {}

class _MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

class _MockAuthBloc extends MockBloc<AppAuthEvent, AppAuthState>
    implements AppAuthBloc {}

WalletEntity _wallet(String id, String name) => WalletEntity(
      id: id,
      userId: 'u1',
      name: name,
      balance: 1500,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '0xFF000000',
      iconName: 'money',
      createdAt: DateTime(2026, 1, 1),
      openingBalance: 0,
    );

const _done = BankImportDone(
  added: 3,
  skipped: 1,
  walletId: 'w1',
  userId: 'u1',
  balance: 1500,
  hasPastMonthRows: false,
);

/// Bitiş ekranı: geri alma diyaloğu, bakiye eşitleme, çıkışta hedef cüzdan.
void main() {
  late _MockBankImportCubit cubit;
  late _MockWalletBloc walletBloc;
  late _MockAuthBloc authBloc;

  void doneState(BankImportDone done) => whenListen(
        cubit,
        const Stream<BankImportState>.empty(),
        initialState: done,
      );

  setUpAll(() {
    Intl.defaultLocale = 'tr';
    registerFallbackValue(
        const SetActiveWalletEvent(userId: 'u1', walletId: 'w1'));
  });

  setUp(() {
    cubit = _MockBankImportCubit();
    walletBloc = _MockWalletBloc();
    authBloc = _MockAuthBloc();

    whenListen(
      cubit,
      const Stream<BankImportState>.empty(),
      initialState: _done,
    );
    when(() => cubit.lastPdfRawText).thenReturn(null);
    when(() => cubit.sharedFilePath).thenReturn(null);

    // Hedef (w1) aktif DEĞİL: çıkışta aktif edilmesi ölçülebilsin.
    whenListen(
      walletBloc,
      const Stream<WalletState>.empty(),
      initialState: WalletLoadedSt(
        [_wallet('w1', 'Banka'), _wallet('w2', 'Nakit')],
        _wallet('w2', 'Nakit'),
      ),
    );
    whenListen(
      authBloc,
      const Stream<AppAuthState>.empty(),
      initialState: AppAuthenticated(LocalUser.guest()),
    );

    getIt.registerFactory<BankImportCubit>(() => cubit);
  });

  tearDown(() => getIt.reset());

  /// Sayfa İKİNCİ rota olarak açılır: geri hareketi gerçekten sayfayı
  /// kapatabilsin.
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      // Üretimde olduğu gibi bloc'lar uygulamanın ÜSTÜNDE: itilen rota da
      // onları görmeli.
      MultiBlocProvider(
        providers: [
          BlocProvider<WalletBloc>.value(value: walletBloc),
          BlocProvider<AppAuthBloc>.value(value: authBloc),
        ],
        child: MaterialApp(
          scaffoldMessengerKey: appMessengerKey,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BankImportPage(),
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

  testWidgets('ileri tarihe yazılan kalan taksitler ayrıca bildirilir',
      (tester) async {
    doneState(const BankImportDone(
      added: 8,
      skipped: 0,
      walletId: 'w1',
      userId: 'u1',
      balance: 1500,
      hasPastMonthRows: false,
      futureInstallments: 11,
    ));
    await pump(tester);

    expect(find.byKey(const ValueKey('import-done-future-installments')),
        findsOneWidget);
    expect(find.text('11 kalan taksit ileri tarihe yazıldı.'), findsOneWidget);
  });

  testWidgets('incelemede işaretlenip bağlanan transferler bildirilir',
      (tester) async {
    doneState(const BankImportDone(
      added: 3,
      skipped: 0,
      walletId: 'w1',
      userId: 'u1',
      balance: 1500,
      hasPastMonthRows: false,
      linkedTransfers: 2,
    ));
    await pump(tester);

    expect(find.byKey(const ValueKey('import-done-linked-transfers')),
        findsOneWidget);
    expect(find.text('2 satır transfer olarak bağlandı.'), findsOneWidget);
  });

  testWidgets('taksit yazılmadıysa o satır hiç görünmez', (tester) async {
    doneState(_done);
    await pump(tester);

    expect(find.byKey(const ValueKey('import-done-future-installments')),
        findsNothing);
  });

  group('geri alma diyaloğu', () {
    testWidgets('önce neyin silineceğini söyler; iptal hiçbir şey yapmaz',
        (tester) async {
      await pump(tester);

      await tester.tap(find.text('İçe aktarımı geri al'));
      await tester.pumpAndSettle();

      expect(find.text('İçe aktarım geri alınsın mı?'), findsOneWidget);
      expect(find.text('Az önce eklenen 3 işlem silinir.'), findsOneWidget);

      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();

      verifyNever(() => cubit.undoImport());
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('onay → çalışıyor → sonuç; bağlı satırlar açıklanır',
        (tester) async {
      final completer = Completer<ImportUndoResult>();
      when(() => cubit.undoImport()).thenAnswer((_) => completer.future);
      await pump(tester);

      await tester.tap(find.text('İçe aktarımı geri al'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Geri al'));
      await tester.pump();

      // Çalışırken diyalog kapatılamaz ve ne olduğu yazar.
      expect(find.text('Geri alınıyor…'), findsOneWidget);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pump();
      expect(find.text('Geri alınıyor…'), findsOneWidget);

      completer.complete(const ImportUndoResult(removed: 2, kept: 1));
      await tester.pumpAndSettle();

      expect(find.text('İçe aktarım geri alındı'), findsOneWidget);
      expect(find.text('2 işlem silindi.'), findsOneWidget);
      expect(
          find.textContaining('Bir kayda bağladığın 1 satır'), findsOneWidget);
      // Sonuç snackbar'da DEĞİL: kullanıcı kendi hızında okur.
      expect(find.byType(SnackBar), findsNothing);

      await tester.tap(find.text('Tamam'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      verify(() => cubit.undoImport()).called(1);
    });
  });

  testWidgets('eşitlemeden sonra kart YENİ bakiyeyi gösterir', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Bakiyeyi eşitle'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2000');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text(formatMoney(2000, currency: 'TRY')), findsOneWidget);
    expect(find.text(formatMoney(1500, currency: 'TRY')), findsNothing);
    expect(find.text('Bankayla eşitlendi'), findsOneWidget);
    verify(() => walletBloc.add(any(that: isA<UpdateWalletEvent>()))).called(1);
  });

  testWidgets('geri hareketiyle çıkınca da hedef cüzdan aktif olur',
      (tester) async {
    await pump(tester);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();

    expect(find.byType(BankImportPage), findsNothing);
    final events = verify(() => walletBloc.add(captureAny())).captured;
    expect(events.whereType<SetActiveWalletEvent>().single.walletId, 'w1');
  });

  group('ekstrenin kapanış bakiyesi', () {
    BankImportDone withClosing(double ledger) => BankImportDone(
          added: 3,
          skipped: 0,
          walletId: 'w1',
          userId: 'u1',
          balance: 1500,
          hasPastMonthRows: false,
          closing: (amount: 1250, date: DateTime(2026, 8, 3)),
          ledgerAtClosing: ledger,
        );

    testWidgets('defter o gün bankayla tutuyorsa yalnız onay görünür',
        (tester) async {
      doneState(withClosing(1250));
      await pump(tester);

      expect(find.text('Ekstreye göre 03.08.26 bakiyesi'), findsOneWidget);
      expect(
          find.text('Cüzdan o gün bankayla birebir tutuyor.'), findsOneWidget);
      expect(find.text('Bankayla eşitle'), findsNothing);
    });

    testWidgets(
        'fark varsa kullanıcı YAZMADAN tek dokunuşla eşitlenir; ekstre '
        'sonrası hareketler korunur', (tester) async {
      // Banka 03.08'de 1.250 diyor, defter o gün 1.150 → +100. Bugünkü
      // bakiye (1.500) ekstre sonrası hareketleri içerir; hedef 1.600.
      doneState(withClosing(1150));
      await pump(tester);

      expect(find.textContaining('100,00'), findsWidgets);
      await tester.tap(find.widgetWithText(FilledButton, 'Bankayla eşitle'));
      await tester.pumpAndSettle();
      expect(find.text('Bakiyeyi Eşitle'), findsOneWidget);
      await tester
          .tap(find.widgetWithText(FilledButton, 'Bankayla eşitle').last);
      await tester.pumpAndSettle();

      final event = verify(() => walletBloc.add(captureAny()))
          .captured
          .whereType<UpdateWalletEvent>()
          .single;
      expect(event.wallet.balance, 1600);
      expect(event.baselineBalance, 1500);
      expect(
          find.text('Cüzdan o gün bankayla birebir tutuyor.'), findsOneWidget);
    });
  });

  testWidgets(
      '"Eklenenleri göster" listeyi ekstrenin aralığına ayarlar ve İşlemler '
      'sekmesini ister', (tester) async {
    final requests = HomeNavigationRequests();
    var asked = 0;
    requests.addListener(() => asked++);
    getIt.registerSingleton<HomeNavigationRequests>(requests);
    doneState(BankImportDone(
      added: 2,
      skipped: 0,
      walletId: 'w1',
      userId: 'u1',
      balance: 1500,
      hasPastMonthRows: true,
      firstDate: DateTime(2026, 5, 30, 14),
      lastDate: DateTime(2026, 8, 25),
    ));
    await pump(tester);

    await tester.tap(find.text('Eklenenleri işlemlerde göster'));
    await tester.pumpAndSettle();

    expect(find.byType(BankImportPage), findsNothing);
    expect(asked, 1);
    // Dönem İSTEKLE taşınır: İşlemler sayfası kendi süzgecini kuruyor,
    // uygulama seviyesindeki süzgece yazmak hiçbir yere ulaşmıyordu (cihazda
    // ölçüldü).
    expect(requests.pendingPeriod!.start, DateTime(2026, 5, 30));
    expect(requests.pendingPeriod!.end, DateTime(2026, 8, 25, 23, 59, 59));
    final events = verify(() => walletBloc.add(captureAny())).captured;
    expect(events.whereType<SetActiveWalletEvent>().single.walletId, 'w1');
  });
}
