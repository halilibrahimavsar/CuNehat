// lib/features/finance_transections/presentation/widgets/transaction_entry_sheet.dart
import 'package:cunehat/features/finance_transections/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transections/presentation/widgets/compare_widgets/finance_entry_widget.dart';
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
          onSave: (transaction) {
            // ⚠️ FIX: Now receives TransactionEntity directly
            Navigator.pop(sheetContext);

            // Send to BLoC
            if (initialTransaction != null) {
              context.read<TransactionBloc>().add(
                    UpdateTransactionEvent(transaction),
                  );
            } else {
              context.read<TransactionBloc>().add(
                    AddTransactionEvent(transaction),
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
