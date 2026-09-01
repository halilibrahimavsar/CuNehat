import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bölüm başlığı + çözünürlük seçicisi.
///
/// Başlık satırı [Row] iken metin ölçeği 1.5'te (TR) ve 1.3'te (EN, daha uzun
/// "Category Distribution") taşıyordu — gerçek Roboto ile ölçüldü. [Wrap]
/// taşmak yerine alt satıra iner.
void main() {
  Widget host(
    Widget child, {
    double width = 360,
    double textScale = 1.0,
    Locale locale = const Locale('tr'),
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr'), Locale('en')],
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: width - 32, child: child),
        ),
      ),
    );
  }

  group('ReportSectionHeader', () {
    testWidgets('kontrol yokken yalnız başlık çizilir', (tester) async {
      await tester.pumpWidget(host(
        const ReportSectionHeader(title: 'Kategori Dağılımı'),
      ));
      expect(find.text('Kategori Dağılımı'), findsOneWidget);
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('büyük metin ölçeğinde taşmaz, alt satıra iner',
        (tester) async {
      await tester.pumpWidget(host(
        textScale: 1.5,
        ReportSectionHeader(
          title: 'Kategori Dağılımı',
          trailing: Container(width: 144, height: 44, color: Colors.blue),
        ),
      ));
      await tester.pump();

      // Taşma olsaydı FlutterError.onError bir exception yakalardı.
      expect(tester.takeException(), isNull);
      final wrapSize = tester.getSize(find.byType(Wrap));
      expect(wrapSize.width, lessThanOrEqualTo(328));
      // İki satıra inmiş olmalı: başlık + kontrol ayrı runlarda.
      expect(wrapSize.height, greaterThan(44));
    });

    testWidgets('sığdığında tek satırda ve iki uca yaslı', (tester) async {
      await tester.pumpWidget(host(
        ReportSectionHeader(
          title: 'Rapor',
          trailing: Container(width: 100, height: 44, color: Colors.blue),
        ),
      ));
      await tester.pump();
      expect(tester.getSize(find.byType(Wrap)).height, 44);
    });
  });

  group('ReportUnitSelector', () {
    Map<ReportBucketUnit, int> counts(int day, int week, int month) => {
          ReportBucketUnit.day: day,
          ReportBucketUnit.week: week,
          ReportBucketUnit.month: month,
        };

    testWidgets('üç seçenek de yazılır', (tester) async {
      await tester.pumpWidget(host(ReportUnitSelector(
        selected: ReportBucketUnit.day,
        onChanged: (_) {},
        bucketCounts: counts(30, 5, 2),
      )));
      expect(find.text('Gün'), findsOneWidget);
      expect(find.text('Hafta'), findsOneWidget);
      expect(find.text('Ay'), findsOneWidget);
    });

    testWidgets('çok yoğun çözünürlük KAPALI — okunmaz grafik seçenek değil',
        (tester) async {
      ReportBucketUnit? picked;
      await tester.pumpWidget(host(ReportUnitSelector(
        selected: ReportBucketUnit.month,
        onChanged: (u) => picked = u,
        // Bir yıl: 365 gün / 53 hafta / 12 ay.
        bucketCounts: counts(365, 53, 12),
      )));

      await tester.tap(find.text('Gün'));
      await tester.pump();
      expect(picked, isNull, reason: '365 çubuk çizilemez');

      await tester.tap(find.text('Hafta'));
      await tester.pump();
      expect(picked, ReportBucketUnit.week);
    });

    testWidgets('tek kovaya inen çözünürlük de KAPALI', (tester) async {
      ReportBucketUnit? picked;
      await tester.pumpWidget(host(ReportUnitSelector(
        selected: ReportBucketUnit.day,
        onChanged: (u) => picked = u,
        // "Bu Ay": 30 gün / 5 hafta / 1 ay → "Ay" tek çubuk çizerdi.
        bucketCounts: counts(30, 5, 1),
      )));

      await tester.tap(find.text('Ay'));
      await tester.pump();
      expect(picked, isNull);
    });
  });
}
