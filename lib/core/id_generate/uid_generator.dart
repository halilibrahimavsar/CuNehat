import 'package:uuid/uuid.dart';

class UidGenerator {
  static const Uuid _uuid = Uuid();

  /// Standart UUID v7 + Kullanıcı ID'si
  /// Çıktı Örneği: "018c1b3d-2e4a-7123-8b44-9d0e1f2a3b4c:user_5912"
  static String generateWithUserId() {
    // final v7 = _uuid.v7();
    // return '$v7:$userId'; // Ayıraç olarak : veya _ kullanabilirsin
    return _uuid.v7();
  }
}
