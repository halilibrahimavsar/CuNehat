// YENİ WIDGET: Tema Seçimi Dropdown'ı
import 'package:cunehat/config/theme/bloc/theme_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeDropdown extends StatelessWidget {
  const ThemeDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    // Mevcut temayı dinle
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Uygulama Teması',
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
            items: <String>['Dark', 'NeoMorphism'] // Mevcut tema isimleriniz
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                // Yeni tema seçildiğinde BLoC'a event gönder
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
