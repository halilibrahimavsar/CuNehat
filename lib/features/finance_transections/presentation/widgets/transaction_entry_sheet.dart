// ==========================================
// lib/features/transaction/presentation/widgets/finance_entry_handler.dart
import 'package:cunehat/features/compare/presentation/widgets/finance_entry_widget.dart';
import 'package:cunehat/features/finance_transections/presentation/bloc/transection_bloc.dart';
import 'package:cunehat/features/finance_transections/presentation/bloc/transection_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionSheetHandler {
  static void showSheet({
    required BuildContext context,
    required String userId,
    required String walletId,
    required TransactionType type,
    TransactionEntity? initialTransaction,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FinanceEntryWidget(
          walletId: walletId,
          isExpense: type == TransactionType.expense,
          initialData: initialTransaction != null
              ? FinanceInitialData(
                  id: initialTransaction.id,
                  title: initialTransaction.title,
                  amount: initialTransaction.amount,
                  tag: initialTransaction.tag,
                  date: initialTransaction.date,
                  time: initialTransaction.time,
                  walletId: initialTransaction.walletId,
                )
              : null,
          onSave: (item) {
            Navigator.pop(sheetContext);

            // BLoC'a gönder
            if (initialTransaction != null) {
              // Update
              context.read<TransactionBloc>().add(
                    UpdateTransactionEvent(
                      TransactionEntity(
                        id: initialTransaction.id,
                        userId: userId,
                        walletId: walletId,
                        title: item['title'],
                        tag: item['tag'],
                        amount: item['amount'],
                        date: item['date'],
                        time: item['time'],
                        type: type,
                      ),
                    ),
                  );
            } else {
              // Add
              context.read<TransactionBloc>().add(
                    AddTransactionEvent(
                      TransactionEntity(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        userId: userId,
                        walletId: walletId,
                        title: item['title'],
                        tag: item['tag'],
                        amount: item['amount'],
                        date: item['date'],
                        time: item['time'],
                        type: type,
                      ),
                    ),
                  );
            }
          },
          onCancel: () => Navigator.pop(sheetContext),
        );
      },
    );
  }

  static void showExpenseSheet(
    BuildContext context,
    String userId,
    String walletId,
  ) {
    showSheet(
      context: context,
      userId: userId,
      walletId: walletId,
      type: TransactionType.expense,
    );
  }

  static void showIncomeSheet(
    BuildContext context,
    String userId,
    String walletId,
  ) {
    showSheet(
      context: context,
      userId: userId,
      walletId: walletId,
      type: TransactionType.income,
    );
  }
}
