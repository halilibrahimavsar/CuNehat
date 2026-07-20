import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String? id;
  final String userId;
  final String walletId;
  final String title;
  final String tag;
  final double amount;
  final DateTime date;
  final TransactionTypeModel type;

  /// Borç/yatırım/alacak kuplajı tarafından otomatik oluşturulan işlemler için
  /// true. Bu işlemler listede manuel silinemez/düzenlenemez (defterle desync
  /// olmasın); ilgili kayıttan yönetilir.
  final bool isSystem;

  /// İşleme iliştirilmiş fiş/fotoğraf görselinin dosya ADI (mutlak yol değil).
  /// Görsel `belgelerDizini/receipts/<receiptFileName>` altında saklanır; mutlak
  /// yol reinstall/cihaz değişince değişeceği için yalnız ad tutulur. Görsel
  /// binary'si yedeğe girmez — yalnız bu ad taşınır (yeni cihazda dosya yoksa
  /// "görsel bu cihazda yok" gösterilir). Ek yoksa null.
  final String? receiptFileName;

  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.title,
    required this.tag,
    required this.amount,
    required this.date,
    required this.type,
    this.isSystem = false,
    this.receiptFileName,
  });

  TransactionEntity copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? title,
    String? tag,
    double? amount,
    DateTime? date,
    TransactionTypeModel? type,
    bool? isSystem,
    String? receiptFileName,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      isSystem: isSystem ?? this.isSystem,
      receiptFileName: receiptFileName ?? this.receiptFileName,
    );
  }

  bool get isIncome => type == TransactionTypeModel.income;
  bool get isExpense => type == TransactionTypeModel.expense;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'walletId': walletId,
      'title': title,
      'tag': tag,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.name,
      'isSystem': isSystem,
      'receiptFileName': receiptFileName,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        title,
        tag,
        amount,
        date,
        type,
        isSystem,
        receiptFileName,
      ];
}
