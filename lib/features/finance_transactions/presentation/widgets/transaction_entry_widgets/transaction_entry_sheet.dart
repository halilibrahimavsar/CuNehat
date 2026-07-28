import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_fields.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/approve_recurring_transaction_usecase.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/save_recurring_transaction_usecase.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_event.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
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
          onSave: (transaction, recurringFrequency) {
            Navigator.pop(sheetContext);

            // Send to BLoC
            if (initialTransaction != null) {
              context.read<TransactionBloc>().add(
                    UpdateTransactionEvent(
                      newTransaction: transaction,
                      previousTransaction: initialTransaction,
                    ),
                  );
            } else {
              context.read<TransactionBloc>().add(
                    AddTransactionEvent(transaction),
                  );

              if (recurringFrequency != null) {
                // Şablonu da kaydet
                // Şablonun id'si uuid ile oluşturulmalı, ama burada uuid paketi
                // var mı? Evet, UidGenerator kullanabiliriz.
                // Çapa, işlemin KENDİ gününden alınır — hesaplanan ilk
                // vadeden değil: 31 Oca'lık bir işlemde ilk vade 28 Şub'a
                // kenetlenir ve çapayı oradan türetmek şablonu kalıcı olarak
                // 28'e sabitlerdi.
                final template = RecurringTransactionEntity(
                  id: UidGenerator.generateV7(),
                  userId: userId,
                  walletId: walletId,
                  title: transaction.title,
                  tag: transaction.tag,
                  amount: transaction.amount,
                  type: type,
                  frequency: recurringFrequency,
                  nextExecutionDate: _calculateNextDate(
                      transaction.date, recurringFrequency),
                  anchorDay: transaction.date.day,
                );
                final saveUsecase = getIt<SaveRecurringTransactionUsecase>();
                final pendingBloc = context.read<PendingRecurringBloc>();
                // Geçmiş tarihli bir işleme tekrar eklenirse şablon ANINDA
                // vadesi gelmiş olur; bekleyen liste tazelenmezse hatırlatma
                // ancak ana sayfa yeniden kurulduğunda çıkardı.
                saveUsecase(template).then(
                  (_) => pendingBloc.add(const LoadPendingTransactionsEvent()),
                );
              }
            }
          },
          onCancel: () => Navigator.pop(sheetContext),
        );
      },
    );
  }

  static DateTime _calculateNextDate(DateTime from, RecurringFrequency freq) =>
      // Ay sonu taşmasına karşı clamp'li ortak hesap (31 Oca → 28 Şub).
      // İlk vade olduğundan çapa işlemin kendi günüdür.
      ApproveRecurringTransactionUsecase.nextExecutionDateAfter(
        from,
        freq,
        anchorDay: from.day,
      );
}
