import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/real_font.dart';

void main() {
  setUpAll(loadRealRoboto);

  Future<void> pump(
    WidgetTester tester, {
    String? body = 'Kategorilerine aylık harcama sınırı koy.',
    List<Widget> actions = const [],
    double textScale = 1.0,
    double width = 360,
  }) async {
    tester.view.physicalSize = Size(width, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final theme = ThemeNames.all[ThemeNames.sysLight]!;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: kRealFontFamily),
        ),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 640),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: Icons.savings_outlined,
                  title: 'Henüz bütçe yok',
                  body: body,
                  actions: actions,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('başlık, tek cümle ve simge', (tester) async {
    await pump(tester);

    expect(find.text('Henüz bütçe yok'), findsOneWidget);
    expect(
        find.text('Kategorilerine aylık harcama sınırı koy.'), findsOneWidget);
    expect(find.byIcon(Icons.savings_outlined), findsOneWidget);
  });

  testWidgets('açıklama isteğe bağlıdır', (tester) async {
    await pump(tester, body: null);

    expect(find.text('Henüz bütçe yok'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('eylemler verilen sırayla, başlığın altında durur',
      (tester) async {
    await pump(tester, actions: [
      FilledButton(onPressed: () {}, child: const Text('Bütçe ekle')),
      TextButton(onPressed: () {}, child: const Text('Daha sonra')),
    ]);

    final title = tester.getCenter(find.text('Henüz bütçe yok')).dy;
    final first = tester.getCenter(find.text('Bütçe ekle')).dy;
    final second = tester.getCenter(find.text('Daha sonra')).dy;
    expect(first, greaterThan(title));
    expect(second, greaterThan(first));
  });

  testWidgets('simge süs: ekran okuyucuya okunmaz', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    expect(find.bySemanticsLabel('Henüz bütçe yok'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byIcon(Icons.savings_outlined),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  for (final width in const [320.0, 360.0]) {
    for (final scale in const [1.0, 1.3, 2.0]) {
      testWidgets('${width.toInt()}dp, yazı ölçeği $scale: taşma yok',
          (tester) async {
        final errors = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        FlutterError.onError = errors.add;
        try {
          await pump(tester, width: width, textScale: scale, actions: [
            FilledButton(onPressed: () {}, child: const Text('Bütçe ekle')),
          ]);
        } finally {
          FlutterError.onError = previous;
        }
        expect(errors, isEmpty,
            reason: errors.isEmpty ? '' : '${errors.first.exception}');
      });
    }
  }
}
