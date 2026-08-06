import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:hive/hive.dart';

/// [DebtCalcMode] için elle yazılmış Hive adapter'ı.
///
/// Enum domain katmanında yaşıyor (entity'nin bir alanı); Clean Architecture
/// gereği orada Hive anotasyonu bulunamaz, bu yüzden codegen yerine adapter
/// burada elle tutulur — `DebtTypeAdapter` ile aynı desen.
class DebtCalcModeAdapter extends TypeAdapter<DebtCalcMode> {
  @override
  final int typeId = 14;

  @override
  DebtCalcMode read(BinaryReader reader) {
    final index = reader.readByte();
    // Diskteki index gelecekte enum'dan çıkarılmış olabilir; açılışta
    // RangeError yerine güvenli varsayılana düş.
    return index < DebtCalcMode.values.length
        ? DebtCalcMode.values[index]
        : DebtCalcMode.none;
  }

  @override
  void write(BinaryWriter writer, DebtCalcMode obj) {
    writer.writeByte(obj.index);
  }
}
