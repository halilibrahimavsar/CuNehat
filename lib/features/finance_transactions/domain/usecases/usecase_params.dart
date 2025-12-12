import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';

class GetTransactionsParams {
  final String userId;
  final String walletId;
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionTypeModel? type;

  GetTransactionsParams({
    required this.userId,
    required this.walletId,
    this.startDate,
    this.endDate,
    this.type,
  });
}

class GetTransactionsGroupedParams {
  final String userId;
  final String walletId;
  final TransactionTypeModel? type;
  final DateTime? startDate;
  final DateTime? endDate;

  GetTransactionsGroupedParams({
    required this.userId,
    required this.walletId,
    this.type,
    this.startDate,
    this.endDate,
  });
}
