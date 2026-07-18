// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DebtModelAdapter extends TypeAdapter<DebtModel> {
  @override
  final int typeId = 6;

  @override
  DebtModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DebtModel(
      id: fields[0] as String?,
      userId: fields[1] as String,
      walletId: fields[2] as String,
      title: fields[3] as String,
      counterparty: fields[17] as String,
      type: fields[4] as DebtType,
      principalAmount: fields[5] as double,
      interestRate: fields[6] as double,
      termMonths: fields[7] as int,
      overdueInterestRate: fields[13] as double,
      startDate: fields[8] as DateTime,
      dueDate: fields[9] as DateTime?,
      payments: (fields[14] as List).cast<Payment>(),
      isPaid: fields[15] as bool,
      notes: fields[16] as String?,
      expectedTotalAmount: fields[18] as double?,
      principalToWallet: fields[19] == null ? true : fields[19] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DebtModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.walletId)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(17)
      ..write(obj.counterparty)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.principalAmount)
      ..writeByte(6)
      ..write(obj.interestRate)
      ..writeByte(7)
      ..write(obj.termMonths)
      ..writeByte(8)
      ..write(obj.startDate)
      ..writeByte(9)
      ..write(obj.dueDate)
      ..writeByte(13)
      ..write(obj.overdueInterestRate)
      ..writeByte(14)
      ..write(obj.payments)
      ..writeByte(15)
      ..write(obj.isPaid)
      ..writeByte(16)
      ..write(obj.notes)
      ..writeByte(18)
      ..write(obj.expectedTotalAmount)
      ..writeByte(19)
      ..write(obj.principalToWallet);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentModelAdapter extends TypeAdapter<PaymentModel> {
  @override
  final int typeId = 9;

  @override
  PaymentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentModel(
      date: fields[0] as DateTime,
      amount: fields[1] as double,
      notes: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
