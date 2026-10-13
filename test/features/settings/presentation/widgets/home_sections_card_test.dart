import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/main_feature/utils/section_records.dart';
import 'package:cunehat/features/main_feature/utils/section_visibility.dart';
import 'package:cunehat/features/settings/presentation/widgets/home_sections_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

class _MockRecords extends Mock implements SectionRecords {}

void main() {
  late SectionVisibility sections;
  late _MockRecords records;

  final savingsSwitch = find.byKey(const ValueKey('section-switch-savedMoney'));
  final debtSwitch = find.byKey(const ValueKey('section-switch-debt'));

  Future<void> pump(
    WidgetTester tester, {
    required bool existingInstall,
    bool savingsHasRecords = false,
    bool debtHasRecords = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    sections = SectionVisibility(await SharedPreferences.getInstance());
    await sections.ensureInitialized(existingInstall: existingInstall);
    records = _MockRecords();
    when(() => records.savingsHasRecords).thenReturn(savingsHasRecords);
    when(() => records.debtHasRecords).thenReturn(debtHasRecords);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeSectionsCard(sections: sections, records: records),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  SwitchListTile tile(WidgetTester tester, Finder finder) =>
      tester.widget<SwitchListTile>(finder);

  testWidgets('yeni kurulumda iki bölüm de kapalı görünür ve açılabilir',
      (tester) async {
    await pump(tester, existingInstall: false);

    expect(tile(tester, savingsSwitch).value, isFalse);
    expect(tile(tester, debtSwitch).value, isFalse);
    expect(tile(tester, savingsSwitch).onChanged, isNotNull);
    expect(find.text('Birikim'), findsOneWidget);
    expect(find.text('Borç ve alacak'), findsOneWidget);
  });

  testWidgets('anahtar bölümü açar; tercih kalıcıdır', (tester) async {
    await pump(tester, existingInstall: false);

    await tester.tap(savingsSwitch);
    await tester.pumpAndSettle();

    expect(sections.savingsEnabled, isTrue);
    expect(tile(tester, savingsSwitch).value, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SectionVisibility.savingsKey), isTrue);
  });

  testWidgets('kaydı olmayan açık bölüm kapatılabilir', (tester) async {
    await pump(tester, existingInstall: true);

    await tester.tap(debtSwitch);
    await tester.pumpAndSettle();

    expect(sections.debtEnabled, isFalse);
    expect(sections.enabledStates,
        {SliderState.savedMoney, SliderState.transactions});
  });

  testWidgets(
      'kaydı OLAN bölümün anahtarı kilitlidir ve NEDENİ yazar (sessizce '
      'gizlenmez)', (tester) async {
    await pump(tester, existingInstall: true, savingsHasRecords: true);

    expect(tile(tester, savingsSwitch).onChanged, isNull);
    expect(
      find.descendant(
        of: savingsSwitch,
        matching: find.textContaining('Kaydı olduğu için kapatılamaz'),
      ),
      findsOneWidget,
    );
    // Öteki bölüm bundan etkilenmez.
    expect(tile(tester, debtSwitch).onChanged, isNotNull);
    expect(
        find.textContaining('Kaydı olduğu için kapatılamaz'), findsOneWidget);
  });

  testWidgets('kilitli anahtara dokunmak bölümü kapatmaz', (tester) async {
    await pump(tester, existingInstall: true, debtHasRecords: true);

    await tester.tap(debtSwitch, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(sections.debtEnabled, isTrue);
  });

  testWidgets('bölüm başka yerden açılınca kart kendini yeniler',
      (tester) async {
    await pump(tester, existingInstall: false);

    await sections.enable(SliderState.debt);
    await tester.pump();

    expect(tile(tester, debtSwitch).value, isTrue);
  });
}
