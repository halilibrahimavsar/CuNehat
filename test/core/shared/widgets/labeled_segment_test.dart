import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/shared/widgets/labeled_segment.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transactions_section_tabs.dart';
import 'package:cunehat/features/main_feature/controllers/home_navigation_requests.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
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
          body: Center(
            child: SizedBox(
              width: width - 32,
              child: child,
            ),
          ),
        ),
      );

  group('LabeledSegment', () {
    testWidgets('dokunmak değeri bildirir; seçili hücre etkisizdir',
        (tester) async {
      final changes = <int>[];
      await tester.pumpWidget(host(LabeledSegment<int>(
        selected: 0,
        onChanged: changes.add,
        items: const [
          SegmentItem(value: 0, label: 'Gider'),
          SegmentItem(value: 1, label: 'Gelir'),
        ],
      )));
      await tester.tap(find.text('Gider'));
      await tester.tap(find.text('Gelir'));
      expect(changes, [1]);
    });

    testWidgets('sekme olarak: rol, seçili bayrağı ve dokunma eylemi',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(LabeledSegment<int>(
        asTabs: true,
        selected: 1,
        onChanged: (_) {},
        items: const [
          SegmentItem(value: 0, label: 'İşlemler'),
          SegmentItem(value: 1, label: 'İçgörü'),
        ],
      )));
      final selected = tester.getSemantics(find.text('İçgörü'));
      expect(selected.getSemanticsData().role, SemanticsRole.tab);
      expect(selected.flagsCollection.isSelected, Tristate.isTrue);
      // Seçili sekmenin de dokunma eylemi var (Flutter sekme rolünde ister).
      expect(selected.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue);
      handle.dispose();
    });

    for (final (width, scale) in [(320.0, 2.0), (360.0, 1.6), (411.0, 1.0)]) {
      testWidgets('${width.toInt()}dp / ölçek $scale — üç etiket taşmaz',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(host(
          const TransactionsSectionTabs(current: TransactionsSection.ledger),
          width: width,
          scale: scale,
        ));
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('sekme şeridi isteği kabuğa iletir', (tester) async {
    getIt.allowReassignment = true;
    final requests = HomeNavigationRequests();
    getIt.registerSingleton<HomeNavigationRequests>(requests);
    addTearDown(getIt.reset);
    final opened = <TransactionsSection>[];
    requests.sectionHandler = opened.add;

    await tester.pumpWidget(host(
        const TransactionsSectionTabs(current: TransactionsSection.ledger)));
    await tester.tap(find.text('Rapor'));
    await tester.tap(find.text('İçgörü'));
    expect(opened, [TransactionsSection.report, TransactionsSection.insights]);
  });
}
