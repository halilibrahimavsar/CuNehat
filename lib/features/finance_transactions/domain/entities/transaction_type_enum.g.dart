// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_type_enum.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionTypeModelAdapter extends TypeAdapter<TransactionTypeModel> {
  @override
  final int typeId = 2;

  @override
  TransactionTypeModel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionTypeModel.income;
      case 1:
        return TransactionTypeModel.expense;
      default:
        return TransactionTypeModel.income;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionTypeModel obj) {
    switch (obj) {
      case TransactionTypeModel.income:
        writer.writeByte(0);
        break;
      case TransactionTypeModel.expense:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionTypeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
