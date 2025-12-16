import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionSheetHandler {
  static void showSheet({
    required BuildContext context,
    required String userId,
    required String walletId,
    required TransactionTypeModel type,
    TransactionEntity? initialTransaction,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return TransactionFormSheet(
          walletId: walletId,
          userId: userId,
          isExpense: type == TransactionTypeModel.expense,
          initialTransaction: initialTransaction,
          onSave: (transaction) {
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
    String walletId, {
    TransactionEntity? initialTransaction,
  }) {
    showSheet(
      context: context,
      userId: userId,
      walletId: walletId,
      type: TransactionTypeModel.expense,
      initialTransaction: initialTransaction,
    );
  }

  static void showIncomeSheet(
    BuildContext context,
    String userId,
    String walletId, {
    TransactionEntity? initialTransaction,
  }) {
    showSheet(
      context: context,
      userId: userId,
      walletId: walletId,
      type: TransactionTypeModel.income,
      initialTransaction: initialTransaction,
    );
  }
}
