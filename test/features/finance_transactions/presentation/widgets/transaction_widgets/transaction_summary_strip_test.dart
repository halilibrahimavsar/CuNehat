import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_summary_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

/// Ana ekranın dönem özeti, rapor sayfasıyla AYNI evreni kullanmak zorundadır.
///
/// Ölçülen hata: `filterLedger` `isSystem` süzmediği için nakitten bankaya
/// 20.000 ₺ taşımak bu kartta "Gider 20.000 ₺" yazdırıyordu; bir kaydırma
/// ötedeki rapor aynı dönem için 0 diyordu. Rapor sayfası bu dersi
/// öğrenmişti, ana ekran öğrenmemişti — ve hiçbir test onu ölçmüyordu.
void main() {
  setUpAll(() => Intl.defaultLocale = 'tr');

  final month = monthRangeOf(DateTime(2026, 9, 1));

  CombinedFilter filter({FinanceMode mode = FinanceMode.compare}) =>
      CombinedFilter(
        viewFilter: ViewFilter(
          financeMode: mode,
          startDate: month.start,
          endDate: month.end,
        ),
        dataFilter: const DataFilter(),
      );

  TransactionEntity tx(
    double amount,
    TransactionTypeModel type, {
    bool isSystem = false,
    String title = 'kalem',
  }) =>
      TransactionEntity(
        id: null,
        userId: 'u',
        walletId: 'w',
        title: title,
        tag: 'cat',
        amount: amount,
        date: DateTime(2026, 9, 4),
        type: type,
        isSystem: isSystem,
      );

  Widget wrap(Widget child, {double width = 360}) {
    return BlocProvider<AmountVisibilityCubit>(
      create: (_) => AmountVisibilityCubit(),
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

  Widget strip(List<TransactionEntity> txs,
          {FinanceMode mode = FinanceMode.compare}) =>
      TransactionSummaryStrip(
        transactions: txs,
        mode: mode,
        filter: filter(mode: mode),
        periodLabel: 'Eylül 2026',
      );

  testWidgets('transfer GİDERE sayılmaz — rapor sayfasıyla aynı evren',
      (tester) async {
    final txs = [
      tx(150, TransactionTypeModel.expense),
      // Kuplaj: nakitten bankaya taşınan para. Harcanmadı, yer değiştirdi.
      tx(20000, TransactionTypeModel.expense,
          isSystem: true, title: 'Transfer → Banka'),
    ];

    await tester.pumpWidget(wrap(strip(txs, mode: FinanceMode.expense)));
    await tester.pumpAndSettle();

    // Manşet gideri gösterir: 150,00 ₺ — 20.150,00 ₺ değil.
    expect(find.text('150,00 ₺'), findsWidgets);
    expect(find.text('20.150,00 ₺'), findsNothing,
        reason: 'transfer gidere sayıldı');

    // Ve aynı evrenle hesaplanan rapor toplamıyla BİREBİR uyuşur.
    const service = TransactionReportService();
    final reportTotals =
        service.calculateTotals(service.splitSystemMovements(txs).spending);
    expect(reportTotals.totalExpense, 150);
  });

  testWidgets('dışarıda bırakılan kuplaj hareketi sayısı SÖYLENİR',
      (tester) async {
    await tester.pumpWidget(wrap(strip([
      tx(150, TransactionTypeModel.expense),
      tx(20000, TransactionTypeModel.expense, isSystem: true),
    ])));
    await tester.pumpAndSettle();

    // Sessizce düşürmek "giderim nereye gitti" sorusunu doğurur.
    // Metin "kuplaj" DEMEZ: son kullanıcı sözlüğünde böyle bir kelime yok.
    expect(find.textContaining('para taşıma hareketi'), findsOneWidget);
    expect(find.textContaining('1 para taşıma'), findsOneWidget);
    expect(find.textContaining('kuplaj'), findsNothing);
  });

  testWidgets('kuplaj yokken dipnot da yok (kart şişmez)', (tester) async {
    await tester.pumpWidget(wrap(strip([
      tx(150, TransactionTypeModel.expense),
    ])));
    await tester.pumpAndSettle();

    expect(find.textContaining('para taşıma hareketi'), findsNothing);
  });

  testWidgets('net de kuplajsız hesaplanır', (tester) async {
    await tester.pumpWidget(wrap(strip([
      tx(1000, TransactionTypeModel.income),
      tx(400, TransactionTypeModel.expense),
      // Borç ödemesi kuplajı: nette görünmemeli.
      tx(5000, TransactionTypeModel.expense, isSystem: true),
    ])));
    await tester.pumpAndSettle();

    // net = 1000 − 400 = 600 (−4.400 değil)
    expect(find.text('600,00 ₺'), findsWidgets);
    expect(find.textContaining('4.400'), findsNothing);
  });
}
