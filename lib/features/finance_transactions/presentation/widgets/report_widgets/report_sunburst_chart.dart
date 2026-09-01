import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Ana kategoriler (iç halka) ve alt kategoriler (dış halka) — tek çember.
///
/// **Neden var:** kategori hiyerarşisi iki seviyeli ve başlangıç paketi
/// alt kategorilerle geliyor (`Fatura › Elektrik/Su/İnternet`), ama raporun
/// hiçbir grafiği bunu göstermiyordu; kırılım yalnız detay sayfasındaki düz
/// metin satırlarında vardı. Kullanıcı "faturaya 4.240 TL gitmiş" görüyor,
/// "hangisine" sorusunun cevabı için ayrı bir sayfa açmak zorunda kalıyordu.
///
/// **Hizalamanın tek koşulu:** dış halkanın toplamı iç halkanınkiyle BİREBİR
/// aynı olmalı, yoksa iki halkanın açıları kayar ve çocuk yanlış anaya
/// bakar. Bu yüzden çocuğu olmayan kök dış halkada kendi rengiyle tam arkını
/// kaplar, çocuklu kökün "doğrudan" harcaması da sentetik bir dilim olarak
/// dış halkaya girer (bkz. [CategoryData.isDirect]).
///
/// **Neden iki ayrı [PieChart]:** fl_chart'ta bir grafiğin tüm dilimleri aynı
/// yarıçap bandını paylaşır; iç içe iki bant tek `PieChartData` ile
/// kurulamıyor. İki grafik aynı `startDegreeOffset` ve aynı toplamla üst üste
/// konunca halkalar hizalanır.
class ReportSunburstChart extends StatelessWidget {
  /// İç halka — ana kategoriler (eşiklenmiş pasta verisi).
  final List<CategoryData> roots;

  /// `tag` → görünen ad.
  final Map<String, String> categoryLabels;

  /// Odaklanılan ana kategori (iç halkaya dokununca). Null ise hepsi normal.
  final int? focusedIndex;

  final ValueChanged<int?> onFocusChanged;

  /// Bir dilime dokunulduğunda: ana kategori ya da alt kategori.
  final void Function(CategoryData slice) onSliceTap;

  const ReportSunburstChart({
    super.key,
    required this.roots,
    required this.onFocusChanged,
    required this.onSliceTap,
    this.categoryLabels = const {},
    this.focusedIndex,
  });

  /// Çemberin boy ölçüleri. Toplam çap = 2 × (merkez + iç + dış) = 220dp;
  /// 360dp telefonda kart dolgusundan sonra rahat sığar.
  static const double _centerRadius = 38;
  static const double _innerBand = 46;
  static const double _outerBand = 26;

  /// Odaklanan halkanın büyüme payı.
  static const double _focusGrow = 6;

  /// Bir dilimin üzerine yüzde yazılabilmesi için gereken en düşük pay.
  /// Ölçüldü: iç halkanın etiket yarıçapında (r≈61) "%3" etiketi 15,7px,
  /// %3'lük yay 11,5px — komşusunun üstüne biniyordu.
  static const double _minLabelPercent = 7;

  double get _total => roots.fold<double>(0.0, (sum, r) => sum + r.totalAmount);

  /// Dış halkanın dilimleri, iç halkayla AYNI sırada ve aynı toplamda.
  ///
  /// Dönen kayıttaki `rootIndex` her dilimin hangi ana kategoriye ait
  /// olduğunu söyler — dokunma ve odak sönümlemesi bunu okur.
  List<({CategoryData slice, int rootIndex})> get _outerSlices => [
        for (var i = 0; i < roots.length; i++)
          if (roots[i].children.isEmpty)
            // Kırılımı olmayan kök dış halkada kendi arkını kaplar: "burada
            // daha derini yok" bilgisi bu süreklilikle okunur.
            (slice: roots[i], rootIndex: i)
          else
            for (final child in roots[i].children) (slice: child, rootIndex: i),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _total;
    if (roots.isEmpty || total <= 0) return const SizedBox.shrink();

    final money = MoneyWriter.of(context);
    final outer = _outerSlices;
    final hasAnyChild = roots.any((r) => r.children.isNotEmpty);

    return Semantics(
      label: context.l10n.reportSunburstSemantics(
        roots.length.toString(),
        outer.where((o) => !o.slice.isDirect).length.toString(),
        money(total),
      ),
      child: SizedBox(
        height: 2 * (_centerRadius + _innerBand + _outerBand + _focusGrow) + 8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // DIŞ halka önce çizilir; iç halka onun üstünde durur.
            if (hasAnyChild) _buildOuterRing(outer, total),
            _buildInnerRing(context, theme, total),
            _buildCenter(context, theme, money, total),
          ],
        ),
      ),
    );
  }

  // ── halkalar ──────────────────────────────────────────────────────────────

  Widget _buildOuterRing(
    List<({CategoryData slice, int rootIndex})> outer,
    double total,
  ) {
    return PieChart(
      PieChartData(
        startDegreeOffset: 0,
        sectionsSpace: 1,
        centerSpaceRadius: _centerRadius + _innerBand,
        borderData: FlBorderData(show: false),
        pieTouchData: PieTouchData(
          touchCallback: (event, response) {
            if (event is! FlTapUpEvent) return;
            final index = response?.touchedSection?.touchedSectionIndex ?? -1;
            if (index < 0 || index >= outer.length) return;
            final hit = outer[index];
            // Kırılımı olmayan kökün dış arkı kökün KENDİSİDİR; alt
            // kategoriymiş gibi açmak yanlış listeyi gösterirdi.
            onSliceTap(hit.slice);
          },
        ),
        sections: [
          for (final item in outer)
            PieChartSectionData(
              value: item.slice.totalAmount,
              title: '',
              radius: _outerBand +
                  (focusedIndex == item.rootIndex ? _focusGrow : 0),
              color: _dim(item.slice.color, item.rootIndex),
            ),
        ],
      ),
    );
  }

  Widget _buildInnerRing(BuildContext context, ThemeData theme, double total) {
    return PieChart(
      PieChartData(
        startDegreeOffset: 0,
        sectionsSpace: 2,
        centerSpaceRadius: _centerRadius,
        borderData: FlBorderData(show: false),
        pieTouchData: PieTouchData(
          touchCallback: (event, response) {
            if (event is! FlTapUpEvent) return;
            final index = response?.touchedSection?.touchedSectionIndex ?? -1;
            if (index < 0 || index >= roots.length) {
              onFocusChanged(null);
              return;
            }
            // İkinci dokunuş odağı KALDIRIR, üçüncü bir jest gerekmez.
            if (focusedIndex == index) {
              onSliceTap(roots[index]);
            } else {
              onFocusChanged(index);
            }
          },
        ),
        sections: [
          for (var i = 0; i < roots.length; i++)
            () {
              final percent = roots[i].totalAmount / total * 100;
              final isFocused = focusedIndex == i;
              return PieChartSectionData(
                value: roots[i].totalAmount,
                title:
                    percent >= _minLabelPercent ? formatPercent(percent) : '',
                titlePositionPercentageOffset: 0.55,
                radius: _innerBand + (isFocused ? _focusGrow : 0),
                color: _dim(roots[i].color, i),
                titleStyle: TextStyle(
                  fontSize: isFocused ? 13 : 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    BoxShadow(
                        color: Colors.black45,
                        blurRadius: 4,
                        offset: Offset(0, 1)),
                  ],
                ),
              );
            }(),
        ],
      ),
    );
  }

  /// Odak varken diğer dilimler sönümlenir — vurgu YALNIZ büyümeyle
  /// taşınmaz, 6dp'lik fark küçük dilimlerde görülmüyor.
  Color _dim(Color color, int rootIndex) {
    if (focusedIndex == null || focusedIndex == rootIndex) return color;
    return color.withValues(alpha: 0.28);
  }

  // ── merkez ────────────────────────────────────────────────────────────────

  /// Merkez boşluğu: odak varsa o kategorinin adı + tutarı, yoksa toplam.
  Widget _buildCenter(
    BuildContext context,
    ThemeData theme,
    MoneyWriter money,
    double total,
  ) {
    final scheme = theme.colorScheme;
    final focused = focusedIndex != null &&
            focusedIndex! >= 0 &&
            focusedIndex! < roots.length
        ? roots[focusedIndex!]
        : null;

    return SizedBox(
      width: _centerRadius * 1.85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            focused == null
                ? context.l10n.reportTotalLabel
                : focused.labelIn(context, categoryLabels),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            money.compact(focused?.totalAmount ?? total),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: focused?.color ?? scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
