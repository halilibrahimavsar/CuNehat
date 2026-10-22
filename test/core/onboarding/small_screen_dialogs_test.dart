import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/notifications/notification_permission_dialog.dart';
import 'package:cunehat/core/onboarding/backup_offer_prompt.dart';
import 'package:cunehat/core/onboarding/log_reminder_offer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// İlk açılışta bir kez çıkan üç diyalog cihazda yeniden üretilemiyor
/// (bayrakları silmek gerekiyor); en küçük yaygın telefonda (320×568, yazı
/// 1,3) taşmadıkları ve iki düğmenin de ekranda kaldığı burada ölçülür.
void main() {
  final cases = <String, void Function(BuildContext)>{
    'bildirim izni': (c) => showNotificationPermissionRationale(c),
    'yedek teklifi': (c) => showBackupOfferDialog(c),
    'hatırlatma teklifi': (c) => showLogReminderOfferDialog(c),
  };

  for (final MapEntry(key: name, value: open) in cases.entries) {
    testWidgets('$name diyaloğu 320×568 + yazı 1,3: taşma yok', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => open(context),
              child: const Text('aç'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final buttons = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
      expect(buttons, findsNWidgets(2));
      for (final b in buttons.evaluate()) {
        final rect = tester.getRect(find.byWidget(b.widget));
        expect(rect.bottom, lessThanOrEqualTo(568), reason: name);
      }
    });
  }
}
