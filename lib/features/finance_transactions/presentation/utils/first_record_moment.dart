import 'dart:async';

import 'package:cunehat/features/main_feature/utils/section_records.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kurulumun İLK kaydını fark eder — bir kez.
///
/// İlk kayıt, uygulamayı deneyen biriyle kullanan biri arasındaki eşiktir;
/// eskiden hiçbir şey olmuyordu. Bir kutlama değil, tek sakin cümle:
/// yazmaya devam etmenin ne getireceğini söyler.
///
/// Sorulduktan sonra bir daha sorulmaz (bayrak sonuçtan bağımsız yazılır):
/// güncellemeyle gelen ya da yedeğini geri yüklemiş kullanıcının defteri
/// zaten doludur, ona "ilk kaydın" demek yanlış olurdu.
class FirstRecordMoment {
  FirstRecordMoment(this._prefs, this._records);

  static const String notedKey = 'first_record_noted';

  final SharedPreferences _prefs;
  final SectionRecords _records;

  /// Kayıt yazılmadan HEMEN ÖNCE çağrılır. Defter boşsa ve daha önce
  /// sorulmadıysa `true`.
  bool takeIfFirst() {
    if (_prefs.getBool(notedKey) ?? false) return false;
    final first = _records.transactionCount == 0;
    unawaited(_prefs.setBool(notedKey, true));
    return first;
  }
}
