import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/transaction_entity.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 1)
class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.userId,
    required super.walletId,
    required super.title,
    required super.tag,
    required super.amount,
    required super.date,
    required super.type,
    super.isSystem = false,
  });

  /// ✅ FIXED: Handle both Timestamp (Firestore) and String (Hive/old data)
  factory TransactionModel.fromJson(String id, Map<String, dynamic> json) {
    // Parse date - support both Timestamp and String
    DateTime parsedDate;
    final dateField = json['date'];

    if (dateField is Timestamp) {
      // From Firestore
      parsedDate = dateField.toDate();
    } else if (dateField is String) {
      // From old data or Hive
      parsedDate = DateTime.parse(dateField);
    } else {
      throw Exception('Invalid date format in transaction data');
    }

    return TransactionModel(
      id: id,
      userId: json['userId'] as String,
      walletId: json['walletId'] as String,
      title: json['title'] as String,
      tag: json['tag'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: parsedDate,
      type: _parseTransactionType(json['type'] as String),
      isSystem: json['isSystem'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'walletId': walletId,
      'title': title,
      'tag': tag,
      'amount': amount,
      'date': Timestamp.fromDate(date), // ✅ Use Timestamp like WalletModel
      'type': type == TransactionTypeModel.income ? 'income' : 'expense',
      'isSystem': isSystem,
    };
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      userId: entity.userId,
      walletId: entity.walletId,
      title: entity.title,
      tag: entity.tag,
      amount: entity.amount,
      date: entity.date,
      type: entity.type,
      isSystem: entity.isSystem,
    );
  }

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      userId: userId,
      walletId: walletId,
      title: title,
      tag: tag,
      amount: amount,
      date: date,
      type: type,
      isSystem: isSystem,
    );
  }

  static TransactionTypeModel _parseTransactionType(String type) {
    return type == 'income'
        ? TransactionTypeModel.income
        : TransactionTypeModel.expense;
  }

  @override
  TransactionModel copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? title,
    String? tag,
    double? amount,
    DateTime? date,
    TransactionTypeModel? type,
    bool? isSystem,
  }) {
    return TransactionModel(
      id: id ?? this.id, // preserve id (önceden id düşüyordu — düzeltildi)
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      isSystem: isSystem ?? this.isSystem,
    );
  }

  @override
  @HiveField(0)
  String? get id => super.id;

  @override
  @HiveField(1)
  String get userId => super.userId;

  @override
  @HiveField(2)
  String get walletId => super.walletId;

  @override
  @HiveField(3)
  String get title => super.title;

  @override
  @HiveField(4)
  String get tag => super.tag;

  @override
  @HiveField(5)
  double get amount => super.amount;

  @override
  @HiveField(6)
  DateTime get date => super.date;

  @override
  @HiveField(7)
  TransactionTypeModel get type => super.type;

  @override
  @HiveField(8, defaultValue: false)
  bool get isSystem => super.isSystem;
}
