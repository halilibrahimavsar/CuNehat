import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// Güvenlik ekranının ortak satır biçimi: ikon kutusu + başlık/alt başlık +
/// sağda bir denetim. Bütün kartlar aynı ritmi paylaşsın diye tek yerde.
class SecurityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? accent;
  final VoidCallback? onTap;
  final bool enabled;

  /// Satırın altına eklenen içerik (eylem düğmeleri, çipler, uyarı).
  final Widget? footer;

  const SecurityTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.accent,
    this.onTap,
    this.enabled = true,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = accent ?? scheme.primary;
    final dim = enabled ? 1.0 : 0.45;

    return AppCard(
      accent: accent,
      onTap: enabled ? onTap : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Opacity(
                opacity: dim,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: color.withValues(alpha: 0.22)),
                  ),
                  child: Icon(icon, size: 21, color: color),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Opacity(
                  opacity: dim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: 14),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Açık/kapalı rozetleri.
class SecurityStatusPill extends StatelessWidget {
  final String label;
  final bool on;

  const SecurityStatusPill({super.key, required this.label, required this.on});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = on ? scheme.primary : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Süre seçimi için çip şeridi.
class SecurityChoiceChips extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool enabled;

  const SecurityChoiceChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          _Chip(
            label: labels[i],
            selected: i == selectedIndex,
            // "Kapalı" her zaman seçilebilir: kullanıcı kilidi kapatmakta
            // hiçbir koşulda kilitlenmemeli.
            enabled: enabled || i == 0,
            onTap: () => onSelected(i),
            scheme: scheme,
            textTheme: theme.textTheme,
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _Chip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.14)
            : scheme.onSurfaceVariant.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
