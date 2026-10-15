/// Uygulamanın sürüm adı (`pubspec.yaml` → `version:` alanının `+` öncesi).
///
/// Çekmecenin dibindeki sürüm satırı eskiden elle yazılmış bir metindi
/// ('ÇuHat v1.0.0') ve pubspec'ten bağımsızdı: sürüm yükseltildiğinde ekranda
/// eskisi kalırdı. Çalışma anında pubspec okunamaz ve bunun için yerel bir
/// eklenti (package_info) eklemek tek satır için fazla; onun yerine sabit
/// burada durur ve `test/core/constants/app_version_test.dart` onu pubspec'le
/// KARŞILAŞTIRIR — sürümü yükseltip burayı unutan commit testte kırılır.
const String kAppVersionName = '1.1.0';

/// Uygulamanın görünen adı. Çeviriye girmez: ad her dilde aynıdır.
const String kAppName = 'ÇuHat';
