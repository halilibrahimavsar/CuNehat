import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_starter_pack_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        // Gerçek kullanımdaki gibi: sheet zaten bir Scaffold'un üstünde açılıyor,
        // yani "en yakın Material" dışarıda VAR. Hata tam da bu yüzden sinsi —
        // Material eksik değil, araya renkli bir kutu giriyor.
        home: Scaffold(body: child),
      );

  // REGRESYON (cihazda ölçüldü, 28 Ağu 2026): sheet renkli bir `Container` ile
  // sarılıydı. `CheckboxListTile` zeminini ve ink dalgasını EN YAKIN Material'a
  // boyar; araya renkli bir kutu girince ikisi de görünmez olur. Flutter bunu
  // debug'da assert ile bildiriyordu ve o assert cihaz günlüğünde yüzlerce kez
  // düşüyordu. Kullanıcı tarafındaki karşılığı: "dokunuyorum, hiçbir şey
  // olmuyor." Testler debug'da koştuğu için assert burada gerçek bir ölçüm.
  testWidgets('sheet çizilirken Flutter assert düşmez', (tester) async {
    await tester.pumpWidget(host(const CategoryStarterPackSheet()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CheckboxListTile), findsWidgets);
  });

  // İkinci kapı: assert'e güvenmeyen yapısal ölçüm. Flutter bir gün bu assert'i
  // kaldırsa bile hata sessizce geri gelmesin — tile ile onu boyayacak Material
  // arasında renkli bir kutu KALMAMALI. (`Container` renk + dekorasyon
  // verildiğinde içeride `DecoratedBox` kurar, o yüzden ikisini birden yakalar.)
  testWidgets('tile ile en yakın Material arasında renkli kutu yok',
      (tester) async {
    await tester.pumpWidget(host(const CategoryStarterPackSheet()));
    await tester.pumpAndSettle();

    final tile = tester.element(find.byType(CheckboxListTile).first);
    final coloredBoxes = <Color>[];
    var reachedMaterial = false;

    tile.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      if (widget is Material) {
        reachedMaterial = true;
        return false;
      }
      if (widget is DecoratedBox) {
        final decoration = widget.decoration;
        if (decoration is BoxDecoration && decoration.color != null) {
          coloredBoxes.add(decoration.color!);
        }
      }
      return true;
    });

    expect(reachedMaterial, isTrue, reason: 'tile bir Material altında olmalı');
    expect(coloredBoxes, isEmpty,
        reason: 'tile ile Material arasında renkli kutu var: $coloredBoxes');
  });
}
