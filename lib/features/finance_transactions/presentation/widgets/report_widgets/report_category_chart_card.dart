import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_bar_list.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ReportCategoryChartCard extends StatefulWidget {
  final String title;
  final List<CategoryData> fullData;
  final List<CategoryData> pieData;
  final bool isExpense;
  final bool showBarChart;
  final ValueChanged<bool> onToggleBarChart;
  final void Function(CategoryData cat, ReportSliceMode sliceMode)
      onCategoryTap;
  final ({double progress, bool isExceeded, double limit})? Function(
      String tag, double spent) budgetProgressFor;

  /// `tag` → görünen ad. Dilim/çubuk anahtarı hep `CategoryData.name` (tag)
  /// kalır; bu harita yalnız etiket basarken kullanılır.
  final Map<String, String> categoryLabels;

  const ReportCategoryChartCard({
    super.key,
    required this.title,
    required this.fullData,
    required this.pieData,
    required this.isExpense,
    required this.showBarChart,
    required this.onToggleBarChart,
    required this.onCategoryTap,
    required this.budgetProgressFor,
    this.categoryLabels = const {},
  });

  @override
  State<ReportCategoryChartCard> createState() =>
      _ReportCategoryChartCardState();
}

class _ReportCategoryChartCardState extends State<ReportCategoryChartCard> {
  int _touchedIndex = -1;

  /// Bir dilimin üzerine yüzde yazılabilmesi için gereken en düşük pay.
  ///
  /// Keyfi değil, ölçüldü: fl_chart etiketi varsayılan olarak iç/dış yarıçapın
  /// ortasına (r ≈ 73) koyar. Orada %1'lik yay 4,6px; "%3" etiketi gerçek
  /// Roboto ile 15,7px genişliğinde, yani etiketin sığması için dilimin en az
  /// ~%3,5 olması gerekir. Pay yerine 6 seçildi ki komşu etiketler arasında
  /// nefes payı da kalsın.
  static const double _minLabelPercent = 6;

  @override
  void didUpdateWidget(ReportCategoryChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dilim listesi değiştiğinde (tarih aralığı seçimi, işlem ekleme/silme)
    // eski indeks artık başka bir kategoriyi işaret eder; vurgu sıfırlanır.
    // Uzunluk yetmez: aynı sayıda ama farklı sıradaki kategoriler de kayar.
    if (!listEquals(
      [for (final c in oldWidget.pieData) c.name],
      [for (final c in widget.pieData) c.name],
    )) {
      _touchedIndex = -1;
    }
  }

  /// Para yazıcısı build başında kurulur ve alt yardımcılara TAŞINIR:
  /// fl_chart'ın tooltip closure'ı build dışında çalışır, orada `watch`
  /// yapılamaz (bkz. [MoneyWriter]).
  late MoneyWriter _money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    _money = MoneyWriter.of(context);

    if (widget.fullData.isEmpty) {
      return AppCard(
        section: AppSection.transactions,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _money(0),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 48,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.titleIcinVeriYok(widget.title),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    final total = widget.fullData
        .fold<double>(0.0, (sum, item) => sum + item.totalAmount);
    final activeData = widget.showBarChart ? widget.fullData : widget.pieData;

    final sections =
        List<PieChartSectionData>.generate(widget.pieData.length, (i) {
      final item = widget.pieData[i];
      final percent = total == 0 ? 0.0 : (item.totalAmount / total) * 100;
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 75.0 : 66.0;

      return PieChartSectionData(
        value: item.totalAmount,
        // Etiket yalnız YAYA SIĞDIĞINDA basılır. Ölçüldü (gerçek Roboto,
        // yarıçap 73): "%3" etiketi 15,7px, %3'lük dilimin yayı 13,8px —
        // etiket kendi diliminden taşıp komşusunun üstüne biniyordu.
        // Eşiğin altındaki dilimlerin payını efsane satırı taşır.
        title: percent >= _minLabelPercent ? formatPercent(percent) : '',
        radius: radius,
        color: item.color,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: const [
            BoxShadow(
                color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      );
    });

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row DEĞİL Wrap: başlık + iki ikon + toplam tutar tek satıra
          // sığmadığında (büyük metin ölçeği, uzun İngilizce başlık, yedi
          // haneli tutar) taşmak yerine alta iner.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.pie_chart,
                      color: !widget.showBarChart
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    tooltip: context.l10n.reportViewPie,
                    onPressed: () => widget.onToggleBarChart(false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.bar_chart,
                      color: widget.showBarChart
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    tooltip: context.l10n.reportViewBars,
                    onPressed: () => widget.onToggleBarChart(true),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _money(total),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.isExpense ? Colors.redAccent : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          widget.showBarChart
              ? const SizedBox.shrink()
              : SizedBox(
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildCenterLabel(context, theme, total),
                      PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          final isTapUp = event is FlTapUpEvent;
                          int? tappedIndex;

                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              final touchIndex = pieTouchResponse
                                      ?.touchedSection?.touchedSectionIndex ??
                                  -1;
                              final actualIndex =
                                  touchIndex != -1 ? touchIndex : _touchedIndex;

                              if (isTapUp &&
                                  actualIndex != -1 &&
                                  actualIndex < widget.pieData.length) {
                                tappedIndex = actualIndex;
                              }

                              _touchedIndex = -1;
                              return;
                            }

                            final newIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                            _touchedIndex = newIndex;

                            if (isTapUp &&
                                newIndex != -1 &&
                                newIndex < widget.pieData.length) {
                              tappedIndex = newIndex;
                            }
                          });

                          if (tappedIndex != null) {
                            widget.onCategoryTap(widget.pieData[tappedIndex!],
                                ReportSliceMode.pie);
                          }
                        },
                      ),
                      sections: sections,
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                    ],
                  ),
                ),
          const SizedBox(height: 24),
          // Çubuk görünümü efsanenin YERİNE geçer (ad, tutar ve pay zaten
          // satırda); pasta görünümünde efsane dilimlerin okunmasını sağlar.
          if (widget.showBarChart)
            ReportCategoryBarList(
              data: widget.fullData,
              total: total,
              categoryLabels: widget.categoryLabels,
              budgetProgressFor:
                  widget.isExpense ? widget.budgetProgressFor : null,
              onCategoryTap: (cat) =>
                  widget.onCategoryTap(cat, ReportSliceMode.full),
            )
          else
            _buildLegend(context, theme, activeData, total),
        ],
      ),
    );
  }

  /// Pastanın ortasındaki boşluk (r=40) eskiden boştu. Seçili dilimin adı ve
  /// payı oraya yazılır: dokunulan dilimi bulmak için efsaneye inip renk
  /// eşleştirmek gerekmez. Seçim yokken toplam kalem sayısı durur.
  Widget _buildCenterLabel(
      BuildContext context, ThemeData theme, double total) {
    final scheme = theme.colorScheme;
    final hasSelection =
        _touchedIndex >= 0 && _touchedIndex < widget.pieData.length;
    if (!hasSelection) return const SizedBox.shrink();

    final item = widget.pieData[_touchedIndex];
    final percent = total == 0 ? 0.0 : (item.totalAmount / total) * 100;

    return SizedBox(
      width: 74,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.labelIn(context, widget.categoryLabels),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatPercent(percent),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: item.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(
    BuildContext context,
    ThemeData theme,
    List<CategoryData> data,
    double total,
  ) {
    final scheme = theme.colorScheme;
    return Column(
      children: data.map((item) {
        final percent = total == 0 ? 0 : (item.totalAmount / total) * 100;
        final budgetInfo = widget.isExpense
            ? widget.budgetProgressFor(item.name, item.totalAmount)
            : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onCategoryTap(
                item,
                widget.showBarChart
                    ? ReportSliceMode.full
                    : ReportSliceMode.pie),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.labelIn(context, widget.categoryLabels),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      context.l10n.formatMoneyItemTotalamountPercent(
                          _money(item.totalAmount),
                          percent.toStringAsFixed(0)),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (budgetInfo != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: budgetInfo.progress,
                        minHeight: 4,
                        backgroundColor:
                            scheme.onSurface.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(
                          budgetInfo.isExceeded
                              ? Colors.redAccent
                              : Colors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
