import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:hive/hive.dart';

class DebtTypeAdapter extends TypeAdapter<DebtType> {
  @override
  final int typeId = 10; // Diğer ID'lerle çakışmayan benzersiz bir ID

  @override
  DebtType read(BinaryReader reader) {
    final index = reader.readByte();
    // Diskteki index gelecekte enum'dan çıkarılmış olabilir; açılışta
    // RangeError yerine güvenli varsayılana düş.
    return index < DebtType.values.length
        ? DebtType.values[index]
        : DebtType.otherDebt;
  }

  @override
  void write(BinaryWriter writer, DebtType obj) {
    writer.writeByte(obj.index);
  }
}
