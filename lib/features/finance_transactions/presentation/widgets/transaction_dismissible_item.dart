// ==========================================
// lib/features/transaction/presentation/widgets/transaction_dismissible_item.dart
import 'package:flutter/material.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionDismissibleItem extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransactionDismissibleItem({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(transaction.id ?? ''),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Delete
          onDelete();
          return false;
        } else {
          // Edit
          onEdit();
          return false;
        }
      },
      background: _buildBackground(
        alignment: Alignment.centerLeft,
        color: Colors.blue,
        icon: Icons.edit,
        text: 'Düzenle',
      ),
      secondaryBackground: _buildBackground(
        alignment: Alignment.centerRight,
        color: Colors.red,
        icon: Icons.delete,
        text: 'Sil',
      ),
      child: ListTile(
        title: Text(transaction.title),
        subtitle: Text(transaction.tag),
        trailing: Text(
          '${transaction.isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)} ₺',
          style: TextStyle(
            color: transaction.isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBackground({
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
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white),
          ],
        ],
      ),
    );
  }
}
