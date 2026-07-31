import 'package:equatable/equatable.dart';
import '../../../domain/entities/transaction_entity.dart';
import 'package:cunehat/core/services/deletion_undo_service.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  /// Helper to access transactions from any state
  List<TransactionEntity> get currentTransactions => [];

  @override
  List<Object?> get props => [];
}

class TransactionLoading extends TransactionState {
  final List<TransactionEntity> previousTransactions;

  const TransactionLoading({this.previousTransactions = const []});

  @override
  List<TransactionEntity> get currentTransactions => previousTransactions;

  @override
  List<Object> get props => [previousTransactions];
}

class TransactionLoaded extends TransactionState {
  final Map<DateTime, List<TransactionEntity>> groupedTransactions;
  final List<TransactionEntity> allTransactions;

  const TransactionLoaded({
    required this.groupedTransactions,
    required this.allTransactions,
  });

  @override
  List<TransactionEntity> get currentTransactions => allTransactions;

  @override
  List<Object> get props => [groupedTransactions, allTransactions];
}

class TransactionError extends TransactionState {
  final String message;
  final List<TransactionEntity> transactions;

  const TransactionError(this.message, {this.transactions = const []});

  @override
  List<TransactionEntity> get currentTransactions => transactions;

  @override
  List<Object> get props => [message, transactions];
}

class TransactionActionSuccess extends TransactionState {
  final String message;

  /// Defter EYLEMDEN SONRAKİ hâliyle: silinen kayıt çıkarılmış, güncellenen
  /// kayıt yenisiyle değiştirilmiş, eklenen kayıt eklenmiş olarak taşınır.
  ///
  /// Eskiden eylem ÖNCESİNDEKİ liste taşınıyordu; "bu kayıt hâlâ defterde mi?"
  /// diye soran her tüketici (ör. silme sonrası kendini kapatan detay sayfası)
  /// yapısal olarak yanlış cevap alıyordu. Yenilenmiş listeyi ayrıca beklemek
  /// gerekmesin diye eylemin sonucu doğrudan bu state'te görünür.
  final List<TransactionEntity> transactions;

  /// İşlem kaydedildi ama bakiye senkronizasyonu başarısız olduysa dolu;
  /// kullanıcıya para tutarlılığı uyarısı göstermek için.
  final String? warning;

  /// Yalnız silmede dolu: UI bunu "Geri al" eylemine bağlar.
  final DeletionUndo? undo;

  const TransactionActionSuccess(
    this.message, {
    this.transactions = const [],
    this.warning,
    this.undo,
  });

  @override
  List<TransactionEntity> get currentTransactions => transactions;

  @override
  List<Object?> get props => [message, transactions, warning, undo];
}
