// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvestmentModelAdapter extends TypeAdapter<InvestmentModel> {
  @override
  final int typeId = 4;

  @override
  InvestmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvestmentModel(
      id: fields[0] as String?,
      userId: fields[1] as String,
      walletId: fields[2] as String,
      name: fields[3] as String,
      amount: fields[4] as double,
      currentValue: fields[5] as double,
      type: fields[6] as InvestmentType,
      color: fields[7] as Color,
      dateAdded: fields[8] as DateTime,
      symbol: fields[9] as String?,
      returnRate: fields[10] as double?,
      targetAmount: fields[11] as double?,
      quantity: fields[12] as double?,
      goalCategory: fields[13] as String?,
      currency: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, InvestmentModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.walletId)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.currentValue)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.color)
      ..writeByte(8)
      ..write(obj.dateAdded)
      ..writeByte(9)
      ..write(obj.symbol)
      ..writeByte(10)
      ..write(obj.returnRate)
      ..writeByte(11)
      ..write(obj.targetAmount)
      ..writeByte(12)
      ..write(obj.quantity)
      ..writeByte(13)
      ..write(obj.goalCategory)
      ..writeByte(14)
      ..write(obj.currency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvestmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
