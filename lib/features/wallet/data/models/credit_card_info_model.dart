import 'package:hive/hive.dart';

import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';

/// [CardStatement]'ın saklama biçimi (Hive typeId 18; `CreditCardInfoModel`
/// içinde durur).
///
/// Alan numaraları KALICIDIR (bkz. CLAUDE.md): yeniden numaralandırılmaz,
/// silinen alanın numarası yakılır; yeni alan nullable eklenir.
class CardStatementModel {
  final DateTime closingDate;
  final DateTime dueDate;
  final double statementBalance;
  final double? minimumPayment;
  final String source;
  final DateTime recordedAt;

  const CardStatementModel({
    required this.closingDate,
    required this.dueDate,
    required this.statementBalance,
    this.minimumPayment,
    required this.source,
    required this.recordedAt,
  });

  factory CardStatementModel.fromEntity(CardStatement e) => CardStatementModel(
        closingDate: e.closingDate,
        dueDate: e.dueDate,
        statementBalance: e.statementBalance,
        minimumPayment: e.minimumPayment,
        source: e.source,
        recordedAt: e.recordedAt,
      );

  CardStatement toEntity() => CardStatement(
        closingDate: closingDate,
        dueDate: dueDate,
        statementBalance: statementBalance,
        minimumPayment: minimumPayment,
        source: source,
        recordedAt: recordedAt,
      );

  /// Sıkı cast: sessiz yanlış yorumlama gürültülü hatadan kötüdür.
  factory CardStatementModel.fromJson(Map<String, dynamic> json) =>
      CardStatementModel(
        closingDate: DateTime.parse(json['closingDate'] as String),
        dueDate: DateTime.parse(json['dueDate'] as String),
        statementBalance: (json['statementBalance'] as num).toDouble(),
        minimumPayment: (json['minimumPayment'] as num?)?.toDouble(),
        source: json['source'] as String,
        recordedAt: DateTime.parse(json['recordedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'closingDate': closingDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'statementBalance': statementBalance,
        'minimumPayment': minimumPayment,
        'source': source,
        'recordedAt': recordedAt.toIso8601String(),
      };
}

/// [CreditCardInfo]'nun saklama biçimi (Hive typeId 17; `WalletModel` alan 15).
class CreditCardInfoModel {
  final String? bankName;
  final String? last4;
  final double? limit;
  final int closingDay;
  final int dueDay;
  final String? paymentWalletId;
  final CardStatementModel? lastStatement;

  // Şema 16 (alan 7–9). Üçü de nullable: eski kayıtta YOKTUR ve `null`
  // "ayarlanmamış" demektir — bugünkü davranış aynen sürer.
  final int? dueOffsetDays;
  final double? monthlyInterestRate;
  final double? lateInterestRate;

  const CreditCardInfoModel({
    this.bankName,
    this.last4,
    this.limit,
    required this.closingDay,
    required this.dueDay,
    this.paymentWalletId,
    this.lastStatement,
    this.dueOffsetDays,
    this.monthlyInterestRate,
    this.lateInterestRate,
  });

  factory CreditCardInfoModel.fromEntity(CreditCardInfo e) =>
      CreditCardInfoModel(
        bankName: e.bankName,
        last4: e.last4,
        limit: e.limit,
        closingDay: e.closingDay,
        dueDay: e.dueDay,
        paymentWalletId: e.paymentWalletId,
        lastStatement: e.lastStatement == null
            ? null
            : CardStatementModel.fromEntity(e.lastStatement!),
        dueOffsetDays: e.dueOffsetDays,
        monthlyInterestRate: e.monthlyInterestRate,
        lateInterestRate: e.lateInterestRate,
      );

  CreditCardInfo toEntity() => CreditCardInfo(
        bankName: bankName,
        last4: last4,
        limit: limit,
        closingDay: closingDay,
        dueDay: dueDay,
        paymentWalletId: paymentWalletId,
        lastStatement: lastStatement?.toEntity(),
        dueOffsetDays: dueOffsetDays,
        monthlyInterestRate: monthlyInterestRate,
        lateInterestRate: lateInterestRate,
      );

  factory CreditCardInfoModel.fromJson(Map<String, dynamic> json) =>
      CreditCardInfoModel(
        bankName: json['bankName'] as String?,
        last4: json['last4'] as String?,
        limit: (json['limit'] as num?)?.toDouble(),
        closingDay: json['closingDay'] as int,
        dueDay: json['dueDay'] as int,
        paymentWalletId: json['paymentWalletId'] as String?,
        lastStatement: json['lastStatement'] == null
            ? null
            : CardStatementModel.fromJson(
                Map<String, dynamic>.from(json['lastStatement'] as Map)),
        dueOffsetDays: json['dueOffsetDays'] as int?,
        monthlyInterestRate: (json['monthlyInterestRate'] as num?)?.toDouble(),
        lateInterestRate: (json['lateInterestRate'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'bankName': bankName,
        'last4': last4,
        'limit': limit,
        'closingDay': closingDay,
        'dueDay': dueDay,
        'paymentWalletId': paymentWalletId,
        'lastStatement': lastStatement?.toJson(),
        'dueOffsetDays': dueOffsetDays,
        'monthlyInterestRate': monthlyInterestRate,
        'lateInterestRate': lateInterestRate,
      };
}

/// El yazımı: alan listesi ve okuma varsayılanları tek bakışta görünsün.
class CreditCardInfoModelAdapter extends TypeAdapter<CreditCardInfoModel> {
  @override
  final int typeId = 17;

  @override
  CreditCardInfoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CreditCardInfoModel(
      bankName: fields[0] as String?,
      last4: fields[1] as String?,
      limit: (fields[2] as num?)?.toDouble(),
      closingDay: fields[3] as int,
      dueDay: fields[4] as int,
      paymentWalletId: fields[5] as String?,
      lastStatement: fields[6] as CardStatementModel?,
      // 7–9 şema 16'da geldi: eski (7 alanlı) kayıtta yoktur → null.
      dueOffsetDays: fields[7] as int?,
      monthlyInterestRate: (fields[8] as num?)?.toDouble(),
      lateInterestRate: (fields[9] as num?)?.toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, CreditCardInfoModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.bankName)
      ..writeByte(1)
      ..write(obj.last4)
      ..writeByte(2)
      ..write(obj.limit)
      ..writeByte(3)
      ..write(obj.closingDay)
      ..writeByte(4)
      ..write(obj.dueDay)
      ..writeByte(5)
      ..write(obj.paymentWalletId)
      ..writeByte(6)
      ..write(obj.lastStatement)
      ..writeByte(7)
      ..write(obj.dueOffsetDays)
      ..writeByte(8)
      ..write(obj.monthlyInterestRate)
      ..writeByte(9)
      ..write(obj.lateInterestRate);
  }
}

class CardStatementModelAdapter extends TypeAdapter<CardStatementModel> {
  @override
  final int typeId = 18;

  @override
  CardStatementModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CardStatementModel(
      closingDate: fields[0] as DateTime,
      dueDate: fields[1] as DateTime,
      statementBalance: (fields[2] as num).toDouble(),
      minimumPayment: (fields[3] as num?)?.toDouble(),
      source: fields[4] as String? ?? CardStatementSource.manual,
      recordedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CardStatementModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.closingDate)
      ..writeByte(1)
      ..write(obj.dueDate)
      ..writeByte(2)
      ..write(obj.statementBalance)
      ..writeByte(3)
      ..write(obj.minimumPayment)
      ..writeByte(4)
      ..write(obj.source)
      ..writeByte(5)
      ..write(obj.recordedAt);
  }
}
