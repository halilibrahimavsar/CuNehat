import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/shared/widgets/app_date_range_picker.dart';
import 'package:cunehat/core/utils/date_range_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Dönem seçicinin hızlı menüsü.
///
/// Menü rapor ve içgörüler sayfalarının dönem kontrolüdür: ay çubuğundaki
/// etikete dokunmak burayı açar ve özel aralığa ("Takvimden seç") giden TEK
/// yol bu listenin son satırıdır. Satır ekrana sığmazsa özel aralık seçilemez.
void main() {
  setUpAll(() => Intl.defaultLocale = 'tr');

  Widget host() => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => AppDateRangePicker.pick(
                  context,
                  quickOptions: DateRangeHelper.buildDateRangeQuickOptions(
                      AppLocalizations.of(context)!),
                ),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      );

  testWidgets(
      'REGRESYON: küçük telefonda "Takvimden seç" gezinme çubuğunun ALTINDA '
      'kalmaz', (tester) async {
    // 360×640 + 48dp gezinme çubuğu. Ölçüldü: `showModalBottomSheet`'in
    // varsayılan tavanı (ekranın 9/16'sı) yüzünden sütun **92px taşıyor**,
    // son satır 620→676'ya, yani ekranın 36px DIŞINA düşüyordu.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    tester.view.padding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);

    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.exceptionAsString());

    await tester.pumpWidget(host());
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    FlutterError.onError = previous;
    expect(errors, isEmpty, reason: '$errors');

    // Beş hızlı seçenek + "Takvimden seç".
    final tiles = find.byType(ListTile);
    expect(tiles, findsNWidgets(6));
    expect(find.text('Takvimden seç'), findsOneWidget);

    const safeBottom = 640.0 - 48.0;
    expect(
      tester.getRect(tiles.last).bottom,
      lessThanOrEqualTo(safeBottom),
      reason: 'son satır gezinme çubuğunun altında kalıyor',
    );
  });

  testWidgets('hızlı seçenek seçilince aralık döner, takvim açılmaz',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bu Ay'));
    await tester.pumpAndSettle();

    expect(find.byType(DateRangePickerDialog), findsNothing);
    expect(find.byType(ListTile), findsNothing);
  });
}
