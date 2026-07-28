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
import 'save_recurring_transaction_usecase.dart';

@injectable
class ApproveRecurringTransactionUsecase {
  final TransactionsRepository transactionRepository;
  final SaveRecurringTransactionUsecase saveTemplate;

  ApproveRecurringTransactionUsecase(
    this.transactionRepository,
    this.saveTemplate,
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
          anchorDay: template.anchorDay,
        );

        // Doğrudan repository'ye değil kaydetme usecase'ine yazılır: bir
        // sonraki vadenin hatırlatması da orada kurulur. (Bu atlandığında
        // şablon ömür boyu yalnızca ilk vadesi için bildirim gönderiyordu.)
        return await saveTemplate(
          template.copyWith(nextExecutionDate: nextDate),
        );
      },
    );
  }

  /// Bir sonraki vade tarihini hesaplar. Aylık/yıllık ilerletmede gün, hedef
  /// ayın son gününe clamp'lenir (31 Oca → 28/29 Şub); aksi halde Dart'ın
  /// tarih normalizasyonu vadeyi sonraki ayın başına kaydırır.
  ///
  /// Kenetleme [anchorDay]'den yapılır, [current]'ın gününden DEĞİL: aksi
  /// halde kısa bir ay zinciri kalıcı olarak aşağı çeker
  /// (31 Oca → 28 Şub → 28 Mar → …) ve ayın 29/30/31'inde tekrarlayan her
  /// şablon (maaş, kira, kart kesim tarihi) ilk Şubat'tan sonra sonsuza dek
  /// 28'e kayardı. Çapayla doğru zincir: 31 Oca → 28 Şub → **31** Mar → 30 Nis.
  static DateTime nextExecutionDateAfter(
    DateTime current,
    RecurringFrequency frequency, {
    required int anchorDay,
  }) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return current.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return current.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return addMonthsAnchored(current, 1, anchorDay);
      case RecurringFrequency.yearly:
        return addMonthsAnchored(current, 12, anchorDay);
    }
  }
}
