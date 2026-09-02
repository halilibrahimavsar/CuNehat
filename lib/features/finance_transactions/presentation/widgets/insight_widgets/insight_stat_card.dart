import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// İçgörüler sayfasındaki tekli bilgi kartı (günlük ortalama, en çok harcanan
/// gün vb.).
///
/// [hint] sayının NASIL üretildiğini yazar. Gerekli, çünkü sayfadaki
/// rakamların çoğu bir bölme sonucu: "günlük ortalama" yaşanan güne,
/// "en çok harcadığınız gün" o günün kaç kez geçtiğine bölünüyor. Böleni
/// söylemeyen bir ortalama, kullanıcının kafasında kendi (yanlış) bölenini
/// kurmasına yol açar.
class InsightStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  /// Sayının altına yazılan küçük açıklama; yoksa çizilmez.
  final String? hint;

  final Color? accent;

  /// Verilirse kart dokunulabilir olur ve sağına bir ok çizilir — dokunma
  /// duyurulmadan kalmasın.
  final VoidCallback? onTap;

  const InsightStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
    this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = accent ?? AppGradients.transactions;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        section: AppSection.transactions,
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      hint!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }
}
