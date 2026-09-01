import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_cumulative_balance_chart.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_daily_net_flow_chart.dart';
import 'package:flutter/material.dart';

/// Dönem içi zaman grafiğinin merceği.
enum ReportPeriodLens {
  /// Gün/hafta/ay başına gelir–gider çubukları.
  flow,

  /// Dönem boyunca bakiyenin seyri.
  balance,
}

/// Dönem içi zaman grafiği — akış ve bakiye TEK kartta, mercek seçimiyle.
///
/// **Neden birleşti:** ölçüldü — sayfa 360×800 telefonda 2.761dp'ye, yani
/// **3,5 ekran** kaydırmaya çıkmıştı ve bunun 690dp'si iki ayrı zaman
/// kartıydı. İkisi AYNI seriden, aynı zaman ekseninden ve aynı çözünürlük
/// seçicisinden besleniyor; ayrı kartlar olarak durmaları kullanıcıya yeni
/// bir soru sormuyor, yalnız iki kez kaydırtıyordu.
///
/// Tek kartta mercek seçimi hem 350dp kazandırıyor hem de çözünürlük
/// seçicisinin neyi yönettiğini netleştiriyor: eskiden seçici bir kartın
/// başlığındaydı ama SESSİZCE alttaki ikinci grafiği de değiştiriyordu.
class ReportPeriodChartCard extends StatelessWidget {
  /// Akış çubuklarının serisi (analiz evreni — kuplaj hareketleri anahtara
  /// bağlı).
  final ReportSeries flowSeries;

  /// Bakiye çizgisinin serisi (defterin TAMAMI + açılış bakiyesi).
  final ReportSeries balanceSeries;

  final ReportPeriodLens lens;
  final ValueChanged<ReportPeriodLens> onLensChanged;

  const ReportPeriodChartCard({
    super.key,
    required this.flowSeries,
    required this.balanceSeries,
    required this.lens,
    required this.onLensChanged,
  });

  @override
  Widget build(BuildContext context) {
    return switch (lens) {
      ReportPeriodLens.flow => ReportDailyNetFlowChart(series: flowSeries),
      ReportPeriodLens.balance =>
        ReportCumulativeBalanceChart(series: balanceSeries),
    };
  }
}

/// Akış / Bakiye mercek seçicisi — bölüm başlığının sağında durur.
class ReportPeriodLensSelector extends StatelessWidget {
  final ReportPeriodLens selected;
  final ValueChanged<ReportPeriodLens> onChanged;

  const ReportPeriodLensSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  String _label(BuildContext context, ReportPeriodLens lens) => switch (lens) {
        ReportPeriodLens.flow => context.l10n.reportLensFlow,
        ReportPeriodLens.balance => context.l10n.reportLensBalance,
      };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final lens in ReportPeriodLens.values)
          ChoiceChip(
            label: Text(_label(context, lens)),
            selected: selected == lens,
            onSelected: (_) => onChanged(lens),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
