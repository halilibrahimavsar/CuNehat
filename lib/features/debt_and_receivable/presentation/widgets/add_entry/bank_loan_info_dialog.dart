import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Banka kredisi hesaplama modlarını ve mantığını açıklayan dialog.
class BankLoanInfoDialog extends StatelessWidget {
  const BankLoanInfoDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const BankLoanInfoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(context.l10n.krediHesaplamaInfoBaslik),
      content: Text(
        context.l10n.krediHesaplamaInfoGovde,
        style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.tamam),
        ),
      ],
    );
  }
}
