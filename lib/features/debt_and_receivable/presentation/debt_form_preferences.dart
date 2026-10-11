import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Borç formunun cihazda hatırladığı tek şey: son kullanılan borç türü.
///
/// Form eskiden her açılışta Banka Kredisi ile, yani EN KARMAŞIK hâliyle
/// geliyordu (hesap modu + vade + taksit + gecikme faizi); arkadaşına borcunu
/// yazacak kullanıcı önce o alanların kendisini ilgilendirmediğini çözmek
/// zorundaydı. Artık ilk açılış Kişisel, sonrakiler son kaydedilen tür.
///
/// Tür ADIYLA saklanır (indeksle değil): enum'a değer eklenmesi ya da sıranın
/// değişmesi eski tercihi başka bir türe kaydırmaz. Tanınmayan ad varsayılana
/// düşer. Yedeğe girmez — bir cihaz alışkanlığıdır, veri değil.
class DebtFormPreferences {
  const DebtFormPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const String lastTypeKey = 'debt_form_last_type';

  static const DebtType fallbackType = DebtType.personalDebt;

  DebtType lastType() {
    final name = _prefs.getString(lastTypeKey);
    for (final type in DebtType.values) {
      if (type.name == name) return type;
    }
    return fallbackType;
  }

  Future<void> rememberType(DebtType type) =>
      _prefs.setString(lastTypeKey, type.name);
}
