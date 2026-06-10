# CuNehat release (R8) kuralları.
# Hive üretilmiş adapter kullanır (reflection yok); google_sign_in /
# local_auth / flutter_secure_storage kendi consumer kurallarını taşır.
# Release duman testinde crash çıkarsa kural buraya eklenir.
-keepattributes *Annotation*, Signature

# Flutter deferred components kullanılmıyor; Play Core referanslarını sustur.
-dontwarn com.google.android.play.core.**
