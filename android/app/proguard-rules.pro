# CuNehat release (R8) kuralları.
# Hive üretilmiş adapter kullanır (reflection yok); google_sign_in /
# local_auth / flutter_secure_storage kendi consumer kurallarını taşır.
# Release duman testinde crash çıkarsa kural buraya eklenir.
-keepattributes *Annotation*, Signature

# Flutter deferred components kullanılmıyor; Play Core referanslarını sustur.
-dontwarn com.google.android.play.core.**

# ---------------------------------------------------------------------------
# google_mlkit_text_recognition — kullanılmayan betik (script) paketleri
#
# Plugin yalnız `com.google.mlkit:text-recognition` (Latin) bağımlılığını
# bildirir, ama Java tarafı betik seçimi için Çince/Devanagari/Japonca/Korece
# seçenek sınıflarına da atıf yapar. O artefaktlar sınıf yolunda olmadığından
# R8 "Missing class" ile derlemeyi KIRAR (uyarı değil, hata).
#
# Uygulama her iki OCR yolunda da yalnız `TextRecognitionScript.latin`
# kullanıyor (receipt_ocr_service.dart, statement_ocr_service.dart), yani bu
# kod yolları erişilemez. Betik desteği eklenirse buradaki kuralı kaldırıp
# ilgili `text-recognition-<script>` bağımlılığını eklemek gerekir.
# ---------------------------------------------------------------------------
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# ---------------------------------------------------------------------------
# flutter_local_notifications + GSON  —  BU KURALLAR ZORUNLU
#
# Plugin, planladığı her bildirimi `NotificationDetails` olarak GSON ile
# SharedPreferences'a serileştirir; ScheduledNotificationBootReceiver cihaz
# yeniden başladığında bunu geri okuyup alarmları tekrar kurar
# (FlutterLocalNotificationsPlugin: `TypeToken<ArrayList<NotificationDetails>>`,
#  ScheduledNotificationReceiver: `TypeToken<NotificationDetails>`).
#
# AGP 8+ ile R8 **full mode** varsayılan olarak açıktır (gradle.properties'te
# android.enableR8.fullMode kapatılmadı): reflection ile örneklenen sınıfların
# varsayılan kurucuları korunmaz, alan ve enum sabit adları yeniden adlandırılır.
# Kurallar olmadan serileştirme/geri okuma bozulur — CRASH ÇIKMAZ, bildirimler
# yalnızca sessizce hiç gelmez (özellikle cihaz yeniden başlatıldıktan sonra).
# Plugin README'si bu kuralları açıkça şart koşar.
#
# Kapsam bilinçli olarak dar: uygulamada GSON'u yalnız bu plugin kullanıyor,
# bu yüzden "tüm sınıfların varsayılan kurucusunu koru" gibi geniş bir kural
# yerine paketin tamamı korunuyor.
# ---------------------------------------------------------------------------
-keep class com.dexterous.** { *; }

# GSON'un kendi gereksinimleri (bkz. google/gson android-proguard-example).
# TypeToken'ın generic imzası silinirse ArrayList<NotificationDetails> ham
# ArrayList'e düşer ve geri okuma LinkedTreeMap üretip ClassCastException verir.
-dontwarn sun.misc.**
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Enum sabitleri ada göre serileştirilir (ScheduleMode, RepeatInterval,
# NotificationStyle, DateTimeComponents); yeniden adlandırma geri okumayı bozar.
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
