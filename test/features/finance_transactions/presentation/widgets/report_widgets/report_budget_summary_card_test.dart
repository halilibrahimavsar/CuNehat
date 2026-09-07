import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_budget_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Bütçe limitleri AYLIKTIR (`BudgetEntity.limitAmount`).
///
/// Ölçülen hata: rapor kartı harcamayı SEÇİLİ ARALIKTAN, limiti ise aylık
/// tanımdan alıyordu. "Bu Yıl" seçiliyken 12 aylık harcama 1 aylık limite
/// bölünüyor ve kart "%340 aşıldı" derken Bütçeler sayfası aynı anda "%28"
/// diyordu — aynı bütçe, aynı veri, iki ekran, iki cevap.
void main() {
  setUpAll(() => Intl.defaultLocale = 'tr');

  Widget host(Widget child) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: 328, child: child),
          ),
        ),
      );

  const statuses = [
    BudgetStatus(categoryId: 'm', label: 'Market', spent: 1200, limit: 1000),
  ];

  testWidgets('aylık pencerede RAKAM gösterir', (tester) async {
    await tester.pumpWidget(host(ReportBudgetSummaryCard(
      statuses: statuses,
      monthScoped: true,
      onTap: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('Market'), findsOneWidget);
    expect(find.textContaining('aylıktır'), findsNothing);
  });

  testWidgets('ay olmayan aralıkta oran ÜRETMEZ, sebebini söyler',
      (tester) async {
    await tester.pumpWidget(host(ReportBudgetSummaryCard(
      // Aralık ay değilse çağıran zaten boş liste verir; kart yine de
      // sebebini söylemeli.
      statuses: const [],
      monthScoped: false,
      onTap: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('aylıktır'), findsOneWidget);
    // Yanıltıcı bir yüzde ya da tutar KALMAMALI.
    expect(find.textContaining('%'), findsNothing);
    expect(find.textContaining('₺'), findsNothing);
  });

  testWidgets('bölüm KAYBOLMAZ — kullanıcı bütçesini silinmiş sanmasın',
      (tester) async {
    // Kart, ay olmayan aralıkta `SizedBox.shrink()` döndürseydi rapor
    // sayfasındaki "Bütçe durumu" başlığı altı bomboş kalırdı.
    await tester.pumpWidget(host(ReportBudgetSummaryCard(
      statuses: const [],
      monthScoped: false,
      onTap: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(ReportBudgetSummaryCard)).height,
        greaterThan(0));
  });

  testWidgets('bütçe yokken (aylık pencerede) hiç çizilmez', (tester) async {
    await tester.pumpWidget(host(ReportBudgetSummaryCard(
      statuses: const [],
      monthScoped: true,
      onTap: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(ReportBudgetSummaryCard)).height, 0);
  });
}
