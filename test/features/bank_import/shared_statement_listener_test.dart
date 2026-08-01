import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/models/local_user.dart';
import 'package:cunehat/features/bank_import/data/shared_statement_channel.dart';
import 'package:cunehat/features/bank_import/presentation/shared_statement_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _MockAuthBloc extends MockBloc<AppAuthEvent, AppAuthState>
    implements AppAuthBloc {}

const _channel = MethodChannel('dev.halilibrahim.cunehat/shared_statement');
const _sharedPath = '/data/cache/bank_import_shared/ekstre.pdf';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final user = LocalUser.guest();

  late _MockAuthBloc authBloc;
  late StreamController<AppAuthState> authStates;
  late GoRouter router;

  /// `true` iken router, içe aktarma yolunu kilit ekranına çevirir — gerçek
  /// `createAppRouter` yönlendirmesinin testteki karşılığı.
  var locked = false;

  /// Native taraf gibi TEK SEFERLİK teslim: ikinci `consume` null döner.
  void mockPendingShare(String? path) {
    var served = false;
    messenger.setMockMethodCallHandler(_channel, (_) async {
      if (served) return null;
      served = true;
      return path;
    });
  }

  setUp(() {
    locked = false;
    authStates = StreamController<AppAuthState>.broadcast();
    authBloc = _MockAuthBloc();
    router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        if (locked && state.matchedLocation == AppRoutes.bankStatementImport) {
          return '/lock';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Text('home')),
        GoRoute(path: '/lock', builder: (_, __) => const Text('lock')),
        GoRoute(
          path: AppRoutes.bankStatementImport,
          builder: (_, state) => Text('import:${state.extra}'),
        ),
      ],
    );
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(_channel, null);
    authStates.close();
    router.dispose();
  });

  Future<void> pump(WidgetTester tester, AppAuthState initial) async {
    whenListen(authBloc, authStates.stream, initialState: initial);
    await tester.pumpWidget(
      // Üretimdeki yerleşimin aynısı: dinleyici bloc'ların ALTINDA,
      // MaterialApp'in ÜSTÜNDE.
      BlocProvider<AppAuthBloc>.value(
        value: authBloc,
        child: SharedStatementListener(
          router: router,
          channel: SharedStatementChannel(),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('kilit yokken paylaşılan dosya içe aktarma ekranını açar',
      (tester) async {
    mockPendingShare(_sharedPath);

    await pump(tester, AppAuthenticated(user));

    expect(find.text('import:$_sharedPath'), findsOneWidget);
  });

  testWidgets('bekleyen paylaşım yoksa hiçbir yönlendirme yapılmaz',
      (tester) async {
    mockPendingShare(null);

    await pump(tester, AppAuthenticated(user));

    expect(find.text('home'), findsOneWidget);
    expect(find.textContaining('import:'), findsNothing);
  });

  testWidgets('kilitliyken açılmaz, kilit açılınca açılır', (tester) async {
    // Gizlilik kapısı: PIN/biyometrik açıkken paylaşılan ekstre kilit
    // açılmadan içe aktarma ekranını AÇAMAZ.
    mockPendingShare(_sharedPath);
    locked = true;

    await pump(tester, AppAuthLocked(user));

    expect(find.textContaining('import:'), findsNothing);

    locked = false;
    authStates.add(AppAuthenticated(user));
    await tester.pumpAndSettle();

    expect(find.text('import:$_sharedPath'), findsOneWidget);
  });

  testWidgets('kilit yönlendirmesi push\'u yuttuysa yol korunur ve tekrarlanır',
      (tester) async {
    // Yarış: uygulama öne gelirken AppAuthBloc de kilit kararını veriyor.
    // Kilit kararı push'tan SONRA gelirse router sayfayı yığından siler;
    // paylaşım sessizce kaybolmamalı, kilit açılınca yeniden denenmeli.
    mockPendingShare(_sharedPath);
    locked = true;

    await pump(tester, AppAuthenticated(user));

    // Push yapıldı ama yönlendirme kilit ekranına çevirdi.
    expect(find.text('lock'), findsOneWidget);
    expect(find.textContaining('import:'), findsNothing);

    locked = false;
    authStates.add(AppAuthenticated(user));
    await tester.pumpAndSettle();

    // Kanal tek seferlik: bu ancak yol elde TUTULDUYSA çalışır.
    expect(find.text('import:$_sharedPath'), findsOneWidget);
  });
}
