// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransferModelAdapter extends TypeAdapter<TransferModel> {
  @override
  final int typeId = 3;

  @override
  TransferModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransferModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      fromWalletId: fields[2] as String,
      toWalletId: fields[3] as String,
      amount: fields[4] as double,
      note: fields[5] as String,
      date: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TransferModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.fromWalletId)
      ..writeByte(3)
      ..write(obj.toWalletId)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
