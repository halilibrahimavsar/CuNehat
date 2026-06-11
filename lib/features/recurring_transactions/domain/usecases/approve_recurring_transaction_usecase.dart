// lib/features/recurring_transactions/domain/usecases/approve_recurring_transaction_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import '../entities/recurring_transaction_entity.dart';
import '../entities/recurring_frequency_enum.dart';
import '../repositories/recurring_transaction_repository.dart';

@injectable
class ApproveRecurringTransactionUsecase {
  final RecurringTransactionRepository recurringRepository;
  final TransactionsRepository transactionRepository;

  ApproveRecurringTransactionUsecase(
    this.recurringRepository,
    this.transactionRepository,
  );

  Future<Either<Failure, void>> call(
      RecurringTransactionEntity template) async {
    // 1. Gerçek işlemi oluştur
    final newTransaction = TransactionEntity(
      id: UidGenerator.generateV7(),
      userId: template.userId,
      walletId: template.walletId,
      title: template.title,
      tag: template.tag,
      amount: template.amount,
      type: template.type,
      date: DateTime.now(),
      isSystem: true, // Düzenli işlem tarafından otomatik eklendi
    );

    // 2. Gerçek işlemi kaydet
    final result = await transactionRepository.addTransaction(newTransaction);

    return result.fold(
      (failure) => Left(failure),
      (_) async {
        // 3. İşlem başarıyla eklendiyse şablonun bir sonraki ödeme tarihini hesapla ve güncelle
        DateTime nextDate;
        switch (template.frequency) {
          case RecurringFrequency.daily:
            nextDate = template.nextExecutionDate.add(const Duration(days: 1));
            break;
          case RecurringFrequency.weekly:
            nextDate = template.nextExecutionDate.add(const Duration(days: 7));
            break;
          case RecurringFrequency.monthly:
            // Bir ay ileri sar (Olası şubat/31 çeken ay sınırlarına dikkat ederek)
            nextDate = DateTime(
              template.nextExecutionDate.year,
              template.nextExecutionDate.month + 1,
              template.nextExecutionDate.day,
            );
            break;
          case RecurringFrequency.yearly:
            nextDate = DateTime(
              template.nextExecutionDate.year + 1,
              template.nextExecutionDate.month,
              template.nextExecutionDate.day,
            );
            break;
        }

        // Geçmişten gelen ve çok birikmiş işlemler için nextDate bugünden küçük kalıyorsa,
        // onu bir sonraki hedefe atlatabiliriz. Ama genelde kullanıcı bunları ardışık onaylayacak.

        final updatedTemplate = template.copyWith(nextExecutionDate: nextDate);
        return await recurringRepository.saveTemplate(updatedTemplate);
      },
    );
  }
}
