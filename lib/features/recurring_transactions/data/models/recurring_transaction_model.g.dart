// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringTransactionModelAdapter
    extends TypeAdapter<RecurringTransactionModel> {
  @override
  final int typeId = 11;

  @override
  RecurringTransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringTransactionModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      walletId: fields[2] as String,
      title: fields[3] as String,
      tag: fields[4] as String,
      amount: fields[5] as double,
      type: fields[6] as TransactionTypeModel,
      frequency: fields[7] as RecurringFrequency,
      nextExecutionDate: fields[8] as DateTime,
      isActive: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringTransactionModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.walletId)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.tag)
      ..writeByte(5)
      ..write(obj.amount)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.frequency)
      ..writeByte(8)
      ..write(obj.nextExecutionDate)
      ..writeByte(9)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
