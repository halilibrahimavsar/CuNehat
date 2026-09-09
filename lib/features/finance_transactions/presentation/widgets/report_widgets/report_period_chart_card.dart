import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_cumulative_balance_chart.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_daily_net_flow_chart.dart';
import 'package:flutter/material.dart';

/// Dönem içi zaman grafiği: gelir–gider akışı ve bakiye seyri TEK kartta,
/// ORTAK zaman ekseni üzerinde.
///
/// **Neden mercek seçici kaldırıldı:** iki grafik "Akış / Bakiye" çipleriyle
/// nöbetleşe çiziliyordu. Kullanıcı dönem bölümüne bakıp "gelir–gider akışı
/// yok" diyordu — çünkü açık olan mercek bakiyeydi ve iki çip bir başlığın
/// sağında, üstelik altındaki çözünürlük çipleriyle birlikte **iki satır
/// kontrol** hâlinde duruyordu. Aynı seriden beslenen, aynı x eksenini
/// paylaşan iki grafiği saklamanın kazancı yoktu: çubuklar "ne zaman ne
/// girdi/çıktı", çizgi "bunun bakiyeye etkisi ne" sorusunu yanıtlar ve
/// ikisi birlikte okunur.
///
/// Tarih etiketleri ALTTA bir kez yazılır; üstteki panelin alt ekseni
/// kapalıdır (bkz. `showDateAxis`).
class ReportPeriodChartCard extends StatelessWidget {
  /// Akış çubuklarının serisi (analiz evreni — kuplaj hareketleri anahtara
  /// bağlı).
  final ReportSeries flowSeries;

  /// Bakiye çizgisinin serisi (defterin TAMAMI + açılış bakiyesi).
  final ReportSeries balanceSeries;

  const ReportPeriodChartCard({
    super.key,
    required this.flowSeries,
    required this.balanceSeries,
  });

  /// Seride çizilecek bir hareket var mı?
  static bool _hasActivity(ReportSeries series) =>
      !(series.isEmpty || series.hasNoActivity);

  /// Kartın çizecek bir şeyi var mı? Bölüm başlığı buna bakarak kurulur:
  /// aksi hâlde başlık + çözünürlük seçicisi çizilip altında BOŞLUK kalıyordu
  /// (yalnız transfer içeren bir dönemde grafik kendini gizliyor).
  static bool hasContent({
    required ReportSeries flowSeries,
    required ReportSeries balanceSeries,
  }) =>
      _hasActivity(flowSeries) || _hasActivity(balanceSeries);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final hasFlow = _hasActivity(flowSeries);
    final hasBalance = _hasActivity(balanceSeries);
    if (!hasFlow && !hasBalance) return const SizedBox.shrink();

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.fromLTRB(16, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasFlow)
            ReportDailyNetFlowChart(
              series: flowSeries,
              height: 160,
              // Tarih ekseni alttaki bakiye panelinde yazılıyor; iki kez
              // yazmak kartın 24dp'sini boşa harcar ve iki eksen arasında
              // "hangisi hangisinin" sorusu doğar.
              showDateAxis: !hasBalance,
            ),
          if (hasFlow && hasBalance) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 3,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.reportLensBalance,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (hasBalance)
            ReportCumulativeBalanceChart(
              series: balanceSeries,
              height: hasFlow ? 120 : 200,
            ),
        ],
      ),
    );
  }
}
