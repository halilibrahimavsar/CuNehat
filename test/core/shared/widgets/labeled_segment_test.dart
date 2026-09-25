import 'dart:ui' show SemanticsAction, Tristate;

import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/shared/widgets/labeled_segment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/real_font.dart';

void main() {
  setUpAll(loadRealRoboto);

  Widget host(Widget child, {double width = 360, double scale = 1.0}) =>
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        theme: ThemeData(fontFamily: kRealFontFamily),
        builder: (context, inner) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: inner!,
        ),
        home: Scaffold(
          body: Center(child: SizedBox(width: width - 32, child: child)),
        ),
      );

  LabeledSegment<int> segment(List<int> changes, {int selected = 0}) =>
      LabeledSegment<int>(
        selected: selected,
        onChanged: changes.add,
        items: const [
          SegmentItem(value: 0, label: 'Göster'),
          SegmentItem(value: 1, label: 'Gizle'),
          SegmentItem(value: 2, label: 'Yalnız bunlar'),
        ],
      );

  testWidgets('dokunmak değeri bildirir; seçili hücre etkisizdir',
      (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(host(segment(changes)));
    await tester.tap(find.text('Göster'));
    await tester.tap(find.text('Gizle'));
    expect(changes, [1]);
  });

  testWidgets('ekran okuyucu: düğme, seçili bayrağı ve dokunma eylemi',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(segment([], selected: 1)));
    final data = tester.getSemantics(find.text('Gizle')).getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.flagsCollection.isSelected, Tristate.isTrue);
    handle.dispose();
  });

  for (final (width, scale) in [(320.0, 2.0), (360.0, 1.6), (411.0, 1.0)]) {
    testWidgets('${width.toInt()}dp / ölçek $scale — üç etiket taşmaz',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(segment([]), width: width, scale: scale));
      expect(tester.takeException(), isNull);
    });
  }
}
