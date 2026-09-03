import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/services/daily_spending_summary_service.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_day_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Gün şeridi, kaldırılan ay ızgarasının yerine geçti. Izgaranın iki ölçülmüş
/// kusurunu tekrarlamamalı:
///  1. tutar 8,5px yazıyla çiziliyordu (okunmuyordu),
///  2. ısı GİDERİ boyuyor ama yazı NETİ söylüyordu — 48,8K'lık bir gelir günü
///     hiç boyanmadığı için görünmez oluyordu.
void main() {
  setUpAll(() => Intl.defaultLocale = 'tr');

  final month = monthRangeOf(DateTime(2026, 9, 1));

  Widget wrap(Widget child,
      {double width = 360, AmountVisibilityCubit? visibility}) {
    return BlocProvider<AmountVisibilityCubit>(
      create: (_) => visibility ?? AmountVisibilityCubit(),
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: Scaffold(body: SizedBox(width: width, child: child)),
      ),
    );
  }

  TransactionDayRail rail({
    Map<DateTime, DaySummary> summaries = const {},
    DateTime? selected,
    void Function(DateTime)? onTap,
    DateTimeRange? range,
  }) {
    return TransactionDayRail(
      range: range ?? month,
      summaries: summaries,
      selectedDay: selected,
      onDaySelected: onTap ?? (_) {},
    );
  }

  testWidgets('dönemin tüm günlerini taşır — veri olmayan günler dahil',
      (tester) async {
    // Yalnız işlem olan günleri göstermek "o gün hiç harcamadım"ı
    // "o gün yok"tan ayırt edilemez yapardı.
    await tester.pumpWidget(wrap(rail(summaries: {
      DateTime(2026, 9, 4): const DaySummary(expense: 100, count: 1),
    })));
    await tester.pumpAndSettle();

    for (final day in ['1', '2', '3', '4', '5']) {
      expect(find.text(day), findsOneWidget, reason: '$day. gün eksik');
    }
  });

  testWidgets('gider çubuğu dönemin en yüksek gününe göre ölçeklenir',
      (tester) async {
    // Normalizasyon dönem içi olmalı: her dönem kendi içinde okunur kalsın.
    await tester.pumpWidget(wrap(rail(summaries: {
      DateTime(2026, 9, 1): const DaySummary(expense: 1000, count: 1),
      DateTime(2026, 9, 2): const DaySummary(expense: 100, count: 1),
    })));
    await tester.pumpAndSettle();

    double barHeightOfDay(String day) {
      final cell = find.ancestor(
        of: find.text(day),
        matching: find.byType(Column),
      );
      final bars = find.descendant(
        of: cell.first,
        matching: find.byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).borderRadius ==
                BorderRadius.circular(3)),
      );
      return tester.getSize(bars.last).height;
    }

    final tall = barHeightOfDay('1');
    final short = barHeightOfDay('2');
    expect(tall, greaterThan(short));
    // 1000 vs 100 → belirgin fark; oran karışırsa ikisi de aynı çıkar.
    expect(tall, greaterThan(short * 2));
  });

  testWidgets('gelir günü AYRI kanalda işaretlenir (çubuk yalnız gideri ölçer)',
      (tester) async {
    // Eski hücrede gelir günü hiç boyanmıyordu: ısı gideri, yazı neti
    // anlatıyordu ve ikisi aynı 23dp'lik kutuda çakışıyordu.
    await tester.pumpWidget(wrap(rail(summaries: {
      DateTime(2026, 9, 1): const DaySummary(income: 50000, count: 1),
    })));
    await tester.pumpAndSettle();

    final cell =
        find.ancestor(of: find.text('1'), matching: find.byType(Column)).first;
    final dot = find.descendant(
      of: cell,
      matching: find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).shape == BoxShape.circle),
    );
    expect(dot, findsOneWidget, reason: 'gelir noktası yok');

    // Gelir günü için gider çubuğu ÇİZİLMEMELİ.
    final bars = find.descendant(
      of: cell,
      matching: find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).borderRadius ==
              BorderRadius.circular(3)),
    );
    expect(bars, findsNothing);
  });

  testWidgets('ekran okuyucu GERÇEK rakamları duyar', (tester) async {
    // Çubuk geometridir; sesli okuyucu onu göremez.
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(rail(summaries: {
      DateTime(2026, 9, 4): const DaySummary(expense: 250, count: 2),
    })));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp(r'4 Eylül.*250,00 ₺.*2')),
      findsOneWidget,
    );
    // Veri olmayan gün de kendini söylemeli.
    expect(
        find.bySemanticsLabel(RegExp(r'5 Eylül.*işlem yok')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('ekran okuyucu hücreyi ETKİNLEŞTİREBİLİR', (tester) async {
    // Rol yetmez, EYLEM de gerekir. `excludeSemantics: true` alt ağacın
    // semantiklerini tümden düşürdüğü için InkWell'in tap eylemi kayboluyordu:
    // hücre "düğme" diye duyuruluyor ama çift dokunma hiçbir şey yapmıyordu
    // (ölçüldü: isButton true, hasAction(tap) false). Şerit, defteri bir güne
    // kaydırmanın TEK yolu olduğundan bu özelliği tamamen erişilemez yapıyordu.
    final handle = tester.ensureSemantics();
    DateTime? tapped;
    await tester.pumpWidget(wrap(rail(onTap: (d) => tapped = d)));
    await tester.pumpAndSettle();

    // `semantics.tap` eylemi desteklenmiyorsa StateError atar.
    tester.semantics.tap(find.semantics.byLabel(RegExp(r'^3 Eylül 2026')));
    expect(tapped, DateTime(2026, 9, 3));
    handle.dispose();
  });

  testWidgets('tutarlar gizliyken etiket de maskelenir', (tester) async {
    // Hücrede rakam çizilmediği için göz düğmesi kapatıldığında ekran görsel
    // olarak temiz görünüyor; etiket `formatMoney`'yi doğrudan çağırdığı sürece
    // ekran okuyucu gerçek tutarı okumaya devam ediyordu, yani gizleme yalnız
    // GÖZE uygulanıyordu.
    SharedPreferences.setMockInitialValues({});
    final visibility = AmountVisibilityCubit();
    await visibility.setVisibility(false);

    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(
      rail(summaries: {
        DateTime(2026, 9, 4): const DaySummary(expense: 250, count: 2),
      }),
      visibility: visibility,
    ));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp(r'4 Eylül.*250,00')), findsNothing);
    expect(find.bySemanticsLabel(RegExp(r'4 Eylül.*\*\*\*\*')), findsOneWidget);
    handle.dispose();
    await visibility.close();
  });

  testWidgets('bir güne dokunmak o günü bildirir', (tester) async {
    DateTime? tapped;
    await tester.pumpWidget(wrap(rail(onTap: (d) => tapped = d)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('3'));
    expect(tapped, DateTime(2026, 9, 3));
  });

  testWidgets('yıllık dönemde 365 hücre kurar (tembel)', (tester) async {
    // Eski takvim yıllık dönemi gösteremiyordu; üstelik sayfa çevirmek onu
    // sessizce tek aya düşürüyordu.
    await tester
        .pumpWidget(wrap(rail(range: yearRangeOf(DateTime(2026, 6, 1)))));
    await tester.pumpAndSettle();

    final list = tester.widget<ListView>(find.byType(ListView));
    expect(
        (list.childrenDelegate as SliverChildBuilderDelegate).childCount, 365);
  });
}
