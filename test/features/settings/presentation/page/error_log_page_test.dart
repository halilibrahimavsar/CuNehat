import 'package:cunehat/core/error/error_log.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/features/settings/presentation/page/error_log_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(ErrorLog.instance.resetForTest);
  tearDown(ErrorLog.instance.resetForTest);

  Widget wrap() {
    return MaterialApp(
      scaffoldMessengerKey: appMessengerKey,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr'), Locale('en')],
      locale: const Locale('tr'),
      home: const ErrorLogPage(),
    );
  }

  Finder actionButton(IconData icon) => find.widgetWithIcon(IconButton, icon);

  testWidgets('kayıt yokken boş durum gösterilir ve eylemler kapalıdır',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Kayıtlı hata yok.'), findsOneWidget);
    for (final icon in [
      Icons.copy_rounded,
      Icons.share_rounded,
      Icons.delete_sweep_rounded,
    ]) {
      expect(tester.widget<IconButton>(actionButton(icon)).onPressed, isNull);
    }
  });

  testWidgets('kayıtlar kaynak ve tekrar sayısıyla listelenir', (tester) async {
    ErrorLog.instance.add('Bloc BankImportCubit', StateError('kapanmış'));
    ErrorLog.instance.add('FlutterError', StateError('her karede'));
    ErrorLog.instance.add('FlutterError', StateError('her karede'));

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.textContaining('kapanmış'), findsOneWidget);
    expect(find.textContaining('Bloc BankImportCubit'), findsOneWidget);
    expect(find.textContaining('FlutterError · ×2'), findsOneWidget);
  });

  testWidgets('temizle onaydan sonra günlüğü boşaltır', (tester) async {
    ErrorLog.instance.add('kaynak', StateError('silinecek'));

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.tap(actionButton(Icons.delete_sweep_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Temizle'));
    await tester.pumpAndSettle();

    expect(ErrorLog.instance.entries, isEmpty);
    expect(find.text('Kayıtlı hata yok.'), findsOneWidget);
  });

  testWidgets('kopyala günlüğü panoya yazar ve haber verir', (tester) async {
    String? clipboard;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    ErrorLog.instance.add('kaynak', StateError('panoya gidecek'));

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.tap(actionButton(Icons.copy_rounded));
    await tester.pumpAndSettle();

    expect(clipboard, contains('panoya gidecek'));
    expect(find.text('Hata günlüğü panoya kopyalandı'), findsOneWidget);
  });
}
