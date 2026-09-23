import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
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
    super.receiptFileName,
    super.reference,
    super.linkedRecordId,
    super.adoptedFromTag,
    super.origin,
  });

  /// ✅ FIXED: Handle date as ISO 8601 String
  factory TransactionModel.fromJson(String id, Map<String, dynamic> json) {
    DateTime parsedDate;
    final dateField = json['date'];

    if (dateField is String) {
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
      isSystem: json['isSystem'] as bool,
      receiptFileName: json['receiptFileName'] as String?,
      reference: json['reference'] as String?,
      // v11 (yedek migrasyonu v10 yedeklerine bu anahtarları açıkça `null`
      // olarak ekler).
      linkedRecordId: json['linkedRecordId'] as String?,
      adoptedFromTag: json['adoptedFromTag'] as String?,
      origin: json['origin'] as String?,
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
      'date': date.toIso8601String(),
      'type': type == TransactionTypeModel.income ? 'income' : 'expense',
      'isSystem': isSystem,
      'receiptFileName': receiptFileName,
      'reference': reference,
      'linkedRecordId': linkedRecordId,
      'adoptedFromTag': adoptedFromTag,
      'origin': origin,
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
      receiptFileName: entity.receiptFileName,
      reference: entity.reference,
      linkedRecordId: entity.linkedRecordId,
      adoptedFromTag: entity.adoptedFromTag,
      origin: entity.origin,
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
      receiptFileName: receiptFileName,
      reference: reference,
      linkedRecordId: linkedRecordId,
      adoptedFromTag: adoptedFromTag,
      origin: origin,
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
    String? receiptFileName,
    String? reference,
    String? linkedRecordId,
    String? adoptedFromTag,
    String? origin,
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
      receiptFileName: receiptFileName ?? this.receiptFileName,
      reference: reference ?? this.reference,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      adoptedFromTag: adoptedFromTag ?? this.adoptedFromTag,
      origin: origin ?? this.origin,
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
  @HiveField(8)
  bool get isSystem => super.isSystem;

  @override
  @HiveField(9)
  String? get receiptFileName => super.receiptFileName;

  @override
  @HiveField(10)
  String? get reference => super.reference;

  // v11 (şema): üçü de nullable — eski kayıtta alan yoktur, `null` okunur.
  // Sıradaki serbest alan: 14.

  @override
  @HiveField(11)
  String? get linkedRecordId => super.linkedRecordId;

  @override
  @HiveField(12)
  String? get adoptedFromTag => super.adoptedFromTag;

  @override
  @HiveField(13)
  String? get origin => super.origin;
}
