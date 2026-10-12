import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/transaction_entity.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class GetTransactionsEvent extends TransactionEvent {
  final String userId;
  final String walletId;
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionTypeModel? type;

  const GetTransactionsEvent({
    required this.userId,
    required this.walletId,
    this.startDate,
    this.endDate,
    this.type,
  });

  @override
  List<Object?> get props => [userId, walletId, startDate, endDate, type];
}

class AddTransactionEvent extends TransactionEvent {
  final TransactionEntity transaction;

  const AddTransactionEvent(this.transaction);

  @override
  List<Object> get props => [transaction];
}

/// Birden çok işlemi (kart taksitleri) tek seferde ekler: tek bakiye
/// senkronu, tek defter bildirimi.
class AddTransactionsEvent extends TransactionEvent {
  final List<TransactionEntity> transactions;

  const AddTransactionsEvent(this.transactions);

  @override
  List<Object> get props => [transactions];
}

class UpdateTransactionEvent extends TransactionEvent {
  final TransactionEntity previousTransaction;
  final TransactionEntity newTransaction;

  const UpdateTransactionEvent({
    required this.previousTransaction,
    required this.newTransaction,
  });

  @override
  List<Object> get props => [
        previousTransaction,
        newTransaction,
      ];
}

/// Birden çok işlemin kategorisini TEK eylemde değiştirir (defterde çoklu
/// seçim). Sistem ve benimsenmiş satırlar atlanır; tutar ve tür değişmediği
/// için bakiye etkilenmez, ama bütçe/rapor dinleyicileri bir kez uyarılır.
///
/// Kategorinin türü (gider/gelir) satırın türüyle uyuşmalıdır; uyuşmayanları
/// ayıklamak çağıranın işidir — bloc kategori deposunu bilmez.
class ChangeTransactionsCategoryEvent extends TransactionEvent {
  final List<TransactionEntity> transactions;
  final String categoryId;

  const ChangeTransactionsCategoryEvent({
    required this.transactions,
    required this.categoryId,
  });

  @override
  List<Object?> get props => [transactions, categoryId];
}

/// Birden çok işlemi TEK eylemde günceller (taksitli alışverişin toplamını,
/// adını ya da kategorisini düzenlemek — bkz. `redistributeInstallments`).
/// Sistem ve benimsenmiş satırlar atlanır; bakiye cüzdan başına bir kez
/// yeniden türetilir.
class UpdateTransactionsEvent extends TransactionEvent {
  /// Satırların YENİ hâlleri (kimlikleri var olan kayıtlarınki).
  final List<TransactionEntity> transactions;

  /// Mesajda görünen ad ("Laptop").
  final String label;

  const UpdateTransactionsEvent(this.transactions, {required this.label});

  @override
  List<Object?> get props => [transactions, label];
}

class DeleteTransactionEvent extends TransactionEvent {
  final String transactionId;

  const DeleteTransactionEvent(this.transactionId);

  @override
  List<Object> get props => [transactionId];
}

/// Birden çok işlemi TEK eylemde siler (taksit grubu): tek bakiye senkronu,
/// tek bildirim, tek "Geri al" (hepsini geri getirir). Sistem işlemleri
/// atlanır.
class DeleteTransactionsEvent extends TransactionEvent {
  final List<String> transactionIds;

  /// Mesajda görünen ad ("Laptop"); verilmezse ilk satırın başlığı.
  final String? label;

  const DeleteTransactionsEvent(this.transactionIds, {this.label});

  @override
  List<Object?> get props => [transactionIds, label];
}
