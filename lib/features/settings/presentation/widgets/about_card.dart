import 'package:flutter/material.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';

/// Card displaying app information and logout option, styled with AppCard.
class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.info_outline, color: scheme.primary),
            title: Text(
              'Versiyon',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            trailing: Text(
              '1.0.0',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Divider(height: 1, color: scheme.outline.withValues(alpha: 0.1)),
          ListTile(
            leading: Icon(Icons.code, color: scheme.primary),
            title: Text(
              'Geliştirici',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            trailing: Text(
              'İbo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
