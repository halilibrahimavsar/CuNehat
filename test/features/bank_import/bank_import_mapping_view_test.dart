import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/bank_import/data/column_mapper.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/domain/column_mapping.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/bank_import/presentation/pages/bank_import_mapping_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

class MockBankImportCubit extends MockCubit<BankImportState>
    implements BankImportCubit {}

void main() {
  setUpAll(() {
    Intl.defaultLocale = 'tr';
    registerFallbackValue(const ColumnMapping(dateCol: -1, descCol: -1));
  });

  final mapper = ColumnMapper();
  late MockBankImportCubit cubit;

  setUp(() {
    cubit = MockBankImportCubit();
    when(() => cubit.updateMapping(any())).thenReturn(null);
    when(() => cubit.applyMapping()).thenAnswer((_) async {});
  });

  // Görünüm hangi durumda açılırsa açılsın aynı çizilir; güvenilirlik kararı
  // cubit'te (bkz. bank_import_mapping_flow_test).
  const table = RawTable([
    ['Tarih', 'Açıklama', 'Tutar', 'Bakiye'],
    ['01.07.2026', 'MARKET', '-100,00', '900,00'],
    ['02.07.2026', 'MAAS', '1.000,00', '1.900,00'],
    ['03.07.2026', 'KIRA', '-500,00', '1.400,00'],
  ]);

  BankImportMapping stateFor(RawTable t, ColumnMapping m) =>
      BankImportMapping(table: t, assessment: mapper.assess(t, m));

  Future<void> pump(WidgetTester tester, BankImportMapping state) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: BlocProvider<BankImportCubit>.value(
            value: cubit,
            child: BankImportMappingView(state: state),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('önce SONUÇ: kaç hareket, kaçı gelir/gider, ilk satırlar',
      (tester) async {
    await pump(tester, stateFor(table, mapper.guess(table)));

    expect(find.text('Dosyayı nasıl okuyalım?'), findsOneWidget);
    expect(find.text('3 hareket okunacak · 1 gelir, 2 gider'), findsOneWidget);
    expect(find.text('MARKET'), findsWidgets);
    // Eski ekranın teknik soruları yok.
    expect(find.text('Tutar işareti'), findsNothing);
    expect(find.text('Tarih biçimi'), findsNothing);
  });

  testWidgets('eksik rol devam etmeyi engeller ve sade dille söylenir',
      (tester) async {
    final noDate = mapper.guess(table).withRole(0, ColumnRole.ignore);
    await pump(tester, stateFor(table, noDate));

    expect(find.text('Tarih sütununu seç'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('sütuna dokun → "bu sütun ne?" → seçim eşlemeye yansır',
      (tester) async {
    final m = mapper.guess(table);
    await pump(tester, stateFor(table, m));

    await tester.ensureVisible(find.text('Tutar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tutar'));
    await tester.pumpAndSettle();
    expect(find.text('“Tutar” sütunu ne?'), findsOneWidget);
    await tester.tap(find.text('Giden para'));
    await tester.pumpAndSettle();

    final captured =
        verify(() => cubit.updateMapping(captureAny())).captured.single;
    final col = table.rows.first.indexOf('Tutar');
    expect(captured, m.withRole(col, ColumnRole.debit));
  });

  testWidgets('tarih sırası belirsizse örnekle sorulur', (tester) async {
    const us = RawTable([
      ['Date', 'Description', 'Amount'],
      ['03/04/2026', 'A', '-10.00'],
      ['05/04/2026', 'B', '-20.00'],
    ]);
    final m = mapper.guess(us);
    await pump(tester, stateFor(us, m));

    expect(find.textContaining('“03/04/2026” biçiminde'), findsOneWidget);
    await tester.tap(find.text('4 Mart 2026'));
    await tester.pump();

    final captured = verify(() => cubit.updateMapping(captureAny()))
        .captured
        .single as ColumnMapping;
    expect(captured.dateFormat, StatementDateFormat.monthFirst);
  });

  testWidgets('"Devam" onaylanan eşlemeyi uygular', (tester) async {
    await pump(tester, stateFor(table, mapper.guess(table)));
    await tester.tap(find.text('Devam'));
    verify(() => cubit.applyMapping()).called(1);
  });

  testWidgets('dar ekranda (360dp) taşmaz', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const wide = RawTable([
      [
        'Islem Tarihi ve Saati',
        'Aciklama Metni Cok Uzun',
        'Tutar (TL)',
        'Kalan'
      ],
      ['01/07/2026', 'COK UZUN BIR ACIKLAMA METNI BURADA', '-100,00', '900,00'],
      ['02/07/2026', 'IKINCI', '-10,00', '890,00'],
    ]);
    await pump(tester, stateFor(wide, mapper.guess(wide)));
    expect(tester.takeException(), isNull);
  });
}
