import 'package:cunehat/config/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart'
    show AppSpacing;

/// Boş bir listenin / sayfanın tek görünümü: simge, başlık, tek cümle ve en
/// çok bir birincil eylem (+ isteğe bağlı ikincil eylemler).
///
/// Uygulamada sekiz ayrı boş durum uygulaması vardı; her biri kendi simge
/// boyutunu, yazı kalınlığını ve boşluğunu yazıyordu ve başlıkları üç ayrı
/// büyük harf düzenindeydi. Yeni boş durumlar bunu kullanır; eskileri yüzey
/// yüzey taşınıyor.
///
/// Kural: başlık ne olduğunu söyler ("Henüz bütçe yok"), cümle ne
/// yapılacağını ("Kategorilerine aylık harcama sınırı koy."). Açıklama iki
/// cümleyi geçmez.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.accent,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String? body;

  /// Simgenin rengi; verilmezse temanın marka rengi.
  final Color? accent;

  /// Eylemler, yukarıdan aşağıya. İlki birincildir.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = accent ?? scheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.large,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 88,
                child: Icon(icon, size: 40, color: color),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          for (var i = 0; i < actions.length; i++) ...[
            SizedBox(height: i == 0 ? AppSpacing.large : AppSpacing.small),
            actions[i],
          ],
        ],
      ),
    );
  }

  /// Boş durum eylemlerinin ortak köşesi (bkz. [AppRadius]).
  static const BorderRadius actionRadius = AppRadius.controlAll;
}
