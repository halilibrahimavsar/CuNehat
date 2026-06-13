// YENİ WIDGET: Tema Seçimi Dropdown'ı
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/settings/presentation/blocs/theme_blocs/theme_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

class ThemeSelectorDropdown extends StatelessWidget {
  const ThemeSelectorDropdown({super.key});

  /// ThemeNames key'lerini lokalize edilmiş etiketlere çevirir.
  /// Key'ler değişmez (ThemeData Map kimliği olarak kullanılır);
  /// yalnızca gösterilen metin lokalize edilir.
  String _localizeThemeName(BuildContext context, String key) {
    final l = context.l10n;
    return switch (key) {
      ThemeNames.sysLight => l.themeSysLight,
      ThemeNames.sysDark => l.themeSysDark,
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Mevcut temayı dinle
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: DropdownButtonFormField<ThemeData>(
            decoration: InputDecoration(
              labelText: context.l10n.labelUygulamaTemasi,
              prefixIcon: const Icon(Icons.palette_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: state.name, // BLoC'tan gelen mevcut tema adı
            items: state.names // Mevcut tema isimleriniz
                .map(
                  (k, v) {
                    return MapEntry(
                        k,
                        DropdownMenuItem(
                          value: v,
                          child: Text(_localizeThemeName(context, k)),
                        ));
                  },
                )
                .values
                .toList(),
            onChanged: (ThemeData? newValue) {
              if (newValue != null) {
                context
                    .read<ThemeBloc>()
                    .add(ThemeChangeEvent(themeName: newValue));
              }
            },
          ),
        );
      },
    );
  }
}
