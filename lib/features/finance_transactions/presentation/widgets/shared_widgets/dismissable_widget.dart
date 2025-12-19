import 'package:cunehat/core/shared/dialogs/confirmation_delete_dialog.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DismissableWidget extends StatelessWidget {
  final TransactionWithBalance item;
  final Widget child;
  const DismissableWidget({super.key, required this.item, required this.child});

  @override
  Widget build(BuildContext context) {
    final transaction = item.transaction;
    return Dismissible(
      key: Key(transaction.id ?? ''),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final confirmed = await ConfirmDeleteDialog.show(
            context,
            title: transaction.title,
          );

          if (confirmed == true && context.mounted) {
            if (transaction.id != null) {
              context.read<TransactionBloc>().add(
                    DeleteTransactionEvent(transaction.id!),
                  );
              return true;
            }
          }
          return false;
        } else {
          TransactionSheetHandler.showSheet(
            context: context,
            userId: transaction.userId,
            walletId: transaction.walletId,
            type: transaction.type,
            initialTransaction: transaction,
          );
          return false;
        }
      },
      background: _buildDismissBackground(
        alignment: Alignment.centerLeft,
        color: Colors.blue,
        icon: Icons.edit,
        text: 'Düzenle',
      ),
      secondaryBackground: _buildDismissBackground(
        alignment: Alignment.centerRight,
        color: Colors.red,
        icon: Icons.delete,
        text: 'Sil',
      ),
      child: child,
    );
  }

  Widget _buildDismissBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ] else ...[
            Text(text,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white),
          ],
        ],
      ),
    );
  }
}
