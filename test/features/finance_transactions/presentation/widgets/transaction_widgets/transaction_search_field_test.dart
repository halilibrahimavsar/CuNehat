import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: Scaffold(body: child),
      );

  String textOf(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  testWidgets('dışarıdan temizlenince alan da boşalır', (tester) async {
    await tester.pumpWidget(wrap(
      TransactionSearchField(value: 'market', onChanged: (_) {}),
    ));
    expect(textOf(tester), 'market');

    // "Filtreleri temizle" sorguyu null'a çeker.
    await tester.pumpWidget(wrap(
      TransactionSearchField(value: null, onChanged: (_) {}),
    ));
    expect(textOf(tester), '');
  });

  testWidgets('ilgisiz yeniden çizim yazılmakta olan boşluğu YEMEZ',
      (tester) async {
    // Kullanıcı "elektrik " yazdı (sonraki kelimeyi yazacak). Cubit sorguyu
    // trim'lediği için dışarıdaki değer "elektrik". Bu anda ilgisiz bir
    // yeniden çizim gelirse (ör. silme sonrası defter tazelemesi) naif
    // senkron alanı "elektrik"e ezip boşluğu siler.
    var external = 'elektrik';
    await tester.pumpWidget(wrap(
      TransactionSearchField(
        value: external,
        onChanged: (v) => external = v.trim(),
      ),
    ));

    await tester.enterText(find.byType(TextField), 'elektrik ');
    await tester.pumpAndSettle();

    // Aynı dış değerle yeniden çizim.
    await tester.pumpWidget(wrap(
      TransactionSearchField(value: 'elektrik', onChanged: (_) {}),
    ));
    await tester.pump();

    expect(textOf(tester), 'elektrik ');
  });

  testWidgets('temizle düğmesi boş sorgu yollar ve alanı boşaltır',
      (tester) async {
    String? seen;
    await tester.pumpWidget(wrap(
      TransactionSearchField(value: 'market', onChanged: (v) => seen = v),
    ));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(seen, '');
    expect(textOf(tester), '');
  });
}
