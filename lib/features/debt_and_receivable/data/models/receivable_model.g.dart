// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receivable_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReceivableModelAdapter extends TypeAdapter<ReceivableModel> {
  @override
  final int typeId = 7;

  @override
  ReceivableModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReceivableModel(
      id: fields[0] as String?,
      userId: fields[1] as String,
      walletId: fields[2] as String,
      debtorName: fields[3] as String,
      amount: fields[4] as double,
      dueDate: fields[5] as DateTime,
      isPaid: fields[6] as bool,
      notes: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ReceivableModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.walletId)
      ..writeByte(3)
      ..write(obj.debtorName)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.isPaid)
      ..writeByte(7)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceivableModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
