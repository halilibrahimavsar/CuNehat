import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/core/shared/widgets/field_hint.dart';
import 'package:cunehat/core/shared/widgets/row_action_sheet.dart';
import 'package:cunehat/features/main_feature/utils/section_records.dart';
import 'package:cunehat/features/main_feature/utils/section_visibility.dart';
import 'package:cunehat/features/settings/presentation/widgets/home_sections_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/real_font.dart';

class _MockRecords extends Mock implements SectionRecords {}

/// Büyük yazı duman testi: yeni kullanıcının yolundaki ORTAK parçalar
/// 360×800'de, sistem yazı ölçeği 1,0 / 1,3 / 2,0 iken taşmadan kurulur.
///
/// Uygulamayı "herkes" kullanacaksa büyük yazı bir köşe durumu değildir:
/// Android'de yazıyı büyüten kişi çoğu zaman uygulamayı en zor okuyan
/// kişidir. Ölçek 2,0 Android'in sunduğu en büyük ayardır.
///
/// Bu dosya yalnız BAŞKA bir testi olmayan parçaları kurar. Aynı üç ölçek
/// şuralarda zaten ölçülüyor — yenisini oraya ekle, buraya kopyalama:
/// - karşılama ekranı → `welcome_view_test.dart` ("sığma")
/// - İşlemler sayfası → `transaction_page_smoke_test.dart`
/// - kayıt formu → `transaction_entry_sheet_test.dart` ("büyük yazı")
/// - Gelir/Gider çubuğu → `simple_action_bar_test.dart` ("sığma")
/// - boş durum → `empty_state_test.dart`
///
/// Ölçüm gerçek Roboto ve uygulamanın temasıyla yapılır: varsayılan test
/// fontu belirgin biçimde geniştir ve var olmayan taşmalar raporlar.
void main() {
  setUpAll(loadRealRoboto);

  const scales = [1.0, 1.3, 2.0];
  const size = Size(360, 800);

  /// [build] ile kurulan içerik boyunca çıkan BÜTÜN düzen hatalarını toplar;
  /// her birinin kaynak satırını failure mesajına koyar.
  Future<void> expectFits(
    WidgetTester tester, {
    required double scale,
    required Widget Function(BuildContext) build,
    Future<void> Function()? then,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final base = ThemeNames.all[ThemeNames.sysLight]!;
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: base.copyWith(
            textTheme: base.textTheme.apply(fontFamily: kRealFontFamily),
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          locale: const Locale('tr'),
          home: Scaffold(body: Builder(builder: build)),
        ),
      );
      await tester.pumpAndSettle();
      await then?.call();
    } finally {
      FlutterError.onError = previous;
    }

    expect(
      errors,
      isEmpty,
      reason: [
        for (final e in errors)
          '${e.exception.toString().split('\n').first}\n  '
              '${e.informationCollector?.call().map((n) => n.toString()).firstWhere((l) => l.contains('.dart:'), orElse: () => '(konum yok)') ?? '(konum yok)'}',
      ].join('\n'),
    );
  }

  for (final scale in scales) {
    group('yazı ölçeği $scale', () {
      testWidgets('▤ sayfası (Defter · İçgörü · Rapor · Transfer)',
          (tester) async {
        await expectFits(
          tester,
          scale: scale,
          build: (context) => Center(
            child: FilledButton(
              onPressed: () => RowActionSheet.show<int>(
                context,
                title: context.l10n.simpleBarSheetTitle,
                icon: Icons.bar_chart_rounded,
                accent: Theme.of(context).colorScheme.primary,
                actions: [
                  RowAction(
                    value: 0,
                    icon: Icons.receipt_long_rounded,
                    title: context.l10n.simpleBarLedger,
                    subtitle: context.l10n.simpleBarLedgerSubtitle,
                  ),
                  RowAction(
                    value: 1,
                    icon: Icons.insights_rounded,
                    title: 'İçgörü',
                    subtitle: context.l10n.simpleBarInsightsSubtitle,
                  ),
                  RowAction(
                    value: 2,
                    icon: Icons.pie_chart_rounded,
                    title: 'Rapor',
                    subtitle: context.l10n.simpleBarReportSubtitle,
                  ),
                  RowAction(
                    value: 3,
                    icon: Icons.swap_horiz_rounded,
                    title: context.l10n.transferKisa,
                    subtitle: context.l10n.simpleBarTransferSubtitle,
                  ),
                ],
              ),
              child: const Text('aç'),
            ),
          ),
          then: () async {
            await tester.tap(find.text('aç'));
            await tester.pumpAndSettle();
            expect(find.text('Nereye bakmak istersin?'), findsOneWidget);
            // Son satır da ekranda: büyük yazıda sayfa kaydırılabilir olsa
            // bile ilk bakışta dört seçenek görünmeli.
            expect(
              tester.getRect(find.text('Transfer')).bottom,
              lessThanOrEqualTo(size.height),
            );
          },
        );
      });

      testWidgets('silme onayı: iki düğme de ekranda', (tester) async {
        await expectFits(
          tester,
          scale: scale,
          build: (context) => Center(
            child: FilledButton(
              onPressed: () => ConfirmDialog.show(
                context,
                title: 'Kayıt silinsin mi?',
                message: 'Market · 150,00 ₺ kaydı silinecek ve cüzdan '
                    'bakiyen buna göre güncellenecek.',
                confirmText: 'Sil',
                danger: true,
              ),
              child: const Text('aç'),
            ),
          ),
          then: () async {
            await tester.tap(find.text('aç'));
            await tester.pumpAndSettle();
            for (final label in const ['Sil', 'İptal']) {
              final rect = tester.getRect(find.text(label));
              expect(rect.top, greaterThanOrEqualTo(0), reason: label);
              expect(rect.bottom, lessThanOrEqualTo(size.height),
                  reason: label);
              expect(rect.left, greaterThanOrEqualTo(0), reason: label);
              expect(rect.right, lessThanOrEqualTo(size.width), reason: label);
            }
          },
        );
      });

      testWidgets('Ayarlar > Bölümler kartı (biri kilitli)', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final sections = SectionVisibility(
          await SharedPreferences.getInstance(),
        );
        await sections.ensureInitialized(existingInstall: true);
        final records = _MockRecords();
        when(() => records.savingsHasRecords).thenReturn(true);
        when(() => records.debtHasRecords).thenReturn(false);

        await expectFits(
          tester,
          scale: scale,
          build: (_) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: HomeSectionsCard(sections: sections, records: records),
          ),
        );
      });

      testWidgets('alan açıklaması dar sütunda satır kırar', (tester) async {
        await expectFits(
          tester,
          scale: scale,
          build: (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TextField(),
                FieldHint(context.l10n.debtStartDateHint),
                const SizedBox(height: 16),
                const TextField(),
                FieldHint(context.l10n.receivableDueDateHint),
              ],
            ),
          ),
        );
      });
    });
  }
}
