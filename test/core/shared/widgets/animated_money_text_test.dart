import 'package:cunehat/core/shared/widgets/animated_money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:unified_flutter_features/amount_visibility.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
    Intl.defaultLocale = 'tr';
  });
  tearDownAll(() => Intl.defaultLocale = null);

  Widget host({
    required double amount,
    Object identity = 'w1|transactions',
    bool reduceMotion = false,
  }) =>
      BlocProvider<AmountVisibilityCubit>(
        create: (_) => AmountVisibilityCubit(),
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: Scaffold(
              body: AnimatedMoneyText(
                amount: amount,
                currency: 'TRY',
                identity: identity,
              ),
            ),
          ),
        ),
      );

  /// Ekrandaki tutarın sayı değeri ("1.234,50 ₺" → 1234.5).
  double shown(WidgetTester tester) {
    final text = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((s) => s.contains(RegExp(r'\d')));
    final digits =
        text.replaceAll(RegExp(r'[^0-9,\-]'), '').replaceAll(',', '.');
    return double.parse(digits);
  }

  testWidgets('ilk kurulumda sayılmaz: tutar doğrudan yazılır', (tester) async {
    await tester.pumpWidget(host(amount: 1000));

    expect(shown(tester), 1000);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('aynı cüzdanın tutarı değişince eskisinden yenisine sayar',
      (tester) async {
    await tester.pumpWidget(host(amount: 1000));

    await tester.pumpWidget(host(amount: 850));
    await tester.pump();
    expect(shown(tester), 1000, reason: 'ilk karede eski değerden başlar');

    await tester.pump(AnimatedMoneyText.duration ~/ 2);
    expect(shown(tester), inExclusiveRange(850, 1000));

    await tester.pumpAndSettle();
    expect(shown(tester), 850);
  });

  testWidgets('sayma yarım saniyede biter', (tester) async {
    await tester.pumpWidget(host(amount: 0));
    await tester.pumpWidget(host(amount: -150));

    await tester.pump();
    // Denetleyici TAM süresinde değil, süreyi geçen ilk karede durur.
    await tester.pump(
      AnimatedMoneyText.duration + const Duration(milliseconds: 1),
    );
    await tester.pump();

    expect(shown(tester), -150);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('başka cüzdana geçince sayılmaz', (tester) async {
    await tester.pumpWidget(host(amount: 1000));

    await tester
        .pumpWidget(host(amount: 61251.37, identity: 'w2|transactions'));
    await tester.pump();

    expect(shown(tester), 61251.37);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('sayma sürerken yeni kayıt gelirse görünen rakamdan devam eder',
      (tester) async {
    await tester.pumpWidget(host(amount: 1000));
    await tester.pumpWidget(host(amount: 800));
    await tester.pump();
    await tester.pump(AnimatedMoneyText.duration ~/ 2);
    final mid = shown(tester);

    await tester.pumpWidget(host(amount: 700));
    await tester.pump();

    expect(shown(tester), closeTo(mid, 0.01), reason: 'geri sıçramaz');
    await tester.pumpAndSettle();
    expect(shown(tester), 700);
  });

  testWidgets('"animasyonları kaldır" açıkken tutar doğrudan yazılır',
      (tester) async {
    await tester.pumpWidget(host(amount: 1000, reduceMotion: true));

    await tester.pumpWidget(host(amount: 850, reduceMotion: true));
    await tester.pump();

    expect(shown(tester), 850);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
