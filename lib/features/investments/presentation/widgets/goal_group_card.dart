import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/goal_progress.dart';
import 'package:cunehat/features/investments/presentation/widgets/goal_category.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_card.dart';
import 'package:flutter/material.dart';

/// Hedefin liste içindeki açılır-kapanır grup başlığı ve üyeleri.
///
/// Karmaşıklık burada toplanır: ilerleme çubuğu ARTIK KAYIT KARTINDA DEĞİL,
/// hedefte. Kart yalnız varlığın kendisini anlatır (miktar, değer, kâr),
/// "hedefin neresindeyim" sorusunu bu başlık cevaplar.
class GoalGroupCard extends StatelessWidget {
  final GoalProgress progress;
  final String currency;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<InvestmentEntity> onMemberTap;
  final VoidCallback onAddAsset;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GoalGroupCard({
    super.key,
    required this.progress,
    required this.currency,
    required this.expanded,
    required this.onToggle,
    required this.onMemberTap,
    required this.onAddAsset,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final goal = progress.goal;
    final accent = goal.color;
    final category = GoalCategory.byKey(goal.category);
    final reached = progress.isReached;

    return AppCard(
      accent: accent,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          category?.icon ?? Icons.flag_rounded,
                          color: accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // İki tutar tek satırda kalmalı: sarmalayınca
                            // başlık üç satıra çıkıyordu (ölçüldü: 164px
                            // alanda 72px yükseklik). Kırpmak yerine küçülür —
                            // parada üç nokta rakam kaybıdır.
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                context.l10n.hedefIlerlemeSatiri(
                                  formatMoney(progress.saved,
                                      currency: currency),
                                  formatMoney(goal.targetAmount,
                                      currency: currency),
                                ),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '%${progress.percentage.toStringAsFixed(0)}',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: reached ? Colors.green : accent,
                        ),
                      ),
                      IconButton(
                        onPressed: onToggle,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ProgressBar(
                    ratio: progress.ratio,
                    accent: accent,
                    reached: reached,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            reached
                                ? context.l10n.hedefeUlasildi
                                : context.l10n.hedefKalanTutar(
                                    formatMoney(progress.remaining,
                                        currency: currency),
                                  ),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  reached ? Colors.green : cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.hedefUyeSayisi(progress.members.length),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      _menu(context, cs),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  if (progress.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        context.l10n.hedefBosAciklama,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ...progress.members.map(
                      (member) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => onMemberTap(member),
                          child: InvestmentCard(
                            investment: member,
                            currency: currency,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onAddAsset,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(context.l10n.hedefeVarlikEkle),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        minimumSize: const Size.fromHeight(46),
                        side: BorderSide(color: accent.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context, ColorScheme cs) {
    return PopupMenuButton<int>(
      tooltip: context.l10n.hedefYonetimi,
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert_rounded, size: 20, color: cs.onSurfaceVariant),
      onSelected: (value) => value == 0 ? onEdit() : onDelete(),
      itemBuilder: (context) => [
        PopupMenuItem(value: 0, child: Text(context.l10n.hedefiDuzenle)),
        PopupMenuItem(
          value: 1,
          child: Text(
            context.l10n.hedefiSil,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double ratio;
  final Color accent;
  final bool reached;

  const _ProgressBar({
    required this.ratio,
    required this.accent,
    required this.reached,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        FractionallySizedBox(
          widthFactor: ratio.clamp(0.0, 1.0),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              gradient: reached
                  ? const LinearGradient(
                      colors: [Colors.green, Colors.lightGreen])
                  : LinearGradient(
                      colors: [accent.withValues(alpha: 0.6), accent]),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}
