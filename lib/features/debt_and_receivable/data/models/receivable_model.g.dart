// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receivable_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReceivableAdapter extends TypeAdapter<Receivable> {
  @override
  final int typeId = 7;

  @override
  Receivable read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Receivable(
      id: fields[0] as String,
      userId: fields[1] as String,
      walletId: fields[2] as String,
      title: fields[3] as String,
      fromPerson: fields[4] as String,
      amount: fields[5] as double,
      expectedDate: fields[6] as DateTime,
      receivedDate: fields[7] as DateTime?,
      isReceived: fields[8] as bool,
      notes: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Receivable obj) {
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
      ..write(obj.fromPerson)
      ..writeByte(5)
      ..write(obj.amount)
      ..writeByte(6)
      ..write(obj.expectedDate)
      ..writeByte(7)
      ..write(obj.receivedDate)
      ..writeByte(8)
      ..write(obj.isReceived)
      ..writeByte(9)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceivableAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
