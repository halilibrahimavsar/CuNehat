import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/core/shared/widgets/dismissable_widget.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

/// A simplified, premium transaction card displaying transaction details, amount, and running balance.
class TransactionCard extends StatelessWidget {
  final BuildContext context;
  final TransactionWithBalance item;
  final bool isListView;

  const TransactionCard({
    super.key,
    required this.context,
    required this.item,
    required this.isListView,
  });

  @override
  Widget build(BuildContext context) {
    final t = item.transaction;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = t.isIncome ? Colors.green : Colors.redAccent;

    return DismissableWidget<TransactionWithBalance>(
      item: item,
      dismissKey: t.id ?? '',
      onDelete: (item) async {
        // System transactions cannot be deleted manually
        if (t.isSystem) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Bu işlem otomatik oluşturuldu. İlgili borç/yatırım/alacak kaydından silin.'),
            ),
          );
          return false;
        }
        final confirmed = await IboDialog.showConfirmation(
          context,
          'İşlem Sil',
          '${t.title} işlemini silmek istediğinizden emin misiniz?',
        );

        if (confirmed == true && context.mounted) {
          if (t.id != null) {
            context.read<TransactionBloc>().add(
                  DeleteTransactionEvent(t.id!),
                );
            return true;
          }
        }
        return false;
      },
      onEdit: (item) {
        if (t.isSystem) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Otomatik işlem düzenlenemez. İlgili borç/yatırım/alacak kaydından değiştirin.'),
            ),
          );
          return;
        }
        TransactionSheetHandler.showSheet(
          context: context,
          userId: t.userId,
          walletId: t.walletId,
          type: t.type,
          initialTransaction: t,
        );
      },
      child: AppCard(
        accent: accent,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Transaction icon container
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Icon(
                t.isIncome
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Transaction details (Title, Tag, and Time)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      if (t.isSystem) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 12,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Tag and time grouped in a clean single line
                  Text(
                    '${t.tag}  •  ${AppFormatters.time.format(t.date)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Amount and running balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SignedAmountDisplay(
                  amount: t.amount,
                  isExpense: t.isExpense,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                // Simplified, elegant running balance display
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Bakiye: ',
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    AmountDisplay(
                      amount: item.balanceAfter,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: item.balanceAfter >= 0
                            ? Colors.blue.withValues(alpha: 0.85)
                            : Colors.orange.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
