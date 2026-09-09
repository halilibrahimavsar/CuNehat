import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_time_axis.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Tek bir çubuğun "ötekileri eziyor" sayılması için gereken kat sayısı.
///
/// Tutucu seçildi: 6 kat altındaki farklarda küçük çubuklar hâlâ okunur,
/// kırpmanın maliyeti (kullanıcı gerçek yüksekliği göremez) kazancından
/// büyüktür.
const double _kClipRatio = 6.0;

/// Kırpma devredeyken eksen tavanı: ikinci en yüksek çubuğun bu kadar üstü.
const double _kClipHeadroom = 1.4;

/// Çubuk ekseninin tavanı — TEK bir kova ötekileri eziyorsa eksen ona göre
/// değil, ÖTEKİLERE göre ölçeklenir. Ezme yoksa `null` döner (eksen normal).
///
/// **Neden var:** aylık maaş, günlük harcamanın onlarca katıdır. Ölçüldü
/// (411dp telefon, "Bu Ay", 83.000 ₺ maaş / en yüksek gün gideri 470 ₺):
/// gider çubukları grafik yüksekliğinin **%0,6'sı**, yani 200dp'lik panelde
/// ~1,2px — hiçbir gider çubuğu görünmüyordu, grafik "tek yeşil çizgi"ye
/// dönüyordu.
///
/// Kırpılan çubuk gizlenmez: tepesi soldurularak "devam ediyor" diye
/// işaretlenir, gerçek tutarı hem karttaki notta hem de dokunma
/// tooltip'inde yazar.
double? flowAxisCap(List<ReportBucket> buckets) {
  final values = <double>[
    for (final b in buckets) ...[
      if (b.income > 0) b.income,
      if (b.expense > 0) b.expense,
    ]
  ]..sort((a, b) => b.compareTo(a));

  // İki çubukla "ezme" diye bir şey yok: birini kırpmak geriye tek çubuk
  // bırakır, o da zaten kendi ölçeğinde okunuyordu.
  if (values.length < 3) return null;

  final top = values.first;
  final next = values[1];
  if (next <= 0 || top < next * _kClipRatio) return null;
  return next * _kClipHeadroom;
}

/// Dönem boyunca gelir/gider çubukları — dönem kartının ÜST paneli.
///
/// Eksen TAKVİM'dir: hareketsiz kovalar da çizilir (bkz. [ReportSeries]).
/// Eskiden yalnız işlem OLAN günler yan yana diziliyordu, yani 1 ve 25
/// Haziran'daki iki işlem komşu iki çubuk oluyordu.
///
/// Çubuklar renkten başka bir şey söylemediği için üstte açıklama (legend)
/// var; dokununca tooltip tam tutarı [MoneyWriter] ile yazar — yani göz
/// düğmesi kapalıyken tooltip de eksen de tutarı ele vermez.
///
/// Kart DEĞİL panel: bakiye çizgisiyle aynı [AppCard] içinde, aynı zaman
/// ekseni üzerinde durur (bkz. `ReportPeriodChartCard`). Tarih etiketleri
/// alttaki panelde bir kez yazıldığı için burada [showDateAxis] kapalı
/// gelebilir.
class ReportDailyNetFlowChart extends StatelessWidget {
  final ReportSeries series;

  /// Grafik alanının yüksekliği (efsane ve not hariç).
  final double height;

  /// Alt eksende tarih etiketleri yazılsın mı?
  final bool showDateAxis;

  const ReportDailyNetFlowChart({
    super.key,
    required this.series,
    this.height = 200,
    this.showDateAxis = true,
  });

  static const incomeColor = Colors.green;
  static const expenseColor = Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Tamamen hareketsiz bir dönemde grafik yerine hiçbir şey çizilmez;
    // 30 boş çubuk bilgi değil gürültüdür.
    if (series.isEmpty || series.hasNoActivity) return const SizedBox();

    final buckets = series.buckets;

    final trueMax = buckets.fold<double>(0.0, (prev, b) {
      final m = b.income > b.expense ? b.income : b.expense;
      return m > prev ? m : prev;
    });
    final cap = flowAxisCap(buckets);
    final maxVal = cap ?? trueMax;
    // Tepedeki çubuğun üstünde nefes payı; tooltip de oraya açılıyor.
    // Kırpma varken pay YOK: tavan zaten yapay, çubuk oraya kadar dolmalı.
    final maxY = maxVal == 0 ? 1.0 : (cap ?? maxVal * 1.2);
    // Etiketler 0 / yarı / tepe hizasına düşsün (tepe maxY'nin altında kalır).
    final yInterval = maxVal == 0 ? 1.0 : maxVal / 2;

    // Tooltip ve eksen etiketleri closure içinde, yani build DIŞINDA
    // çalışır: birim ve görünürlük burada bir kez okunup taşınır.
    final money = MoneyWriter.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Legend(scheme: scheme),
        if (cap != null) ...[
          const SizedBox(height: 6),
          Text(
            context.l10n.reportFlowClippedBar(money(trueMax)),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Semantics(
          // Grafiğin kendisi ekran okuyucuya hiçbir şey söylemiyordu.
          label: context.l10n.reportFlowChartSemantics(
            buckets.length.toString(),
            money(buckets.fold<double>(0, (s, b) => s + b.income)),
            money(buckets.fold<double>(0, (s, b) => s + b.expense)),
          ),
          child: SizedBox(
            height: height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final step = dateLabelStep(
                  pointCount: buckets.length,
                  availableWidth: constraints.maxWidth - kValueAxisWidth,
                  slotWidth: scaledDateLabelSlot(context),
                );
                // Az kovada kalın, çok kovada ince çubuk: 30 günlük veride
                // sabit 10px genişlik çubukları birbirine yapıştırıyordu.
                final barWidth = switch (buckets.length) {
                  <= 7 => 12.0,
                  <= 14 => 8.0,
                  <= 24 => 5.0,
                  _ => 3.0,
                };

                return BarChart(
                  BarChartData(
                    maxY: maxY,
                    minY: 0,
                    // Kovalar dilimlerinin ORTASINA oturur. fl_chart'ın
                    // varsayılanı (spaceEvenly) kenarlara da tam boşluk
                    // koyuyor ve grubu dilim ortasından kaydırıyor: ölçüldü
                    // (411dp, 10 kova) — 1 Eylül'ün çubuğu, altındaki
                    // "01 Eyl" etiketinin ve bakiye panelindeki 1 Eylül
                    // noktasının 25px sağındaydı.
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: List.generate(buckets.length, (index) {
                      final b = buckets[index];
                      return BarChartGroupData(
                        x: index,
                        barsSpace: barWidth / 4,
                        barRods: [
                          _rod(b.income, incomeColor, barWidth, cap),
                          _rod(b.expense, expenseColor, barWidth, cap),
                        ],
                      );
                    }),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          if (group.x < 0 || group.x >= buckets.length) {
                            return null;
                          }
                          final bucket = buckets[group.x];
                          final isIncome = rodIndex == 0;
                          final label = isIncome
                              ? context.l10n.detailLabelGelir
                              : context.l10n.detailLabelGider;
                          // `rod.toY` DEĞİL kovanın kendi tutarı: kırpılan
                          // çubukta çizilen yükseklik tavana eşittir ve
                          // tooltip "83.000" yerine "658" derdi.
                          final value =
                              isIncome ? bucket.income : bucket.expense;
                          return BarTooltipItem(
                            '${bucketTooltipDate(bucket, series.unit)}\n'
                            '$label: ${money(value)}',
                            kChartTooltipStyle,
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: kValueAxisWidth,
                          interval: yInterval,
                          getTitlesWidget: (value, meta) {
                            // Tepe boşluğuna denk gelen etiket çizilmez.
                            if (value > maxVal) {
                              return const SizedBox.shrink();
                            }
                            // Tutarlar gizliyken değer ekseni HİÇ yazılmaz:
                            // üç kere "****" basmak gürültü, üstelik hiçbir
                            // şey anlatmıyor. Çubukların oranı zaten görünür.
                            if (!money.visible) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                money.compact(value, symbol: false),
                                style: chartAxisLabelStyle(scheme),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: showDateAxis,
                          reservedSize: showDateAxis ? 24 : 0,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 ||
                                index >= buckets.length ||
                                index % step != 0) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              // Serinin ilk/son tarihi eksenin tam ucuna
                              // denk geliyor ve kartın dışına taşıyordu.
                              fitInside:
                                  SideTitleFitInsideData.fromTitleMeta(meta),
                              child: Text(
                                bucketAxisLabel(buckets[index], series.unit),
                                style: chartAxisLabelStyle(scheme),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: scheme.onSurface.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Tek bir çubuk. Tavanı aşan çubuk tavanda KESİLİR ve tepesi soldurulur:
  /// düz kesilmiş bir çubuk "değeri tam bu" diye okunurdu.
  BarChartRodData _rod(
    double value,
    Color color,
    double width,
    double? cap,
  ) {
    final clipped = cap != null && value > cap;
    return BarChartRodData(
      toY: clipped ? cap : value,
      color: clipped ? null : color,
      gradient: clipped
          ? LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [color, color.withValues(alpha: 0.12)],
              stops: const [0.65, 1.0],
            )
          : null,
      width: width,
      borderRadius: BorderRadius.circular(3),
    );
  }
}

class _Legend extends StatelessWidget {
  final ColorScheme scheme;
  const _Legend({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(context, ReportDailyNetFlowChart.incomeColor,
            context.l10n.detailLabelGelir),
        const SizedBox(width: 14),
        _dot(context, ReportDailyNetFlowChart.expenseColor,
            context.l10n.detailLabelGider),
      ],
    );
  }

  Widget _dot(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
