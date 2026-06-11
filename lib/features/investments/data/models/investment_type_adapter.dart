import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:hive/hive.dart';

class InvestmentTypeAdapter extends TypeAdapter<InvestmentType> {
  @override
  final int typeId = 5; // InvestmentModel 4 olduğu için buna 5 verdik

  @override
  InvestmentType read(BinaryReader reader) {
    final index = reader.readByte();
    // Diskteki index gelecekte enum'dan çıkarılmış olabilir; açılışta
    // RangeError yerine güvenli varsayılana düş.
    return index < InvestmentType.values.length
        ? InvestmentType.values[index]
        : InvestmentType.custom;
  }

  @override
  void write(BinaryWriter writer, InvestmentType obj) {
    writer.writeByte(obj.index);
  }
}
