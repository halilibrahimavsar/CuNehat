import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// A premium, theme-aware view representing pending offline transactions awaiting synchronization.
class TransactionPendingPage extends StatelessWidget {
  final String userId;
  final String walletId;
  final bool showAppBar;

  const TransactionPendingPage({
    super.key,
    required this.userId,
    required this.walletId,
    this.showAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Bekleyen İşlemler'),
              centerTitle: true,
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: AppCard(
            section: AppSection.transactions,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated synchronization icon representation
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: scheme.primary.withValues(alpha: 0.4),
                        value: 1.0,
                      ),
                    ),
                    const SizedBox(
                      width: 68,
                      height: 68,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blueAccent,
                      ),
                    ),
                    Icon(
                      Icons.sync_rounded,
                      size: 36,
                      color: scheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Tüm İşlemleriniz Güncel',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bekleyen çevrimdışı işlem bulunmuyor. Cihazınız internete bağlandığında veya yeni veriler girildiğinde senkronizasyon otomatik olarak tetiklenir.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
