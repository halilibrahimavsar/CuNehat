import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/labeled_segment.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/portfolio_slices.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Portföy dağılımı: halka + büyükten küçüğe efsane.
///
/// Dilimler TEK yerde kurulur ([buildPortfolioSlices]); halka ile efsane ayrı
/// ayrı hesaplayınca renk benzersizleştirmesi ikisinde farklı sonuç
/// verebilirdi.
///
/// Elden geçirme (12 Eki 2026, kullanıcı isteği). Eskiden: dilimler kayıt
/// sırasındaydı (en büyük pay listenin ortasında kalabiliyordu), efsane
/// yalnız yüzde yazıyordu (tutar yok), halkanın ortası boştu ve "altınım
/// toplamda ne kadar" sorusunun cevabı yoktu (her kayıt ayrı dilimdi).
class InvestmentChart extends StatefulWidget {
  const InvestmentChart({
    super.key,
    required this.investments,
    required this.currency,
  });

  final List<InvestmentEntity> investments;

  /// Tutarların birimi: kayıtların cüzdanınınki (açık parametre — aktif
  /// cüzdan bir kartken kayıtlar sahibinin birimindedir).
  final String currency;

  /// Bu payın altındaki dilime halka ÜSTÜNDE etiket yazılmaz: %0,1'lik bir
  /// dilim birkaç piksel geniştir, yazı kendi diliminin dışına taşıp komşunun
  /// ve halkanın kenarının üstüne düşüyordu. Değer zaten efsanede yazıyor.
  static const double _inlineLabelMinPercent = 4.0;

  /// Efsanede katlanmadan gösterilen satır sayısı.
  static const int _collapsedLegendRows = 5;

  @override
  State<InvestmentChart> createState() => _InvestmentChartState();
}

class _InvestmentChartState extends State<InvestmentChart> {
  PortfolioBreakdown _by = PortfolioBreakdown.asset;

  /// Seçili dilimin anahtarı; ortada onun adı/tutarı/payı yazar.
  String? _selected;
  bool _showAll = false;

  void _toggle(String key) =>
      setState(() => _selected = _selected == key ? null : key);

  String _typeLabel(InvestmentType type) => switch (type) {
        InvestmentType.gold => context.l10n.portfoyTurAltin,
        InvestmentType.stock => context.l10n.portfoyTurHisse,
        InvestmentType.custom => context.l10n.portfoyTurOzel,
        InvestmentType.cash => context.l10n.portfoyTurNakit,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    if (widget.investments.isEmpty) {
      return AppCard(
        section: AppSection.savings,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            l10n.grafikIcinYatirimBulunmuyor,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final money =
        MoneyWriter(currency: widget.currency, visible: context.amountsVisible);
    final slices = buildPortfolioSlices(
      widget.investments,
      by: _by,
      typeLabel: _typeLabel,
    );
    final ring = foldPortfolioRing(
      slices,
      otherLabel: l10n.portfoyDiger,
      otherColor: scheme.onSurfaceVariant.withValues(alpha: 0.45),
    );
    final total = slices.fold<double>(0.0, (sum, s) => sum + s.value);
    // Seçim başka bir kipten kalmış olabilir: bu kipte yoksa yok sayılır.
    final selected = slices.where((s) => s.key == _selected).firstOrNull;

    final collapsible = slices.length > InvestmentChart._collapsedLegendRows;
    final legend = collapsible && !_showAll
        ? slices.take(InvestmentChart._collapsedLegendRows).toList()
        : slices;

    return AppCard(
      section: AppSection.savings,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.portfoyDagilimi,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          // Tek kayıtta iki kip de aynı tek dilimi gösterir.
          if (widget.investments.length > 1) ...[
            const SizedBox(height: 12),
            LabeledSegment<PortfolioBreakdown>(
              selected: _by,
              onChanged: (by) => setState(() {
                _by = by;
                _selected = null;
                _showAll = false;
              }),
              items: [
                SegmentItem(
                  value: PortfolioBreakdown.asset,
                  label: l10n.portfoyVarligaGore,
                  color: AppGradients.savings,
                ),
                SegmentItem(
                  value: PortfolioBreakdown.type,
                  label: l10n.portfoyTureGore,
                  color: AppGradients.savings,
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Toplam sıfırken (hepsi 0 değerli) halka çizilemez: paylar tanımsız.
          if (total > 0)
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: [
                        for (final slice in ring)
                          _section(slice, selected: _isHighlighted(slice)),
                      ],
                      centerSpaceRadius: 52,
                      sectionsSpace: 3,
                      borderData: FlBorderData(show: false),
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (event is! FlTapUpEvent) return;
                          final index =
                              response?.touchedSection?.touchedSectionIndex;
                          if (index == null ||
                              index < 0 ||
                              index >= ring.length) {
                            if (_selected != null) {
                              setState(() => _selected = null);
                            }
                            return;
                          }
                          // "Diğer" dilimi tek bir kayda karşılık gelmez:
                          // dokununca efsanenin tamamı açılır.
                          if (ring[index].key == kPortfolioOtherKey) {
                            setState(() {
                              _selected = null;
                              _showAll = true;
                            });
                            return;
                          }
                          _toggle(ring[index].key);
                        },
                      ),
                    ),
                  ),
                  // Dokunuşlar halkaya gitsin diye orta yazı işaretçiyi yutmaz.
                  IgnorePointer(
                    child: SizedBox(
                      width: 92,
                      child: _center(theme, scheme, money, total, selected),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          for (final slice in legend) _legendRow(theme, scheme, money, slice),
          if (collapsible)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: const ValueKey('portfolio-legend-toggle'),
                onPressed: () => setState(() => _showAll = !_showAll),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: Text(_showAll
                    ? l10n.portfoyDahaAzGoster
                    : l10n.portfoyTumunuGoster(slices.length)),
              ),
            ),
        ],
      ),
    );
  }

  /// Halka dilimi vurgulu mu: kendisi seçili ya da seçili kayıt "Diğer"in
  /// içine katlanmış.
  bool _isHighlighted(PortfolioSlice ringSlice) =>
      _selected != null &&
      (ringSlice.key == _selected || ringSlice.memberKeys.contains(_selected));

  PieChartSectionData _section(PortfolioSlice slice, {required bool selected}) {
    return PieChartSectionData(
      color: slice.color,
      value: slice.value,
      title: slice.percent >= InvestmentChart._inlineLabelMinPercent
          ? formatPercent(slice.percent, decimals: 1)
          : '',
      radius: selected ? 48 : 42,
      titleStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }

  /// Halkanın ortası: seçim yokken toplam, varken seçili dilim.
  Widget _center(
    ThemeData theme,
    ColorScheme scheme,
    MoneyWriter money,
    double total,
    PortfolioSlice? selected,
  ) {
    final caption = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final amount = theme.textTheme.titleSmall?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w800,
    );
    return Column(
      key: const ValueKey('portfolio-center'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          selected?.name ?? context.l10n.portfoyToplam,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: caption,
        ),
        const SizedBox(height: 2),
        // Tutar kırpılmaz, küçülür: parada üç nokta rakam kaybıdır.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(money(selected?.value ?? total), style: amount),
        ),
        if (selected != null)
          Text(
            formatPercent(selected.percent, decimals: 1),
            style: caption?.copyWith(color: selected.color),
          ),
      ],
    );
  }

  Widget _legendRow(
    ThemeData theme,
    ColorScheme scheme,
    MoneyWriter money,
    PortfolioSlice slice,
  ) {
    final isSelected = slice.key == _selected;
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        key: ValueKey('portfolio-legend-${slice.key}'),
        onTap: () => _toggle(slice.key),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? slice.color.withValues(alpha: 0.10) : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: slice.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      slice.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    money(slice.value),
                    maxLines: 1,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 44),
                    child: Text(
                      formatPercent(slice.percent, decimals: 1),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // Pay çubuğu: yüzdeleri okumadan da büyüklük sırası görünsün.
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (slice.percent / 100).clamp(0.0, 1.0),
                    minHeight: 3,
                    color: slice.color,
                    backgroundColor: scheme.onSurface.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
