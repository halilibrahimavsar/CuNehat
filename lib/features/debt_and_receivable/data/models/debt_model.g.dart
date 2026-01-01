// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DebtAdapter extends TypeAdapter<Debt> {
  @override
  final int typeId = 6;

  @override
  Debt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Debt(
      id: fields[0] as String,
      userId: fields[1] as String,
      walletId: fields[2] as String,
      title: fields[3] as String,
      type: fields[4] as DebtType,
      principalAmount: fields[5] as double,
      interestRate: fields[6] as double,
      termMonths: fields[7] as int,
      startDate: fields[8] as DateTime,
      dueDate: fields[9] as DateTime?,
      bankName: fields[10] as String?,
      personName: fields[11] as String?,
      latePaymentDays: fields[12] as int,
      latePaymentInterest: fields[13] as double,
      payments: (fields[14] as List).cast<Payment>(),
      isPaid: fields[15] as bool,
      notes: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Debt obj) {
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
      ..writeByte(10)
      ..write(obj.bankName)
      ..writeByte(11)
      ..write(obj.personName)
      ..writeByte(12)
      ..write(obj.latePaymentDays)
      ..writeByte(13)
      ..write(obj.latePaymentInterest)
      ..writeByte(14)
      ..write(obj.payments)
      ..writeByte(15)
      ..write(obj.isPaid)
      ..writeByte(16)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 2;

  @override
  Payment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Payment(
      date: fields[0] as DateTime,
      amount: fields[1] as double,
      notes: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
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
      other is PaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DebtTypeAdapter extends TypeAdapter<DebtType> {
  @override
  final int typeId = 5;

  @override
  DebtType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DebtType.bankLoan;
      case 1:
        return DebtType.installmentDebt;
      case 2:
        return DebtType.personalDebt;
      case 3:
        return DebtType.otherDebt;
      default:
        return DebtType.bankLoan;
    }
  }

  @override
  void write(BinaryWriter writer, DebtType obj) {
    switch (obj) {
      case DebtType.bankLoan:
        writer.writeByte(0);
        break;
      case DebtType.installmentDebt:
        writer.writeByte(1);
        break;
      case DebtType.personalDebt:
        writer.writeByte(2);
        break;
      case DebtType.otherDebt:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
