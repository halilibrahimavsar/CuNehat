// lib/features/recurring_transactions/domain/usecases/approve_recurring_transaction_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/utils/date_math.dart';
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

  /// [overrideAmount] yalnızca bu vadenin işlemine uygulanır; şablonun
  /// kalıcı tutarı değişmez.
  Future<Either<Failure, void>> call(
    RecurringTransactionEntity template, {
    double? overrideAmount,
  }) async {
    // 1. Gerçek işlemi oluştur
    final newTransaction = TransactionEntity(
      id: UidGenerator.generateV7(),
      userId: template.userId,
      walletId: template.walletId,
      title: template.title,
      tag: template.tag,
      amount: overrideAmount ?? template.amount,
      type: template.type,
      // Onay tarihi değil vade tarihi: birikmiş vadeler doğru aya işlensin
      // diye (bütçe ve raporlar bu tarihe göre toplar).
      date: template.nextExecutionDate,
    );

    // 2. Gerçek işlemi kaydet
    final result = await transactionRepository.addTransaction(newTransaction);

    return result.fold(
      (failure) => Left(failure),
      (_) async {
        // 3. İşlem başarıyla eklendiyse şablonun bir sonraki ödeme tarihini
        // hesapla ve güncelle
        final nextDate = nextExecutionDateAfter(
          template.nextExecutionDate,
          template.frequency,
        );

        final updatedTemplate = template.copyWith(nextExecutionDate: nextDate);
        return await recurringRepository.saveTemplate(updatedTemplate);
      },
    );
  }

  /// Bir sonraki vade tarihini hesaplar. Aylık/yıllık ilerletmede gün, hedef
  /// ayın son gününe clamp'lenir (31 Oca → 28/29 Şub); aksi halde Dart'ın
  /// tarih normalizasyonu vadeyi sonraki ayın başına kaydırır.
  static DateTime nextExecutionDateAfter(
    DateTime current,
    RecurringFrequency frequency,
  ) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return current.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return current.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return addMonthsClamped(current, 1);
      case RecurringFrequency.yearly:
        return addMonthsClamped(current, 12);
    }
  }
}
