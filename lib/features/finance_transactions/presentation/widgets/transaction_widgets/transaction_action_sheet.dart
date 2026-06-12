import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';

enum TransactionAction { edit, delete }

class TransactionActionSheet extends StatelessWidget {
  final TransactionEntity transaction;
  final Color accent;

  const TransactionActionSheet({
    super.key,
    required this.transaction,
    required this.accent,
  });

  static Future<TransactionAction?> show(
    BuildContext context, {
    required TransactionEntity transaction,
    required Color accent,
  }) {
    return showModalBottomSheet<TransactionAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionActionSheet(
        transaction: transaction,
        accent: accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      transaction.isIncome
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      transaction.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            _tile(
              context,
              icon: Icons.edit_rounded,
              color: Colors.blueGrey,
              title: 'Düzenle',
              subtitle: 'Tutar, tarih, kategori ve diğer detaylar',
              action: TransactionAction.edit,
            ),
            _tile(
              context,
              icon: Icons.delete_outline_rounded,
              color: Colors.red,
              title: 'İşlemi Sil',
              subtitle: 'Bakiye eski haline döner',
              action: TransactionAction.delete,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required TransactionAction action,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: action == TransactionAction.delete ? Colors.red : cs.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      onTap: () => Navigator.pop(context, action),
    );
  }
}
