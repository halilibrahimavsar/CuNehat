import 'dart:math' as math;

import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:flutter/material.dart';

/// Gelir ve gideri TEK grafikte karşılaştıran kart.
///
/// Eskiden "Karşılaştırma" modu iki ayrı pasta kartını alt alta diziyordu —
/// yani hiçbir şeyi karşılaştırmıyordu, sadece ikisini birden gösteriyordu.
/// Burada iki taraf **aynı değer ölçeğinde**, ortak sol tabandan büyüyen iki
/// yatay yığılmış çubuk olur: çubuk uzunlukları doğrudan kıyaslanabilir,
/// aradaki fark net'in kendisidir, her çubuğun içindeki dilimler de o tarafın
/// kategori dağılımını verir.
///
/// Neden ortak taban (kelebek/diverging değil): ortak tabandan büyüyen iki
/// çubuk iki toplamı kıyaslamak için en okunaklı biçimdir ve telefonda her
/// çubuğa kartın TAM genişliği düşer. Sıfır çizgisinden iki yöne açılan
/// düzende her tarafa yarım genişlik kalır ve %3'lük bir kalem ~7dp'ye iner.
///
/// KUTUPLULUK RENKLE TAŞINMAZ: gelir yeşili ile gider kırmızısı tam şiddette
/// deuteranopia altında çakışır (ölçülen ΔE 1.2–4.6; taban 6). Hangi çubuğun
/// hangisi olduğunu satır etiketi + yön ikonu + sıralama söyler; renk yalnız
/// pekiştirir. Bkz. [ReportCompareRamp].
class ReportCompareChartCard extends StatelessWidget {
  /// Gelir tarafının dilimleri (ilk N + "Diğer"), rank sırasında.
  final List<CategoryData> incomeSlices;

  /// Gider tarafının dilimleri (ilk N + "Diğer"), rank sırasında.
  final List<CategoryData> expenseSlices;

  /// `tag` → görünen ad. Dilim anahtarı hep `CategoryData.name` (tag) kalır.
  final Map<String, String> categoryLabels;

  /// Bir dilime dokunulduğunda çağrılır; `isExpense` hangi taraf olduğunu
  /// söyler (detay sayfası kırılımı kendi yeniden hesaplar).
  final void Function(CategoryData slice, bool isExpense) onSliceTap;

  const ReportCompareChartCard({
    super.key,
    required this.incomeSlices,
    required this.expenseSlices,
    required this.onSliceTap,
    this.categoryLabels = const {},
  });

  /// Çubuk kalınlığı — mark tavanı 24dp; biraz hava bırakılır.
  static const double _barHeight = 22;

  /// Dilimleri ayıran boşluk. Renk verilmez: kartın kendi gradyanı görünür,
  /// yani ayırıcı gerçekten "yüzey boşluğu"dur. Dilimlerin etrafına çerçeve
  /// çizilmez — ayrımı boşluk yapar.
  static const double _sliceGap = 2;

  /// Bu genişliğin altında yığın anlamsız: dilimler alt-piksele düşer,
  /// tek parça gösterilir.
  static const double _minStackWidth = 24;

  /// Çubuklar adlandırılır ki testler kartın tüm iddiasını — iki çubuğun
  /// AYNI ölçekte olduğunu — genişlik oranından doğrulayabilsin.
  static const Key incomeBarKey = Key('report-compare-bar-income');
  static const Key expenseBarKey = Key('report-compare-bar-expense');

  double _sumOf(List<CategoryData> slices) =>
      slices.fold<double>(0.0, (sum, s) => sum + s.totalAmount);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness =
        (theme.extension<AppSurface>() ?? AppSurface.light).brightness;
    final money = MoneyWriter.of(context);

    final incomeTotal = _sumOf(incomeSlices);
    final expenseTotal = _sumOf(expenseSlices);
    // Ortak ölçek: iki çubuk aynı eksene göre çizilir, yoksa uzunlukları
    // kıyaslanamaz.
    //
    // Eksen ucu BÜYÜK TARAFIN TOPLAMI, yuvarlanmış bir "temiz sayı" değil:
    // 26.600'ü 50.000'e yuvarlamak genişliğin yarısını harcıyordu ve bedelini
    // ödeyen tam da bu kartın işi — küçük kalemlerin görünürlüğü. Uzun çubuk
    // kartın tamamını kaplar, kısa çubuk oranı kadarını; işaret etiketleri
    // kısaltılmış biçimle (13.3K) okunur kalır.
    final axisMax = math.max(incomeTotal, expenseTotal);

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSide(
            context,
            theme,
            money: money,
            brightness: brightness,
            slices: incomeSlices,
            sideTotal: incomeTotal,
            axisMax: axisMax,
            isExpense: false,
          ),
          const SizedBox(height: 20),
          _buildSide(
            context,
            theme,
            money: money,
            brightness: brightness,
            slices: expenseSlices,
            sideTotal: expenseTotal,
            axisMax: axisMax,
            isExpense: true,
          ),
          const SizedBox(height: 12),
          _buildAxis(theme, money, axisMax),
          const SizedBox(height: 8),
          // Kartın tüm iddiası bu: uzunluklar kıyaslanabilir. Bir kez yazılır.
          Text(
            context.l10n.reportCompareScaleHint,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          _buildNetLine(context, theme, money, incomeTotal, expenseTotal),
          const SizedBox(height: 4),
          Divider(color: scheme.onSurface.withValues(alpha: 0.08), height: 24),
          _buildLegendGroup(
            context,
            theme,
            money: money,
            slices: incomeSlices,
            sideTotal: incomeTotal,
            isExpense: false,
          ),
          if (incomeSlices.isNotEmpty && expenseSlices.isNotEmpty)
            const SizedBox(height: 12),
          _buildLegendGroup(
            context,
            theme,
            money: money,
            slices: expenseSlices,
            sideTotal: expenseTotal,
            isExpense: true,
          ),
        ],
      ),
    );
  }

  // ── bir taraf: etiket satırı + çubuk + en büyük kalemin doğrudan etiketi ──

  Widget _buildSide(
    BuildContext context,
    ThemeData theme, {
    required MoneyWriter money,
    required Brightness brightness,
    required List<CategoryData> slices,
    required double sideTotal,
    required double axisMax,
    required bool isExpense,
  }) {
    final scheme = theme.colorScheme;
    final sideLabel =
        isExpense ? context.l10n.menuExpense : context.l10n.menuIncome;
    // Rampanın ilk adımı = o tarafın "sesi"; toplamı da onunla yazarız.
    final sideColor =
        ReportCompareRamp.of(isExpense: isExpense, brightness: brightness)
            .first;

    if (slices.isEmpty || sideTotal <= 0) {
      return Row(
        children: [
          Icon(
            isExpense ? Icons.south_rounded : Icons.north_rounded,
            size: 14,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Text(
            sideLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            context.l10n.titleIcinVeriYok(sideLabel),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      );
    }

    final top = slices.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Yön ikonu + etiket: kutupluluğun renkten BAĞIMSIZ kanalı.
            Icon(
              isExpense ? Icons.south_rounded : Icons.north_rounded,
              size: 14,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              sideLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              money(sideTotal),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: sideColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) => _buildBar(
            slices: slices,
            sideTotal: sideTotal,
            axisMax: axisMax,
            fullWidth: constraints.maxWidth,
            isExpense: isExpense,
          ),
        ),
        const SizedBox(height: 6),
        // Seçici doğrudan etiket: yalnız en büyük kalem. Her dilime değer
        // basmak okunmaz — kalanları efsane taşır.
        Text(
          context.l10n.reportCompareTopSlice(
            top.labelIn(context, categoryLabels),
            money(top.totalAmount),
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildBar({
    required List<CategoryData> slices,
    required double sideTotal,
    required double axisMax,
    required double fullWidth,
    required bool isExpense,
  }) {
    final barWidth = axisMax <= 0
        ? 0.0
        : (fullWidth * (sideTotal / axisMax)).clamp(0.0, fullWidth);

    // Veri ucu 4px yuvarlak, taban (sol) köşeli — çubuk tek bir tabandan
    // büyür ve nerede bittiği yuvarlak uçtan okunur.
    const radius = BorderRadius.horizontal(right: Radius.circular(4));

    final key = isExpense ? expenseBarKey : incomeBarKey;

    if (barWidth < _minStackWidth || slices.length == 1) {
      return SizedBox(
        key: key,
        width: barWidth,
        height: _barHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: slices.first.color,
            borderRadius: radius,
          ),
        ),
      );
    }

    return SizedBox(
      key: key,
      width: barWidth,
      height: _barHeight,
      child: ClipRRect(
        borderRadius: radius,
        child: Row(
          // stretch ŞART: dilimler çocuksuz ColoredBox, yani kendiliğinden
          // sıfır yüksekliktedir. Row'un varsayılan `center` hizalaması
          // hepsini görünmez yapıyordu (çubuk kabı doğru ölçüde, içi boş).
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < slices.length; i++) ...[
              if (i > 0) const SizedBox(width: _sliceGap),
              Expanded(
                // Oranı flex'e taşımak alt-piksel aritmetiğini Flutter'a
                // bırakır; boşluklar sabit 2px'ini alır, kalanı dilimler
                // paylaşır → negatif genişlik imkânsız.
                flex: math.max(
                    1, (slices[i].totalAmount / sideTotal * 10000).round()),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSliceTap(slices[i], isExpense),
                  child: ColoredBox(color: slices[i].color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── eksen: ince çizgi + üç temiz sayı ─────────────────────────────────────

  Widget _buildAxis(ThemeData theme, MoneyWriter money, double axisMax) {
    final scheme = theme.colorScheme;
    final style = theme.textTheme.bodySmall?.copyWith(
      fontSize: 10,
      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 1, color: scheme.onSurface.withValues(alpha: 0.12)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text('0', style: style, textAlign: TextAlign.left),
            ),
            Expanded(
              child: Text(
                money.compact(axisMax / 2, symbol: false),
                style: style,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Text(
                money.compact(axisMax),
                style: style,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNetLine(
    BuildContext context,
    ThemeData theme,
    MoneyWriter money,
    double incomeTotal,
    double expenseTotal,
  ) {
    final scheme = theme.colorScheme;
    final net = incomeTotal - expenseTotal;
    // Net gelir/gider rampalarından RENK ALMAZ: yeşil/kırmızı bu kartta iki
    // tarafa ayrılmıştır. Özet kartlarıyla aynı mavi/turuncu kullanılır.
    final netColor = net >= 0 ? Colors.blue : Colors.orange;

    // Oran yalnız gelir varken anlamlı: gelir 0 iken "gelirin %x'i" yok.
    String? hint;
    if (incomeTotal > 0) {
      final rate = (net.abs() / incomeTotal) * 100;
      hint = net >= 0
          ? context.l10n.reportSavingsSubtitle(rate.toStringAsFixed(0))
          : context.l10n.reportCompareOverspend(rate.toStringAsFixed(0));
    }

    return Row(
      children: [
        Icon(
          net >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          size: 16,
          color: netColor,
        ),
        const SizedBox(width: 6),
        Text(
          context.l10n.reportNetLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          money.withSign(net),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: netColor,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '· $hint',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── efsane: taraf başlığı + tam genişlik satırlar ─────────────────────────

  /// İki taraf yan yana iki kolona SIĞMAZ (telefonda kolon başına ~140dp;
  /// "Ulaşım 1.250,00 ₺ %15" kesilir), bu yüzden tek kolon, taraf başlıklı.
  /// Satırlar tam genişlik olduğu için aynı zamanda dilimlerin güvenilir
  /// dokunma hedefidir — 22dp'lik ince bir dilime nişan almak gerekmez.
  Widget _buildLegendGroup(
    BuildContext context,
    ThemeData theme, {
    required MoneyWriter money,
    required List<CategoryData> slices,
    required double sideTotal,
    required bool isExpense,
  }) {
    if (slices.isEmpty) return const SizedBox.shrink();

    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isExpense ? context.l10n.menuExpense : context.l10n.menuIncome,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        for (final slice in slices)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSliceTap(slice, isExpense),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: slice.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      slice.labelIn(context, categoryLabels),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.formatMoneyItemTotalamountPercent(
                      money(slice.totalAmount),
                      (sideTotal <= 0
                              ? 0.0
                              : slice.totalAmount / sideTotal * 100)
                          .toStringAsFixed(0),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
