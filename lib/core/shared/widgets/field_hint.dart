import 'package:flutter/material.dart';

/// Bir form alanının hemen altında duran tek satırlık açıklama.
///
/// Tanıtım turlarının yerini alır: bir alanın ne işe yaradığı, formun ilk
/// açılışında bir kez gösterilip kaybolan bir baloncukta değil, alanın
/// yanında ve her açılışta durur.
class FieldHint extends StatelessWidget {
  const FieldHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
