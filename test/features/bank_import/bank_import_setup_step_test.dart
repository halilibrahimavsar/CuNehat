import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/models/local_user.dart';
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

WalletEntity _wallet() => WalletEntity(
      id: 'w1',
      userId: 'local_user',
      name: 'Nakit',
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
}
