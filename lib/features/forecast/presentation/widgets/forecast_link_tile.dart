import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_tokens.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/forecast/domain/forecast_horizon.dart';
import 'package:cunehat/features/main_feature/controllers/home_navigation_requests.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// İçgörü ve Rapor'dan Gelecek sayfasına tek satırlık geçiş.
///
/// Gelecek dikey yığının en altında; oraya kaydırmayı bilmeyen kullanıcı
/// için keşif kapısı. Yalnız seçili dönem BUGÜNÜ içeriyorsa gösterilir:
/// geçen ayın raporunda "önümüzdeki günler" bağlamsızdır. Başlık Gelecek'in
/// ufkunu yazar (dönem sonu, bkz. [forecastHorizonEnd]).
class ForecastLinkTile extends StatelessWidget {
  const ForecastLinkTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    String title;
    try {
      final prefs = context.read<TransactionFilterCubit>().periodPreferences;
      title = l10n.forecastLinkTitleUntil(AppFormatters.dayMonth
          .format(forecastHorizonEnd(prefs, DateTime.now())));
    } on ProviderNotFoundException {
      title = l10n.menuForecast;
    }
    return AppCard(
      key: const ValueKey('forecast-link'),
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => getIt<HomeNavigationRequests>()
          .openSection(TransactionsSection.forecast),
      child: Row(
        children: [
          Icon(Icons.update_rounded, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: AppType.strong)),
                Text(l10n.forecastLinkBodyPlan,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// [range] bugünü içeriyor mu (gün bazında).
bool rangeContainsToday(DateTimeRange range, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final s = DateTime(range.start.year, range.start.month, range.start.day);
  final e = DateTime(range.end.year, range.end.month, range.end.day);
  return !today.isBefore(s) && !today.isAfter(e);
}
