import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:flutter/material.dart';

/// Bütçelerin toplu görünümü.
///
/// **Neden gerekli:** bütçe ilerlemesi yalnız ilgili kategori satırının
/// altındaki ince çubukta görünüyordu. Yani "bu ay hangi bütçeleri aştım"
/// sorusunun cevabı için listeyi baştan sona taramak gerekiyordu — üstelik
/// aşılan bütçe listenin altlarında, küçük bir kalemin yanında olabilir.
///
/// Kart üç şeyi söyler: kaç bütçeden kaçı aşıldı, hepsinin toplamı ne durumda,
/// ve **limite en yakın olanlar** hangileri. Sıralama tamamlanma oranına göre:
/// "1.000 TL'lik bütçenin 980'i" 20.000 TL'lik bütçenin 12.000'inden daha
/// acildir.
class ReportBudgetSummaryCard extends StatelessWidget {
  /// Dönemdeki bütçe durumları.
  final List<BudgetStatus> statuses;

  final void Function(BudgetStatus status) onTap;

  const ReportBudgetSummaryCard({
    super.key,
    required this.statuses,
    required this.onTap,
  });

  /// En fazla kaç satır listelenir. Tamamı zaten Bütçeler sayfasında.
  static const int maxRows = 3;

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final money = MoneyWriter.of(context);

    final exceeded = statuses.where((s) => s.isExceeded).length;
    final totalLimit = statuses.fold<double>(0, (s, b) => s + b.limit);
    final totalSpent = statuses.fold<double>(0, (s, b) => s + b.spent);

    // Tamamlanma oranına göre azalan — limite en yakın olan en acil.
    final ranked = [...statuses]..sort((a, b) => b.ratio.compareTo(a.ratio));

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                exceeded > 0
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
                color: exceeded > 0 ? Colors.redAccent : Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exceeded > 0
                      ? context.l10n.reportBudgetExceededCount(
                          '${statuses.length}', '$exceeded')
                      : context.l10n
                          .reportBudgetAllWithinLimit('${statuses.length}'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Toplam: bütün bütçelerin tek çubuğu.
          _Bar(
            ratio: totalLimit <= 0 ? 0 : (totalSpent / totalLimit).clamp(0, 1),
            isExceeded: totalSpent > totalLimit,
            height: 8,
            scheme: scheme,
          ),
          const SizedBox(height: 6),
          Text(
            '${money(totalSpent)} / ${money(totalLimit)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Divider(color: scheme.onSurface.withValues(alpha: 0.08), height: 20),
          for (final status in ranked.take(maxRows))
            _BudgetRow(
              status: status,
              money: money,
              theme: theme,
              onTap: () => onTap(status),
            ),
          if (statuses.length > maxRows)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                context.l10n
                    .reportBudgetMoreCount('${statuses.length - maxRows}'),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bir kategorinin dönem içindeki bütçe durumu.
class BudgetStatus {
  /// Kategori kimliği (`TransactionEntity.tag`).
  final String categoryId;

  /// Kullanıcıya gösterilecek ad.
  final String label;

  final double spent;
  final double limit;

  const BudgetStatus({
    required this.categoryId,
    required this.label,
    required this.spent,
    required this.limit,
  });

  bool get isExceeded => spent > limit;

  /// Tamamlanma oranı; çubuk için tavana kırpılır ama SIRALAMA kırpılmamış
  /// değeri kullanır — %300 aşan bütçe %101 aşandan önce gelmeli.
  double get ratio => limit <= 0 ? 0 : spent / limit;
}

class _BudgetRow extends StatelessWidget {
  final BudgetStatus status;
  final MoneyWriter money;
  final ThemeData theme;
  final VoidCallback onTap;

  const _BudgetRow({
    required this.status,
    required this.money,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final percentText = formatPercent(status.ratio * 100);

    return Semantics(
      button: true,
      label: '${status.label}, $percentText, '
          '${money(status.spent)} / ${money(status.limit)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      status.label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    percentText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          status.isExceeded ? Colors.redAccent : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              _Bar(
                ratio: status.ratio.clamp(0, 1),
                isExceeded: status.isExceeded,
                height: 5,
                scheme: scheme,
              ),
              const SizedBox(height: 4),
              Text(
                '${money(status.spent)} / ${money(status.limit)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double ratio;
  final bool isExceeded;
  final double height;
  final ColorScheme scheme;

  const _Bar({
    required this.ratio,
    required this.isExceeded,
    required this.height,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: ratio.toDouble(),
        minHeight: height,
        backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
        valueColor: AlwaysStoppedAnimation(
          isExceeded ? Colors.redAccent : Colors.green,
        ),
      ),
    );
  }
}
