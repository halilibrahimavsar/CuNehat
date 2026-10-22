import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/services/wallet_category_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_controller.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_when_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

class _MockWalletCategoryService extends Mock
    implements WalletCategoryService {}

void main() {
  setUp(() {
    Intl.defaultLocale = 'tr_TR';
    // Denetleyici kategori kapsamını getIt'ten alır; burada kullanılmaz.
    getIt.allowReassignment = true;
    getIt
        .registerSingleton<WalletCategoryService>(_MockWalletCategoryService());
  });
  tearDown(() => getIt.reset());

  Future<TransactionFormController> pump(WidgetTester tester,
      {Size size = const Size(400, 900), double textScale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final controller =
        TransactionFormController(isExpense: true, walletId: 'w');
    controller.dateTime.value = DateTime(2026, 10, 14, 16, 13);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Sistemde 24 saat KAPALI (ör. sistem dili İngilizce olan telefon).
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          alwaysUse24HourFormat: false,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: WhenRow(controller: controller, accent: Colors.red),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets(
      'sistemde 24 saat kapalıyken de saat metinle 19:00 girilebilir '
      '(kadran 24 saatlik, giriş 12\'den büyüğü reddediyordu)', (tester) async {
    final controller = await pump(tester);

    await tester.tap(find.text('16:13'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '19');
    await tester.enterText(fields.at(1), '00');
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();

    expect(controller.dateTime.value.hour, 19);
    expect(controller.dateTime.value.minute, 0);
  });

  testWidgets('dar hapta tarih yılı kesmez, kısa biçime düşer', (tester) async {
    // Cihazda 320dp + 1,3 yazıda "20 Ekim…" görünüyordu. Test fontu
    // gerçeğinden geniş: 490dp burada "uzun sığmaz, kısa sığar" koşulunu kurar.
    final date = DateTime(2026, 10, 14);
    await pump(tester, size: const Size(490, 900), textScale: 1.3);

    expect(find.text(AppFormatters.dateLong.format(date)), findsNothing);
    final short = find.text(AppFormatters.dayMonthYear.format(date));
    expect(short, findsOneWidget);
    expect(
        tester.renderObject<RenderParagraph>(short).didExceedMaxLines, isFalse);
  });
}
