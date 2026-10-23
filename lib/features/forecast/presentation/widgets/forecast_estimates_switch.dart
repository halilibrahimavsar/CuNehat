import 'package:cunehat/config/theme/money_colors.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/forecast/presentation/bloc/forecast_estimates_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tahmin katmanının anahtarı — Gelecek başlığında ve Ayarlar'da aynı
/// bileşen. Açıkken mor: anahtar, açtığı katmanın rengini taşır.
class ForecastEstimatesSwitch extends StatelessWidget {
  /// Ayarlar'da: uzun açıklama (ufuk ve bildirimler) ve ikon.
  final bool settings;

  /// Gösterilen değer; verilmezse kalıcı ayar. Gelecek ETKİN değeri verir:
  /// bildirimden açılışta tahmin ayar kapalıyken de görünür.
  final bool? value;

  /// Tahmin yalnız bu açılış için açık (bildirimden): alt yazı nedenini
  /// söyler.
  final bool temporary;

  /// Verilmezse kalıcı ayarı yazar.
  final ValueChanged<bool>? onChanged;

  const ForecastEstimatesSwitch({
    super.key,
    this.settings = false,
    this.value,
    this.temporary = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ForecastEstimatesCubit cubit;
    try {
      cubit = context.read<ForecastEstimatesCubit>();
    } on ProviderNotFoundException {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final on = value ?? context.forecastEstimates;
    final violet = MoneyColors.forecastText(theme.brightness);
    return SwitchListTile(
      key: const ValueKey('forecast-estimates-switch'),
      contentPadding:
          settings ? null : const EdgeInsets.symmetric(horizontal: 4),
      secondary: Icon(Icons.auto_graph_rounded,
          color: on ? violet : theme.colorScheme.onSurfaceVariant),
      title: Text(l10n.forecastEstimatesTitle),
      subtitle: Text(settings
          ? l10n.forecastEstimatesSettingDesc
          : temporary
              ? l10n.forecastEstimatesTemporaryDesc
              : (on
                  ? l10n.forecastEstimatesOnDesc
                  : l10n.forecastEstimatesOffDesc)),
      value: on,
      activeTrackColor: MoneyColors.forecast,
      onChanged: onChanged ?? cubit.set,
    );
  }
}
