import 'package:cunehat/features/settings/presentation/blocs/language_bloc/language_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

class LanguageSelectorDropdown extends StatelessWidget {
  const LanguageSelectorDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: context.l10n.language,
              prefixIcon: const Icon(Icons.language),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            initialValue: state.languageCode,
            items: [
              DropdownMenuItem(
                value: 'tr',
                child: Text(context.l10n.turkish),
              ),
              DropdownMenuItem(
                value: 'en',
                child: Text(context.l10n.english),
              ),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                context.read<LanguageBloc>().add(LanguageChangeEvent(newValue));
              }
            },
          ),
        );
      },
    );
  }
}
