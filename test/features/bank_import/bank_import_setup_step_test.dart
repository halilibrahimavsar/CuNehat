import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/models/local_user.dart';
import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/bank_import/presentation/pages/bank_import_page.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBankImportCubit extends MockCubit<BankImportState>
    implements BankImportCubit {}

class _MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

class _MockAuthBloc extends MockBloc<AppAuthEvent, AppAuthState>
    implements AppAuthBloc {}

const _sharedPath = '/data/cache/bank_import_shared/Hesap Özeti.pdf';

WalletEntity _wallet({String id = 'w1', String name = 'Nakit'}) => WalletEntity(
      id: id,
      userId: 'local_user',
      name: name,
      balance: 0,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '0xFF000000',
      iconName: 'money',
      createdAt: DateTime(2026, 1, 1),
      openingBalance: 0,
    );

void main() {
  late _MockBankImportCubit cubit;
  late _MockWalletBloc walletBloc;
  late _MockAuthBloc authBloc;

  setUp(() {
    cubit = _MockBankImportCubit();
    walletBloc = _MockWalletBloc();
    authBloc = _MockAuthBloc();

    when(() => cubit.state).thenReturn(const BankImportInitial());
    when(() => cubit.lastPdfRawText).thenReturn(null);
    when(() => cubit.attachSharedFile(any())).thenReturn(null);
    when(() => cubit.sharedFilePath).thenReturn(null);
    when(() => cubit.lastTargetWalletId()).thenAnswer((_) async => null);
    when(() => cubit.importHistory(userId: any(named: 'userId')))
        .thenAnswer((_) async => const <ImportBatch>[]);
    when(() => cubit.parseFile(
          userId: any(named: 'userId'),
          walletId: any(named: 'walletId'),
          path: any(named: 'path'),
        )).thenAnswer((_) async {});
    when(() => cubit.pickAndParse(
          userId: any(named: 'userId'),
          walletId: any(named: 'walletId'),
        )).thenAnswer((_) async {});

    whenListen(
      walletBloc,
      const Stream<WalletState>.empty(),
      initialState: WalletLoadedSt([_wallet()], _wallet()),
    );
    whenListen(
      authBloc,
      const Stream<AppAuthState>.empty(),
      initialState: AppAuthenticated(LocalUser.guest()),
    );

    getIt.registerFactory<BankImportCubit>(() => cubit);
  });

  tearDown(() => getIt.reset());

  Future<void> pump(WidgetTester tester, {String? sharedFilePath}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<WalletBloc>.value(value: walletBloc),
            BlocProvider<AppAuthBloc>.value(value: authBloc),
          ],
          child: BankImportPage(sharedFilePath: sharedFilePath),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Kayıt sürerken geri çıkılırsa yazım yine tamamlanır (SafeEmitMixin) ama
  // sonuç ekranı ve "Geri al" kaybolur; kullanıcı içe aktarımın yarım kalıp
  // kalmadığını bilemezdi.
  testWidgets('kaydetme sürerken geri çıkış engellenir', (tester) async {
    whenListen(
      cubit,
      const Stream<BankImportState>.empty(),
      initialState: BankImportCommitting(done: 1, total: 3),
    );

    await pump(tester);

    final popScope = tester
        .widgetList<PopScope<Object?>>(
            find.byWidgetPredicate((widget) => widget is PopScope))
        .first;
    expect(popScope.canPop, isFalse);
  });

  testWidgets('kayıt dışındaki adımlarda geri çıkış serbesttir',
      (tester) async {
    await pump(tester);

    final popScope = tester
        .widgetList<PopScope<Object?>>(
            find.byWidgetPredicate((widget) => widget is PopScope))
        .first;
    expect(popScope.canPop, isTrue);
  });

  testWidgets('paylaşım olmadan kurulum adımı dosya seçiciyi sunar',
      (tester) async {
    await pump(tester);

    expect(find.text('Dosya seç ve tara'), findsOneWidget);
    expect(find.text('Paylaşılan dosya'), findsNothing);
    verifyNever(() => cubit.attachSharedFile(any()));
  });

  testWidgets('paylaşılan dosya cubit\'e bağlanır ve adı gösterilir',
      (tester) async {
    when(() => cubit.sharedFilePath).thenReturn(_sharedPath);

    await pump(tester, sharedFilePath: _sharedPath);

    verify(() => cubit.attachSharedFile(_sharedPath)).called(1);
    // Kullanıcı hangi dosyayı aktardığını cüzdanı seçmeden önce görmeli.
    expect(find.text('Paylaşılan dosya'), findsOneWidget);
    expect(find.text('Hesap Özeti.pdf'), findsOneWidget);
    expect(find.text('Bu dosyayı tara'), findsOneWidget);
    expect(find.text('Dosya seç ve tara'), findsNothing);
  });

  testWidgets('tarama, dosya seçiciyi AÇMADAN paylaşılan yolu kullanır',
      (tester) async {
    when(() => cubit.sharedFilePath).thenReturn(_sharedPath);

    await pump(tester, sharedFilePath: _sharedPath);
    await tester.tap(find.text('Bu dosyayı tara'));
    await tester.pump();

    verify(() => cubit.parseFile(
          userId: 'local_user',
          walletId: 'w1',
          path: _sharedPath,
        )).called(1);
    verifyNever(() => cubit.pickAndParse(
          userId: any(named: 'userId'),
          walletId: any(named: 'walletId'),
        ));
  });

  testWidgets('paylaşımdayken bile dosya seçici yolu erişilebilir kalır',
      (tester) async {
    when(() => cubit.sharedFilePath).thenReturn(_sharedPath);

    await pump(tester, sharedFilePath: _sharedPath);
    await tester.tap(find.text('Başka dosya seç'));
    await tester.pump();

    verify(() => cubit.pickAndParse(userId: 'local_user', walletId: 'w1'))
        .called(1);
  });

  testWidgets(
      'hedef cüzdanın varsayılanı SON içe aktarımın hedefi (aktif cüzdan değil)',
      (tester) async {
    whenListen(
      walletBloc,
      const Stream<WalletState>.empty(),
      initialState: WalletLoadedSt(
        [_wallet(), _wallet(id: 'w2', name: 'Maaş hesabı')],
        _wallet(),
      ),
    );
    when(() => cubit.lastTargetWalletId()).thenAnswer((_) async => 'w2');

    await pump(tester);

    expect(find.text('Maaş hesabı'), findsOneWidget);
    await tester.tap(find.text('Dosya seç ve tara'));
    await tester.pump();
    verify(() => cubit.pickAndParse(
          userId: any(named: 'userId'),
          walletId: 'w2',
        )).called(1);
  });

  testWidgets('son içe aktarımlar listelenir ve geri alma diyaloğu açılır',
      (tester) async {
    final batch = ImportBatch(
      id: '01922b7e-3f00-7abc-8def-0123456789ab',
      walletId: 'w1',
      walletName: 'Nakit',
      count: 157,
      importedAt: DateTime(2026, 9, 24, 9, 50),
      firstDate: DateTime(2026, 5, 30),
      lastDate: DateTime(2026, 8, 25),
    );
    var undone = false;
    when(() => cubit.importHistory(userId: any(named: 'userId')))
        .thenAnswer((_) async => undone ? const <ImportBatch>[] : [batch]);
    when(() => cubit.undoBatch(batch, userId: any(named: 'userId')))
        .thenAnswer((_) async {
      undone = true;
      return const ImportUndoResult(removed: 157);
    });

    await pump(tester);

    expect(find.text('Son içe aktarımlar'), findsOneWidget);
    expect(find.text('Nakit · 157 işlem'), findsOneWidget);

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();
    // Sonradan geri almada düzeltmeler/kart künyesi geri dönmez: söylenir.
    expect(find.textContaining('olduğu gibi kalır'), findsOneWidget);
    expect(find.text('Bu içe aktarımın eklediği 157 işlem silinir.'),
        findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Geri al'));
    await tester.pumpAndSettle();

    expect(find.text('157 işlem silindi.'), findsOneWidget);
    verify(() => cubit.undoBatch(batch, userId: any(named: 'userId')))
        .called(1);

    // Sonuç kapanınca liste TAZELENİR: geri alınan parti kaybolur (cihazda
    // ölçüldü — eskiden satır ekranda kalıyordu).
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect(find.text('Nakit · 157 işlem'), findsNothing);
    expect(find.text('Son içe aktarımlar'), findsNothing);
  });

  testWidgets('kategori önerisi kaç satırı kapsadığını ve örnekleri gösterir',
      (tester) async {
    whenListen(
      cubit,
      const Stream<BankImportState>.empty(),
      initialState: const BankImportCategorySuggestion(
        suggestions: [
          CategorySuggestion(
            name: 'Yatırım',
            isIncome: false,
            iconName: 'category',
            rowCount: 3,
            samples: ['MIDAS MENKUL', 'BORSA ISTANBUL'],
          ),
        ],
        rawDrafts: [],
        skippedRows: 0,
      ),
    );

    await pump(tester);

    expect(find.text('Gider · 3 satır · MIDAS MENKUL, BORSA ISTANBUL'),
        findsOneWidget);
  });
}
