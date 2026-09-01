import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:flutter/material.dart';

class PeriodChange {
  final double? percent;
  final bool increaseIsGood;

  const PeriodChange({required this.percent, required this.increaseIsGood});
}

/// Dönemin üç sayısı: gelir, gider, net.
///
/// **Düzen neden 3 sütun değil:** ölçüldü (gerçek Roboto, 360dp) — üç eşit
/// sütunda kart içi genişlik **77,3dp** kalıyor, oysa `44.620,00 ₺` 80,9dp,
/// `1.234.567,89 ₺` 102,5dp istiyor. Tutar üç satıra sarıyordu (widget
/// yüksekliği 69px = 3 satır) ve dönemsel değişim rozeti — kartın taşıdığı
/// asıl bilgi — "%23 önceki dö…" diye kesiliyordu (124,9dp gerekiyor, 65,3dp
/// vardı).
///
/// Gelir/gider yan yana iki sütuna alındığında iç genişlik 134dp'ye,
/// net tam genişliğe (304dp) çıkar; her ikisi de yedi haneli tutarı ve tam
/// rozet metnini alır. Net zaten dönemin manşet sayısı — genişliği hak eder.
class ReportSummaryCards extends StatelessWidget {
  final ReportTotals totals;
  final ReportTotals previousTotals;

  const ReportSummaryCards({
    super.key,
    required this.totals,
    required this.previousTotals,
  });

  PeriodChange? _periodChange(
    double current,
    double previous, {
    required bool increaseIsGood,
  }) {
    if (current == 0 && previous == 0) return null;
    if (previous == 0) {
      return PeriodChange(percent: null, increaseIsGood: increaseIsGood);
    }
    final percent = ((current - previous) / previous) * 100;
    return PeriodChange(percent: percent, increaseIsGood: increaseIsGood);
  }

  /// Net kartının alt satırı.
  ///
  /// Üç ayrı durum, üç ayrı cümle — eskiden hepsi tek şablondan geçiyordu:
  ///  • **Gelir yok:** oran tanımsızdır. `totalIncome == 0` iken kod 0'a
  ///    düşüyor ve 5.000 TL gideri olan bir döneme "%0 Birikim" yazıyordu.
  ///  • **Net negatif:** "%-25 Birikim" okunmuyor. İşaretin `%`'den önce
  ///    gelmesi kuralı (bkz. `formatPercent`) burada da geçerli; karşılaştırma
  ///    kartıyla aynı "gelirin üzerinde" cümlesi kullanılır.
  ///  • **Net pozitif:** birikim oranı.
  String _netSubtitle(BuildContext context) {
    if (totals.totalIncome == 0) return context.l10n.reportNoIncomeForRate;
    final rate = (totals.net.abs() / totals.totalIncome) * 100;
    return totals.net >= 0
        ? context.l10n.reportSavingsSubtitle(rate.toStringAsFixed(0))
        : context.l10n.reportCompareOverspend(rate.toStringAsFixed(0));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // IntrinsicHeight ŞART: `stretch` sınırsız yükseklikli bir Column
        // içinde sonsuz kısıt üretir. İki kart aynı boyda dursun diye
        // yükseklik önce ölçülür (iki çocuk; maliyeti ihmal edilebilir).
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SummaryTile(
                  title: context.l10n.menuIncome,
                  amount: totals.totalIncome,
                  color: Colors.green,
                  change: _periodChange(
                    totals.totalIncome,
                    previousTotals.totalIncome,
                    increaseIsGood: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryTile(
                  title: context.l10n.menuExpense,
                  amount: totals.totalExpense,
                  color: Colors.redAccent,
                  change: _periodChange(
                    totals.totalExpense,
                    previousTotals.totalExpense,
                    increaseIsGood: false,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SummaryTile(
          title: context.l10n.reportNetLabel,
          amount: totals.net,
          color: totals.net >= 0 ? Colors.blue : Colors.orange,
          subtitle: _netSubtitle(context),
          // Net tam genişlikte olduğu için başlık, tutar ve alt satır tek
          // satıra sığar; dikey yığın yerine yatay düzen okunmayı kolaylaştırır.
          horizontal: true,
        ),
      ],
    );
  }
}

class SummaryTile extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final String? subtitle;
  final PeriodChange? change;

  /// Tam genişlikteki kart (net) başlık ve tutarı yan yana yazar.
  final bool horizontal;

  const SummaryTile({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    this.subtitle,
    this.change,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final money = MoneyWriter.of(context);

    final titleStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
    );
    final amountStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: color,
      fontSize: 15,
    );

    if (horizontal) {
      return AppCard(
        accent: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        elevated: false,
        child: Row(
          children: [
            Text(title, style: titleStyle),
            const SizedBox(width: 10),
            Text(money(amount), style: amountStyle),
            if (subtitle != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '· ${subtitle!}',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return AppCard(
      accent: color,
      padding: const EdgeInsets.all(12),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 8),
          Text(money(amount), style: amountStyle),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
          if (change != null) ...[
            const SizedBox(height: 4),
            _buildChangeBadge(context, scheme, change!),
          ],
        ],
      ),
    );
  }

  Widget _buildChangeBadge(
    BuildContext context,
    ColorScheme scheme,
    PeriodChange change,
  ) {
    if (change.percent == null) {
      return Text(
        // "Yeni" DEĞİL: rozet para tutarının hemen altında duruyor ve
        // kullanıcı "yeni gelir" diye okuyordu. Anlatılmak istenen
        // kıyaslanacak önceki dönemin olmadığı.
        context.l10n.reportNoPreviousPeriod,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      );
    }

    final percent = change.percent!;
    final isIncrease = percent > 0;
    final isNeutral = percent == 0;
    final isGood = isIncrease == change.increaseIsGood;
    final badgeColor = isNeutral
        ? scheme.onSurfaceVariant.withValues(alpha: 0.6)
        : (isGood ? Colors.green : Colors.redAccent);
    final icon = isNeutral
        ? Icons.remove_rounded
        : (isIncrease
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: badgeColor),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            context.l10n
                .oncekiDonemeGorePercent(percent.abs().toStringAsFixed(0)),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }
}
