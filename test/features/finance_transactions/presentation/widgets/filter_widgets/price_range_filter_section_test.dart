import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/filter_widgets/price_range_filter_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Smoke test: cihazda tutar alanı "900" → "400" düzenlenirken bir kez
/// "4.400" göründü (adb girişi sırasında). Gerçek panel gibi: değer yazıldıkça
/// dışarı bildirilir, dışarıdaki durum geri gelir ve alan yeniden kurulur.
void main() {
  setUpAll(() => Intl.defaultLocale = 'tr');

  Widget host(ValueNotifier<PriceRangeFilter?> range) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: Scaffold(
          body: ValueListenableBuilder<PriceRangeFilter?>(
            valueListenable: range,
            builder: (_, value, __) => PriceRangeFilterSection(
              range: value,
              accent: Colors.blue,
              onChanged: (r) => range.value = r,
            ),
          ),
        ),
      );

  /// IME gibi tek tuş: imleç sonda, metin bir karakter uzar/kısalır.
  Future<void> key(WidgetTester tester, String text, {bool pump = true}) async {
    tester.testTextInput.updateEditingValue(TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    ));
    if (pump) await tester.pump();
  }

  String fieldText(WidgetTester tester, int i) =>
      tester.widget<TextField>(find.byType(TextField).at(i)).controller!.text;

  for (final pumpEachKey in [true, false]) {
    testWidgets(
        '"900" silinip "400" yazılınca alan 400 olur '
        '(her tuşta kare: $pumpEachKey)', (tester) async {
      final range = ValueNotifier<PriceRangeFilter?>(null);
      await tester.pumpWidget(host(range));

      // Alt sınır alanı.
      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      for (final t in ['9', '90', '900']) {
        await key(tester, t, pump: pumpEachKey);
      }
      await tester.pump();
      expect(fieldText(tester, 0), '900');
      expect(range.value?.minPrice, 900);

      for (final t in ['90', '9', '', '4', '40', '400']) {
        await key(tester, t, pump: pumpEachKey);
      }
      await tester.pumpAndSettle();

      expect(fieldText(tester, 0), '400');
      expect(range.value?.minPrice, 400);
    });
  }

  testWidgets('üst sınır doluyken alt sınır "900" → "400" (geçersiz ara durum)',
      (tester) async {
    final range = ValueNotifier<PriceRangeFilter?>(null);
    await tester.pumpWidget(host(range));

    await tester.tap(find.byType(TextField).at(1));
    await tester.pump();
    for (final t in ['5', '50', '500']) {
      await key(tester, t);
    }
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    // 900 > 500 → geçersiz: filtreye dokunulmaz, uyarı çıkar.
    for (final t in ['9', '90', '900']) {
      await key(tester, t);
    }
    for (final t in ['90', '9', '', '4', '40', '400']) {
      await key(tester, t);
    }
    await tester.pumpAndSettle();

    expect(fieldText(tester, 0), '400');
    expect(fieldText(tester, 1), '500');
    expect(range.value, const PriceRangeFilter(minPrice: 400, maxPrice: 500));
  });

  testWidgets('dışarıdan temizlenince alanlar boşalır', (tester) async {
    final range = ValueNotifier<PriceRangeFilter?>(null);
    await tester.pumpWidget(host(range));
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await key(tester, '4');
    await key(tester, '40');
    expect(range.value?.minPrice, 40);

    range.value = null;
    await tester.pump();
    expect(fieldText(tester, 0), '');
  });
}
