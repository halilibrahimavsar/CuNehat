import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/settings/presentation/blocs/data_export_import/data_export_import_cubit.dart';
import 'package:cunehat/features/settings/presentation/blocs/data_export_import/data_export_import_state.dart';
import 'package:cunehat/features/settings/presentation/widgets/data_export_import_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/real_font.dart';

class _MockCubit extends MockCubit<DataExportImportState>
    implements DataExportImportCubit {}

class _MockAuthBloc extends MockBloc<AppAuthEvent, AppAuthState>
    implements AppAuthBloc {}

/// "Yedeğim var" sayfasındaki kart yalnız GERİ YÜKLEMEYİ sunar.
///
/// Cihazda görüldü (13 Eki 2026): sıfır kurulumda "Yedeğim var"a dokunan
/// kişinin önündeki dolu düğme "Tam yedeği cihaza kaydet"ti; aradığı eylem
/// ikinci sıradaki çerçeveli düğmeydi.
void main() {
  late _MockCubit cubit;
  late _MockAuthBloc auth;
  late StreamController<DataExportImportState> states;

  // Onay diyaloğunun düğme satırı varsayılan (geniş) test fontuyla taşar.
  setUpAll(loadRealRoboto);

  setUp(() async {
    await getIt.reset();
    cubit = _MockCubit();
    auth = _MockAuthBloc();
    states = StreamController<DataExportImportState>.broadcast();
    whenListen(cubit, states.stream, initialState: DataExportImportInitial());
    when(() => cubit.importFullBackupFromDevice(userId: any(named: 'userId')))
        .thenAnswer((_) async {});
    when(() => cubit.close()).thenAnswer((_) async {});
    // Oturum henüz yok: karşılama ekranı cüzdan kurulmadan önce gelir.
    when(() => auth.state).thenReturn(AppAuthInitial());
    getIt.registerFactory<DataExportImportCubit>(() => cubit);
  });

  tearDown(() async {
    await states.close();
    await getIt.reset();
  });

  Future<void> pump(
    WidgetTester tester, {
    required bool restoreOnly,
    VoidCallback? onRestored,
  }) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<AppAuthBloc>.value(
        value: auth,
        child: MaterialApp(
          theme: ThemeData(fontFamily: kRealFontFamily),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          locale: const Locale('tr'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: DataExportImportCard(
                restoreOnly: restoreOnly,
                onRestored: onRestored,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  final pick = find.byKey(const ValueKey('restore-only-pick'));

  testWidgets('tek eylem: yedek dosyasını seç', (tester) async {
    await pump(tester, restoreOnly: true);

    expect(find.text('Telefondaki yedek dosyası'), findsOneWidget);
    expect(find.text('Yedek dosyasını seç'), findsOneWidget);
    expect(tester.widget(pick), isA<FilledButton>());
    // Henüz kaydı olmayan biri için anlamsız olanlar yok.
    expect(find.text('Tam yedeği cihaza kaydet'), findsNothing);
    expect(find.text('Tam yedeği paylaş'), findsNothing);
    expect(find.textContaining('CSV'), findsNothing);
  });

  testWidgets('Ayarlar\'daki kart değişmedi: bütün eylemler duruyor',
      (tester) async {
    await pump(tester, restoreOnly: false);

    expect(find.text('Tam yedeği cihaza kaydet'), findsOneWidget);
    expect(find.text('Tam yedeği cihazdan geri yükle'), findsOneWidget);
    expect(find.text('Tam yedeği paylaş'), findsOneWidget);
    expect(pick, findsNothing);
  });

  testWidgets('onay sorulur; onaylanınca dosya seçici açılır', (tester) async {
    await pump(tester, restoreOnly: true);

    await tester.tap(pick);
    await tester.pumpAndSettle();
    expect(find.text('Tam yedek geri yüklensin mi?'), findsOneWidget);
    verifyNever(
      () => cubit.importFullBackupFromDevice(userId: any(named: 'userId')),
    );

    await tester.tap(find.text('Geri yükle'));
    await tester.pumpAndSettle();

    verify(
      () => cubit.importFullBackupFromDevice(userId: any(named: 'userId')),
    ).called(1);
  });

  testWidgets('vazgeçilirse hiçbir şey yüklenmez', (tester) async {
    await pump(tester, restoreOnly: true);

    await tester.tap(pick);
    await tester.pumpAndSettle();
    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();

    verifyNever(
      () => cubit.importFullBackupFromDevice(userId: any(named: 'userId')),
    );
  });

  testWidgets('yedek gelince onRestored çağrılır', (tester) async {
    var restored = 0;
    await pump(tester, restoreOnly: true, onRestored: () => restored++);

    states.add(const DataExportImportSuccess(
      DataExportMessageType.fullBackupImportSuccess,
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    expect(restored, 1);
  });

  testWidgets('iptal edilen seçimde onRestored ÇAĞRILMAZ', (tester) async {
    var restored = 0;
    await pump(tester, restoreOnly: true, onRestored: () => restored++);

    states.add(const DataExportImportSuccess(
      DataExportMessageType.fullBackupCancelled,
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    expect(restored, 0);
  });

  testWidgets('yükleme sürerken düğme kilitli', (tester) async {
    await pump(tester, restoreOnly: true);

    states.add(DataExportImportLoading());
    await tester.pump();
    await tester.pump();

    expect(tester.widget<FilledButton>(pick).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
