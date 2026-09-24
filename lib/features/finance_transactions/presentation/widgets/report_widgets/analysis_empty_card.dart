import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// Boş durum kartından sunulan bir eylem.
typedef AnalysisEmptyAction = ({String label, VoidCallback onTap});

/// Rapor ve İçgörü sayfalarının ortak "burada gösterilecek bir şey yok" kartı.
///
/// Eskiden iki sayfa bu durumu iki ayrı biçimde ve YANLIŞ anlatıyordu: dönemde
/// yalnız para taşıma hareketi (kart ödemesi, transfer) varken İçgörü "Bu
/// dönemde işlem yok" diyordu (işlemler sayfası aynı dönemde o satırı
/// gösterirken), Rapor ise 0/0 özet, "↓%100 önceki döneme göre" rozeti ve
/// boş eksenli bir grafik çiziyordu. Kart NEDENİ söyler ve kullanıcıya bir
/// sonraki adımı ([actions]) sunar; bir eylem yoksa yalnız açıklar.
class AnalysisEmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;

  /// Nedeni anlatan satırlar; her biri ayrı paragraf.
  final List<String> lines;

  /// İlki birincil (dolgulu) düğme, gerisi metin düğmesi olarak çizilir.
  final List<AnalysisEmptyAction> actions;

  const AnalysisEmptyCard({
    super.key,
    required this.icon,
    required this.title,
    this.lines = const [],
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metin tek cümle okunur; düğmeler birleştirilmez, yoksa TalkBack'te
          // ayrı ayrı etkinleştirilemezler.
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 22, color: scheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                for (final line in lines) ...[
                  const SizedBox(height: 8),
                  Text(
                    line,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            // Wrap: büyük yazı ölçeğinde düğmeler alt satıra iner, taşmaz.
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (var i = 0; i < actions.length; i++)
                  i == 0
                      ? FilledButton.tonal(
                          onPressed: actions[i].onTap,
                          child: Text(actions[i].label),
                        )
                      : TextButton(
                          onPressed: actions[i].onTap,
                          child: Text(actions[i].label),
                        ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
