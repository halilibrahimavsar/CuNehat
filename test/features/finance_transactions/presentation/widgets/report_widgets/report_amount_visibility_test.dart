import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_chart_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_compare_chart_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_cumulative_balance_chart.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_daily_net_flow_chart.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_summary_cards.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:unified_flutter_features/amount_visibility.dart';

/// Uygulama çubuğundaki göz düğmesi (`AmountVisibilityButton`) tutarları
/// gizlerken rapor sayfası bunu TAMAMEN es geçiyordu: cüzdan başlığı ve işlem
/// listesi maskeleniyor, kullanıcı rapora kaydırınca her sayı açıkta kalıyordu.
///
/// Sebep yapısaldı: fl_chart tooltip'i ve l10n şablonları widget değil `String`
/// ister, bu yüzden rapor `formatMoney`'yi doğrudan çağırıyordu ve
/// `MoneyText`'in görünürlük sarmalayıcısına hiç uğramıyordu. Çözüm
/// `MoneyWriter` — bu dosya onun rapor genelinde gerçekten uygulandığını
/// sabitler.
class _FixedVisibilityCubit extends Cubit<bool>
    implements AmountVisibilityCubit {
  _FixedVisibilityCubit(super.initialState);

  @override
  Future<void> setVisibility(bool isVisible) async => emit(isVisible);

  @override
  Future<void> toggleVisibility() async => emit(!state);
}

void main() {
  setUpAll(() => Intl.defaultLocale = 'tr');

  Widget host(Widget child, {required bool visible, double width = 400}) {
    return BlocProvider<AmountVisibilityCubit>(
      create: (_) => _FixedVisibilityCubit(visible),
      child: MaterialApp(
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
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );
  }

  TransactionEntity tx(DateTime d, double a, bool income) => TransactionEntity(
        id: 'tx-${d.day}-$a-$income',
        userId: 'u',
        walletId: 'w',
        title: 'T',
        tag: 'Market',
        amount: a,
        date: d,
        type: income
            ? TransactionTypeModel.income
            : TransactionTypeModel.expense,
      );

  /// 6.200 gelir + 1.500 gider, iki günlük seri.
  ReportSeries flowSeries() => const ReportSeriesService().build(
        inRange: [
          tx(DateTime(2026, 6, 1), 6200, true),
          tx(DateTime(2026, 6, 2), 1500, false),
        ],
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 2),
      );

  List<CategoryData> slices() => [
        CategoryData('Market', 1200, [tx(DateTime(2026, 6, 2), 1200, false)],
            Colors.red),
        CategoryData('Ulaşım', 300, [tx(DateTime(2026, 6, 3), 300, false)],
            Colors.orange),
      ];

  /// Ekrandaki tüm metinler.
  Iterable<String> texts(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .where((t) => t.isNotEmpty);

  group('göz düğmesi kapalıyken', () {
    testWidgets('özet kartlarındaki tutarlar maskelenir', (tester) async {
      await tester.pumpWidget(host(
        visible: false,
        const Padding(
          padding: EdgeInsets.all(16),
          child: ReportSummaryCards(
            totals: ReportTotals(
                totalIncome: 6200, totalExpense: 1500, net: 4700),
            previousTotals: ReportTotals(),
          ),
        ),
      ));
      await tester.pump();

      final all = texts(tester).toList();
      expect(all.where((t) => t.contains('6.200')), isEmpty);
      expect(all.where((t) => t.contains('1.500')), isEmpty);
      expect(all.where((t) => t.contains('4.700')), isEmpty);
      expect(find.text('**** ₺'), findsNWidgets(3));
    });

    testWidgets('karşılaştırma kartının toplamları ve efsanesi maskelenir',
        (tester) async {
      await tester.pumpWidget(host(
        visible: false,
        ReportCompareChartCard(
          incomeSlices: [
            CategoryData('Maaş', 6200, [tx(DateTime(2026, 6, 1), 6200, true)],
                Colors.green),
          ],
          expenseSlices: slices(),
          onSliceTap: (_, __) {},
        ),
      ));
      await tester.pump();

      final all = texts(tester).toList();
      expect(all.where((t) => t.contains('6.200')), isEmpty,
          reason: 'taraf toplamı ve "En büyük: ..." satırı da maskelenmeli');
      expect(all.where((t) => t.contains('1.200')), isEmpty,
          reason: 'efsane satırındaki tutar maskelenmeli');
      // Yüzdeler tutar DEĞİL: gizlenmezler, kırılım okunur kalır.
      expect(all.any((t) => t.contains('%80')), isTrue);
    });

    testWidgets('pasta kartının toplamı ve efsanesi maskelenir',
        (tester) async {
      await tester.pumpWidget(host(
        visible: false,
        ReportCategoryChartCard(
          title: 'Giderler',
          fullData: slices(),
          pieData: slices(),
          isExpense: true,
          showBarChart: false,
          onToggleBarChart: (_) {},
          onCategoryTap: (_, __) {},
          budgetProgressFor: (_, __) => null,
        ),
      ));
      await tester.pump();

      final all = texts(tester).toList();
      expect(all.where((t) => t.contains('1.500')), isEmpty);
      expect(all.where((t) => t.contains('1.200')), isEmpty);
    });

    testWidgets('günlük akış grafiğinin tooltip\'i ve değer ekseni susar',
        (tester) async {
      await tester.pumpWidget(host(
        visible: false,
        ReportDailyNetFlowChart(series: flowSeries()),
      ));
      await tester.pump();

      final chart = tester.widget<BarChart>(find.byType(BarChart));
      final group = chart.data.barGroups.first;
      final item = chart.data.barTouchData.touchTooltipData.getTooltipItem(
        group,
        0,
        group.barRods.first,
        0,
      );
      expect(item!.text, contains('**** ₺'));
      expect(item.text, isNot(contains('6.200')));

      // Değer ekseni gizliyken hiç yazılmaz: üç kere "****" gürültüdür.
      expect(texts(tester).where((t) => t.endsWith('K')), isEmpty);
    });

    testWidgets('bakiye grafiğinin tooltip\'i maskelenir', (tester) async {
      await tester.pumpWidget(host(
        visible: false,
        ReportCumulativeBalanceChart(series: flowSeries()),
      ));
      await tester.pump();

      final data = tester.widget<LineChart>(find.byType(LineChart)).data;
      final bar = data.lineBarsData.first;
      final items = data.lineTouchData.touchTooltipData.getTooltipItems(
        [LineBarSpot(bar, 0, bar.spots.first)],
      );
      expect(items.single!.text, contains('**** ₺'));
      expect(items.single!.text, isNot(contains('6.200')));
    });
  });

  group('göz düğmesi açıkken', () {
    testWidgets('tutarlar olduğu gibi yazılır (regresyon kapısı)',
        (tester) async {
      await tester.pumpWidget(host(
        visible: true,
        const Padding(
          padding: EdgeInsets.all(16),
          child: ReportSummaryCards(
            totals: ReportTotals(
                totalIncome: 6200, totalExpense: 1500, net: 4700),
            previousTotals: ReportTotals(),
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('6.200,00 ₺'), findsOneWidget);
      expect(find.text('1.500,00 ₺'), findsOneWidget);
      expect(find.text('**** ₺'), findsNothing);
    });
  });
}
