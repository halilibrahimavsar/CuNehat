import 'package:cunehat/core/utils/money_format.dart';
import 'package:flutter/material.dart';

/// Bir kalemin önceki döneme göre değişimi: ok + yüzde.
///
/// **Neden kategori satırlarında da var:** karşılaştırma yalnız üç toplamda
/// (gelir/gider/net) vardı. Ama "bu ay 44.620 harcadım" bilgisi tek başına
/// eylem üretmiyor; eylemi üreten "Market %38 arttı" satırıdır.
///
/// Kutupluluk RENKLE TAŞINMAZ: ok yönü + işaret zaten söylüyor, renk yalnız
/// pekiştiriyor (bkz. `ReportCompareRamp` uyarısı). Gider tarafında artış
/// kötü, gelir tarafında iyidir — bu yüzden [increaseIsGood] açıkça verilir,
/// widget kendi tahmin etmez.
class ReportChangeBadge extends StatelessWidget {
  /// Yüzde değişim; null ise (önceki dönem sıfır ya da bilinmiyor) hiçbir şey
  /// çizilmez — "%∞ arttı" bilgi değildir.
  final double? percent;

  final bool increaseIsGood;

  /// Rozet metnini okunur kılan üst sınır. Bunun üstü "%999+" yazılır:
  /// 40 TL'den 12.000 TL'ye çıkan bir kategori "%29.900" diye yazıldığında
  /// satırın yarısını yiyordu.
  static const double maxPercent = 999;

  /// Bu eşiğin altındaki değişim GÖSTERİLMEZ. Kuruş oynamalarını "değişim"
  /// diye sunmak gürültüdür.
  static const double minPercent = 1;

  const ReportChangeBadge({
    super.key,
    required this.percent,
    required this.increaseIsGood,
  });

  @override
  Widget build(BuildContext context) {
    final value = percent;
    if (value == null || value.abs() < minPercent) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isIncrease = value > 0;
    final isGood = isIncrease == increaseIsGood;
    final color = isGood ? Colors.green : Colors.redAccent;

    final magnitude = value.abs();
    final text = magnitude > maxPercent
        ? '${formatPercent(maxPercent)}+'
        : formatPercent(magnitude);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isIncrease
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded,
          size: 11,
          color: color,
        ),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
