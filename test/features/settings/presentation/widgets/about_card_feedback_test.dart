import 'package:cunehat/core/constants/app_version.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/settings/presentation/page/privacy_policy_page.dart';
import 'package:cunehat/features/settings/presentation/widgets/about_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ayarlar > Hakkında > "Görüş gönder".
void main() {
  const mail = MethodChannel('dev.halilibrahim.cunehat/feedback_mail');
  final calls = <MethodCall>[];
  String? clipboard;

  Future<void> pump(WidgetTester tester, {required bool mailAppExists}) async {
    calls.clear();
    clipboard = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(mail, (call) async {
      calls.add(call);
      return mailAppExists;
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(mail, null);
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('tr'), Locale('en')],
        locale: Locale('tr'),
        home: Scaffold(body: SingleChildScrollView(child: AboutCard())),
      ),
    );
    await tester.pump();
  }

  final row = find.byKey(const ValueKey('about-feedback'));

  testWidgets('satır görünür ve ne işe yaradığını söyler', (tester) async {
    await pump(tester, mailAppExists: true);
    debugDefaultTargetPlatformOverride = null;

    expect(find.text('Görüş gönder'), findsOneWidget);
    expect(
      find.text('Sorun, istek ya da fikir — doğrudan geliştiriciye gider.'),
      findsOneWidget,
    );
  });

  testWidgets('dokununca alıcısı ve sürümü dolu bir taslak açılır',
      (tester) async {
    await pump(tester, mailAppExists: true);

    await tester.tap(row);
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;

    final args = calls.single.arguments as Map;
    expect(args['to'], PrivacyPolicyPage.contactEmail);
    expect(args['subject'], 'ÇuHat görüş · v$kAppVersionName');
    expect(args['body'], contains(kAppVersionName));
    // Taslak açıldı: panoya dokunulmaz.
    expect(clipboard, isNull);
  });

  testWidgets('e-posta uygulaması yoksa adres panoya kopyalanır',
      (tester) async {
    await pump(tester, mailAppExists: false);

    await tester.tap(row);
    await tester.pump();
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;

    expect(clipboard, PrivacyPolicyPage.contactEmail);
  });
}
