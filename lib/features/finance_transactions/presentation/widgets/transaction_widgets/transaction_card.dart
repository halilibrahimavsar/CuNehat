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
    final scheme = Theme.of(context).colorScheme;
    final accent = t.isIncome ? Colors.green : Colors.redAccent;

    return DismissableWidget<TransactionWithBalance>(
      item: item,
      dismissKey: t.id ?? '',
      onDelete: (item) async {
        // Oto-işlemler (borç/yatırım/alacak kuplajı) manuel silinemez.
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Kategori ikonu
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                t.isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Detaylar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      if (t.isSystem) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.lock_outline,
                            size: 13, color: scheme.onSurfaceVariant),
                      ],
                    ],
                  ),
                  Text(
                    t.tag,
                    style: TextStyle(
                        color: scheme.onSurfaceVariant, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.time.format(t.date),
                    style: TextStyle(
                        color: scheme.onSurfaceVariant, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Tutar
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SignedAmountDisplay(
                  amount: t.amount,
                  isExpense: t.isExpense,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Kalan bakiye : ',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    AmountDisplay(
                      amount: item.balanceAfter,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.balanceAfter >= 0
                            ? Colors.blue
                            : Colors.orange,
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
