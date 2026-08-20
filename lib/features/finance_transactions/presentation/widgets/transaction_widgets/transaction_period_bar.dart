import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Aktif dönemin TEK görünür kontrolü: `‹ Ağustos 2026 ›`.
///
/// Eskiden aktif tarih aralığı ekranda hiçbir yerde yazmıyordu — özet kartı
/// "NET DURUM 12.480" diyordu ama hangi dönemin neti olduğu ancak filtre
/// sayfası açılınca görülebiliyordu. Oklar dönemi kendi doğasına göre
/// kaydırır (ay ise ay, hafta ise hafta; bkz. [shiftPeriod]), etikete
/// dokunmak hızlı aralık menüsünü açar.
class TransactionPeriodBar extends StatelessWidget {
  final DateTimeRange range;
  final ValueChanged<int> onStep;
  final VoidCallback onPick;

  const TransactionPeriodBar({
    super.key,
    required this.range,
    required this.onStep,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _StepButton(
            icon: Icons.chevron_left_rounded,
            tooltip: l10n.txPeriodPrev,
            onPressed: () => onStep(-1),
          ),
          Expanded(
            child: Semantics(
              button: true,
              label: '${l10n.txPeriodPick}: ${periodLabel(range, l10n)}',
              child: InkWell(
                onTap: onPick,
                borderRadius: BorderRadius.circular(10),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    // Etiket dar ekranda kırpılmak yerine küçülür: "Karşılaştırma"
                    // modunda segment + filtre düğmesi bu satırı 360dp'de
                    // ~140dp'ye indiriyor.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        periodLabel(range, l10n),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.chevron_right_rounded,
            tooltip: l10n.txPeriodNext,
            onPressed: () => onStep(1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 22,
        // 44×44: Material'in dokunma hedefi alt sınırı. Eski ok düğmeleri
        // 32px'ti ve hareket hâlindeyken ıskalanıyordu.
        child: SizedBox(
          width: 34,
          height: 44,
          child: Icon(icon, size: 22, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Aralığın insan-okur adı: "Bugün", "Ağustos 2026", "10 – 16 Ağu", "2026"
/// ya da özel aralıkta "1 Ağu – 15 Eyl".
///
/// Ayrı ve saf tutuluyor ki widget kurmadan test edilebilsin; locale
/// [Intl.defaultLocale]'den okunur (uygulamanın geri kalanıyla aynı yol).
String periodLabel(DateTimeRange range, AppLocalizations l10n) {
  final locale = Intl.defaultLocale;
  final start = dayOf(range.start);
  final end = dayOf(range.end);
  final today = dayOf(DateTime.now());

  switch (periodKindOf(range)) {
    case PeriodKind.day:
      if (isSameDayValue(start, today)) return l10n.txPeriodToday;
      if (isSameDayValue(start, today.subtract(const Duration(days: 1)))) {
        return l10n.txPeriodYesterday;
      }
      return DateFormat.yMMMMd(locale).format(start);

    case PeriodKind.month:
      return DateFormat.yMMMM(locale).format(start);

    case PeriodKind.year:
      return DateFormat.y(locale).format(start);

    case PeriodKind.week:
    case PeriodKind.custom:
      return _rangeLabel(start, end, locale);
  }
}

String _rangeLabel(DateTime start, DateTime end, String? locale) {
  final dayMonth = DateFormat.MMMd(locale);
  if (start.year != end.year) {
    final full = DateFormat.yMMMd(locale);
    return '${full.format(start)} – ${full.format(end)}';
  }
  if (start.month == end.month) {
    return '${start.day} – ${dayMonth.format(end)}';
  }
  return '${dayMonth.format(start)} – ${dayMonth.format(end)}';
}
