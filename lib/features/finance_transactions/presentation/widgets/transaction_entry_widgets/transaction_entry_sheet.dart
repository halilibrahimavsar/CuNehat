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
  /// [transactionBloc] / [pendingBloc] verilmezse [context]'ten okunur.
  ///
  /// Cüzdan yönetimi sheet'i gibi bu bloc'ların ÜSTÜNDE olmayan yüzeylerden
  /// (kendi route'unda açılır, ana sayfanın ağacında değildir) çağrılırken
  /// açıkça geçilir. Her ikisi de DI'da factory; ayrı örnekten yazılan işlem
  /// `TransactionsChangedNotifier` üzerinden ana sayfadaki bloc'a ulaşır.
  ///
  /// [prefill]: "Yeniden ekle" — bu işlemin içeriğiyle YENİ kayıt açar.
  static void showSheet({
    required BuildContext context,
    required String userId,
    required String walletId,
    required TransactionTypeModel type,
    TransactionEntity? initialTransaction,
    TransactionEntity? prefill,
    TransactionBloc? transactionBloc,
    PendingRecurringBloc? pendingBloc,
  }) {
    // Bloc'lar KULLANILDIĞI anda çözülür (sayfa açılırken değil): çağıran
    // [context] sayfa kapandıktan sonra da ağaçta kalır.
    TransactionBloc txBloc() =>
        transactionBloc ?? context.read<TransactionBloc>();
    PendingRecurringBloc pending() =>
        pendingBloc ?? context.read<PendingRecurringBloc>();

    void addNew(TransactionEntity transaction, RecurringFrequency? frequency) {
      txBloc().add(AddTransactionEvent(transaction));
      if (frequency == null) return;

      // Çapa, işlemin KENDİ gününden alınır — hesaplanan ilk vadeden değil:
      // 31 Oca'lık bir işlemde ilk vade 28 Şub'a kenetlenir ve çapayı oradan
      // türetmek şablonu kalıcı olarak 28'e sabitlerdi.
      final template = RecurringTransactionEntity(
        id: UidGenerator.generateV7(),
        userId: userId,
        // İşlemin KENDİ cüzdanı ve türü: formdaki ödeme yöntemi seçicisi
        // kaydı sahibinden bir karta (ya da tersi) yönlendirebilir, tür
        // seçicisi de sayfa açıldıktan sonra değişebilir.
        walletId: transaction.walletId,
        title: transaction.title,
        tag: transaction.tag,
        amount: transaction.amount,
        type: transaction.type,
        frequency: frequency,
        nextExecutionDate: _calculateNextDate(transaction.date, frequency),
        anchorDay: transaction.date.day,
      );
      final pendingBloc = pending();
      // Geçmiş tarihli bir işleme tekrar eklenirse şablon ANINDA vadesi
      // gelmiş olur; bekleyen liste tazelenmezse hatırlatma ancak ana sayfa
      // yeniden kurulduğunda çıkardı.
      getIt<SaveRecurringTransactionUsecase>()(template).then(
        (_) => pendingBloc.add(const LoadPendingTransactionsEvent()),
      );
    }

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
          prefill: prefill,
          onSave: (transaction, recurringFrequency) {
            Navigator.pop(sheetContext);

            if (initialTransaction != null) {
              txBloc().add(
                UpdateTransactionEvent(
                  newTransaction: transaction,
                  previousTransaction: initialTransaction,
                ),
              );
            } else {
              addNew(transaction, recurringFrequency);
            }
          },
          // Düzenlemede "yeni" yok: tek kayıt güncellenir ve sayfa kapanır.
          onSaveAndNew: initialTransaction != null
              ? null
              : (rows, recurringFrequency) {
                  if (rows.length > 1) {
                    txBloc().add(AddTransactionsEvent(rows));
                  } else {
                    addNew(rows.single, recurringFrequency);
                  }
                },
          onSaveInstallments: (installments) {
            Navigator.pop(sheetContext);
            txBloc().add(AddTransactionsEvent(installments));
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
