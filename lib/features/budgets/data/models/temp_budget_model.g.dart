// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'temp_budget_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TempBudgetModelAdapter extends TypeAdapter<TempBudgetModel> {
  @override
  final int typeId = 19;

  @override
  TempBudgetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TempBudgetModel(
      id: fields[0] as String,
      walletId: fields[1] as String,
      name: fields[2] as String,
      limitAmount: fields[3] as double,
      startDate: fields[4] as DateTime,
      endDate: fields[5] as DateTime,
      categoryIds: (fields[6] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, TempBudgetModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.walletId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.limitAmount)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.endDate)
      ..writeByte(6)
      ..write(obj.categoryIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TempBudgetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
