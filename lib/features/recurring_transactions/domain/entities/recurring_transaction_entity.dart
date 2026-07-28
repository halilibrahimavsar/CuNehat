// lib/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart

import 'package:equatable/equatable.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'recurring_frequency_enum.dart';

class RecurringTransactionEntity extends Equatable {
  final String id;
  final String userId;
  final String walletId;
  final String title;
  final String tag;
  final double amount;
  final TransactionTypeModel type;
  final RecurringFrequency frequency;
  final DateTime nextExecutionDate;
  final bool isActive;

  /// Şablonun ayın kaçında tekrarlayacağı (1–31). Aylık/yıllık ilerletmenin
  /// çapası; günlük/haftalık frekansta kullanılmaz.
  ///
  /// Neden ayrı alan: vade tarihi kısa aylarda kenetlenir (31 Oca → 28 Şub).
  /// Bir sonraki vade kenetlenmiş tarihten hesaplanırsa gün kalıcı olarak
  /// aşağı çekilir ve ayın 29/30/31'inde tekrarlayan her şablon (maaş, kira,
  /// kart kesim tarihi) ilk Şubat'tan sonra sonsuza dek 28'e kayar. Kenetleme
  /// tersine çevrilemediği için asıl gün ayrıca saklanmak zorunda.
  ///
  /// Şablon oluşturulurken ilk vadenin gününden türetilir; sonradan değişmez.
  final int anchorDay;

  const RecurringTransactionEntity({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.title,
    required this.tag,
    required this.amount,
    required this.type,
    required this.frequency,
    required this.nextExecutionDate,
    required this.anchorDay,
    this.isActive = true,
  });

  /// Çapayı ilk vade tarihinden türeterek şablon kurar. Oluşturma yollarının
  /// tamamı bunu kullanmalı: [anchorDay]'i elle geçmek, kenetlenmiş bir
  /// tarihten (28 Şub) çapa üretme hatasına açık.
  factory RecurringTransactionEntity.startingOn({
    required String id,
    required String userId,
    required String walletId,
    required String title,
    required String tag,
    required double amount,
    required TransactionTypeModel type,
    required RecurringFrequency frequency,
    required DateTime firstExecutionDate,
    bool isActive = true,
  }) =>
      RecurringTransactionEntity(
        id: id,
        userId: userId,
        walletId: walletId,
        title: title,
        tag: tag,
        amount: amount,
        type: type,
        frequency: frequency,
        nextExecutionDate: firstExecutionDate,
        anchorDay: firstExecutionDate.day,
        isActive: isActive,
      );

  RecurringTransactionEntity copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? title,
    String? tag,
    double? amount,
    TransactionTypeModel? type,
    RecurringFrequency? frequency,
    DateTime? nextExecutionDate,
    int? anchorDay,
    bool? isActive,
  }) {
    return RecurringTransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
      anchorDay: anchorDay ?? this.anchorDay,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        title,
        tag,
        amount,
        type,
        frequency,
        nextExecutionDate,
        anchorDay,
        isActive,
      ];
}
