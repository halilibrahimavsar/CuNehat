import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// Dönemin manşet kartı — iki yüzü var ve ikisi de gösterilmek zorunda.
///
/// Eskiden yalnız olumlu yüz vardı: harcanabilir tutar ≤ 0 olduğunda kart
/// TAMAMEN kayboluyordu. Yani kullanıcı en çok uyarıya ihtiyaç duyduğu anda
/// hiçbir şey görmüyor, hatta "kart yok" durumunu "sorun yok" diye
/// okuyabiliyordu. [InsightOverspentCard] o boşluğu doldurur.
class DailySafeToSpendCard extends StatelessWidget {
  final double dailySafeAmount;
  final int remainingDays;

  /// Dönemin kalanında vadesi gelecek düzenli giderler; 0 ise satır çizilmez.
  final double upcomingObligations;

  final MoneyWriter money;

  const DailySafeToSpendCard({
    super.key,
    required this.dailySafeAmount,
    required this.remainingDays,
    required this.upcomingObligations,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return _InsightPulseCard(
      icon: Icons.shield_outlined,
      accent: AppGradients.savings,
      title: context.l10n.insightDailyLimitTitle,
      value: money(dailySafeAmount),
      valueColor: AppGradients.savings,
      description: context.l10n.insightDailyLimitDesc(remainingDays),
      footnote: upcomingObligations > 0
          ? context.l10n
              .insightDailyLimitObligations(money(upcomingObligations))
          : null,
    );
  }
}

/// Dönemin önünde gün var ama harcanacak bir şey kalmadı.
class InsightOverspentCard extends StatelessWidget {
  /// Açığın büyüklüğü (pozitif olarak yazılır).
  final double shortfall;
  final int remainingDays;
  final double upcomingObligations;
  final MoneyWriter money;

  const InsightOverspentCard({
    super.key,
    required this.shortfall,
    required this.remainingDays,
    required this.upcomingObligations,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return _InsightPulseCard(
      icon: Icons.report_gmailerrorred_rounded,
      accent: AppGradients.debt,
      title: context.l10n.insightOverspentTitle,
      value: money(shortfall),
      valueColor: AppGradients.debt,
      description:
          context.l10n.insightOverspentDesc(remainingDays, money(shortfall)),
      footnote: upcomingObligations > 0
          ? context.l10n
              .insightDailyLimitObligations(money(upcomingObligations))
          : null,
    );
  }
}

/// İki manşet kartının ortak gövdesi.
class _InsightPulseCard extends StatelessWidget {
  const _InsightPulseCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.value,
    required this.valueColor,
    required this.description,
    this.footnote,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String value;
  final Color valueColor;
  final String description;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        accent: accent,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                  if (footnote != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.event_repeat_rounded,
                            size: 12,
                            color:
                                scheme.onSurfaceVariant.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            footnote!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
